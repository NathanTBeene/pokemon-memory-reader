-- Pokemon Data Reader
-- Handles reading Pokemon data from ROM tables

local pokemonData = {}
local gameUtils = require("utils.gameutils")
local constants = require("data.constants")
local charmaps = require("data.charmaps")

-- Read species name from ROM
function pokemonData.readSpeciesName(speciesId)
    -- Get game data
    local gameData = MemoryReader.currentGame
    if not gameData then
        return "Unknown"
    end

    -- We always attempt to get the name from the ROM first.
    local speciesNameTableAddr = gameData.addresses.speciesNameTable

    if speciesNameTableAddr then
        local nameAddr = gameUtils.hexToNumber(speciesNameTableAddr) + (speciesId * 11)
        local nameBytes = gameUtils.readBytes(nameAddr, 10, "ROM")
        local name = charmaps.decryptText(nameBytes, "GBA")
        return name
    end

    -- A fallback for romhacks and unknown games.
    -- Checks in the constants.
    if gameData.gameInfo.isRomhack then
        if speciesId > 0 and speciesId <= #constants.pokemonData.species then
            return constants.pokemonData.species[speciesId + 1]
        end
        return "Unknown"
    end

    -- Normal gen 3 games have an odd offset for the species ID's
    -- Anything after the first two gens is offset by 24.
    if speciesId > 0 and speciesId <= #constants.pokemonData.species then
        -- If ID is greater than 177, we need to account for the offset.
        if speciesId > 177 then
            return constants.pokemonData.species[speciesId - 24]
        end

        return constants.pokemonData.species[speciesId + 1]
    end
    
    return "Unknown"
end

-- Read nature name from ROM
function pokemonData.readNatureName(natureID)
    if not natureID then
        return "Unknown"
    end

    local gameData = MemoryReader.currentGame
    if not gameData then
        return "Unknown"
    end

    -- Always attempt to read from the ROM first.
    local naturePointersAddr = gameData.addresses.naturePointersAddr
    if not naturePointersAddr then
        -- Fallback to constants if no ROM address is available.
        return constants.pokemonData.nature[natureID + 1]
    end

    local pointerAddr = gameUtils.hexToNumber(naturePointersAddr) + (natureID * 4)
    local natureAddr = gameUtils.read32(pointerAddr, "ROM")
    if not natureAddr then
        return "Unknown"
    end

    local nameBytes = gameUtils.readBytes(natureAddr, 8, "ROM")
    local name = charmaps.decryptText(nameBytes, "GBA")
    return name
end

-- Read species base stats and abilities from ROM
function pokemonData.readSpeciesData(speciesId)
    -- Get game data from database
    local gameData = MemoryReader.currentGame
    if not gameData then
        console.log("Game data not found for current ROM!")
        return nil
    end

    -- Get species data table address
    local speciesDataAddr = gameData.addresses.speciesDataTable
    if not speciesDataAddr then
        console.log("Unknown species data address for game: " .. gameData.gameInfo.name)
        return nil
    end
    
    -- Convert hex string to number and calculate species offset
    local tableAddr = gameUtils.hexToNumber(speciesDataAddr)
    local speciesDataSize = 28  -- Standard GBA species data size
    local speciesAddr = tableAddr + ((speciesId) * speciesDataSize)

    local domain = "ROM"
    
    return {
        baseHP = gameUtils.read8(speciesAddr + 0, domain),
        baseAttack = gameUtils.read8(speciesAddr + 1, domain),
        baseDefense = gameUtils.read8(speciesAddr + 2, domain),
        baseSpeed = gameUtils.read8(speciesAddr + 3, domain),
        baseSpAttack = gameUtils.read8(speciesAddr + 4, domain),
        baseSpDefense = gameUtils.read8(speciesAddr + 5, domain),

        -- If singular type, both types will be the same value.
        type1 = gameUtils.read8(speciesAddr + 6, domain),
        type2 = gameUtils.read8(speciesAddr + 7, domain),
        catchRate = gameUtils.read8(speciesAddr + 8, domain),
        baseExpYield = gameUtils.read8(speciesAddr + 9, domain),

        -- Effort Values is two bytes. Each stat is given
        -- two bits to determine the yield, and the rest
        -- are empty.
        effortYield = gameUtils.read16(speciesAddr + 10, domain),

        -- The item ID here is a 50% chance for the pokemon
        -- to be holding this item.
        item1 = gameUtils.read16(speciesAddr + 12, domain),

        -- Item 2 is a 5% chance. If both are the same, then
        -- the pokemon will ALWAYS hold that item.
        item2 = gameUtils.read16(speciesAddr + 14, domain),

        -- The chance a pokemon will be male or female.
        -- This is compared with the lowest byte of the
        -- personality value to determine the nature.
        -- 0 = Always Male
        -- 1-253 = Mixed
        -- 254 = Always Female
        -- 255 = Genderless
        gender = gameUtils.read8(speciesAddr + 16, domain),
        eggCycles = gameUtils.read8(speciesAddr + 17, domain),
        baseFriendship = gameUtils.read8(speciesAddr + 18, domain),
        levelUpType = gameUtils.read8(speciesAddr + 19, domain),
        eggGroup1 = gameUtils.read8(speciesAddr + 20, domain),
        eggGroup2 = gameUtils.read8(speciesAddr + 21, domain),

        -- The ability IDs of the two slots.
        ability1 = gameUtils.read8(speciesAddr + 22, domain),
        ability2 = gameUtils.read8(speciesAddr + 23, domain),
        safariZoneRate = gameUtils.read8(speciesAddr + 24, domain),
        colorAndFlip = gameUtils.read8(speciesAddr + 25, domain)
    }
end

-- Read ability name from ROM and fallback to constants.
function pokemonData.getAbilityName(abilityId)
    local gameData = MemoryReader.currentGame
    if not gameData then
        console.log("Game data not found for current ROM!")
        return "Unknown"
    end

    local abilityNameTableAddr = gameData.addresses.abilityNameTable
    if not abilityNameTableAddr then
        console.log("No ability name table address for game. Falling back to constants.")
        if abilityId >= 0 and abilityId < #constants.pokemonData.ability then
            return constants.pokemonData.ability[abilityId + 1]
        end
        return "Unknown"
    end

    local nameAddr = gameUtils.hexToNumber(abilityNameTableAddr) + (abilityId * 13)
    local nameBytes = gameUtils.readBytes(nameAddr, 12, "ROM")
    return charmaps.decryptText(nameBytes) or "Unknown"
end

-- Get type name from constants
function pokemonData.getTypeName(typeId)
    if typeId >= 0 and typeId < #constants.pokemonData.type then
        return constants.pokemonData.type[typeId + 1]
    end
    return "Unknown"
end

-- Get hidden power type name from constants
function pokemonData.getHiddenPowerName(hpTypeId)
    if hpTypeId >= 0 and hpTypeId < #constants.pokemonData.hiddenPowerType then
        return constants.pokemonData.hiddenPowerType[hpTypeId + 1]
    end
    return "Unknown"
end

function pokemonData.getTMMoveID(tmNumber)
    local gameData = MemoryReader.currentGame
    if not gameData then
        console.log("Game data not found for current ROM!")
        return nil
    end

    local tmToMoveTableAddr = gameData.addresses.tmToMoveTable
    if not tmToMoveTableAddr then
        console.log("No TM to Move table address for game.")
        return nil
    end

    -- Gen 3 tms are 2 bytes each
    if gameData.gameInfo.generation == 3 then
        local moveId = gameUtils.read16(gameUtils.hexToNumber(tmToMoveTableAddr) + ((tmNumber - 1) * 2), "ROM")
        return moveId
    end

    local moveId = gameUtils.read8(gameUtils.hexToNumber(tmToMoveTableAddr) + (tmNumber - 1), "ROM")
    return moveId
end

-- Read variable length string from ROM
function pokemonData.getVariableLengthString(startingAddr, ID)
    local currentAddr = startingAddr
    local currentID = 1

    while currentID <= ID do
        local nameBytes = {}
        local byteValue = 0

        -- Read bytes until we hit a string terminator (0x50)
        repeat
            byteValue = gameUtils.read8(currentAddr, "ROM")
            currentAddr = currentAddr + 1
            
            table.insert(nameBytes, byteValue)
        until byteValue == 0x50

        if currentID == ID then
            table.remove(nameBytes)  -- Remove the terminator
            return charmaps.decryptText(nameBytes, "GB")
        end

        currentID = currentID + 1
    end
end

-- Get move name from constants
function pokemonData.getMoveName(moveId)
    local gameData = MemoryReader.currentGame
    if not gameData then
        console.log("Game data not found for current ROM!")
        return "Unknown"
    end
    local movesTableAddr = gameUtils.hexToNumber(gameData.addresses.moveNamesTable)

    -- Generation 2 has variable move names that end in a null terminator 0x50
    if gameData.gameInfo.generation == 2 then
        local name = pokemonData.getVariableLengthString(movesTableAddr, moveId)
        if name and name ~= "" then
            return name
        end
    end
    

    -- If we have a valid moves table address
    -- Moves are 13 bytes each
    if gameData and movesTableAddr then
        local moveNameAddr = movesTableAddr + (moveId * 13)
        local nameBytes = gameUtils.readBytes(moveNameAddr, 12, "ROM")
        return charmaps.decryptText(nameBytes)
    end

    if moveId >= 0 and moveId <= #constants.pokemonData.moves then
        return constants.pokemonData.moves[moveId + 1]
    end
    return "Unknown"
end

function pokemonData.getItemName(itemID)
    if not MemoryReader.isInitialized or not MemoryReader.currentGame or itemID <= 0 then
        return "Unknown"
    end

    local gameData = MemoryReader.currentGame
    if not gameData then
        console.log("Game data not found for current ROM!")
        return "Unknown"
    end

    -- If we have the itemNameTable then we get the name from the ROM.
    if gameData.addresses.itemNameTable then
        local name = pokemonData.getItemFromROM(itemID, gameData)
        if name and name ~= "" then
            return name
        end
            console.log("Failed to read item with id " .. itemID .. " from ROM.")
    end

    -- Fallback to constants if no ROM table is available.
    -- Offset id by 1 since Lua is 1-indexed.
    local generation = gameData.gameInfo.generation
    if generation == 1 then
        if itemID > 0 and itemID <= #constants.pokemonData.itemsGen1 then
            return constants.pokemonData.itemsGen1[itemID + 1]
        end
    elseif generation == 2 then
        if itemID > 0 and itemID <= #constants.pokemonData.itemsGen2 then
            return constants.pokemonData.itemsGen2[itemID + 1]
        end
    else
        if itemID > 0 and itemID <= #constants.pokemonData.itemsGen3 then
            return constants.pokemonData.itemsGen3[itemID + 1]
        end
    end

end

-- Item
function pokemonData.getItemFromROM(itemID, gameData)
    local tableAddr = gameData.addresses.itemNameTable
    local generation = gameData.gameInfo.generation

    if type(tableAddr) == "string" then
        tableAddr = gameUtils.hexToNumber(tableAddr)
    end

    if not tableAddr then
        console.log("No item name table address.")
        return nil
    end

    -- Generation 1 & 2 names are variable length with a null terminator.
    if generation == 1 or generation == 2 then
        return pokemonData.getVariableLengthString(tableAddr, itemID)
    end
    -- Gen 3 items are stored as the entire item structure.
    -- Each item is 44 bytes in total, and the name is the first 14 bytes.
    if generation == 3 then
        local itemAddr = tableAddr + ((itemID) * 44)
        local nameBytes = gameUtils.readBytes(itemAddr, 14, "ROM")
        return charmaps.decryptText(nameBytes, "GBA")
    end
end

return pokemonData
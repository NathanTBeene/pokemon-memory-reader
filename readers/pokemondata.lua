-- Pokemon Data Reader
-- Handles reading Pokemon data from ROM tables

local pokemonData = {}
local gameUtils = require("utils.gameutils")
local constants = require("data.constants")
local charmaps = require("data.charmaps")
local GamesDB = require("data.gamesdb")

-- Read species name from ROM
function pokemonData.readSpeciesName(speciesId, gameCode)
    -- Get game data from database
    local gameData = GamesDB.getGameByCode(gameCode)
    if not gameData then
        return "Unknown"
    end

    local speciesNameTableAddr = gameData.addresses.speciesNameTable

    if speciesNameTableAddr then
        local nameAddr = gameUtils.hexToNumber(speciesNameTableAddr) + (speciesId * 11)
        local nameBytes = gameUtils.readBytesROM(nameAddr, 10)
        local name = charmaps.decryptText(nameBytes, "GBA")
        return name
    end

    -- This should be used for romhacks.
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

function pokemonData.readNatureName(natureID, gameCode)
    console.log("reading nature name")
    if not natureID then
        return "Unknown"
    end

    -- get game from code
    local gameData = GamesDB.getGameByCode(gameCode)
    if not gameData then
        return "Unknown"
    end

    local naturePointersAddr = gameData.addresses.naturePointersAddr
    if not naturePointersAddr then
        return constants.pokemonData.nature[natureID + 1]
    end

    local pointerAddr = gameUtils.hexToNumber(naturePointersAddr) + (natureID * 4)
    local natureAddr = gameUtils.read32ROM(pointerAddr)
    if not natureAddr then
        return "Unknown"
    end

    local nameBytes = gameUtils.readBytesROM(natureAddr, 8)
    local name = charmaps.decryptText(nameBytes, "GBA")
    return name
end

-- Read species base stats and abilities from ROM
function pokemonData.readSpeciesData(speciesId, gameCode)
    -- Get game data from database
    local hash = gameUtils.getROMHash(gameCode)
    local gameData = GamesDB.getGameByHash(hash)
    if not gameData then
        console.log("Unknown game code: " .. gameCode)
        return nil
    end

    -- Get species data table address
    local speciesDataAddr = gameData.addresses.speciesDataTable
    if not speciesDataAddr then
        console.log("Unknown species data address for game code: " .. gameCode)
        return nil
    end
    
    -- Convert hex string to number and calculate species offset
    local tableAddr = gameUtils.hexToNumber(speciesDataAddr)
    local speciesDataSize = 28  -- Standard GBA species data size
    local speciesAddr = tableAddr + ((speciesId) * speciesDataSize)
    
    return {
        baseHP = gameUtils.read8ROM(speciesAddr + 0),
        baseAttack = gameUtils.read8ROM(speciesAddr + 1),
        baseDefense = gameUtils.read8ROM(speciesAddr + 2),
        baseSpeed = gameUtils.read8ROM(speciesAddr + 3),
        baseSpAttack = gameUtils.read8ROM(speciesAddr + 4),
        baseSpDefense = gameUtils.read8ROM(speciesAddr + 5),

        -- If singular type, both types will be the same value.
        type1 = gameUtils.read8ROM(speciesAddr + 6),
        type2 = gameUtils.read8ROM(speciesAddr + 7),
        catchRate = gameUtils.read8ROM(speciesAddr + 8),
        baseExpYield = gameUtils.read8ROM(speciesAddr + 9),

        -- Effort Values is two bytes. Each stat is given
        -- two bits to determine the yield, and the rest
        -- are empty.
        effortYield = gameUtils.read16ROM(speciesAddr + 10),

        -- The item ID here is a 50% chance for the pokemon
        -- to be holding this item.
        item1 = gameUtils.read16ROM(speciesAddr + 12),

        -- Item 2 is a 5% chance. If both are the same, then
        -- the pokemon will ALWAYS hold that item.
        item2 = gameUtils.read16ROM(speciesAddr + 14),

        -- The chance a pokemon will be male or female.
        -- This is compared with the lowest byte of the
        -- personality value to determine the nature.
        -- 0 = Always Male
        -- 1-253 = Mixed
        -- 254 = Always Female
        -- 255 = Genderless
        gender = gameUtils.read8ROM(speciesAddr + 16),
        eggCycles = gameUtils.read8ROM(speciesAddr + 17),
        baseFriendship = gameUtils.read8ROM(speciesAddr + 18),
        levelUpType = gameUtils.read8ROM(speciesAddr + 19),
        eggGroup1 = gameUtils.read8ROM(speciesAddr + 20),
        eggGroup2 = gameUtils.read8ROM(speciesAddr + 21),

        -- The ability IDs of the two slots.
        ability1 = gameUtils.read8ROM(speciesAddr + 22),
        ability2 = gameUtils.read8ROM(speciesAddr + 23),
        safariZoneRate = gameUtils.read8ROM(speciesAddr + 24),
        colorAndFlip = gameUtils.read8ROM(speciesAddr + 25)
    }
end

-- Get ability name from constants
function pokemonData.getAbilityName(abilityId)
    if abilityId >= 0 and abilityId < #constants.pokemonData.ability then
        return constants.pokemonData.ability[abilityId + 1]
    end
    return "Unknown"
end

-- Get type name from constants
function pokemonData.getTypeName(typeId)
    if typeId >= 0 and typeId < #constants.pokemonData.type then
        return constants.pokemonData.type[typeId + 1]
    end
    return "Unknown"
end

-- Get nature name from constants
function pokemonData.getNatureName(natureId)
    if natureId >= 0 and natureId < #constants.pokemonData.nature then
        return constants.pokemonData.nature[natureId + 1]
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

-- Get move name from constants
function pokemonData.getMoveName(moveId)
    if moveId >= 0 and moveId <= #constants.pokemonData.moves then
        return constants.pokemonData.moves[moveId + 1]
    end
    return "Unknown"
end

return pokemonData
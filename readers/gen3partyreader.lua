local PartyReader = require("readers.partyreader")
local gameUtils = require("utils.gameutils")
local pokemonData = require("readers.pokemondata")
local constants = require("data.constants")
local charmaps = require("data.charmaps")

local Gen3PartyReader = {}
Gen3PartyReader.__index = Gen3PartyReader
setmetatable(Gen3PartyReader, {__index = PartyReader})

function Gen3PartyReader:new()
    local obj = PartyReader:new()
    setmetatable(obj, Gen3PartyReader)
    
    obj.dataOrderTable = {
        growth = {1,1,1,1,1,1, 2,2,3,4,3,4, 2,2,3,4,3,4, 2,2,3,4,3,4},
        attack = {2,2,3,4,3,4, 1,1,1,1,1,1, 3,4,2,2,4,3, 3,4,2,2,4,3},
        effort = {3,4,2,2,4,3, 3,4,2,2,4,3, 1,1,1,1,1,1, 4,3,4,3,2,2},
        misc   = {4,3,4,3,2,2, 4,3,4,3,2,2, 4,3,4,3,2,2, 1,1,1,1,1,1}
    }
    
    return obj
end

function Gen3PartyReader:readParty(addresses, gameCode)
    local party = {}
    for i = 1, 6 do
        party[i] = self:readPokemon(addresses.partyAddr, i, gameCode)
    end
    return party
end

function Gen3PartyReader:readEnemyParty(addresses, gameCode)
    local party = {}
    for i = 1, 6 do
        party[i] = self:readPokemon(addresses.enemyStats, i, gameCode)
    end
    return party
end

function Gen3PartyReader:readPokemon(startAddress, slot, gameCode)
    local pokemonStart = startAddress + 100 * (slot - 1)
    
    -- Personality Value is 4 bytes at offset 0x00
    local personality = gameUtils.read32(pokemonStart)
    -- If we can't find a personality value, then there isn't a pokemon.
    if personality == 0 then
        return nil
    end
    
    -- Original Trainer ID is 4 bytes at offset 0x04
    local otid = gameUtils.read32(pokemonStart + 4)
    -- Magic Word is the XOR of Personality and Original Trainer ID
    -- This is used for decryption of data substructure.
    local magicword = (personality ~ otid)
    
    -- Determine data order based on personality value
    local dataOrder = personality % 24
    local growthOffset = (self.dataOrderTable.growth[dataOrder + 1] - 1) * 12
    local attackOffset = (self.dataOrderTable.attack[dataOrder + 1] - 1) * 12
    local effortOffset = (self.dataOrderTable.effort[dataOrder + 1] - 1) * 12
    local miscOffset = (self.dataOrderTable.misc[dataOrder + 1] - 1) * 12

    -- Data substructure is a 48 byte encrypted data section at offset 0x20
    -- Each portion of this needs to be decrypted using the magic word.
    -- The portions are decrypted 32 bits at a time.
    -- Then they can be combined to form the final values.
    local growth1 = (gameUtils.read32(pokemonStart + 32 + growthOffset) ~ magicword)
    local growth2 = (gameUtils.read32(pokemonStart + 32 + growthOffset + 4) ~ magicword)
    local growth3 = (gameUtils.read32(pokemonStart + 32 + growthOffset + 8) ~ magicword)
    local attack1 = (gameUtils.read32(pokemonStart + 32 + attackOffset) ~ magicword)
    local attack2 = (gameUtils.read32(pokemonStart + 32 + attackOffset + 4) ~ magicword)
    local attack3 = (gameUtils.read32(pokemonStart + 32 + attackOffset + 8) ~ magicword)
    local effort1 = (gameUtils.read32(pokemonStart + 32 + effortOffset) ~ magicword)
    local effort2 = (gameUtils.read32(pokemonStart + 32 + effortOffset + 4) ~ magicword)
    local effort3 = (gameUtils.read32(pokemonStart + 32 + effortOffset + 8) ~ magicword)
    local misc1 = (gameUtils.read32(pokemonStart + 32 + miscOffset) ~ magicword)
    local misc2 = (gameUtils.read32(pokemonStart + 32 + miscOffset + 4) ~ magicword)
    local misc3 = (gameUtils.read32(pokemonStart + 32 + miscOffset + 8) ~ magicword)

    -- Debug for radical red species
    -- Stores directly at offset 32, unencrypted 16 bit little endian
    local speciesDebug = gameUtils.read8(pokemonStart + 32) + (gameUtils.read8(pokemonStart + 33) * 256)
    console.log("DEBUG: Raw Species Data: " .. string.format("%04X", speciesDebug))

    -- Read nickname (10 bytes starting at offset 8)
    local bytes = gameUtils.readBytes(pokemonStart + 8, 10)
    local nickname = charmaps.decryptText(bytes, "GBA")

    -- Read status condition (1 byte at offset 0x50)
    -- 0 = None, 1 = Sleep, 2 = Bad Sleep, 3 = Poison,
    -- 4 = Burn, 5 = Freeze, 6 = Paralyze, 7 = Bad Poison
    local statusAux = gameUtils.read32(pokemonStart + 80)
    local status = 0
    local sleepTurns = 0

    if statusAux <= 0 then
        status = 0
    elseif statusAux < 8 then
        status = 1
    elseif statusAux == 8 then
        status = 2
    elseif statusAux == 16 then
        status = 3
    elseif statusAux == 32 then
        status = 4
    elseif statusAux == 64 then
        status = 5
    elseif statusAux == 128 then
        status = 6
    end

    -- Species ID is 2 bytes at offset 0 of the growth1 substructure.
    local speciesID = self:getBits(growth1, 0, 16)
    -- Held Item ID is 2 bytes at offset 16 of the growth1 substructure.
    local heldItemID = self:getBits(growth1, 16, 16)

    -- Attempt to search for the species data based on the id.
    local speciesData = gameCode and pokemonData.readSpeciesData(speciesID, gameCode) or nil

    -- Ability Slot index is 1 bit at offset 31 of the misc2 substructure.
    local abilitySlot = self:getBits(misc2, 31, 1)
    local abilityID = 0
    local abilityName = "Unknown"
    
    if speciesData then
        if abilitySlot == 0 then
            abilityID = speciesData.ability1
        else
            abilityID = speciesData.ability2
        end
        abilityName = pokemonData.getAbilityName(abilityID)
        
        print(string.format("DEBUG: Pokemon ID=%d, Slot=%d, Ability1=%d, Ability2=%d, Selected=%d, Name=%s", 
                speciesID, abilitySlot, speciesData.ability1 or 0, speciesData.ability2 or 0, abilityID, abilityName))
    end
    
    -- Get type information from species data
    local type1Name = "Unknown"
    local type2Name = "Unknown" 
    local type1ID = 0
    local type2ID = 0
    if speciesData then
        type1ID = speciesData.type1
        type2ID = speciesData.type2
        type1Name = pokemonData.getTypeName(speciesData.type1)
        type2Name = pokemonData.getTypeName(speciesData.type2)
    end
    
    return {
        personality = personality,
        otid = otid,
        nickname = nickname,
        speciesID = speciesID,
        speciesName = self:getSpeciesName(speciesID, gameCode),
        heldItem = constants.getItemName(heldItemID, 3),
        heldItemId = heldItemID,
        experience = growth2,
        -- PP bonuses byte has two bits per move, noting
        -- how many extra PP each move has.
        ppBonuses = self:getBits(growth3, 0, 8),
        friendship = self:getBits(growth3, 8, 8),
        pokerus = self:getBits(misc1, 0, 8),
        metLocation = self:getBits(misc1, 8, 8),
        metLevel = self:getBits(misc1, 16, 7),
        metBall = self:getBits(misc1, 23, 4),
        otGender = self:getBits(misc1, 31, 1),
        ivs = misc2,
        ivHP = self:getBits(misc2, 0, 5),
        ivAttack = self:getBits(misc2, 5, 5),
        ivDefense = self:getBits(misc2, 10, 5),
        ivSpeed = self:getBits(misc2, 15, 5),
        ivSpAttack = self:getBits(misc2, 20, 5),
        ivSpDefense = self:getBits(misc2, 25, 5),
        ribbons = misc3,
        move1 = self:getBits(attack1, 0, 16),
        move2 = self:getBits(attack1, 16, 16),
        move3 = self:getBits(attack2, 0, 16),
        move4 = self:getBits(attack2, 16, 16),
        pp1 = self:getBits(attack3, 0, 8),
        pp2 = self:getBits(attack3, 8, 8),
        pp3 = self:getBits(attack3, 16, 8),
        pp4 = self:getBits(attack3, 24, 8),
        evHP = self:getBits(effort1, 0, 8),
        evAttack = self:getBits(effort1, 8, 8),
        evDefense = self:getBits(effort1, 16, 8),
        evSpeed = self:getBits(effort1, 24, 8),
        evSpAttack = self:getBits(effort2, 0, 8),
        evSpDefense = self:getBits(effort2, 8, 8),
        coolness = self:getBits(effort2, 16, 8),
        beauty = self:getBits(effort2, 24, 8),
        cuteness = self:getBits(effort3, 0, 8),
        smartness = self:getBits(effort3, 8, 8),
        toughness = self:getBits(effort3, 16, 8),
        level = gameUtils.read8(pokemonStart + 84),
        status = status,
        sleepTurns = sleepTurns,
        curHP = gameUtils.read16(pokemonStart + 86),
        maxHP = gameUtils.read16(pokemonStart + 88),
        attack = gameUtils.read16(pokemonStart + 90),
        defense = gameUtils.read16(pokemonStart + 92),
        speed = gameUtils.read16(pokemonStart + 94),
        spAttack = gameUtils.read16(pokemonStart + 96),
        spDefense = gameUtils.read16(pokemonStart + 98),
        nature = personality % 25,
        natureName = pokemonData.getNatureName(personality % 25),
        ability = self:getBits(misc2, 31, 1),
        abilityID = abilityID,
        abilityName = abilityName,
        type1 = type1ID,
        type2 = type2ID,
        type1Name = type1Name,
        type2Name = type2Name,
        hiddenPower = self:calculateHiddenPowerType(misc2),
        hiddenPowerName = pokemonData.getHiddenPowerName(self:calculateHiddenPowerType(misc2)),
        isShiny = self:isShiny(personality, otid),
        tid = self:getBits(otid, 0, 16),
        sid = self:getBits(otid, 16, 16)
    }
end

function Gen3PartyReader:getBits(value, start, length)
    return gameUtils.getBits(value, start, length)
end

function Gen3PartyReader:calculateHiddenPowerType(ivs)
    local hpIV = self:getBits(ivs, 0, 5)
    local atkIV = self:getBits(ivs, 5, 5)
    local defIV = self:getBits(ivs, 10, 5)
    local speIV = self:getBits(ivs, 15, 5)
    local spaIV = self:getBits(ivs, 20, 5)
    local spdIV = self:getBits(ivs, 25, 5)
    
    local type = ((hpIV % 2) +
                 2 * (atkIV % 2) +
                 4 * (defIV % 2) +
                 8 * (speIV % 2) +
                 16 * (spaIV % 2) +
                 32 * (spdIV % 2)) * 15 // 63
    
    return type
end

function Gen3PartyReader:isShiny(personality, otid)
    local tid = self:getBits(otid, 0, 16)
    local sid = self:getBits(otid, 16, 16)
    local shinyValue = (personality ~ otid) ~ (tid ~ sid)
    return (shinyValue & 0xFFFF) < 8
end

function Gen3PartyReader:getSpeciesName(speciesId, gameCode)
    -- Try ROM lookup first
    local romName = gameCode and pokemonData.readSpeciesName(speciesId, gameCode)
    if romName and romName ~= "Unknown" then
        return romName
    end
    
    -- Fallback to constants  
    if speciesId > 0 and speciesId <= #constants.pokemonData.species then
        return constants.pokemonData.species[speciesId + 1]
    end
    
    return "Unknown"
end

return Gen3PartyReader
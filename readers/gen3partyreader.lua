local PartyReader = require("readers.partyreader")
local MemoryReader = require("core.memoryreader")
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
        party[i] = self:readPokemon(addresses.playerStats, i, gameCode)
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
    
    local personality = MemoryReader.readDword(pokemonStart)
    if personality == 0 then
        return nil
    end
    
    local otid = MemoryReader.readDword(pokemonStart + 4)
    local magicword = (personality ~ otid)
    
    local dataOrder = personality % 24
    local growthOffset = (self.dataOrderTable.growth[dataOrder + 1] - 1) * 12
    local attackOffset = (self.dataOrderTable.attack[dataOrder + 1] - 1) * 12
    local effortOffset = (self.dataOrderTable.effort[dataOrder + 1] - 1) * 12
    local miscOffset = (self.dataOrderTable.misc[dataOrder + 1] - 1) * 12
    
    local growth1 = (MemoryReader.readDword(pokemonStart + 32 + growthOffset) ~ magicword)
    local growth2 = (MemoryReader.readDword(pokemonStart + 32 + growthOffset + 4) ~ magicword)
    local growth3 = (MemoryReader.readDword(pokemonStart + 32 + growthOffset + 8) ~ magicword)
    local attack1 = (MemoryReader.readDword(pokemonStart + 32 + attackOffset) ~ magicword)
    local attack2 = (MemoryReader.readDword(pokemonStart + 32 + attackOffset + 4) ~ magicword)
    local attack3 = (MemoryReader.readDword(pokemonStart + 32 + attackOffset + 8) ~ magicword)
    local effort1 = (MemoryReader.readDword(pokemonStart + 32 + effortOffset) ~ magicword)
    local effort2 = (MemoryReader.readDword(pokemonStart + 32 + effortOffset + 4) ~ magicword)
    local effort3 = (MemoryReader.readDword(pokemonStart + 32 + effortOffset + 8) ~ magicword)
    local misc1 = (MemoryReader.readDword(pokemonStart + 32 + miscOffset) ~ magicword)
    local misc2 = (MemoryReader.readDword(pokemonStart + 32 + miscOffset + 4) ~ magicword)
    local misc3 = (MemoryReader.readDword(pokemonStart + 32 + miscOffset + 8) ~ magicword)
    
    local statusAux = MemoryReader.readDword(pokemonStart + 80)
    local sleepTurns = 0
    local status = 0
    
    -- Read nickname (10 bytes starting at offset 8)
    local nickname = ""
    for i = 0, 9 do
        local byte = MemoryReader.readByte(pokemonStart + 8 + i)
        if byte == 0xFF then
            break
        elseif byte ~= 0 then
            local char = charmaps.GBACharmap[byte] or ""
            nickname = nickname .. char
        end
    end
    
    if statusAux == 0 then
        status = 0
    elseif statusAux < 8 then
        sleepTurns = statusAux
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
    
    -- Get the actual ability ID from species data
    local pokemonID = self:getBits(growth1, 0, 16)
    local abilitySlot = self:getBits(misc1, 27, 1)
    local speciesData = gameCode and pokemonData.readSpeciesData(pokemonID, gameCode) or nil
    local abilityID = 0
    local abilityName = "Unknown"
    
    if speciesData then
        if abilitySlot == 0 then
            abilityID = speciesData.ability1
        else
            abilityID = speciesData.ability2
        end
        abilityName = pokemonData.getAbilityName(abilityID)
    end
    
    -- Get type information from species data
    local type1Name = "Unknown"
    local type2Name = "Unknown"
    if speciesData then
        type1Name = pokemonData.getTypeName(speciesData.type1)
        type2Name = pokemonData.getTypeName(speciesData.type2)
    end
    
    return {
        personality = personality,
        otid = otid,
        nickname = nickname,
        pokemonID = self:getBits(growth1, 0, 16),
        speciesName = gameCode and pokemonData.readSpeciesName(self:getBits(growth1, 0, 16), gameCode) or "Unknown",
        heldItem = constants.getItemName(self:getBits(growth1, 16, 16), 3),
        heldItemId = self:getBits(growth1, 16, 16),
        experience = growth2,
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
        level = MemoryReader.readByte(pokemonStart + 84),
        status = status,
        sleepTurns = sleepTurns,
        curHP = MemoryReader.readWord(pokemonStart + 86),
        maxHP = MemoryReader.readWord(pokemonStart + 88),
        attack = MemoryReader.readWord(pokemonStart + 90),
        defense = MemoryReader.readWord(pokemonStart + 92),
        speed = MemoryReader.readWord(pokemonStart + 94),
        spAttack = MemoryReader.readWord(pokemonStart + 96),
        spDefense = MemoryReader.readWord(pokemonStart + 98),
        nature = personality % 25,
        natureName = pokemonData.getNatureName(personality % 25),
        ability = self:getBits(misc1, 27, 1),
        abilityID = abilityID,
        abilityName = abilityName,
        type1 = speciesData and speciesData.type1 or 0,
        type2 = speciesData and speciesData.type2 or 0,
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

function Gen3PartyReader:readSpeciesName(speciesId, gameCode)
    local speciesNameTableAddr = self.speciesNameTableAddresses[gameCode]
    if not speciesNameTableAddr then
        return "Unknown"
    end
    
    -- Each species name is 11 bytes long (10 chars + terminator)
    local nameAddr = speciesNameTableAddr + (speciesId * 11)
    
    local name = ""
    for i = 0, 10 do
        local byte = MemoryReader.readByte(nameAddr + i)
        if byte == 0xFF or byte == 0 then
            break
        end
        local char = charmaps.GBACharmap[byte] or ""
        name = name .. char
    end
    
    return name ~= "" and name or "Unknown"
end

function Gen3PartyReader:readSpeciesData(speciesId, gameCode)
    local speciesDataTableAddr = self.speciesDataTableAddresses[gameCode]
    if not speciesDataTableAddr or speciesId == 0 then
        return nil
    end
    
    -- Each species data entry is 28 bytes
    local speciesAddr = speciesDataTableAddr + ((speciesId - 1) * 28)
    
    return {
        baseHP = MemoryReader.readByte(speciesAddr + 0),
        baseAttack = MemoryReader.readByte(speciesAddr + 1),
        baseDefense = MemoryReader.readByte(speciesAddr + 2),
        baseSpeed = MemoryReader.readByte(speciesAddr + 3),
        baseSpAttack = MemoryReader.readByte(speciesAddr + 4),
        baseSpDefense = MemoryReader.readByte(speciesAddr + 5),
        type1 = MemoryReader.readByte(speciesAddr + 6),
        type2 = MemoryReader.readByte(speciesAddr + 7),
        catchRate = MemoryReader.readByte(speciesAddr + 8),
        baseExpYield = MemoryReader.readByte(speciesAddr + 9),
        effortYield = MemoryReader.readWord(speciesAddr + 10),
        item1 = MemoryReader.readWord(speciesAddr + 12),
        item2 = MemoryReader.readWord(speciesAddr + 14),
        gender = MemoryReader.readByte(speciesAddr + 16),
        eggCycles = MemoryReader.readByte(speciesAddr + 17),
        baseFriendship = MemoryReader.readByte(speciesAddr + 18),
        levelUpType = MemoryReader.readByte(speciesAddr + 19),
        eggGroup1 = MemoryReader.readByte(speciesAddr + 20),
        eggGroup2 = MemoryReader.readByte(speciesAddr + 21),
        ability1 = MemoryReader.readByte(speciesAddr + 22),
        ability2 = MemoryReader.readByte(speciesAddr + 23),
        safariZoneRate = MemoryReader.readByte(speciesAddr + 24),
        colorAndFlip = MemoryReader.readByte(speciesAddr + 25)
    }
end

function Gen3PartyReader:readAbilityName(abilityId, gameCode)
    local abilityNameTableAddr = self.abilityNameTableAddresses[gameCode]
    if not abilityNameTableAddr or abilityId == 0 then
        return "Unknown"
    end
    
    -- Each ability name might be 13 bytes long (12 chars + terminator), but let's try different lengths
    local nameLength = 13
    if gameCode == "BPEE" then
        nameLength = 13  -- Emerald might be different
    end
    local nameAddr = abilityNameTableAddr + (abilityId * nameLength)
    
    local name = ""
    for i = 0, 12 do
        local byte = MemoryReader.readByte(nameAddr + i)
        if byte == 0xFF or byte == 0 then
            break
        end
        local char = charmaps.GBACharmap[byte] or ""
        name = name .. char
    end
    
    return name ~= "" and name or "Unknown"
end


function Gen3PartyReader:validatePokemonData(pokemonData)
    if not PartyReader.validatePokemonData(self, pokemonData) then
        return false
    end
    
    if pokemonData.level and (pokemonData.level < 1 or pokemonData.level > 100) then
        return false
    end
    
    return true
end

return Gen3PartyReader
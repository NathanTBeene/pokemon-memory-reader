-- Pokemon Data Reader
-- Handles reading Pokemon data from ROM tables

local pokemonData = {}
local gameUtils = require("utils.gameutils")
local configLoader = require("utils.configloader")
local constants = require("data.constants")
local charmaps = require("data.charmaps")

-- Read species name from ROM
function pokemonData.readSpeciesName(speciesId, gameCode)
    -- For Ruby/Sapphire, use constants table instead of ROM reading due to complex National Dex ordering
    if gameCode == "AXVE" or gameCode == "AXPE" then
        if speciesId > 0 and speciesId <= #constants.pokemonData.species then
            return constants.pokemonData.species[speciesId - 24]
        end
        return "Unknown"
    end
    
    local gameConfig = configLoader.getGameConfig(gameCode)
    if not gameConfig or not gameConfig.addresses.speciesNameTable then
        return "Unknown"
    end
    
    local dataStructure = configLoader.getDataStructure(gameConfig.generation)
    if not dataStructure then
        return "Unknown"
    end
    
    local tableAddr = gameConfig.addresses.speciesNameTable
    local nameAddr = tableAddr + (speciesId * dataStructure.speciesNameLength)
    
    return gameUtils.readROMText(nameAddr, dataStructure.speciesNameLength, charmaps.GBACharmap) or "Unknown"
end

-- Read species base stats and abilities from ROM
function pokemonData.readSpeciesData(speciesId, gameCode)
    local gameConfig = configLoader.getGameConfig(gameCode)
    if not gameConfig or not gameConfig.addresses.speciesDataTable then
        return nil
    end
    
    local dataStructure = configLoader.getDataStructure(gameConfig.generation)
    if not dataStructure then
        return nil
    end
    
    local tableAddr = gameConfig.addresses.speciesDataTable
    local speciesAddr = tableAddr + ((speciesId - 1) * dataStructure.speciesDataSize)
    
    return {
        baseHP = gameUtils.readROMByte(speciesAddr + 0),
        baseAttack = gameUtils.readROMByte(speciesAddr + 1),
        baseDefense = gameUtils.readROMByte(speciesAddr + 2),
        baseSpeed = gameUtils.readROMByte(speciesAddr + 3),
        baseSpAttack = gameUtils.readROMByte(speciesAddr + 4),
        baseSpDefense = gameUtils.readROMByte(speciesAddr + 5),
        type1 = gameUtils.readROMByte(speciesAddr + 6),
        type2 = gameUtils.readROMByte(speciesAddr + 7),
        catchRate = gameUtils.readROMByte(speciesAddr + 8),
        baseExpYield = gameUtils.readROMByte(speciesAddr + 9),
        effortYield = gameUtils.readROMWord(speciesAddr + 10),
        item1 = gameUtils.readROMWord(speciesAddr + 12),
        item2 = gameUtils.readROMWord(speciesAddr + 14),
        gender = gameUtils.readROMByte(speciesAddr + 16),
        eggCycles = gameUtils.readROMByte(speciesAddr + 17),
        baseFriendship = gameUtils.readROMByte(speciesAddr + 18),
        levelUpType = gameUtils.readROMByte(speciesAddr + 19),
        eggGroup1 = gameUtils.readROMByte(speciesAddr + 20),
        eggGroup2 = gameUtils.readROMByte(speciesAddr + 21),
        ability1 = gameUtils.readROMByte(speciesAddr + 22),
        ability2 = gameUtils.readROMByte(speciesAddr + 23),
        safariZoneRate = gameUtils.readROMByte(speciesAddr + 24),
        colorAndFlip = gameUtils.readROMByte(speciesAddr + 25)
    }
end

-- Get ability name from constants (using lookup instead of ROM reading)
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
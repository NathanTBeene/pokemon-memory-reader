local PartyReader = require("readers.partyreader")
local charmaps = require("data.charmaps")
local gameUtils = require("utils.gameutils")
local gamesdb = require("data.gamesdb")
local pokemonData = require("readers.pokemondata")
local constants = require("data.constants")

-- This reader is for Romhacks that use the
-- Complete Fire Red Upgrade
-- This is also most likely going to be combined
-- with the Dynamic Pokemon Expansion

local CFRUPartyReader = {}
CFRUPartyReader.__index = CFRUPartyReader
setmetatable(CFRUPartyReader, {__index = PartyReader})

function CFRUPartyReader:new()
    local obj = PartyReader:new()
    setmetatable(obj, CFRUPartyReader)
    return obj
end

function CFRUPartyReader:readParty(addresses, gameCode)
  local party = {}
  for i = 1, 6 do
    party[i] = self:readPokemon(addresses.partyAddr, i, gameCode)
  end
  return party
end

function CFRUPartyReader:readPokemon(startAddress, slot, gameCode)
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
    -- Don't think this is needed for CFRU
    local magicword = (personality ~ otid)

    -- Read nickname (10 bytes starting at offset 8)
    local bytes = gameUtils.readBytes(pokemonStart + 8, 10)
    local nickname = charmaps.decryptText(bytes)

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

    -- Species ID is stored directly at offset 32 (unencrypted, 16-bit little endian)
    local speciesID = gameUtils.read16(pokemonStart + 32)

    -- Held Item ID is 2 bytes stored at offset 34
    local heldItemID = gameUtils.read16(pokemonStart + 34)

    -- Attempt to search for the species data based on the id.
    local speciesData = self:getSpeciesData(speciesID) or nil
    console.log("Species Data: ", gameUtils.printTable(speciesData))

    -- misc 2 contains IVS, Egg, and Ability Slot
    -- 4 bytes at offset 72
    local misc2 = gameUtils.read32(pokemonStart + 72)

    -- Ability Slot index is the last bit
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

    -- Origins info is 2 bytes at offset 70
    local origins = gameUtils.read16(pokemonStart + 70)

    return {
        personality = personality,
        otid = otid,
        nickname = nickname,
        speciesID = speciesID,
        speciesName = self:getSpeciesName(speciesID),
        -- 2 bytes at offset 34
        heldItemId = heldItemID,
        heldItem = constants.getItemName(heldItemID, 3),
        -- 4 bytes at offset 36
        experience = gameUtils.read32(pokemonStart + 36),
        -- PP bonuses byte has two bits per move, noting
        -- how many extra PP each move has.
        -- 1 byte at offset 40
        ppBonuses = gameUtils.read8(pokemonStart + 40),
        -- 1 byte at offset 41
        friendship = gameUtils.read8(pokemonStart + 41),
        -- 2 bytes each starting at offset 44
        move1 = gameUtils.read16(pokemonStart + 44),
        move2 = gameUtils.read16(pokemonStart + 46),
        move3 = gameUtils.read16(pokemonStart + 48),
        move4 = gameUtils.read16(pokemonStart + 50),
        -- 1 byte each starting at offset 52
        pp1 = gameUtils.read8(pokemonStart + 52),
        pp2 = gameUtils.read8(pokemonStart + 53),
        pp3 = gameUtils.read8(pokemonStart + 54),
        pp4 = gameUtils.read8(pokemonStart + 55),

        -- 1 Byte each starting at 56
        evHP = gameUtils.read8(pokemonStart + 56),
        evAttack = gameUtils.read8(pokemonStart + 57),
        evDefense = gameUtils.read8(pokemonStart + 58),
        evSpeed = gameUtils.read8(pokemonStart + 59),
        evSpAttack = gameUtils.read8(pokemonStart + 60),
        evSpDefense = gameUtils.read8(pokemonStart + 61),
        coolness = gameUtils.read8(pokemonStart + 62),
        beauty = gameUtils.read8(pokemonStart + 63),
        cuteness = gameUtils.read8(pokemonStart + 64),
        smartness = gameUtils.read8(pokemonStart + 65),
        toughness = gameUtils.read8(pokemonStart + 66),
        feel = gameUtils.read8(pokemonStart + 67),

        -- 1 byte at offset 68
        pokerus = gameUtils.read8(pokemonStart + 68),
        -- 1 byte at offset 69
        metLocation = gameUtils.read8(pokemonStart + 69),

        -- Level met is bits 0-6 of origins
        metLevel = self:getBits(origins, 0, 6),
        -- Origin Game is bits 7-10 of origins
        originGame = self:getBits(origins, 7, 4),
        -- Pokeball caught is bits 11-14 of origins
        metBall = self:getBits(origins, 11, 4),
        -- Gender is bit 15 of origins
        otGender = self:getBits(origins, 15, 1),

        -- Individual Values (IVs)
        -- Each is 5 bits
        ivHP = self:getBits(misc2, 0, 5),
        ivAttack = self:getBits(misc2, 5, 5),
        ivDefense = self:getBits(misc2, 10, 5),
        ivSpeed = self:getBits(misc2, 15, 5),
        ivSpAttack = self:getBits(misc2, 20, 5),
        ivSpDefense = self:getBits(misc2, 25, 5),
        -- 1 bit at 30
        isEgg = self:getBits(misc2, 30, 1) == 1,
        -- Ability index is the last bit
        ability = self:getBits(misc2, 31, 1),
        abilityID = abilityID,
        abilityName = abilityName,

        -- Ribbons is 4 bytes at offset 76
        ribbons = gameUtils.read32(pokemonStart + 76),

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
        natureName = pokemonData.getNatureName(personality % 25, gameCode),
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

function CFRUPartyReader:getBits(value, start, length)
    return gameUtils.getBits(value, start, length)
end

function CFRUPartyReader:calculateHiddenPowerType(ivs)
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

function CFRUPartyReader:isShiny(personality, otid)
    local tid = self:getBits(otid, 0, 16)
    local sid = self:getBits(otid, 16, 16)
    local shinyValue = (personality ~ otid) ~ (tid ~ sid)
    return (shinyValue & 0xFFFF) < 8
end

function CFRUPartyReader:getSpeciesName(id)
  local gameData = gamesdb.getGameByHash(gameUtils.getROMHash())

  local speciesNameTableAddr = gameData.addresses.speciesNameTable

  local number = gameUtils.hexToNumber(speciesNameTableAddr)

  -- Calculate the name address: base_address + ((id - 1) * 11)
  local pointer = number + ((id - 1) * 11)
  local bytes = gameUtils.readBytesCFRU(pointer, 11)

  return charmaps.decryptText(bytes)
end


function CFRUPartyReader:getSpeciesData(speciesID)
  local gameData = gamesdb.getGameByHash(gameUtils.getROMHash())

  local speciesDataTableAddr = gameData.addresses.speciesDataTable

  local number = gameUtils.hexToNumber(speciesDataTableAddr)

  -- Species data is 28 bytes long
  local speciesAddr = number + ((speciesID - 1) * 28)
  console.log("Species Address: ", string.format("0x%X", speciesAddr))

  local speciesData = gameUtils.readBytesCFRU(speciesAddr, 28)

  return {
    baseHP = speciesData[1],
    baseAttack = speciesData[2],
    baseDefense = speciesData[3],
    baseSpeed = speciesData[4],
    baseSpAttack = speciesData[5],
    baseSpDefense = speciesData[6],

    -- If singular type, both types will be the same value.
    type1 = speciesData[7],
    type2 = speciesData[8],
    catchRate = speciesData[9],
    baseExpYield = speciesData[10],

    -- Effort Values is two bytes. Each stat is given
    -- two bits to determine the yield, and the rest
    -- are empty.
    effortYield = speciesData[11] + (speciesData[12] << 8),

    -- The item ID here is a 50% chance for the pokemon
    -- to be holding this item.
    item1 = speciesData[13] + (speciesData[14] << 8),

    -- Item 2 is a 5% chance. If both are the same, then
    -- the pokemon will ALWAYS hold that item.
    item2 = speciesData[15] + (speciesData[16] << 8),

    -- The chance a pokemon will be male or female.
    -- This is compared with the lowest byte of the
    -- personality value to determine the nature.
    -- 0 = Always Male
    -- 1-253 = Mixed
    -- 254 = Always Female
    -- 255 = Genderless
    gender = speciesData[17],
    eggCycles = speciesData[18],
    baseFriendship = speciesData[19],
    levelUpType = speciesData[20],
    eggGroup1 = speciesData[21],
    eggGroup2 = speciesData[22],

    -- The ability IDs of the two slots.
    ability1 = speciesData[23],
    ability2 = speciesData[24],
    safariZoneRate = speciesData[25],
    colorAndFlip = speciesData[26],
    hiddenAbility = speciesData[27]
  }
end

return CFRUPartyReader
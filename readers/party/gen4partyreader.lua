local PartyReader = require("readers.party.partyreader")
local gameUtils = require("utils.gameutils")
local pokemonData = require("readers.pokemondata")
local constants = require("data.constants")
local charmaps = require("data.charmaps")

local Gen4PartyReader = {}
Gen4PartyReader.__index = Gen4PartyReader
setmetatable(Gen4PartyReader, {__index = PartyReader})

function Gen4PartyReader:new()
  local obj = PartyReader:new()
  setmetatable(obj, Gen4PartyReader)

  return obj
end

function Gen4PartyReader:readParty()
  local party = {}

  for i = 1, 6 do
    party[i] = self:readPokemon(i)
  end
  return party
end

function Gen4PartyReader:readPokemon(slot)
  local gameData = MemoryReader.currentGame
  local partyAddr = gameData.addresses.partyAddr

  -- Each Pokemon is in a block of 136 bytes
  local pokemonAddr = partyAddr + (slot - 1) * 136

  -- Personality Value is 4 bytes at offset 0
  local personalityValue = gameUtils.read32(pokemonAddr + 0x00)

  -- Get the block shuffle order based on the personality value
  local blockShuffleOrder = self:getBlockShuffleOrder(personalityValue)
  local blockAddresses = self:getBlockAddresses(pokemonAddr, blockShuffleOrder)

  -- Checksum is stored at offset 6
  local checksum = gameUtils.read16(pokemonAddr + 0x06)

  -- Decrypt the blocks
  local decryptedBlocks = self:decryptBlocks(pokemonAddr, blockShuffleOrder, checksum)

  local pokemon = {}
  -- Block A
  local blockA = decryptedBlocks[1]

  -- Species ID is 2 bytes at offset 0x00 of Block A
  pokemon.speciesId = gameUtils.read16FromBytes(blockA, 0x00)

  -- Held Item ID is 2 bytes at offset 0x02 of Block A
  pokemon.heldItemId = gameUtils.read16FromBytes(blockA, 0x02)

  -- Original Trainer ID is 4 bytes at offset 0x04 of Block A
  pokemon.otId = gameUtils.read32FromBytes(blockA, 0x04)

  -- Experience Points is 4 bytes at offset 0x08 of Block A
  pokemon.exp = gameUtils.read32FromBytes(blockA, 0x08)

  -- Friendship is 1 byte at offset 0x0C of Block A
  pokemon.friendship = gameUtils.read8FromBytes(blockA, 0x0C)

  -- Ability  is 1 byte at offset 0x0D of Block A
  pokemon.abilityIndex = gameUtils.read8FromBytes(blockA, 0x0D)

  return {
    speciesId = pokemon.speciesId,
    heldItemId = pokemon.heldItemId
  }
end

function Gen4PartyReader:getBlockShuffleOrder(personalityValue)
  -- Calculate Shift Value
  local shift = math.floor((personalityValue & 0x3E000) / 0x2000) % 24

  -- All 24 possible block orders
  local shuffleOrders = {
    {1, 2, 3, 4}, -- 0:  A B C D
    {1, 2, 4, 3}, -- 1:  A B D C
    {1, 3, 2, 4}, -- 2:  A C B D
    {1, 3, 4, 2}, -- 3:  A C D B
    {1, 4, 2, 3}, -- 4:  A D B C
    {1, 4, 3, 2}, -- 5:  A D C B
    {2, 1, 3, 4}, -- 6:  B A C D
    {2, 1, 4, 3}, -- 7:  B A D C
    {2, 3, 1, 4}, -- 8:  B C A D
    {2, 3, 4, 1}, -- 9:  B C D A
    {2, 4, 1, 3}, -- 10: B D A C
    {2, 4, 3, 1}, -- 11: B D C A
    {3, 1, 2, 4}, -- 12: C A B D
    {3, 1, 4, 2}, -- 13: C A D B
    {3, 2, 1, 4}, -- 14: C B A D
    {3, 2, 4, 1}, -- 15: C B D A
    {3, 4, 1, 2}, -- 16: C D A B
    {3, 4, 2, 1}, -- 17: C D B A
    {4, 1, 2, 3}, -- 18: D A B C
    {4, 1, 3, 2}, -- 19: D A C B
    {4, 2, 1, 3}, -- 20: D B A C
    {4, 2, 3, 1}, -- 21: D B C A
    {4, 3, 1, 2}, -- 22: D C A B
    {4, 3, 2, 1}, -- 23: D C B A
  }

  return shuffleOrders[shift + 1]
end

function Gen4PartyReader:getBlockAddresses(pokemonAddr, blockShuffleOrder)
  local blockAddresses = {}
  for i = 1, 4 do
    local blockNum = blockShuffleOrder[i]
    local blockOffset = (i - 1) * 32 
    blockAddresses[blockNum] = pokemonAddr + 0x08 + blockOffset 
  end

  return blockAddresses
end

function Gen4PartyReader:prng(seed)
  -- Linear Congruential Generator: X[n+1] = (0x41C64E6D * X[n] + 0x6073) & 0xFFFFFFFF
  local result = (0x41C64E6D * seed + 0x6073) & 0xFFFFFFFF
  return result
end

function Gen4PartyReader:decryptBlocks(pokemonAddr, blockShuffleOrder, checksum)
  local seed = checksum
  local decryptedBlocks = {}
  
  -- Decrypt all 4 blocks in order, maintaining PRNG state
  for i = 1, 4 do
    local blockNum = blockShuffleOrder[i]
    local blockAddr = pokemonAddr + 0x08 + (i - 1) * 32
    local encryptedData = gameUtils.readBytes(blockAddr, 32)
    
    local decryptedData = {}
    for j = 0, 15 do  -- 16 words per 32-byte block
      seed = self:prng(seed)
      local prngValue = (seed >> 16) & 0xFFFF
      
      local word = (encryptedData[j * 2 + 1] | (encryptedData[j * 2 + 2] << 8)) & 0xFFFF
      local decryptedWord = word ~ prngValue
      
      decryptedData[j * 2 + 1] = decryptedWord & 0xFF
      decryptedData[j * 2 + 2] = (decryptedWord >> 8) & 0xFF
    end
    
    decryptedBlocks[blockNum] = decryptedData  -- Store in logical order
  end
  
  return decryptedBlocks
end
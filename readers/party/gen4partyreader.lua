local PartyReader = require("readers.base.partyreader")
local gameUtils = require("utils.gameutils")
local pokemonData = require("readers.pokemondata")
local constants = require("data.constants")
local charmaps = require("data.charmaps")

---@class Gen4PartyReader : PartyReader
local Gen4PartyReader = {}
Gen4PartyReader.__index = Gen4PartyReader
setmetatable(Gen4PartyReader, {__index = PartyReader})

---@param gameEntry GameEntry
---@return Gen4PartyReader
function Gen4PartyReader:new(gameEntry)
  local obj = PartyReader.new(Gen4PartyReader, gameEntry)
  return obj
end

---@return (Pokemon?)[]
function Gen4PartyReader:readParty()
  self:calculatePartyAddr()
  local partyAddr = gameUtils.hexToNumber(self.gameEntry.addresses.partyAddr)
  if not partyAddr then return {} end
  local domain = "Main RAM"
  local partyCount = gameUtils.read8(partyAddr - 0x04, domain)
  local party = {}
  for i = 1, partyCount do
    party[i] = self:readPokemon(i)
  end
  return party
end

function Gen4PartyReader:calculatePartyAddr()
  local pointers = self.gameEntry.pointers
  local offsets  = self.gameEntry.offsets
  local ptrStr = pointers and pointers.partyPointer
  local offStr = offsets  and offsets.partyOffset
  if not ptrStr or not offStr then
    console.log("Gen4: missing pointer or offset configuration")
    return nil
  end
  local partyPointer = gameUtils.hexToNumber(ptrStr)
  local partyOffset  = gameUtils.hexToNumber(offStr)
  if not partyPointer or not partyOffset then return nil end
  local domain = "Main RAM"
  local partyPointerAddr = gameUtils.read32(partyPointer, domain)
  local partyAddr = partyPointerAddr + partyOffset
  self.gameEntry.addresses.partyAddr = string.format("%08X", partyAddr)
  console.log(string.format("Gen4 Party Address: %s", self.gameEntry.addresses.partyAddr))
  return partyAddr
end

---@param slot integer  1-based slot index
---@return Pokemon?
function Gen4PartyReader:readPokemon(slot)
  local partyAddr = gameUtils.hexToNumber(self.gameEntry.addresses.partyAddr)
  if not partyAddr then return nil end

  local domain = "Main RAM"

  -- Each Pokemon is in a block of 236 bytes
  local pokemonAddr = partyAddr + (slot - 1) * 236

  -- Personality Value is 4 bytes at offset 0
  local personalityValue = gameUtils.read32(pokemonAddr + 0x00, domain)

  -- Get the block shuffle order based on the personality value
  local blockShuffleOrder = self:getBlockShuffleOrder(personalityValue)

  -- Checksum is stored at offset 6
  local checksum = gameUtils.read16(pokemonAddr + 0x06, domain)

  -- Decrypt the blocks
  local decryptedBlocks = self:decryptBlocks(pokemonAddr, blockShuffleOrder, checksum)

  local pokemon = {}

  -- Nature is determined by personality value mod 25
  pokemon.natureId = personalityValue % 25
  pokemon.nature = pokemonData.readNatureName(pokemon.natureId)

  -- Block A
  local blockA = decryptedBlocks[1]

  -- Species ID is 2 bytes at offset 0x00 of Block A
  pokemon.speciesID = gameUtils.read16FromBytes(blockA, 0x00)
  console.log(string.format("Slot %d Species ID: %d", slot, pokemon.speciesID))

  pokemon.speciesName = pokemonData.readSpeciesName(pokemon.speciesID)

  -- Held Item ID is 2 bytes at offset 0x02 of Block A
  pokemon.heldItemID = gameUtils.read16FromBytes(blockA, 0x02)
  console.log(string.format("Slot %d Held Item ID: %d", slot, pokemon.heldItemID))

  -- Original Trainer ID is 4 bytes at offset 0x04 of Block A
  pokemon.otID = gameUtils.read32FromBytes(blockA, 0x04)
  console.log(string.format("Slot %d OT ID: %d", slot, pokemon.otID))

  -- Experience Points is 4 bytes at offset 0x08 of Block A
  pokemon.exp = gameUtils.read32FromBytes(blockA, 0x08)

  -- Friendship is 1 byte at offset 0x0C of Block A
  pokemon.friendship = gameUtils.read8FromBytes(blockA, 0x0C)

  -- Ability  is 1 byte at offset 0x0D of Block A
  pokemon.abilityIndex = gameUtils.read8FromBytes(blockA, 0x0D)

  -- HP EV is 1 byte at offset 0x10 of Block A
  pokemon.evHP = gameUtils.read8FromBytes(blockA, 0x10)
  -- Attack EV is 1 byte at offset 0x11 of Block A
  pokemon.evAttack = gameUtils.read8FromBytes(blockA, 0x11)
  -- Defense EV is 1 byte at offset 0x12 of Block A
  pokemon.evDefense = gameUtils.read8FromBytes(blockA, 0x12)
  -- Speed EV is 1 byte at offset 0x13 of Block A
  pokemon.evSpeed = gameUtils.read8FromBytes(blockA, 0x13)
  -- Special Attack EV is 1 byte at offset 0x14 of Block A
  pokemon.evSpecialAttack = gameUtils.read8FromBytes(blockA, 0x14)
  -- Special Defense EV is 1 byte at offset 0x15 of Block A
  pokemon.evSpecialDefense = gameUtils.read8FromBytes(blockA, 0x15)

  -- Block B
  local blockB = decryptedBlocks[2]

  -- Moveset is 8 bytes at offset 0x00 of Block B (4 moves, 2 bytes each)
  pokemon.moveIDs = {
    gameUtils.read16FromBytes(blockB, 0x00),
    gameUtils.read16FromBytes(blockB, 0x02),
    gameUtils.read16FromBytes(blockB, 0x04),
    gameUtils.read16FromBytes(blockB, 0x06)
  }
  -- Move PP is 8 bytes at offset 0x08 of Block B (4 moves, 2 bytes each)
  pokemon.movePP = {
    gameUtils.read16FromBytes(blockB, 0x08),
    gameUtils.read16FromBytes(blockB, 0x0A),
    gameUtils.read16FromBytes(blockB, 0x0C),
    gameUtils.read16FromBytes(blockB, 0x0E)
  }
  -- Move PP Ups is 4 bytes at offset 0x10 of Block B (4 moves, 1 byte each)
  pokemon.movePPUps = {
    gameUtils.read8FromBytes(blockB, 0x10),
    gameUtils.read8FromBytes(blockB, 0x11),
    gameUtils.read8FromBytes(blockB, 0x12),
    gameUtils.read8FromBytes(blockB, 0x13)
  }

  -- IV and Flags are 4 bytes at offset 0x14 of Block B
  -- Bits 0-29 are IVs
  pokemon.IVs = {}
  pokemon.IVs.hp = gameUtils.readBitsFromBytes(blockB, 0x14, 0, 5)
  pokemon.IVs.attack = gameUtils.readBitsFromBytes(blockB, 0x14, 5, 5)
  pokemon.IVs.defense = gameUtils.readBitsFromBytes(blockB, 0x14, 10, 5)
  pokemon.IVs.speed = gameUtils.readBitsFromBytes(blockB, 0x14, 15, 5)
  pokemon.IVs.specialAttack = gameUtils.readBitsFromBytes(blockB, 0x14, 20, 5)
  pokemon.IVs.specialDefense = gameUtils.readBitsFromBytes(blockB, 0x14, 25, 5)

  -- Gender is bits 1 and 2 of 1 byte at offset 0x18 of Block B
  -- Bit 1 is female flag, Bit 2 is genderless flag. If both are 0, it's male
  local genderBits = gameUtils.readBitsFromBytes(blockB, 0x18, 1, 2)
  if genderBits == 0 then
    pokemon.gender = "Male"
  elseif genderBits == 1 then
    pokemon.gender = "Female"
  else
    pokemon.gender = "Genderless"
  end

  -- Block C
  local blockC = decryptedBlocks[3]

  -- Nickname is 22 bytes at offset 0x00 of Block C, encoded in the Gen4 character set
  local rawNicknameBytes = {}
  for i = 0, 21 do
    rawNicknameBytes[i + 1] = gameUtils.read8FromBytes(blockC, 0x00 + i)
  end
  pokemon.nickname = charmaps.decryptText(rawNicknameBytes)


  return pokemon
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
    local encryptedData = gameUtils.readBytes(blockAddr, 32, "Main RAM")

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

return Gen4PartyReader

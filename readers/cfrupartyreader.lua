local PartyReader = require("readers.partyreader")
local Charmaps = require("data.charmaps")

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

  -- Personality value is 4 bytes at offset 0
  local personalityValue = gameUtils.read32(pokemonStart)
  if personalityValue == 0 then
      return nil -- Empty slot
  end

  -- Original Trainer ID is 4 bytes at offset 4
  local otID = gameUtils.read32(pokemonStart + 4)
  local magicword = personalityValue ~ otID

  -- Nature is personality mod 25
  local nature = personalityValue % 25

  -- Nickname is 11 bytes at offset 8 (10 bytes + null terminator)
  local nicknameBytes = gameUtils.readBytes(pokemonStart + 8, 10)

  -- Species ID is stored directly at offset 32 (unencrypted, 16-bit little endian)
  local speciesID = gameUtils.read8(pokemonStart + 32) + (gameUtils.read8(pokemonStart + 33) * 256)

  return {
      personalityValue = personalityValue,
      otID = otID,
      magicword = magicword,
      nature = nature,
      nickname = nicknameBytes,
      speciesID = speciesID
  }
end

function CFRUPartyReader.getSpeciesName(game, id)
  -- Calculate the name address: base_address + (id * 11)
  local pointer = gameInfo.speciesNameTable + (id * 11)
  return Charmaps.decryptText(gameUtils.readBytes(pointer, 11))
end

return CFRUPartyReader
local PlayerReader = require("readers.player.playerreader")
local gameUtils = require("utils.gameutils")

local Gen1PlayerReader = {}
Gen1PlayerReader.__index = Gen1PlayerReader
setmetatable(Gen1PlayerReader, {__index = PlayerReader})

function Gen1PlayerReader:new()
  local obj = PlayerReader:new()
  setmetatable(obj, Gen1PlayerReader)
  return obj
end

function Gen1PlayerReader:updateTrainerInfo()
  if not MemoryReader.isInitialized or not MemoryReader.currentGame then
    console.log("MemoryReader not initialized or no game loaded")
    return
  end

  local gameData = gameUtils.getGameData()
  if not gameData or not gameData.trainerOffsets then
    console.log("No game data or trainer offsets found")
    return
  end

  local domain = "System Bus"

  -- Trainer Name is 11 bytes
  local nameAddr = gameData.trainerOffsets.name
  local nameData = gameUtils.readBytes(nameAddr, 11, domain)
  local name = decryptText(nameData, "GB")

  -- Badges is 1 byte, 1 bit per badge
  local badgesAddr = gameData.trainerOffsets.badges
  local badges = gameUtils.read8(badgesAddr, domain)

  local badgeList = {
    {name = "Boulder Badge", earned = (badges & 0x01) ~= 0},
    {name = "Cascade Badge", earned = (badges & 0x02) ~= 0},
    {name = "Thunder Badge", earned = (badges & 0x04) ~= 0},
    {name = "Rainbow Badge", earned = (badges & 0x08) ~= 0},
    {name = "Soul Badge", earned = (badges & 0x10) ~= 0},
    {name = "Marsh Badge", earned = (badges & 0x20) ~= 0},
    {name = "Volcano Badge", earned = (badges & 0x40) ~= 0},
    {name = "Earth Badge", earned = (badges & 0x80) ~= 0}
  }

  -- Money is 3 bytes, BCD encoded
  local moneyAddr = gameData.trainerOffsets.money
  local moneyBCD = gameUtils.readBytes(moneyAddr, 3, domain)

  local money = gameUtils.bcdToDecimal(moneyBCD)

  -- Coins is 2 bytes, binary encoded
  local coinsAddr = gameData.trainerOffsets.coins
  local coins = gameUtils.read16(coinsAddr, domain)
  coins = coins or 0

  self.trainerInfo = {
    name = name,
    badges = badgeList,
    money = money,
    coins = coins,
  }

end

-- MARK: Utility

function Gen1PlayerReader:printTrainerInfo()
  self:updateTrainerInfo()

  if self.trainerInfo then
    console.log("Trainer Info:")
    console.log("Name: " .. (self.trainerInfo.name or "N/A"))
    console.log("Money: " .. (self.trainerInfo.money or 0) .. " Pokedollars")
    console.log("Coins: " .. (self.trainerInfo.coins or 0) .. " Coins")
    console.log("Badges:")
    for _, badge in ipairs(self.trainerInfo.badges) do
      local status = badge.earned and "Earned" or "Not Earned"
      console.log(" - " .. badge.name .. ": " .. status)
    end
  else
    console.log("No trainer info available")
  end
end

return Gen1PlayerReader
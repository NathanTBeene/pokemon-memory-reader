local PlayerReader = require("readers.player.playerreader")
local gameUtils = require("utils.gameutils")
local pokemonData = require("readers.pokemondata")
local charmaps = require("data.charmaps")

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

  local gameData = MemoryReader.currentGame
  if not gameData or not gameData.trainerOffsets then
    console.log("No game data or trainer offsets found")
    return
  end

  local domain = "System Bus"

  -- Trainer Name is 11 bytes
  local nameAddr = gameData.trainerOffsets.name
  local nameData = gameUtils.readBytes(nameAddr, 11, domain)
  local name = charmaps.decryptText(nameData, "GB")

  -- Badges is 1 byte, 1 bit per badge
  local badgesAddr = gameData.trainerOffsets.badges
  local badges = gameUtils.read8(badgesAddr, domain)

  local badgeList = {
    {badgeNum = 1, name = "Boulder Badge", earned = (badges & 0x01) ~= 0},
    {badgeNum = 2, name = "Cascade Badge", earned = (badges & 0x02) ~= 0},
    {badgeNum = 3, name = "Thunder Badge", earned = (badges & 0x04) ~= 0},
    {badgeNum = 4, name = "Rainbow Badge", earned = (badges & 0x08) ~= 0},
    {badgeNum = 5, name = "Soul Badge", earned = (badges & 0x10) ~= 0},
    {badgeNum = 6, name = "Marsh Badge", earned = (badges & 0x20) ~= 0},
    {badgeNum = 7, name = "Volcano Badge", earned = (badges & 0x40) ~= 0},
    {badgeNum = 8, name = "Earth Badge", earned = (badges & 0x80) ~= 0}
  }

  -- Money is 3 bytes, BCD encoded
  local moneyAddr = gameData.trainerOffsets.money
  local moneyBCD = gameUtils.readBytes(moneyAddr, 3, domain)

  local money = gameUtils.bcdToDecimal(moneyBCD)

  -- Coins is 2 bytes, binary encoded
  local coinsAddr = gameData.trainerOffsets.coins
  local coins = gameUtils.read16(coinsAddr, domain)

  self.trainerInfo = {
    name = name,
    badges = badgeList,
    money = money,
    coins = coins or 0,
  }

end

function Gen1PlayerReader:readBag()
  self:updateTrainerInfo()
  local gameData = MemoryReader.currentGame

  if not self.trainerInfo then
    console.log("No trainer info available, cannot read bag")
    return
  elseif not gameData or not gameData.trainerOffsets then
    console.log("No game data or trainer offsets found")
    return
  end

  local domain = "System Bus"

  -- Bag count is 1 byte
  local bagCount = gameUtils.read8(gameData.trainerOffsets.bagCount, domain)
  local bag = {}

  -- Bag is max 40 items, each being 2 bytes (item ID and quantity)
  local bagStartAddr = gameData.trainerOffsets.bagItems
  for i = 0, bagCount - 1 do
    local itemAddr = bagStartAddr + (i * 2)
    local itemData = gameUtils.readBytes(itemAddr, 2, domain)
    local item = {
      id = itemData[1],
      quantity = itemData[2],
      name = pokemonData.getItemName(itemData[1])
    }
    if item.id == 0 then
      break
    end
    table.insert(bag, item)
  end

  self.bag.items = bag
  return self.bag
end
return Gen1PlayerReader
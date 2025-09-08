local PlayerReader = require("readers.player.playerreader")
local gameUtils = require("utils.gameutils")
local charmaps = require("data.charmaps")

local Gen2PlayerReader = {}
Gen2PlayerReader.__index = Gen2PlayerReader
setmetatable(Gen2PlayerReader, {__index = PlayerReader})

function Gen2PlayerReader:new()
    local obj = PlayerReader:new()
    setmetatable(obj, Gen2PlayerReader)
    return obj
end

function Gen2PlayerReader:updateTrainerInfo()
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


    -- Johto Badges is 1 byte, 1 bit per badge
    local johtoBadgesAddr = gameData.trainerOffsets.johtoBadges
    local johtoBadges = gameUtils.read8(johtoBadgesAddr, domain)

    -- Kanto Badges is 1 byte, 1 bit per badge
    local kantoBadgesAddr = gameData.trainerOffsets.kantoBadges
    local kantoBadges = gameUtils.read8(kantoBadgesAddr, domain)

    local badgeList = {
        {name = "Zephyr Badge", earned = (johtoBadges & 0x01) ~= 0},
        {name = "Hive Badge", earned = (johtoBadges & 0x02) ~= 0},
        {name = "Plain Badge", earned = (johtoBadges & 0x04) ~= 0},
        {name = "Fog Badge", earned = (johtoBadges & 0x08) ~= 0},
        {name = "Storm Badge", earned = (johtoBadges & 0x10) ~= 0},
        {name = "Mineral Badge", earned = (johtoBadges & 0x20) ~= 0},
        {name = "Glacier Badge", earned = (johtoBadges & 0x40) ~= 0},
        {name = "Rising Badge", earned = (johtoBadges & 0x80) ~= 0},
        {name = "Boulder Badge", earned = (kantoBadges & 0x01) ~= 0},
        {name = "Cascade Badge", earned = (kantoBadges & 0x02) ~= 0},
        {name = "Thunder Badge", earned = (kantoBadges & 0x04) ~= 0},
        {name = "Rainbow Badge", earned = (kantoBadges & 0x08) ~= 0},
        {name = "Soul Badge", earned = (kantoBadges & 0x10) ~= 0},
        {name = "Marsh Badge", earned = (kantoBadges & 0x20) ~= 0},
        {name = "Volcano Badge", earned = (kantoBadges & 0x40) ~= 0},
        {name = "Earth Badge", earned = (kantoBadges & 0x80) ~= 0}
    }

    -- Money is 3 bytes
    local moneyAddr = gameData.trainerOffsets.money
    local money = gameUtils.readBytes(moneyAddr, 3, domain)

    -- Crystal bytes are in weird order, but Gold/Silver are normal.
    if gameData.gameInfo.versionColor == "Crystal" then
        money = gameUtils.bytesToNumber({money[3], money[1], money[2]})
    else
        money = gameUtils.bytesToNumber(money)
    end

    -- Mom Money is 3 bytes
    local momMoneyAddr = gameData.trainerOffsets.momMoney
    local momMoney = gameUtils.readBytes(momMoneyAddr, 3, domain)
    
    if gameData.gameInfo.versionColor == "Crystal" then
        momMoney = gameUtils.bytesToNumber({momMoney[3], momMoney[1], momMoney[2]})
    else
        momMoney = gameUtils.bytesToNumber(momMoney)
    end

    -- Coins is 2 bytes, binary encoded
    local coinsAddr = gameData.trainerOffsets.coins
    local coins = gameUtils.read16(coinsAddr, domain)

    self.trainerInfo = {
        name = name,
        badges = badgeList,
        money = money,
        momMoney = momMoney,
        coins = coins or 0,
    }
end

function Gen2PlayerReader:printTrainerInfo()
    self:updateTrainerInfo()
    if self.trainerInfo then
        console.log("Trainer Name: " .. self.trainerInfo.name)
        console.log("Money: " .. self.trainerInfo.money)
        console.log("Mom's Money: " .. self.trainerInfo.momMoney)
        console.log("Coins: " .. self.trainerInfo.coins)
        console.log("Badges:")
        for _, badge in ipairs(self.trainerInfo.badges) do
            console.log("  " .. badge.name .. ": " .. (badge.earned and "Earned" or "Not Earned"))
        end
    else
        console.log("No trainer info available")
    end
end

return Gen2PlayerReader
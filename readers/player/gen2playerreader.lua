local PlayerReader = require("readers.player.playerreader")
local gameUtils = require("utils.gameutils")
local charmaps = require("data.charmaps")
local pokemonData = require("readers.pokemondata")

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

function Gen2PlayerReader:readBag()
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

    local itemCount = gameUtils.read8(gameData.trainerOffsets.itemCount, domain)
    local keyItemCount = gameUtils.read8(gameData.trainerOffsets.keyItemCount, domain)
    local ballCount = gameUtils.read8(gameData.trainerOffsets.ballCount, domain)
    local bag = {}

    -- Items are 2 bytes each (item ID and quantity) and 20 max
    local itemStartAddr = gameData.trainerOffsets.itemsPocket
    local items = {}
    for i = 0, itemCount - 1 do
        local itemAddr = itemStartAddr + (i * 2)
        local itemData = gameUtils.readBytes(itemAddr, 2, domain)
        -- Stop if we hit an empty slot (0 or 255)
        if itemData[1] == 0 or itemData[1] == 255 then
            break
        end
        local item = {
            id = itemData[1],
            quantity = itemData[2],
            name = pokemonData.getItemName(itemData[1])
        }
        table.insert(items, item)
    end
    bag.items = items

    -- Key Items are 2 bytes each (item ID and quantity) and 25 max
    local keyItemStartAddr = gameData.trainerOffsets.keyItemsPocket
    local keyItems = {}
    for i = 0, keyItemCount - 1 do
        local keyItemAddr = keyItemStartAddr + (i * 2)
        local keyItemData = gameUtils.readBytes(keyItemAddr, 2, domain)
        -- Stop if we hit an empty slot (0 or 255)
        if keyItemData[1] == 0 or keyItemData[1] == 255 then
            break
        end
        local keyItem = {
            id = keyItemData[1],
            quantity = keyItemData[2],
            name = pokemonData.getItemName(keyItemData[1])
        }
        table.insert(keyItems, keyItem)
    end
    bag.keyItems = keyItems

    -- Balls are 2 bytes each (item ID and quantity) and 12 max
    local ballStartAddr = gameData.trainerOffsets.ballsPocket
    local balls = {}
    for i = 0, ballCount - 1 do
        local ballAddr = ballStartAddr + (i * 2)
        local ballData = gameUtils.readBytes(ballAddr, 2, domain)
        -- Stop if we hit an empty slot (0 or 255)
        if ballData[1] == 0 or ballData[1] == 255 then
            break
        end
        local ball = {
            id = ballData[1],
            quantity = ballData[2],
            name = pokemonData.getItemName(ballData[1])
        }
        table.insert(balls, ball)
    end
    bag.pokeballs = balls

    self.bagInfo = bag

    --TM's and HM's are 1 byte each with 50 tms and 8 hms max
    -- The value at the index is the quantity owned (0-99)
    local tmhmStartAddr = gameData.trainerOffsets.tmhmPocket
    local tmhms = {tms = {}, hms = {}}

    for i = 1, 50 do
        local tmAddr = tmhmStartAddr + (i - 1)
        local tmQuantity = gameUtils.read8(tmAddr, domain)
        local tmMoveId = pokemonData.getTMMoveID(i)
        if tmQuantity > 0 then
            table.insert(tmhms.tms, {
                id = i,
                quantity = tmQuantity,
                name = string.format("TM%02d: %s", i, pokemonData.getMoveName(tmMoveId))
            })
        end
    end

    for i = 1, 7 do
        local hmAddr = tmhmStartAddr + 50 + (i - 1)
        local hmQuantity = gameUtils.read8(hmAddr, domain)
        local hmMoveId = pokemonData.getTMMoveID(i + 50)
        if hmQuantity > 0 then
            table.insert(tmhms.hms, {
                id = i + 50,
                quantity = hmQuantity,
                name = string.format("HM%02d: %s", i, pokemonData.getMoveName(hmMoveId))
            })
        end
    end

    bag.tmhms = tmhms

    self.bag = bag
    return self.bag
end

return Gen2PlayerReader
local PlayerReader = require("readers.player.playerreader")
local gameUtils = require("utils.gameutils")
local charmaps = require("data.charmaps")
local pokemonData = require("data.pokemondb")

local Gen3PlayerReader = {}
Gen3PlayerReader.__index = Gen3PlayerReader
setmetatable(Gen3PlayerReader, {__index = PlayerReader})

function Gen3PlayerReader:new()
    local obj = PlayerReader:new()
    setmetatable(obj, Gen3PlayerReader)
    return obj
end

function Gen3PlayerReader:updateTrainerInfo()
  if not MemoryReader.isInitialized or not MemoryReader.currentGame then
      console.log("MemoryReader is not initialized or no game detected.")
      return false
  end

  local gameData = MemoryReader.currentGame

  if not gameData or not gameData.trainerPointers then
      console.log("No trainer pointer data available for this game.")
      return false
  end

  local domain = "EWRAM"

  local trainerPointers = gameData.trainerPointers
  local trainerOffsets = gameData.trainerOffsets

  local saveBlock1Addr = gameUtils.read32(gameUtils.hexToNumber(trainerPointers.saveBlock1))
  local saveBlock2Addr = gameUtils.read32(gameUtils.hexToNumber(trainerPointers.saveBlock2))

  -- Money and Coins come encrypted
  local moneyEncrypted = gameUtils.read32(saveBlock1Addr + trainerOffsets.money, domain)
  local coinsEncrypted = gameUtils.read16(saveBlock1Addr + trainerOffsets.coins, domain)

  -- Save Block 2
  
  -- Name is 7 characters max + null terminator
  local nameBytes = gameUtils.readBytes(saveBlock2Addr + trainerOffsets.name, 8, domain)
  local name = charmaps.decryptText(nameBytes)
  
  -- Gender is 1 byte (0 = Male, 1 = Female)
  local gender = gameUtils.read8(saveBlock2Addr + trainerOffsets.gender, domain)

  -- Trainer ID is 4 bytes
  -- Public ID is the lower 16 bits
  -- Secret ID is the upper 16 bits
  local trainerID = gameUtils.read32(saveBlock2Addr + trainerOffsets.trainerID, domain)
  local publicID = trainerID & 0xFFFF
  local secretID = (trainerID >> 16) & 0xFFFF

  local encryptionKey = gameUtils.read32(saveBlock2Addr + trainerOffsets.encryptionKey, domain)

  -- Money is the XOR of the encrypted money and the encryption key
  local money = moneyEncrypted ~ encryptionKey
  -- Coins is the XOR of the encrypted coins and the lower 16 bits of the encryption key
  local coins = coinsEncrypted ~ (encryptionKey & 0xFFFF)

  self.trainerInfo = {
      name = name,
      gender = gender,
      money = money,
      coins = coins,
      trainerID = {
          id = trainerID,
          public = publicID,
          secret = secretID
      },
      encryptionKey = encryptionKey
  }
end

function Gen3PlayerReader:readBag()
    self:updateTrainerInfo()

    if not self.trainerInfo then
        console.log("Unable to read trainer info. Cannot read bag.")
        return false
    end

    local gameData = MemoryReader.currentGame
    local domain = "EWRAM"
    local bag = {}
    local saveBlock1Addr = gameUtils.read32(gameUtils.hexToNumber(gameData.trainerPointers.saveBlock1))
    local trainerOffsets = gameData.trainerOffsets

    -- Bag Contents
    --  Items Pocket (30 Items, 4 bytes each)
    --  Key Items Pocket (30 Items, 4 bytes each)
    --  Pokeballs Pocket (16 Items, 4 bytes each)
    --  TMs/HMs Pocket (64 Items, 4 bytes each)
    --  Berries Pocket (46 Items, 4 bytes each)
    --  PC Item Storage (50 items, 4 bytes each)

    -- Items are stored as pairs of (ItemID, Quantity 1-999)

    local quantityKey = self.trainerInfo.encryptionKey & 0xFFFF

    -- Items Pocket

    bag.items = {}
    local itemsStart = saveBlock1Addr + trainerOffsets.itemsPocket
    for i = 0, 29 do
        local itemID = gameUtils.read16(itemsStart + i * 4, domain)
        local quantity = gameUtils.read16(itemsStart + i * 4 + 2, domain) ~ quantityKey
        local name = pokemonData.getItemName(itemID)
        if itemID ~= 0 then
            table.insert(bag.items, {id = itemID, quantity = quantity, name = name})
        end
    end

    -- Key Items Pocket
    bag.keyItems = {}
    local keyItemsStart = saveBlock1Addr + trainerOffsets.keyItemsPocket
    for i = 0, 29 do
        local itemID = gameUtils.read16(keyItemsStart + i * 4, domain)
        local quantity = gameUtils.read16(keyItemsStart + i * 4 + 2, domain) ~ quantityKey
        local name = pokemonData.getItemName(itemID)
        if itemID ~= 0 then
            table.insert(bag.keyItems, {id = itemID, quantity = quantity, name = name})
        end
    end

    -- Pokeballs Pocket
    bag.pokeballs = {}
    local pokeballsStart = saveBlock1Addr + trainerOffsets.ballsPocket
    for i = 0, 15 do
        local itemID = gameUtils.read16(pokeballsStart + i * 4, domain)
        local quantity = gameUtils.read16(pokeballsStart + i * 4 + 2, domain) ~ quantityKey
        local name = pokemonData.getItemName(itemID)
        if itemID ~= 0 then
            table.insert(bag.pokeballs, {id = itemID, quantity = quantity, name = name})
        end
    end

    -- TMs/HMs Pocket
    bag.tms = {}
    local tmsStart = saveBlock1Addr + trainerOffsets.tmhmPocket
    for i = 0, 63 do
        local itemID = gameUtils.read16(tmsStart + i * 4, domain)
        local quantity = gameUtils.read16(tmsStart + i * 4 + 2, domain) ~ quantityKey
        local name = pokemonData.getItemName(itemID)
        if itemID ~= 0 then
            table.insert(bag.tms, {id = itemID, quantity = quantity, name = name})
        end
    end

    -- Berries Pocket
    bag.berries = {}
    local berriesStart = saveBlock1Addr + trainerOffsets.berriesPocket
    for i = 0, 45 do
        local itemID = gameUtils.read16(berriesStart + i * 4, domain)
        local quantity = gameUtils.read16(berriesStart + i * 4 + 2, domain) ~ quantityKey
        local name = pokemonData.getItemName(itemID)
        if itemID ~= 0 then
            table.insert(bag.berries, {id = itemID, quantity = quantity, name = name})
        end
    end

    self.bag = bag
end


-- MARK: - SETTERS

function Gen3PlayerReader:setMoney(amount)
    self:updateTrainerInfo()

    if not self.trainerInfo then
        console.log("Unable to read trainer info. Cannot set money.")
        return false
    end

    local money = gameUtils.clamp(amount, 0, 999999)  -- Clamp money to valid range

    local gameData = MemoryReader.currentGame
    local domain = "EWRAM"

    local trainerPointers = gameData.trainerPointers
    local trainerOffsets = gameData.trainerOffsets

    local saveBlock1Addr = gameUtils.read32(gameUtils.hexToNumber(trainerPointers.saveBlock1))

    local encryptionKey = self.trainerInfo.encryptionKey

    -- Encrypt the new money amount using the encryption key
    local encryptedMoney = money ~ encryptionKey

    -- Write the encrypted money back to memory
    console.log("Writing encrypted money to address: " .. string.format("0x%X", saveBlock1Addr + trainerOffsets.money))
    gameUtils.write32(saveBlock1Addr + trainerOffsets.money, encryptedMoney, domain)

    console.log("Set money to " .. amount .. " (encrypted: " .. string.format("0x%X", encryptedMoney) .. ")")

    -- Update internal state
    self.trainerInfo.money = amount

    return true
end

function Gen3PlayerReader:addItemPocket(id, quantity, slotOverride)
    self:updateTrainerInfo()
    self:readBag()

    if not self.trainerInfo then
        console.log("Unable to read trainer info. Cannot read bag.")
        return false
    end

    quantity = gameUtils.clamp(quantity, 1, 99)

    local gameData = MemoryReader.currentGame
    local domain = "EWRAM"
    local saveBlock1Addr = gameUtils.read32(gameUtils.hexToNumber(gameData.trainerPointers.saveBlock1))
    local trainerOffsets = gameData.trainerOffsets

    local slotAddr = self:findFreeSlot(saveBlock1Addr + trainerOffsets.itemsPocket, 30)
    if slotOverride then
        if slotOverride < 1 or slotOverride > 30 then
            console.log("Invalid slot override. Must be between 1 and 30.")
            return false
        end
        console.log("Using slot override: " .. slotOverride)

      
        slotAddr = saveBlock1Addr + trainerOffsets.itemsPocket + (slotOverride - 1) * 4

        if self:getItemAt(slotAddr).id ~= 0 then
            console.log("Warning: There is already an item in slot " .. slotOverride)
            return false
        end
    end

    if not slotAddr then
        console.log("No free slot available in Items Pocket.")
        return false
    end

    local quantityKey = self.trainerInfo.encryptionKey & 0xFFFF
    local encryptedQuantity = quantity ~ quantityKey

    console.log("Writing item ID " .. id .. " with encrypted quantity " .. string.format("0x%X", encryptedQuantity) .. " to address: " .. string.format("0x%X", slotAddr))

    gameUtils.write16(slotAddr, id, domain)
    gameUtils.write16(slotAddr + 2, encryptedQuantity, domain)

    console.log("Set item ID " .. id .. " with quantity " .. quantity)
end

-- MARK: - UTILITY

function Gen3PlayerReader:printTrainerInfo()
    self:updateTrainerInfo()

    if self.trainerInfo then
        console.log("Trainer Info:")
        console.log("Name: " .. self.trainerInfo.name)
        console.log("Gender: " .. (self.trainerInfo.gender == 0 and "Male" or "Female"))
        console.log("Money: " .. self.trainerInfo.money)
        console.log("Coins: " .. self.trainerInfo.coins)
        console.log("Trainer ID: " .. self.trainerInfo.trainerID.id)
        console.log("Public ID: " .. self.trainerInfo.trainerID.public)
        console.log("Secret ID: " .. self.trainerInfo.trainerID.secret)
    end
end

function Gen3PlayerReader:printBag()
  self:readBag()
  local bag = self.bag
  if bag then
    console.log("Bag Contents:")
    console.log("Items:")
    for _, item in ipairs(bag.items) do
      console.log(string.format("  ID: %d, Name: %s, Quantity: %d", item.id, item.name or "", item.quantity))
    end
    console.log("Key Items:")
    for _, item in ipairs(bag.keyItems) do
      console.log(string.format("  ID: %d, Name: %s, Quantity: %d", item.id, item.name or "", item.quantity))
    end
    console.log("Pokeballs:")
    for _, item in ipairs(bag.pokeballs) do
      console.log(string.format("  ID: %d, Name: %s, Quantity: %d", item.id, item.name or "", item.quantity))
    end
    console.log("TMs/HMs:")
    for _, item in ipairs(bag.tms) do
      console.log(string.format("  ID: %d, Name: %s, Quantity: %d", item.id, item.name or "", item.quantity))
    end
    console.log("Berries:")
    for _, item in ipairs(bag.berries) do
      console.log(string.format("  ID: %d, Name: %s, Quantity: %d", item.id, item.name or "", item.quantity))
    end
  end
end

function Gen3PlayerReader:getItemAt(address)
    return {
        id = gameUtils.read16(address, "EWRAM"),
        quantity = gameUtils.read16(address + 2, "EWRAM") ~ 0x0508  -- Decrypt quantity
    }
end

function Gen3PlayerReader:findFreeSlot(startingAddress, maxSlots)
    for i = 0, maxSlots - 1 do
        local addr = startingAddress + i * 4
        if self:getItemAt(addr).id == 0 then
            return addr
        end
    end
    return nil  -- No free slot found
end

return Gen3PlayerReader
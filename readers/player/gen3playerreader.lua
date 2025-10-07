local PlayerReader = require("readers.player.playerreader")
local gameUtils = require("utils.gameutils")
local charmaps = require("data.charmaps")
local pokemonData = require("readers.pokemondata")

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

  local saveBlock1Addr = gameUtils.hexToNumber(trainerPointers.saveBlock1)
  local saveBlock2Addr = gameUtils.hexToNumber(trainerPointers.saveBlock2)


  -- For Emerald, FireRed, and LeafGreen, save block data require pointers to find the position.
  if gameData.trainerPointers.isPointer then
    saveBlock1Addr = gameUtils.read32(gameUtils.hexToNumber(trainerPointers.saveBlock1))
    saveBlock2Addr = gameUtils.read32(gameUtils.hexToNumber(trainerPointers.saveBlock2))
  end


  -- Money and Coins come encrypted for Emerald.
  -- For Ruby/Sapphire, they are stored in plain binary.
  local money = gameUtils.read32(saveBlock1Addr + trainerOffsets.money, domain)
  local coins = gameUtils.read16(saveBlock1Addr + trainerOffsets.coins, domain)

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

  local encryptionKey = nil -- Default to nil if not present

    -- Some games have an encryption key used for encrypting money and items
    -- Emerald, Firered, Leafgreen
  if gameData.trainerOffsets.encryptionKey then
      encryptionKey = gameUtils.read32(saveBlock2Addr + trainerOffsets.encryptionKey, domain)
      -- Money is the XOR of the encrypted money and the encryption key
      money = money ~ encryptionKey
      -- Coins is the XOR of the encrypted coins and the lower 16 bits of the encryption key
      coins = coins ~ (encryptionKey & 0xFFFF)
  end

  local flagsAddr = saveBlock1Addr + trainerOffsets.flags
  local badgeOffset = trainerOffsets.badgeFlags
  local badgeAddr = flagsAddr + badgeOffset
  -- Read 2 bytes to get all 8 badges.
  -- Badge 1 starts at bit 7 of the first byte.
  -- Each badge is 1 bit.
    local badgeData = gameUtils.read16(badgeAddr, domain)
    local badgeBits = (badgeData >> 7) & 0xFF  -- Shift to get badges in lower 8 bits

  -- Firered and Leafgreen are a single bit and don't need fancy footwork.
  if gameData.gameInfo.versionColor == "FireRed" or gameData.gameInfo.versionColor == "LeafGreen" then
      badgeBits = gameUtils.read8(badgeAddr, domain)
  end

  local badgeList = {
        {badgeNum = 1, name = "Boulder Badge", earned = (badgeBits & 0x01) ~= 0},
        {badgeNum = 2, name = "Cascade Badge", earned = (badgeBits & 0x02) ~= 0},
        {badgeNum = 3, name = "Thunder Badge", earned = (badgeBits & 0x04) ~= 0},
        {badgeNum = 4, name = "Rainbow Badge", earned = (badgeBits & 0x08) ~= 0},
        {badgeNum = 5, name = "Soul Badge", earned = (badgeBits & 0x10) ~= 0},
        {badgeNum = 6, name = "Marsh Badge", earned = (badgeBits & 0x20) ~= 0},
        {badgeNum = 7, name = "Volcano Badge", earned = (badgeBits & 0x40) ~= 0},
        {badgeNum = 8, name = "Earth Badge", earned = (badgeBits & 0x80) ~= 0}
  }


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
    badges = badgeList,
      encryptionKey = encryptionKey or nil
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

    -- Emerald uses a pointer to find the SaveBlock1 location.
    -- Ruby/Sapphire, Firered, Leafgreen have fixed locations.
    local saveBlock1Addr = gameUtils.hexToNumber(gameData.trainerPointers.saveBlock1)
    if gameData.trainerPointers.isPointer then
        saveBlock1Addr = gameUtils.read32(gameUtils.hexToNumber(gameData.trainerPointers.saveBlock1))
    end
    local trainerOffsets = gameData.trainerOffsets


    -- Items are stored as pairs of (ItemID, Quantity 1-999)
    -- Ruby/Sapphire don't have an encryption key and items are
    -- stored in plain binary.
    -- Emerald, Firered, Leafgreen use the encryption key to XOR
    -- the quantity value.
    
    local quantityKey = nil
    if self.trainerInfo.encryptionKey then
        quantityKey = self.trainerInfo.encryptionKey & 0xFFFF
    end

    -- Items Pocket
    bag.items = {}
    local itemsStart = saveBlock1Addr + trainerOffsets.itemsPocket
    for i = 0, gameData.pocketSize.itemsPocket - 1 do
        local itemID = gameUtils.read16(itemsStart + i * 4, domain)
        local quantity = gameUtils.read16(itemsStart + i * 4 + 2, domain)
        if quantityKey then
            quantity = quantity ~ quantityKey
        end
        local name = pokemonData.getItemName(itemID)
        if itemID ~= 0 then
            table.insert(bag.items, {id = itemID, quantity = quantity, name = name})
        end
    end

    -- Key Items Pocket
    bag.keyItems = {}
    local keyItemsStart = saveBlock1Addr + trainerOffsets.keyItemsPocket
    for i = 0, gameData.pocketSize.keyItemsPocket - 1 do
        local itemID = gameUtils.read16(keyItemsStart + i * 4, domain)
        local quantity = gameUtils.read16(keyItemsStart + i * 4 + 2, domain)
        if quantityKey then
            quantity = quantity ~ quantityKey
        end
        local name = pokemonData.getItemName(itemID)
        if itemID ~= 0 then
            table.insert(bag.keyItems, {id = itemID, quantity = quantity, name = name})
        end
    end

    -- Pokeballs Pocket
    bag.pokeballs = {}
    local pokeballsStart = saveBlock1Addr + trainerOffsets.ballsPocket
    for i = 0, gameData.pocketSize.ballsPocket - 1 do
        local itemID = gameUtils.read16(pokeballsStart + i * 4, domain)
        local quantity = gameUtils.read16(pokeballsStart + i * 4 + 2, domain)
        if quantityKey then
            quantity = quantity ~ quantityKey
        end
        local name = pokemonData.getItemName(itemID)
        if itemID ~= 0 then
            table.insert(bag.pokeballs, {id = itemID, quantity = quantity, name = name})
        end
    end

    -- TMs/HMs Pocket
    bag.tmhms = {tms = {}, hms = {}}
    local tmsStart = saveBlock1Addr + trainerOffsets.tmhmPocket
    for i = 0, gameData.pocketSize.tmhmPocket - 1 do
        local itemID = gameUtils.read16(tmsStart + i * 4, domain)
        local quantity = gameUtils.read16(tmsStart + i * 4 + 2, domain)
        if quantityKey then
            quantity = quantity ~ quantityKey
        end
        local name = pokemonData.getItemName(itemID)
        --Number is last two chars of name
        local number = name and tonumber(name:match("%d+"))
        if itemID == 0 then
            goto continue
        end

        -- Check Name
        if name and name:match("^TM") then
            local moveID = pokemonData.getTMMoveID(number)
            local moveName = pokemonData.getMoveName(moveID)
            table.insert(bag.tmhms.tms, {id = itemID, quantity = quantity, name = string.format("%s: %s", name, moveName or "Unknown Move")})
        elseif name and name:match("^HM") then
            local moveID = pokemonData.getTMMoveID(number + 50)
            local moveName = pokemonData.getMoveName(moveID)
            table.insert(bag.tmhms.hms, {id = itemID, quantity = quantity, name = string.format("%s: %s", name, moveName or "Unknown Move")})
        end
        ::continue::
    end

    -- Berries Pocket
    bag.berries = {}
    local berriesStart = saveBlock1Addr + trainerOffsets.berriesPocket
    for i = 0, gameData.pocketSize.berriesPocket - 1 do
        local itemID = gameUtils.read16(berriesStart + i * 4, domain)
        local quantity = gameUtils.read16(berriesStart + i * 4 + 2, domain)
        if quantityKey then
            quantity = quantity ~ quantityKey
        end
        local name = pokemonData.getItemName(itemID)
        if itemID ~= 0 then
            table.insert(bag.berries, {id = itemID, quantity = quantity, name = name})
        end
    end

    self.bag = bag
    return self.bag
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

    
    -- Encrypt the new money amount using the encryption key
    if gameData.trainerOffsets.encryptionKey then
        local encryptionKey = self.trainerInfo.encryptionKey
        money = money ~ encryptionKey
    end

    -- Write the encrypted money back to memory
    console.log("Writing encrypted money to address: " .. string.format("0x%X", saveBlock1Addr + trainerOffsets.money))
    gameUtils.write32(saveBlock1Addr + trainerOffsets.money, money, domain)

    console.log("Set money to " .. amount .. " (encrypted: " .. string.format("0x%X", money) .. ")")

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
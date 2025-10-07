local json = require("modules.dkjson")

local PlayerFormatter = {}

function PlayerFormatter.formatPlayerData(trainerInfo, bag)
  trainerInfo = trainerInfo or {}
  bag = bag or {}

  -- Ensure fields we index are present to avoid nil-index errors
  trainerInfo.name = trainerInfo.name or "(unknown)"
  trainerInfo.gender = trainerInfo.gender
  trainerInfo.money = trainerInfo.money or 0
  trainerInfo.coins = trainerInfo.coins or 0
  trainerInfo.badges = trainerInfo.badges or {}
  trainerInfo.encryptionKey = trainerInfo.encryptionKey or nil
  trainerInfo.momMoney = trainerInfo.momMoney or nil

  local output = {}
  table.insert(output, "=== TRAINER INFORMATION ===")
  table.insert(output, "Name: " .. trainerInfo.name)
  -- Gen 1 doesn't use gender.
  if trainerInfo.gender then
    table.insert(output, "Gender: " .. (trainerInfo.gender or "n/a"))
  end
  table.insert(output, "Money: " .. trainerInfo.money)
  -- Only gen 2 and gen 4 remakes have Mom's money.
  if trainerInfo.momMoney then
    table.insert(output, "Mom's Money: " .. trainerInfo.momMoney)
  end
  table.insert(output, "Coins: " .. trainerInfo.coins)
  -- Some games don't have encryption keys.
  if trainerInfo.encryptionKey then
    table.insert(output, "Encryption Key: " .. trainerInfo.encryptionKey)
  end
  table.insert(output, "=== BADGES ===")
  for _, badge in ipairs(trainerInfo.badges) do
    local status = (badge and badge.earned) and "Earned" or "Not Earned"
    local badgeNum = badge and badge.badgeNum or "?"
    table.insert(output, string.format(" - Badge %s: %s", tostring(badgeNum), status))
  end

  table.insert(output, PlayerFormatter.formatBagData(bag))

  return table.concat(output, "\n")
end

function PlayerFormatter.formatBagData(bag)
  bag = bag or {}
  local gen = 0
  if MemoryReader and MemoryReader.currentGame and MemoryReader.currentGame.gameInfo then
    gen = tonumber(MemoryReader.currentGame.gameInfo.generation) or 0
  end

  local output = {}
  table.insert(output, "=== BAG CONTENTS ===")

  -- Generation 1 only has items.
  if gen == 1 then
    table.insert(output, "Items:")
    for _, item in ipairs(bag.items or {}) do
      table.insert(output, string.format("  - %s (ID: %d, Qty: %d)", item.name or "", item.id or 0, item.quantity or 0))
    end
  else
    for _, category in ipairs({"items", "keyItems", "pokeballs"}) do
      table.insert(output, string.upper(category) .. ":")
      for _, item in ipairs(bag[category] or {}) do
        table.insert(output, string.format("  - %s (ID: %d, Qty: %d)", item.name or "", item.id or 0, item.quantity or 0))
      end
    end
    table.insert(output, "TMs/HMs:")
    for _, tm in ipairs(bag.tmhms and bag.tmhms.tms or {}) do
      table.insert(output, string.format("  - %s (ID: %d, Qty: %d)", tm.name or "", tm.id or 0, tm.quantity or 0))
    end
    for _, hm in ipairs(bag.tmhms and bag.tmhms.hms or {}) do
      table.insert(output, string.format("  - %s (ID: %d, Qty: %d)", hm.name or "", hm.id or 0, hm.quantity or 0))
    end
  end
  return table.concat(output, "\n")
end

-- MARK: JSON

function PlayerFormatter.formatPlayerJSON(trainerInfo)
  return json.encode(trainerInfo)
end

function PlayerFormatter.formatBagJSON(bag)
  return json.encode(bag)
end

return PlayerFormatter
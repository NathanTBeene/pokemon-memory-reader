local json = require("modules.dkjson")

local PlayerFormatter = {}

function PlayerFormatter.formatPlayerData(trainerInfo, bag)
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
    local status = badge.earned and "Earned" or "Not Earned"
    table.insert(output, string.format(" - Badge %d: %s", badge.badgeNum, status))
  end

  table.insert(output, PlayerFormatter.formatBagData(bag))

  return table.concat(output, "\n")
end

function PlayerFormatter.formatBagData(bag)
  local gen = MemoryReader.currentGame.gameInfo.generation
  local output = {}

  table.insert(output, "=== BAG CONTENTS ===")
  -- Generation 1 only has items.
  if gen == 1 then
    table.insert(output, "Items:")
    for _, item in ipairs(bag.items) do
      table.insert(output, string.format("  - %s (ID: %d, Qty: %d)", item.name, item.id, item.quantity))
    end
  else
    for pocketName, items in pairs(bag) do
      if #items > 0 then
        table.insert(output, pocketName .. ":")
        for _, item in ipairs(items) do
          table.insert(output, string.format("  - %s (ID: %d, Qty: %d)", item.name, item.id, item.quantity))
        end
      end
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
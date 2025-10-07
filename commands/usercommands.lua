
local UserCommands = {}
local formatter = require("formatting.formatter")
local debugTools = require("debug.debugtools")
local GamesDB = require("data.gamesdb")

-- MARK: Basic Utility

-- Ensures the global MemoryReader has been properly initialized.
local function ensureInitialized()
  if not MemoryReader.isInitialized then
    console.log("MemoryReader is not initialized, please restart the application.")
    return false
  end
  return true
end

-- Prints the available commands forr the user.
function UserCommands.help()
  console.log("=== Pokemon Memory Reader Commands ===")
  console.log("showParty() - Displays the current party information.")
  console.log("startServer() - Starts the memory reading server.")
  console.log("stopServer() - Stops the memory reading server.")
  console.log("toggleServer() - Toggles the memory reading server.")
  console.log("debugParty() - Displays raw data about the current party.")
  console.log("")
  console.log("API Endpoints (when server running):")
  console.log("  GET http://localhost:8080/party - Party data in JSON")
  console.log("  GET http://localhost:8080/status - Server status")
  console.log("  GET http://localhost:8080/ - API documentation")
  console.log("=====================================")
end

function UserCommands.showGameInfo()
  if not ensureInitialized() then return end
  if not MemoryReader.currentGame then
    console.log("No game loaded.")
    return
  end

  local gameInfo = MemoryReader.currentGame.gameInfo
  console.log("Current Game Information:")
  console.log("Name: " .. (gameInfo.gameName or "Unknown"))
  console.log("Code: " .. (string.format("%04X", gameInfo.gameCode) or "Unknown"))
  console.log("Platform: " .. (gameInfo.platform or "Unknown"))
  console.log("Version: " .. (gameInfo.versionColor or "Unknown"))
  console.log("Generation: " .. (gameInfo.generation or "Unknown"))
  console.log("Is Hack: " .. tostring(gameInfo.isHack or false))

end

-- MARK: Party

-- Retrieves and prints the current party data.
function UserCommands.showParty()
  if not ensureInitialized() then return end

  local party = MemoryReader.getPartyData()
  if party then
    console.log(formatter.formatPartyData(party))
  end
end

-- MARK: Server

function UserCommands.startServer()
  MemoryReader.serverEnabled = true
  MemoryReader.startServer()
end

function UserCommands.stopServer()
  MemoryReader.serverEnabled = false
  MemoryReader.stopServer()
end

function UserCommands.toggleServer()
  MemoryReader.serverEnabled = not MemoryReader.serverEnabled
  MemoryReader.toggleServer()
end

-- MARK: Player

-- Prints the Player information to console.
function UserCommands.showPlayer()
  if not ensureInitialized() then return end
  local playerReader = MemoryReader.playerReader
  playerReader:updateTrainerInfo()
  playerReader:readBag()

  local trainerInfo = playerReader.trainerInfo
  local bag = playerReader.bag
  console.log(formatter.formatPlayerData(trainerInfo, bag))
end

-- Sets the player's money to the specified amount.
-- TODO: Implement for other games besides Emerald.
-- function UserCommands.setMoney(amount)
--   if not ensureInitialized() then return end
--   MemoryReader.playerReader:setMoney(amount)
-- end

-- Adds an item to the player's bag in the first available slot.
-- If slot is specified, adds to that slot instead or warns if
-- the slot is occupied.
-- !Only works in Emerald for now.
-- TODO: Implement for other games.
-- function UserCommands.addItemPocket(id, quantity, slotOverride)
--   if not ensureInitialized() then return end
--   MemoryReader.playerReader:addItemPocket(id, quantity, slotOverride)
-- end

-- MARK: Debug

-- Prints raw party data for debugging purposes.
function UserCommands.debugParty()
  if not ensureInitialized() then return end

  debugTools.debugParty()
end

-- Dumps a section of the ROM to a file for debugging purposes.
function UserCommands.dumpROM(address, length)
  if not ensureInitialized() then return end

  debugTools.dumpROMData(address, length)
end

-- Encodes a Pokemon's Misc2 data and prints the result.
function UserCommands.encodeMisc2(hp, atk, def, spd, spatk, spdef, isEgg, ability)
  if not ensureInitialized() then return end

  debugTools.encodeMisc2(hp, atk, def, spd, spatk, spdef, isEgg, ability)
end

return UserCommands
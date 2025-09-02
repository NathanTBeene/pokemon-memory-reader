
local UserCommands = {}
local formatter = require("utils.pokemonformatter")
local debugTools = require("debug.debugtools")

local function ensureInitialized()
  if not MemoryReader.isInitialized then
    console.log("MemoryReader is not initialized, please restart the application.")
    return false
  end
  return true
end

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

function UserCommands.showParty()
  if not ensureInitialized() then return end

  local party = MemoryReader.getPartyData()
  if party then
    console.log(formatter.formatPartyData(party))
  end
end

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

function UserCommands.debugParty()
  if not ensureInitialized() then return end

  debugTools.debugParty(MemoryReader)
end

return UserCommands
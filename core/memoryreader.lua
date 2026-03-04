---@class MemoryReader
---@field currentGame GameEntry|nil   Detected game entry from GamesDB
---@field isInitialized boolean       Whether the memory reader has been initialized
---@field partyReader PartyReader|nil The party reader instance for the detected game
---@field playerReader PlayerReader|nil The player reader instance (if applicable)
---@field server table|nil            The HTTP server instance
---@field serverEnabled boolean       Whether the HTTP server is enabled

local gameDetection = require("core.gamedetection")
local Server = require("network.server")

---@type table<integer, GenerationConfig>
local generationRegistry = {
    [1] = {
        partyReader  = function(g) return require("readers.party.gen1partyreader"):new(g) end,
        playerReader = function(g) return require("readers.player.gen1playerreader"):new(g) end,
    },
    [2] = {
        partyReader  = function(g) return require("readers.party.gen2partyreader"):new(g) end,
        playerReader = function(g) return require("readers.player.gen2playerreader"):new(g) end,
    },
    [3] = {
        partyReader  = function(g) return require("readers.party.gen3partyreader"):new(g) end,
        playerReader = function(g) return require("readers.player.gen3playerreader"):new(g) end,
    },
    [4] = {
        partyReader  = function(g) return require("readers.party.gen4partyreader"):new(g) end,
    },
}

---@type table<string, GenerationConfig>
local romHackRegistry = {
    ["CFRU"] = {
        partyReader = function(g) return require("readers.party.cfrupartyreader"):new(g) end,
    },
}

MemoryReader = {}
MemoryReader.currentGame = nil
MemoryReader.isInitialized = false
MemoryReader.partyReader = nil
MemoryReader.playerReader = nil
MemoryReader.server = nil
MemoryReader.serverEnabled = true

--- Initializes the Memory Reader by detecting the currently loaded game
--- and setting up the appropriate readers and server.
---@return boolean
function MemoryReader.initialize()
    console.log("----- Pokemon Memory Reader -----")
    console.log("Initializing...")

    local detectedGame = gameDetection.detectGame()

    if detectedGame and detectedGame.gameInfo then
        local gameName = detectedGame.gameInfo.gameName or "Unknown Game"
        console.log("Game found: " .. gameName)

        MemoryReader.currentGame = detectedGame
        MemoryReader.isInitialized = true

        local generation = detectedGame.gameInfo.generation

        local config = romHackRegistry[detectedGame.gameInfo.romHackType or ""]
            or generationRegistry[generation]
        if not config then
            console.log("Unsupported generation: " .. tostring(generation))
            return false
        end

        MemoryReader.partyReader = config.partyReader(detectedGame)
        if config.playerReader then
            MemoryReader.playerReader = config.playerReader(detectedGame)
        end

        if MemoryReader.serverEnabled then
            MemoryReader.startServer()
        end

        return true
    else
        local supportedGames = gameDetection.getSupportedGames()
        console.log("No supported Pokemon game detected!")
        console.log("Supported games: " .. table.concat(supportedGames, ", "))
        return false
    end
end

--- Main update loop — called every frame.
function MemoryReader.update()
    if not MemoryReader.isInitialized then return end
    if MemoryReader.server then
        MemoryReader.server:update()
    end
end

---@return (Pokemon?)[]|nil
function MemoryReader.getPartyData()
    if not MemoryReader.isInitialized then
        console.log("Memory Reader not initialized! Please restart the script.")
        return nil
    end
    if not MemoryReader.partyReader then
        console.log("Party reader not available for this game!")
        return nil
    end
    return MemoryReader.partyReader:readParty()
end

---@return boolean
function MemoryReader.startServer()
    if MemoryReader.server then
        console.log("Server is already running!")
        return true
    end
    MemoryReader.server = Server:new(MemoryReader)
    return MemoryReader.server:start()
end

---@return boolean
function MemoryReader.stopServer()
    if not MemoryReader.server then
        console.log("Server is not running!")
        return true
    end
    local success = MemoryReader.server:stop()
    MemoryReader.server = nil
    return success
end

function MemoryReader.toggleServer()
    if MemoryReader.server then
        MemoryReader.stopServer()
        console.log("Server disabled")
    else
        if MemoryReader.startServer() then
            console.log("Server enabled")
        else
            console.log("Failed to start server")
        end
    end
end

function MemoryReader.shutdown()
    console.log("Pokemon Memory Reader shutting down...")
    if MemoryReader.server then
        MemoryReader.stopServer()
    end
    MemoryReader.isInitialized = false
end

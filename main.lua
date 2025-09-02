-- Pokemon Memory Reader - Main Script
-- This script initializes the application and manages the game detection system

-- Load required modules
local gameDetection = require("core.gamedetection")
local Gen3PartyReader = require("readers.gen3partyreader")
local Gen2PartyReader = require("readers.gen2partyreader")
local Gen1PartyReader = require("readers.gen1partyreader")
local gameUtils = require("utils.gameutils")
local debugTools = require("debug.debugtools")
local Server = require("network.server")

-- Global variables
MemoryReader = {}
MemoryReader.currentGame = nil
MemoryReader.gameAddresses = nil
MemoryReader.isInitialized = false
MemoryReader.partyReader = nil
MemoryReader.server = nil
MemoryReader.serverEnabled = true -- Can be toggled by user


-- Initialize the Memory Reader
function MemoryReader.initialize()
    console.log("----- Pokemon Memory Reader -----")
    console.log("Initializing...")
    
    -- Detect the currently loaded game
    local detectedGame = gameDetection.detectGame()
    
    if detectedGame and detectedGame.GameInfo then
        
        -- Get game name from detected game info
        local gameName = detectedGame.GameInfo.gameName or "Unknown Game"
        console.log("Game found: " .. gameName)
        
        MemoryReader.currentGame = detectedGame
        MemoryReader.gameAddresses = detectedGame.Addresses or {}
        MemoryReader.isInitialized = true
        
        -- Initialize party reader based on game generation (simplified)
        local generation = detectedGame.GameInfo.generation
        if generation == 3 then
            MemoryReader.partyReader = Gen3PartyReader:new()
        elseif generation == 2 then
            MemoryReader.partyReader = Gen2PartyReader:new()
        elseif generation == 1 then
            MemoryReader.partyReader = Gen1PartyReader:new()
        else
            console.log("Unsupported generation: " .. tostring(generation))
            return false
        end
        
        -- Start HTTP server
        if MemoryReader.serverEnabled then
            MemoryReader.startServer()
        end
        
        return true
    else
        console.log("No supported Pokemon game detected!")
        console.log("Supported games: Red, Blue, Green, Yellow, Gold, Silver, Crystal, Ruby, Sapphire, Emerald, FireRed, LeafGreen")
        
        return false
    end
end

-- Main update loop (called every frame)
function MemoryReader.update()
    if not MemoryReader.isInitialized then
        return
    end
    
    -- Update HTTP server
    if MemoryReader.server then
        MemoryReader.server:update()
    end
end

-- Get party data based on game generation
function MemoryReader.getPartyData()
    if not MemoryReader.isInitialized then
        console.log("Memory Reader not initialized! Please restart the script.")
        return nil
    end
    
    if not MemoryReader.partyReader then
        console.log("Party reader not available for this game!")
        return nil
    end
    
    -- Read party based on game generation
    local gameCode = MemoryReader.currentGame.GameInfo.gameCode
    local party
    
    if MemoryReader.currentGame.GameInfo.generation == 1 or MemoryReader.currentGame.GameInfo.generation == 2 then
        -- Gen1 and Gen2 use integer addresses directly
        party = MemoryReader.partyReader:readParty(MemoryReader.gameAddresses, gameCode)
    else
        -- Gen3 uses partyAddr (string hex format)
        if not MemoryReader.gameAddresses.partyAddr then
            console.log("Player party address not available!")
            return nil
        end
        local partyAddr = gameUtils.hexToNumber(MemoryReader.gameAddresses.partyAddr)
        party = MemoryReader.partyReader:readParty({partyAddr = partyAddr}, gameCode)
    end
    
    return party
end



-- Server management functions
function MemoryReader.startServer()
    if MemoryReader.server then
        console.log("Server is already running!")
        return true
    end
    
    MemoryReader.server = Server:new(MemoryReader)
    return MemoryReader.server:start()
end

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


-- Shutdown cleanup
function MemoryReader.shutdown()
    console.log("Pokemon Memory Reader shutting down...")
    
    -- Stop server if running
    if MemoryReader.server then
        MemoryReader.stopServer()
    end
    
    MemoryReader.isInitialized = false
end

-- Register user commands
local UserCommands = require("commands.usercommands")

-- Register global command functions
showParty = UserCommands.showParty
startServer = UserCommands.startServer
stopServer = UserCommands.stopServer
toggleServer = UserCommands.toggleServer
help = UserCommands.help
debugParty = UserCommands.debugParty

-- Initialize on script start
if MemoryReader.initialize() then
    console.log("----- PMR Ready -----")
    console.log("Type help() for a list of commands!")
    
    -- Register event callbacks
    event.onexit(MemoryReader.shutdown)
    
    -- Main execution loop
    while true do
        MemoryReader.update()
        emu.frameadvance()
    end
else
    console.log("Initialization failed!")
end
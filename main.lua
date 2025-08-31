-- Pokemon Memory Reader - Main Script
-- This script initializes the application and manages the game detection system

-- Load required modules
local charmaps = require("data.charmaps")
local gameDetection = require("core.gamedetection")
local Gen3PartyReader = require("readers.gen3partyreader")
local Gen2PartyReader = require("readers.gen2partyreader")
local Gen1PartyReader = require("readers.gen1partyreader")
local gameUtils = require("utils.gameutils")
local debugTools = require("debug.debugtools")
local Server = require("network.server")

-- Global variables
local MemoryReader = {}
MemoryReader.currentGame = nil
MemoryReader.gameAddresses = nil
MemoryReader.isInitialized = false
MemoryReader.partyReader = nil
MemoryReader.server = nil
MemoryReader.serverEnabled = true -- Can be toggled by user

-- Global debug functions for console access
function debugSpeciesData(slot)
    debugTools.debugSpeciesData(MemoryReader, slot or 1)
end

function debugParty()
    debugTools.debugParty(MemoryReader)
end

function debugAbility(slot)
    debugTools.debugAbility(MemoryReader, slot or 1)
end

function debugAbilityNamesFromROM(startId, endId, address)
    debugTools.debugAbilityNamesFromROM(startId or 0, endId or 10, address)
end

function searchAbilityTable()
    debugTools.searchAbilityTable()
end

function dumpROMData(address, length)
    debugTools.dumpROMData(address or 0x8240000, length or 256)
end

-- Initialize the Memory Reader
function MemoryReader.initialize()
    console.log("----- Pokemon Memory Reader -----")
    console.log("Initializing...")
    
    -- Detect the currently loaded game
    local detectedGame = gameDetection.detectGame()
    
    if detectedGame and detectedGame.GameInfo then
        -- Show game code detected
        local gameCode = gameUtils.gameCodeToString(detectedGame.GameInfo.GameCode)
        console.log("Game code detected: " .. gameCode)
        console.log("Config loaded...")
        
        -- Get game name from our config
        local configLoader = require("utils.configloader")
        local gameConfig = configLoader.getGameConfig(gameCode)
        local gameName = gameConfig and gameConfig.name or detectedGame.GameInfo.GameName or "Unknown Game"
        console.log("Game found: " .. gameName)
        
        MemoryReader.currentGame = detectedGame
        MemoryReader.gameAddresses = detectedGame.Addresses or {}
        MemoryReader.isInitialized = true
        
        -- Initialize party reader based on game generation
        if detectedGame.GameInfo.VersionColor == "Ruby" or 
           detectedGame.GameInfo.VersionColor == "Sapphire" or
           detectedGame.GameInfo.VersionColor == "Emerald" or
           detectedGame.GameInfo.VersionColor == "FireRed" or
           detectedGame.GameInfo.VersionColor == "LeafGreen" then
            MemoryReader.partyReader = Gen3PartyReader:new()
        elseif detectedGame.GameInfo.VersionColor == "Gold" or
               detectedGame.GameInfo.VersionColor == "Silver" or
               detectedGame.GameInfo.VersionColor == "Crystal" then
            MemoryReader.partyReader = Gen2PartyReader:new()
        elseif detectedGame.GameInfo.VersionColor == "Red" or
               detectedGame.GameInfo.VersionColor == "Blue" or
               detectedGame.GameInfo.VersionColor == "Green" or
               detectedGame.GameInfo.VersionColor == "Yellow" then
            MemoryReader.partyReader = Gen1PartyReader:new()
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
    
    -- Add your memory reading logic here
    -- For now, just maintain the detection
end


-- Show party information function
function showParty()
    if not MemoryReader.isInitialized then
        console.log("Memory Reader not initialized! Please restart the script.")
        return
    end
    
    if not MemoryReader.partyReader then
        console.log("Party reader not available for this game!")
        return
    end
    
    console.log("=== PARTY INFORMATION ===")
    
    -- Read party based on game generation
    local gameCode = gameUtils.gameCodeToString(MemoryReader.currentGame.GameInfo.GameCode)
    local party
    
    if MemoryReader.currentGame.GameInfo.Generation == 1 or MemoryReader.currentGame.GameInfo.Generation == 2 then
        -- Gen1 and Gen2 use similar address structure
        party = MemoryReader.partyReader:readParty(MemoryReader.gameAddresses, gameCode)
    else
        -- Gen3 uses pstats address
        if not MemoryReader.gameAddresses.pstats then
            console.log("Player party address not available!")
            return
        end
        local playerStatsAddr = gameUtils.hexToNumber(MemoryReader.gameAddresses.pstats)
        party = MemoryReader.partyReader:readParty({playerStats = playerStatsAddr}, gameCode)
    end
    
    for i = 1, 6 do
        local pokemon = party[i]
        if pokemon and pokemon.pokemonID > 0 then
            console.log("Slot " .. i .. ":")
            console.log("  Nickname: " .. (pokemon.nickname ~= "" and pokemon.nickname or pokemon.speciesName))
            console.log("  Species: " .. pokemon.speciesName .. " (" .. pokemon.pokemonID .. ")")
            console.log("  Type: " .. pokemon.type1Name .. (pokemon.type1Name ~= pokemon.type2Name and "/" .. pokemon.type2Name or ""))
            console.log("  Level: " .. pokemon.level)
            console.log("  Nature: " .. pokemon.natureName .. " (" .. pokemon.nature .. ")")
            console.log("  HP: " .. pokemon.curHP .. "/" .. pokemon.maxHP)
            
            -- EVs
            console.log("  EVs: HP:" .. pokemon.evHP .. " ATK:" .. pokemon.evAttack .. " DEF:" .. pokemon.evDefense .. 
                       " SPA:" .. pokemon.evSpAttack .. " SPD:" .. pokemon.evSpDefense .. " SPE:" .. pokemon.evSpeed)
            
            -- IVs
            console.log("  IVs: HP:" .. pokemon.ivHP .. " ATK:" .. pokemon.ivAttack .. " DEF:" .. pokemon.ivDefense .. 
                       " SPA:" .. pokemon.ivSpAttack .. " SPD:" .. pokemon.ivSpDefense .. " SPE:" .. pokemon.ivSpeed)
            
            -- Moves array
            local moves = {}
            if pokemon.move1 > 0 then table.insert(moves, pokemon.move1) end
            if pokemon.move2 > 0 then table.insert(moves, pokemon.move2) end
            if pokemon.move3 > 0 then table.insert(moves, pokemon.move3) end
            if pokemon.move4 > 0 then table.insert(moves, pokemon.move4) end
            console.log("  Moves: [" .. table.concat(moves, ", ") .. "]")
            
            -- Status
            if pokemon.status > 0 then
                local statusNames = {"Sleep", "Poison", "Burn", "Freeze", "Paralysis", "Bad Poison"}
                console.log("  Status: " .. statusNames[pokemon.status])
            else
                console.log("  Status: Normal")
            end
            
            -- Held Item
            console.log("  Held Item: " .. pokemon.heldItem .. " (ID: " .. (pokemon.heldItemId or 0) .. ")")
            
            -- Friendship
            console.log("  Friendship: " .. pokemon.friendship)
            
            -- Ability
            console.log("  Ability: " .. pokemon.abilityName .. " (slot " .. (pokemon.ability + 1) .. ")")
            
            -- Hidden Power
            console.log("  Hidden Power: " .. pokemon.hiddenPowerName .. " (" .. pokemon.hiddenPower .. ")")
            
            console.log("")
        else
            console.log("Slot " .. i .. ": Empty")
        end
    end
    
    console.log("=== END PARTY INFO ===")
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

-- User command functions for server control
function startServer()
    MemoryReader.serverEnabled = true
    MemoryReader.startServer()
end

function stopServer()
    MemoryReader.serverEnabled = false
    MemoryReader.stopServer()
end

function toggleServer()
    MemoryReader.serverEnabled = not MemoryReader.serverEnabled
    MemoryReader.toggleServer()
end

-- Debug functions (cleaner interface)
function debugAbility(slot)
    debugTools.debugAbility(MemoryReader, slot)
end

function debugAbilityNames(startId, endId)
    debugTools.debugAbilityNames(MemoryReader, startId, endId)
end

function debugParty()
    debugTools.debugParty(MemoryReader)
end

-- Help function to show available commands
function help()
    console.log("=== Pokemon Memory Reader Commands ===")
    console.log("showParty() - Display current party information")
    console.log("")
    console.log("Server Commands:")
    console.log("  startServer() - Start HTTP API server")
    console.log("  stopServer() - Stop HTTP API server") 
    console.log("  toggleServer() - Toggle server on/off")
    console.log("")
    console.log("Debug Commands:")
    console.log("  debugParty() - Debug party data")
    console.log("  debugAbility(slot) - Debug ability for Pokemon slot")
    console.log("  debugAbilityNames(start, end) - Debug ability names")
    console.log("")
    console.log("API Endpoints (when server running):")
    console.log("  GET http://localhost:8080/party - Party data in JSON")
    console.log("  GET http://localhost:8080/status - Server status")
    console.log("  GET http://localhost:8080/ - API documentation")
    console.log("=====================================")
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
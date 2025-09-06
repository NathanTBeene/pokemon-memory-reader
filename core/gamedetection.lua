-- Game Detection Module for Pokemon Memory Reader
-- This module handles detecting which Pokemon game is currently loaded in BizHawk

local gameDetection = {}
local GamesDB = require("data.gamesdb")
local gameUtils = require("utils.gameutils")

-- Main detection function
function gameDetection.detectGame()
    console.log("Detecting game...")

    -- Get system ID
    local systemID = gameUtils.getSystem()
    if not systemID or systemID == "NULL" then
        console.log("No system detected")
        return nil
    end

    -- Get ROM hash from BizHawk
    local romHash = gameUtils.getROMHash()
    if not romHash then
        console.log("Could not get ROM hash from BizHawk")
        return nil
    end
    
    -- Look up game in database by hash
    local gameData = gameUtils.getGameData()

    if gameData then
        return gameData
    end

    console.log("Unknown " .. systemID .. " game detected with hash: " .. romHash)
    console.log("Attempting to identify the game through game code...")

    local gameCode = gameDetection.findGameCode()
    if gameCode then
        console.log("Game code found: " .. gameCode)
        gameData = gameUtils.getGameDataByCode(gameCode) or gameData
        if gameData then
            console.log("Game code matches: " .. gameData.gameInfo.gameName)
            console.log("If this is incorrect, then you might be playing a modified version of the game. Please open a ticket on the github to have your game supported.")
            return gameData
        end

        console.log("Game code not found. You might be playing a modified version of the game. Please open a ticket on the github to have your game supported.")
    end

    return nil
end

-- Function to read game code from a default memory address.
-- Typically doesn't need to be used.
function gameDetection.findGameCode()
    local code = memory.read_u16_le(0x00013C)
    if not code then
        return nil
    end
    return gameUtils.gameCodeToString(code)
end

-- Get supported games list
function gameDetection.getSupportedGames()
    return GamesDB.getSupportedGamesList()
end

-- Validate if current game is supported
function gameDetection.isGameSupported()
    local romHash = gameUtils.getROMHash()
    if not romHash then
        return false
    end
    
    return GamesDB.isGameSupported(romHash)
end

return gameDetection
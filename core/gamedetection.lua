-- Game Detection Module for Pokemon Memory Reader
-- This module handles detecting which Pokemon game is currently loaded in BizHawk

local gameDetection = {}
local GamesDB = require("data.gamesdb")
local gameUtils = require("utils.gameutils")

---@return GameEntry|nil
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
-- GB games store the game code at 0x13C
-- GBA games store the game code at 0x0AC
-- NDS games store the game code at 0x00C
-- Typically doesn't need to be used.
---@return string|nil
function gameDetection.findGameCode()
    local system = gameUtils.getSystem()
    local code = nil
    if system == "NULL" then
        return nil
    end

    if system == "GB" or system == "GBC" then
        code = gameUtils.read16(0x013C, "ROM")
    elseif system == "GBA" then
        code = gameUtils.read16(0x0AC, "ROM")
    elseif system == "NDS" then
        code = gameUtils.read32(0x00C, "ROM")
    else
        return nil
    end

    return gameUtils.gameCodeToString(code)
end

---@return string[]
function gameDetection.getSupportedGames()
    return GamesDB.getSupportedGamesList()
end

return gameDetection
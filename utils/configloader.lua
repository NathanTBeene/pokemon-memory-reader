-- Configuration Loader
-- Loads game configurations from Lua module

local configLoader = {}
local gameConfig = require("core.gameconfig")

-- Load game configurations
function configLoader.loadGameConfigs()
    return gameConfig
end

-- Get configuration for a specific game code
function configLoader.getGameConfig(gameCode)
    local configs = configLoader.loadGameConfigs()
    if not configs or not configs.games then
        return nil
    end
    
    return configs.games[gameCode]
end

-- Get data structure configuration
function configLoader.getDataStructure(generation)
    local configs = configLoader.loadGameConfigs()
    if not configs or not configs.dataStructures then
        return nil
    end
    
    return configs.dataStructures["generation" .. generation]
end

-- Get all supported game codes
function configLoader.getSupportedGames()
    local configs = configLoader.loadGameConfigs()
    if not configs or not configs.games then
        return {}
    end
    
    local games = {}
    for gameCode, config in pairs(configs.games) do
        table.insert(games, {
            code = gameCode,
            name = config.name,
            generation = config.generation
        })
    end
    
    return games
end

return configLoader
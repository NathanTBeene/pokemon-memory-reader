
local playerFormatter = require("formatting.playerformatter")
local pokeFormatter = require("formatting.pokemonformatter")

local Formatter = {}

-- Pokemon Formatting
Formatter.formatPartyData = pokeFormatter.formatPartyData
Formatter.formatPartyJSON = pokeFormatter.formatPartyJSON

-- Player Formatting
Formatter.formatPlayerData = playerFormatter.formatPlayerData
Formatter.formatPlayerJSON = playerFormatter.formatPlayerJSON
Formatter.formatBagJSON = playerFormatter.formatBagJSON

return Formatter
-- Debug Tools Module
-- Provides debugging utilities for Pokemon data inspection

local debugTools = {}
local gameUtils = require("utils.gameutils")
local pokemonData = require("readers.pokemondata")

-- Debug ability lookup for a specific Pokemon slot
function debugTools.debugAbility(memoryReader, slot)
    if not memoryReader.isInitialized then
        console.log("Memory Reader not initialized!")
        return
    end
    
    if not memoryReader.partyReader then
        console.log("Party reader not available!")
        return
    end
    
    local playerStatsAddr = gameUtils.hexToNumber(memoryReader.gameAddresses.pstats)
    local gameCode = gameUtils.gameCodeToString(memoryReader.currentGame.GameInfo.GameCode)
    
    local party = memoryReader.partyReader:readParty({playerStats = playerStatsAddr}, gameCode)
    local pokemon = party[slot]
    
    if pokemon and pokemon.pokemonID > 0 then
        console.log("=== ABILITY DEBUG ===")
        console.log("Slot: " .. slot)
        console.log("Species: " .. pokemon.speciesName .. " (" .. pokemon.pokemonID .. ")")
        console.log("Ability Slot: " .. pokemon.ability)
        console.log("Ability ID: " .. pokemon.abilityID)
        console.log("Ability Name: " .. pokemon.abilityName)
        console.log("=== END DEBUG ===")
    else
        console.log("No Pokemon in slot " .. slot)
    end
end

-- Debug ability names table - print a range of ability names  
function debugTools.debugAbilityNames(memoryReader, startId, endId)
    console.log("=== ABILITY NAMES DEBUG ===")
    console.log("Reading ability IDs " .. startId .. " to " .. endId .. ":")
    console.log("")
    
    for i = startId, endId do
        local abilityName = pokemonData.getAbilityName(i)
        console.log("ID " .. i .. ": " .. abilityName)
    end
    
    console.log("=== END ABILITY NAMES DEBUG ===")
end

-- Debug Pokemon party information in detail
function debugTools.debugParty(memoryReader)
    if not memoryReader.isInitialized then
        console.log("Memory Reader not initialized!")
        return
    end
    
    if not memoryReader.partyReader then
        console.log("Party reader not available!")
        return
    end
    
    local playerStatsAddr = gameUtils.hexToNumber(memoryReader.gameAddresses.pstats)
    local gameCode = gameUtils.gameCodeToString(memoryReader.currentGame.GameInfo.GameCode)
    local party = memoryReader.partyReader:readParty({playerStats = playerStatsAddr}, gameCode)
    
    console.log("=== DETAILED PARTY DEBUG ===")
    console.log("Game Code: " .. gameCode)
    console.log("Player Stats Address: 0x" .. string.format("%08X", playerStatsAddr))
    console.log("")
    
    for i = 1, 6 do
        local pokemon = party[i]
        if pokemon and pokemon.pokemonID > 0 then
            console.log("Slot " .. i .. " - Raw Data:")
            console.log("  Pokemon ID: " .. pokemon.pokemonID)
            console.log("  Personality: " .. pokemon.personality)
            console.log("  OT ID: " .. pokemon.otid)
            console.log("  Level: " .. pokemon.level)
            console.log("  Ability Slot: " .. pokemon.ability)
            console.log("  Ability ID: " .. pokemon.abilityID)
            console.log("  Type IDs: " .. pokemon.type1 .. "/" .. pokemon.type2)
            console.log("  Nature ID: " .. pokemon.nature)
            console.log("  IVs (raw): " .. pokemon.ivs)
            console.log("  Hidden Power ID: " .. pokemon.hiddenPower)
            console.log("")
        end
    end
    
    console.log("=== END DETAILED DEBUG ===")
end

return debugTools
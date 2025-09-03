-- Debug Tools Module
-- Provides debugging utilities for Pokemon data inspection

local debugTools = {}
local gameUtils = require("utils.gameutils")
local pokemonData = require("readers.pokemondata")
local charmaps = require("data.charmaps")

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
    
    local playerStatsAddr = gameUtils.hexToNumber(memoryReader.currentGame.addresses.partyAddr)
    local gameCode = gameUtils.gameCodeToString(memoryReader.currentGame.gameInfo.gameCode)
    
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
    
    local playerStatsAddr = gameUtils.hexToNumber(memoryReader.currentGame.addresses.partyAddr)
    local gameCode = gameUtils.gameCodeToString(memoryReader.currentGame.gameInfo.gameCode)
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

-- Debug ROM species data for a specific Pokemon slot
function debugTools.debugSpeciesData(memoryReader, slot)
    if not memoryReader.isInitialized then
        console.log("Memory Reader not initialized!")
        return
    end
    
    if not memoryReader.partyReader then
        console.log("Party reader not available!")
        return
    end
    
    local playerStatsAddr = gameUtils.hexToNumber(memoryReader.currentGame.addresses.partyAddr)
    local gameCode = gameUtils.gameCodeToString(memoryReader.currentGame.gameInfo.gameCode)
    local party = memoryReader.partyReader:readParty({playerStats = playerStatsAddr}, gameCode)
    local pokemon = party[slot]
    
    if pokemon and pokemon.pokemonID > 0 then
        console.log("=== SPECIES ROM DATA DEBUG ===")
        console.log("Slot: " .. slot)
        console.log("Species ID: " .. pokemon.pokemonID)
        console.log("Species Name: " .. pokemon.speciesName)
        console.log("")
        
        -- Try to get ROM species data directly
        local speciesData = pokemonData.readSpeciesData(pokemon.pokemonID, gameCode)
        if speciesData then
            console.log("ROM Species Data:")
            console.log("  Type 1 (raw): " .. speciesData.type1)
            console.log("  Type 2 (raw): " .. speciesData.type2)
            console.log("  Ability 1 (raw): " .. speciesData.ability1)
            console.log("  Ability 2 (raw): " .. speciesData.ability2)
            console.log("  Base HP: " .. speciesData.baseHP)
            console.log("  Base Attack: " .. speciesData.baseAttack)
            console.log("  Base Defense: " .. speciesData.baseDefense)
            console.log("  Base Speed: " .. speciesData.baseSpeed)
            console.log("  Base Sp. Attack: " .. speciesData.baseSpAttack)
            console.log("  Base Sp. Defense: " .. speciesData.baseSpDefense)
        else
            console.log("Failed to read ROM species data!")
        end
        
        console.log("")
        console.log("Pokemon Data (processed):")
        console.log("  Type 1 Name: " .. pokemon.type1Name)
        console.log("  Type 2 Name: " .. pokemon.type2Name)
        console.log("  Ability Name: " .. pokemon.abilityName)
        console.log("  Ability Slot: " .. pokemon.ability)
        console.log("=== END SPECIES ROM DEBUG ===")
    else
        console.log("No Pokemon in slot " .. slot)
    end
end

-- Debug ability names from ROM pointer table
function debugTools.debugAbilityNamesFromROM(startId, endId, address)
    local abilityTableAddr = address or 0x824FC4D
    console.log("=== ROM ABILITY NAMES DEBUG ===")
    console.log("Reading ability names from ROM pointer table at 0x" .. string.format("%08X", abilityTableAddr))
    console.log("Range: " .. startId .. " to " .. endId)
    console.log("")
    
    for i = startId, endId do
        -- Read the 4-byte pointer for this ability ID (little endian)
        local pointerAddr = abilityTableAddr + (i * 4)
        local byte1 = gameUtils.readROMByte(pointerAddr)
        local byte2 = gameUtils.readROMByte(pointerAddr + 1)
        local byte3 = gameUtils.readROMByte(pointerAddr + 2)
        local byte4 = gameUtils.readROMByte(pointerAddr + 3)
        
        -- Construct the pointer (little endian)
        local pointer = byte1 + (byte2 << 8) + (byte3 << 16) + (byte4 << 24)
        
        -- Convert ROM pointer to address (GBA ROM pointers have 0x08 prefix, mask to ROM address)
        local nameAddr = pointer & 0x01FFFFFF
        
        console.log("Ability ID " .. i .. " - Raw bytes: " .. string.format("%02X %02X %02X %02X", byte1, byte2, byte3, byte4))
        console.log("  -> Pointer: 0x" .. string.format("%08X", pointer) .. " -> ROM Address: 0x" .. string.format("%08X", nameAddr))
        
        -- Read ability name from the pointed address
        local name = ""
        for j = 0, 20 do -- Read up to 20 characters
            local byte = gameUtils.readROMByte(nameAddr + j)
            if byte == 0xFF or byte == 0 then
                break
            end
            local char = charmaps.GBACharmap[byte] or ""
            name = name .. char
        end
        
        if name == "" then
            name = "Unknown"
        end
        
        console.log("  -> Name: " .. name)
        console.log("")
    end
    
    console.log("=== END ROM ABILITY NAMES DEBUG ===")
end

-- Search for ability names table by looking for known ability names
function debugTools.searchAbilityTable()
    console.log("=== SEARCHING FOR ABILITY TABLE ===")
    console.log("Searching ROM for ability names...")
    console.log("")
    
    -- Search for simple ability names first
    local searchTargets = {"Static", "Limber", "Sturdy", "Overgrow"}
    
    -- Search broader ROM ranges
    local searchRanges = {
        {start = 0x8200000, endAddr = 0x8280000, name = "ROM Range 1"},
        {start = 0x8280000, endAddr = 0x8320000, name = "ROM Range 2"},
        {start = 0x8320000, endAddr = 0x8400000, name = "ROM Range 3"}
    }
    
    for _, range in ipairs(searchRanges) do
        console.log("Searching " .. range.name .. "...")
        
        for addr = range.start, range.endAddr - 20, 1 do
            -- Read up to 15 characters to form a potential name
            local testName = ""
            local validChars = 0
            
            for j = 0, 14 do
                local byte = gameUtils.readROMByte(addr + j)
                if byte == 0xFF or byte == 0 then
                    break
                elseif byte >= 32 and byte <= 126 then -- ASCII printable range
                    testName = testName .. string.char(byte)
                    validChars = validChars + 1
                elseif charmaps.GBACharmap[byte] then
                    testName = testName .. charmaps.GBACharmap[byte]
                    validChars = validChars + 1
                else
                    break
                end
            end
            
            -- Check if this matches any known ability (must have at least 4 valid chars)
            if validChars >= 4 then
                for _, target in ipairs(searchTargets) do
                    if testName:find(target) then
                        console.log("Found '" .. target .. "' in '" .. testName .. "' at address 0x" .. string.format("%08X", addr))
                    end
                end
            end
        end
    end
    
    console.log("=== END SEARCH ===")
end

-- Simple function to dump raw ROM data at an address
function debugTools.dumpROMData(address, length)
    console.log("=== ROM DUMP ===")
    console.log("Address: 0x" .. string.format("%08X", address))
    console.log("Length: " .. length .. " bytes")
    console.log("")
    
    for i = 0, length - 1 do
        local byte = gameUtils.readROMByte(address + i)
        local char = ""
        
        if byte >= 32 and byte <= 126 then
            char = string.char(byte)
        elseif charmaps.GBACharmap[byte] then
            char = charmaps.GBACharmap[byte]
        else
            char = "."
        end
        
        if i % 16 == 0 then
            console.log(string.format("%08X: ", address + i))
        end
        
        console.log(string.format("%02X(%s) ", byte, char))
        
        if i % 16 == 15 then
            console.log("")
        end
    end
    
    console.log("")
    console.log("=== END ROM DUMP ===")
end

return debugTools
-- Debug Tools Module
-- Provides debugging utilities for Pokemon data inspection

local debugTools = {}
local gameUtils = require("utils.gameutils")
local charmaps = require("data.charmaps")

-- Debug Pokemon party information in detail
function debugTools.debugParty()
    if not MemoryReader.isInitialized then
        console.log("Memory Reader not initialized!")
        return
    end

    if not MemoryReader.partyReader then
        console.log("Party reader not available!")
        return
    end

    local playerStatsAddr = gameUtils.hexToNumber(MemoryReader.currentGame.addresses.partyAddr)
    local gameCode = gameUtils.gameCodeToString(MemoryReader.currentGame.gameInfo.gameCode)
    local partyAddr = MemoryReader.partyReader:readParty({playerStats = playerStatsAddr}, gameCode)

    console.log("=== DETAILED PARTY DEBUG ===")
    console.log("Game Code: " .. gameCode)
    console.log("Player Stats Address: 0x" .. string.format("%08X", playerStatsAddr))
    console.log("")
    
    for i = 1, 6 do
        local pokemon = partyAddr[i]
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

-- Simple function to dump raw ROM data at an address
function debugTools.dumpROMData(address, length)
    console.log("=== ROM DUMP ===")
    console.log("Address: 0x" .. string.format("%08X", address))
    console.log("Length: " .. length .. " bytes")
    console.log("")
    
    for i = 0, length - 1 do
        local byte = gameUtils.read8(address + i, "ROM")
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

-- Encodes misc2 field from individual IVs and flags
function debugTools.encodeMisc2(hp, atk, def, spd, spatk, spdef, isEgg, ability)
    console.log("=== ENCODE MISC 2 ===")
    print("Input Values:")
    gameUtils.printTable({
        HP = hp,
        Attack = atk,
        Defense = def,
        Speed = spd,
        SpAttack = spatk,
        SpDefense = spdef,
        IsEgg = isEgg,
        Ability = ability
    })
    local misc2 = 0

    misc2 = misc2 | (hp & 0x1F) -- Bits 0-4
    misc2 = misc2 | ((atk & 0x1F) << 5) -- Bits 5-9
    misc2 = misc2 | ((def & 0x1F) << 10) -- Bits 10-14
    misc2 = misc2 | ((spd & 0x1F) << 15) -- Bits 15-19
    misc2 = misc2 | ((spatk & 0x1F) << 20) -- Bits 20-24
    misc2 = misc2 | ((spdef & 0x1F) << 25) -- Bits 25-29
    misc2 = misc2 | ((isEgg == 1 and 1 or 0) << 30) -- Bit 30
    misc2 = misc2 | ((ability & 0x01) << 31) -- Bit 31

    print("Encoded Misc 2 Value:")
    gameUtils.printHex(misc2)
    console.log("=== END ENCODE MISC 2 ===")
    return misc2
end

function debugTools.decodeMisc2(misc2)
    print("=== DECODE MISC 2 ===")
    print("Raw Misc 2 Bytes:")
    gameUtils.printHex(misc2)

    local ivHp = gameUtils.getBits(misc2, 0, 5)
    local ivAtk = gameUtils.getBits(misc2, 5, 5)
    local ivDef = gameUtils.getBits(misc2, 10, 5)
    local ivSpd = gameUtils.getBits(misc2, 15, 5)
    local ivSpAtk = gameUtils.getBits(misc2, 20, 5)
    local ivSpDef = gameUtils.getBits(misc2, 25, 5)
    local isEgg = gameUtils.getBits(misc2, 30, 1) == 1
    local ability = gameUtils.getBits(misc2, 31, 1)

    print("Decoded Misc 2 Values:")
    gameUtils.printTable({
        HP = ivHp,
        Attack = ivAtk,
        Defense = ivDef,
        Speed = ivSpd,
        SpAttack = ivSpAtk,
        SpDefense = ivSpDef,
        IsEgg = isEgg,
        Ability = ability
    })
end

return debugTools
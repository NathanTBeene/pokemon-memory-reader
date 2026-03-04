-- Debug Utilities Module
-- Console print helpers and Pokemon data inspection tools.
-- Merges debug/debugtools.lua with the print helpers from gameutils.lua.

local debugutils = {}

-- ============================================================
-- PRINT HELPERS
-- ============================================================

--- Print key-value pairs from a table.
---@param t table
---@param format string?  Optional format string with two %s placeholders (key, value)
function debugutils.printTable(t, format)
    for k, v in pairs(t) do
        console.log(string.format(format or "%s: %s", k, v))
    end
end

--- Print a single number in hex.
---@param value integer
function debugutils.printHex(value)
    console.log(string.format("%X", value))
end

--- Print an array of numbers in hex, comma-separated.
---@param t integer[]
function debugutils.printHexTable(t)
    local result = ""
    for i, v in ipairs(t) do
        result = result .. string.format("%X", v)
        if i < #t then result = result .. ", " end
    end
    console.log("Hex Table: " .. result)
end

--- Print a byte array as space-separated two-digit hex values.
---@param byteArray integer[]
function debugutils.printHexBytes(byteArray)
    local result = ""
    for i, v in ipairs(byteArray) do
        result = result .. string.format("%02X", v)
        if i < #byteArray then result = result .. " " end
    end
    console.log("Hex Bytes: " .. result)
end

-- ============================================================
-- POKEMON DATA INSPECTION
-- ============================================================

--- Dump detailed raw data for all party slots to the console.
function debugutils.debugParty()
    if not MemoryReader.isInitialized then
        console.log("Memory Reader not initialized!")
        return
    end
    if not MemoryReader.partyReader then
        console.log("Party reader not available!")
        return
    end

    local gameUtils = require("utils.gameutils")
    local playerStatsAddr = gameUtils.hexToNumber(MemoryReader.currentGame.addresses.partyAddr)
    local gameCode = gameUtils.gameCodeToString(MemoryReader.currentGame.gameInfo.gameCode)
    local party = MemoryReader.partyReader:readParty({playerStats = playerStatsAddr}, gameCode)

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

--- Dump raw ROM bytes at an address to the console.
---@param address integer
---@param length integer
function debugutils.dumpROMData(address, length)
    local memoryio = require("utils.memoryio")
    local charmaps = require("data.charmaps")

    console.log("=== ROM DUMP ===")
    console.log("Address: 0x" .. string.format("%08X", address))
    console.log("Length: " .. length .. " bytes")
    console.log("")

    for i = 0, length - 1 do
        local byte = memoryio.read8(address + i, "ROM")
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

--- Encode Gen 3 misc2 field from individual IVs and flags.
---@param hp integer
---@param atk integer
---@param def integer
---@param spd integer
---@param spatk integer
---@param spdef integer
---@param isEgg integer  0 or 1
---@param ability integer  0 or 1
---@return integer
function debugutils.encodeMisc2(hp, atk, def, spd, spatk, spdef, isEgg, ability)
    local gameUtils = require("utils.gameutils")
    console.log("=== ENCODE MISC 2 ===")
    print("Input Values:")
    debugutils.printTable({
        HP = hp, Attack = atk, Defense = def, Speed = spd,
        SpAttack = spatk, SpDefense = spdef, IsEgg = isEgg, Ability = ability
    })

    local misc2 = 0
    misc2 = misc2 | (hp & 0x1F)
    misc2 = misc2 | ((atk & 0x1F) << 5)
    misc2 = misc2 | ((def & 0x1F) << 10)
    misc2 = misc2 | ((spd & 0x1F) << 15)
    misc2 = misc2 | ((spatk & 0x1F) << 20)
    misc2 = misc2 | ((spdef & 0x1F) << 25)
    misc2 = misc2 | ((isEgg == 1 and 1 or 0) << 30)
    misc2 = misc2 | ((ability & 0x01) << 31)

    print("Encoded Misc 2 Value:")
    debugutils.printHex(misc2)
    console.log("=== END ENCODE MISC 2 ===")
    return misc2
end

--- Decode a Gen 3 misc2 value and print its fields.
---@param misc2 integer
function debugutils.decodeMisc2(misc2)
    local gameUtils = require("utils.gameutils")
    print("=== DECODE MISC 2 ===")
    print("Raw Misc 2 Bytes:")
    debugutils.printHex(misc2)

    debugutils.printTable({
        HP       = gameUtils.getBits(misc2, 0, 5),
        Attack   = gameUtils.getBits(misc2, 5, 5),
        Defense  = gameUtils.getBits(misc2, 10, 5),
        Speed    = gameUtils.getBits(misc2, 15, 5),
        SpAttack = gameUtils.getBits(misc2, 20, 5),
        SpDefense = gameUtils.getBits(misc2, 25, 5),
        IsEgg    = gameUtils.getBits(misc2, 30, 1) == 1,
        Ability  = gameUtils.getBits(misc2, 31, 1),
    })
end

return debugutils

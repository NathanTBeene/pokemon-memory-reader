-- Game Utility Functions
-- Common utilities for game code conversion, address handling, etc.
local gamesDB = require("data.gamesdb")
local constants = require("data.constants")
local charmaps = require("data.charmaps")

local gameUtils = {}

-- MARK: BizAPI

-- Returns the system id of the currently loaded core.
-- GB, GBC, GBA, NDS, etc.
function gameUtils.getSystem()
    return emu.getsystemid()
end

-- BizHawk provides ROM hash through gameinfo
function gameUtils.getROMHash()
    return gameinfo.getromhash()
end

-- Get game data from the games database using the current ROM hash
function gameUtils.getGameData()
    local romHash = gameUtils.getROMHash()
    return gamesDB.getGameByHash(romHash)
end

-- Get game data from the games database using a game code
function gameUtils.getGameDataByCode(gameCode)
    return gamesDB.getGameByCode(gameCode)
end

-- Convert numeric game code to string
function gameUtils.gameCodeToString(gameCodeNum)
    if not gameCodeNum then
        return nil
    end

    if type(gameCodeNum) == "string" then
        return gameCodeNum
    end

    return string.char(
        gameCodeNum % 256,
        (gameCodeNum >> 8) % 256,
        (gameCodeNum >> 16) % 256,
        (gameCodeNum >> 24) % 256
    )
end

-- Convert hex string to number
function gameUtils.hexToNumber(hexStr)
    if type(hexStr) == "string" then
        return tonumber(hexStr, 16)
    end
    return hexStr
end

-- MARK: Read

-- Base memory reading function.
-- Handles memory domain selection based on address.
-- Can also take an override.
-- All memory reads should go through this function.
function gameUtils.readMemory(addr, size, memOverride)
    local mem = ""
    local memdomain = (addr >> 24)
    if memdomain == 0 then
        mem = "BIOS"
    elseif memdomain == 2 then
        mem = "EWRAM"
    elseif memdomain == 3 then
        mem = "IWRAM"
    elseif memdomain == 8 then
        mem = "ROM"
    end
    addr = (addr & 0xFFFFFF)
    if size == 1 then
        return memory.read_u8(addr, memOverride or mem)
    elseif size == 2 then
        return memory.read_u16_le(addr, memOverride or mem)
    elseif size == 3 then
        return memory.read_u24_le(addr, memOverride or mem)
    else
        return memory.read_u32_le(addr, memOverride or mem)
    end
end

-- Extract bits from a value (commonly used for Pokemon data)
function gameUtils.getBits(value, start, length)
    return (value >> start) & ((1 << length) - 1)
end

-- Basic reading functions for common sizes
function gameUtils.read8(addr, memOverride)
    return gameUtils.readMemory(addr, 1, memOverride)
end

function gameUtils.read16(addr, memOverride)
    return gameUtils.readMemory(addr, 2, memOverride)
end

function gameUtils.read32(addr, memOverride)
    return gameUtils.readMemory(addr, 4, memOverride)
end

function gameUtils.readBytes(startAddr, size, memOverride)
    local bytes = {}
    for i = 0, size - 1 do
        table.insert(bytes, gameUtils.read8(startAddr + i, memOverride))
    end
    return bytes
end

function gameUtils.readByteRange(startAddr, endAddr, memOverride)
    local bytes = {}
    for i = startAddr, endAddr do
        table.insert(bytes, gameUtils.read8(i, memOverride))
    end
    return bytes
end

-- CFRU Reading requires a special ROM read due to 28-bit addressing
function gameUtils.readBytesCFRU(startAddr, size)
    local addr = startAddr & 0xFFFFFFF
    local bytes = {}
    for i = 0, size - 1 do
        table.insert(bytes, memory.read_u8((addr + i) & 0xFFFFFFF, "ROM"))
    end
    return bytes
end

-- MARK: Write
function gameUtils.writeMemory(startAddr, value, size, memOverride)
    local mem = ""
    local memdomain = (startAddr >> 24)
    if memdomain == 0 then
        mem = "BIOS"
    elseif memdomain == 2 then
        mem = "EWRAM"
    elseif memdomain == 3 then
        mem = "IWRAM"
    elseif memdomain == 8 then
        mem = "ROM"
    end
    startAddr = (startAddr & 0xFFFFFF)

    if size == 1 then
        memory.write_u8(startAddr, value, memOverride)
    elseif size == 2 then
        memory.write_u16_le(startAddr, value, memOverride)
    elseif size == 3 then
        memory.write_u24_le(startAddr, value, memOverride)
    else
        memory.write_u32_le(startAddr, value, memOverride)
    end
end

function gameUtils.write8(startAddr, value, memOverride)
    gameUtils.writeMemory(startAddr, value, 1, memOverride)
end

function gameUtils.write16(startAddr, value, memOverride)
    gameUtils.writeMemory(startAddr, value, 2, memOverride)
end

function gameUtils.write24(startAddr, value, memOverride)
    gameUtils.writeMemory(startAddr, value, 3, memOverride)
end

function gameUtils.write32(startAddr, value, memOverride)
    gameUtils.writeMemory(startAddr, value, 4, memOverride)
end

function gameUtils.writeBytes(startAddr, byteArray, memOverride)
    for i = 0, #byteArray - 1 do
        gameUtils.write8(startAddr + i, byteArray[i + 1], memOverride)
    end
end

-- MARK: Helpers

function gameUtils.hasValue(table, value)
    for _, v in ipairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

function gameUtils.clamp(value, min, max)
    if value < min then
        return min
    elseif value > max then
        return max
    else
        return value
    end
end

-- MARK: Print

function gameUtils.printTable(table, format)
    for k, v in pairs(table) do
        console.log(string.format(format or "%s: %s", k, v))
    end
end

function gameUtils.printHex(value)
    console.log(string.format("%X", value))
end

function gameUtils.printHexTable(table1)
    local result = ""
    for i, v in ipairs(table1) do
        result = result .. string.format("%X", v)
        if i < #table1 then
            result = result .. ", "
        end
    end
    console.log("Hex Table: " .. result)
end

-- MARK: Temp
-- Functions that are temporary and will be moved later

function gameUtils.getItemName(itemID)
    if not itemID or itemID == 0 then
        return "???"
    end

    local gameData = gamesDB.getGameByHash(gameUtils.getROMHash())
    if not gameData or not gameData.addresses.itemNameTable then
        return "???"
    end

    local itemNameTableAddr = gameUtils.hexToNumber(gameData.addresses.itemNameTable)

    local itemAddr = itemNameTableAddr + (itemID) * 44  -- Each item is 44 bytes

    local name = gameUtils.readBytes(itemAddr, 14, "ROM")
    return charmaps.decryptText(name) or "???"
end

return gameUtils
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
    if type(hexStr) == "number" then
        return hexStr & 0xFFFFFFFF
    end
    if type(hexStr) == "string" then
        -- remove 0x prefix and any non-hex characters (safety from bad DB entries)
        local s = hexStr:gsub("^0[xX]", ""):gsub("[^%x]", "")
        if s == "" then return nil end
        local n = tonumber(s, 16)
        if not n then return nil end
        -- ensure n is 32-bit positive integer
        return n & 0xFFFFFFFF
    end
    return nil
end

-- Return memory domain string and local (masked) address for a full 32-bit address
-- e.g. 0x02024284 -> returns "EWRAM", 0x024284
function gameUtils.addrToDomainAndOffset(addr)
    if type(addr) == "string" then
        addr = gameUtils.hexToNumber(addr)
    end
    if not addr then return nil, nil end
    -- ensure integer
    addr = addr & 0xFFFFFFFF
    local domainByte = (addr >> 24) & 0xFF
    local mem = nil
    if domainByte == 0 then
        mem = "BIOS"
    elseif domainByte == 2 then
        mem = "EWRAM"
    elseif domainByte == 3 then
        mem = "IWRAM"
    elseif domainByte == 8 then
        mem = "ROM"
    else
        -- Unknown domain: choose ROM as a safe default for offline tables, but log
        mem = "ROM"
        console.log(string.format("Warning: unknown memory domain 0x%02X for address 0x%X", domainByte, addr))
    end
    local offset = addr & 0xFFFFFF
    return mem, offset
end

-- MARK: Read

-- Base memory reading function.
-- Handles memory domain selection based on address.
-- Can also take an override.
-- All memory reads should go through this function.
function gameUtils.readMemory(addr, size, memOverride)
    -- If addr is string like "02024284" convert and determine domain/offset
    if type(addr) == "string" then
        local memFromAddr, offsetFromAddr = gameUtils.addrToDomainAndOffset(addr)
        if memOverride == nil then memOverride = memFromAddr end
        addr = offsetFromAddr
    end

    local memdomain = 0
    if memOverride then
        -- if caller provided an explicit memOverride, try to map common names to domain byte for logging only
        -- but memory.* functions expect the domain name string.
    else
        -- If numeric addr still has domain byte (shouldn't happen here), detect it
        if addr > 0xFFFFFF then
            memdomain = (addr >> 24) & 0xFF
        else
            memdomain = 0
        end
    end

    local mem = memOverride or ""
    if mem == "" then
        if memdomain == 0 then mem = "BIOS"
        elseif memdomain == 2 then mem = "EWRAM"
        elseif memdomain == 3 then mem = "IWRAM"
        elseif memdomain == 8 then mem = "ROM"
        else mem = "ROM" end
    end

    -- ensure local address is within 24 bits
    addr = addr & 0xFFFFFF

    -- Basic safety: prevent obviously out-of-range reads from being attempted
    -- (will still surface warnings if mem domain size mismatch)
    if addr > 0xFFFFFF then
        console.log(string.format("Warning: attempt to read with offset 0x%X which is > 24-bit", addr))
    end

    if size == 1 then
        return memory.read_u8(addr, mem)
    elseif size == 2 then
        return memory.read_u16_le(addr, mem)
    elseif size == 3 then
        return memory.read_u24_le(addr, mem)
    else
        return memory.read_u32_le(addr, mem)
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

-- Reads from a starting address until it finds a null terminator or reaches maxLength.
-- @return Tuple(byte array, length)
function gameUtils.readVariableLength(startAddr, maxLength, memOverride)
    local currentAddr = startAddr
    local bytes = {}
    for i = 0, maxLength - 1 do
        currentAddr = startAddr + i
        local byte = gameUtils.read8(currentAddr, memOverride)
        if byte == 0x50 then  -- End of string marker in Pokemon games
            break
        end
        table.insert(bytes, byte)
    end
    return {bytes, #bytes}
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

function gameUtils.bcdToDecimal(bcdBytes)
    local decimal = 0
    for i = 1, #bcdBytes do
        local byte = bcdBytes[i]
        local highNibble = (byte >> 4) & 0x0F
        local lowNibble = byte & 0x0F
        decimal = decimal * 100 + highNibble * 10 + lowNibble
    end
    return decimal
end

function gameUtils.bytesToNumber(byteArray)
    local number = 0
    for i = 1, #byteArray do
        number = (number << 8) | byteArray[i]
    end
    return number
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

return gameUtils
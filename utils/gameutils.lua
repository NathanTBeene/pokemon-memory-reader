-- Game Utility Functions
-- Common utilities for game code conversion, address handling, etc.

local gameUtils = {}

-- Returns the system id of the currently loaded core.
-- GB, GBC, GBA, NDS, etc.
function gameUtils.getSystem()
    return emu.getsystemid()
end

-- BizHawk provides ROM hash through gameinfo
function gameUtils.getROMHash()
    return gameinfo.getromhash()
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

-- Safe ROM memory read with address masking
function gameUtils.readROM8(address)
    return memory.read_u8(address & 0xFFFFFF, "ROM")
end

function gameUtils.readROM16(address)
    return memory.read_u16_le(address & 0xFFFFFF, "ROM")
end

function gameUtils.readROM32(address)
    return memory.read_u32_le(address & 0xFFFFFF, "ROM")
end

-- Extract bits from a value (commonly used for Pokemon data)
function gameUtils.getBits(value, start, length)
    return (value >> start) & ((1 << length) - 1)
end

-- Read text from ROM using character mapping
function gameUtils.readROMText(address, maxLength, charMap)
    local text = ""
    for i = 0, maxLength - 1 do
        local byte = gameUtils.readROMByte(address + i)
        if byte == 0xFF or byte == 0 then
            break
        end
        local char = charMap[byte] or ""
        text = text .. char
    end
    return text ~= "" and text or nil
end

-- Memory reading functions (consolidated from core.memoryreader)
function gameUtils.readMemory(addr, size)
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
        return memory.read_u8(addr, mem)
    elseif size == 2 then
        return memory.read_u16_le(addr, mem)
    elseif size == 3 then
        return memory.read_u24_le(addr, mem)
    else
        return memory.read_u32_le(addr, mem)
    end
end

function gameUtils.read32(addr)
    return gameUtils.readMemory(addr, 4)
end

function gameUtils.read16(addr)
    return gameUtils.readMemory(addr, 2)
end

function gameUtils.read8(addr)
    return gameUtils.readMemory(addr, 1)
end

function gameUtils.readBytes(startAddr, size)
    local bytes = {}
    for i = 0, size - 1 do
        table.insert(bytes, gameUtils.read8(startAddr + i))
    end
    return bytes
end

function gameUtils.readByteRange(startAddr, endAddr)
    local bytes = {}
    for i = startAddr, endAddr do
        table.insert(bytes, gameUtils.read8(i))
    end
    return bytes
end

function gameUtils.hasValue(table, value)
    for _, v in ipairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

return gameUtils
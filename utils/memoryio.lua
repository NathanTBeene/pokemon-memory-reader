-- Memory I/O Module
-- Low-level BizHawk memory read/write primitives and address utilities.
-- All memory access should go through this module.

local memoryio = {}

-- ============================================================
-- ADDRESS UTILITIES
-- ============================================================

--- Convert a hex string or raw integer address to a (domain, offset) pair.
--- Domain byte prefix: 0x00=BIOS, 0x02=EWRAM, 0x03=IWRAM, 0x08=ROM
--- e.g. 0x02024284 -> "EWRAM", 0x024284
---@param addr integer | string
---@return string? domain
---@return integer? offset
function memoryio.addrToDomainAndOffset(addr)
    if type(addr) == "string" then
        addr = memoryio.hexToNumber(addr)
    end
    if not addr then return nil, nil end
    addr = addr & 0xFFFFFFFF
    local domainByte = (addr >> 24) & 0xFF
    local domain
    if domainByte == 0 then
        domain = "BIOS"
    elseif domainByte == 2 then
        domain = "EWRAM"
    elseif domainByte == 3 then
        domain = "IWRAM"
    elseif domainByte == 8 then
        domain = "ROM"
    else
        domain = "ROM"
        console.log(string.format("Warning: unknown memory domain 0x%02X for address 0x%X", domainByte, addr))
    end
    local offset = addr & 0xFFFFFF
    return domain, offset
end

--- Convert a hex string (with or without "0x" prefix) to an integer.
---@param hexStr integer | string
---@return integer?
function memoryio.hexToNumber(hexStr)
    if type(hexStr) == "number" then
        return hexStr & 0xFFFFFFFF
    end
    if type(hexStr) == "string" then
        local s = hexStr:gsub("^0[xX]", ""):gsub("[^%x]", "")
        if s == "" then return nil end
        local n = tonumber(s, 16)
        if not n then return nil end
        return n & 0xFFFFFFFF
    end
    return nil
end

-- ============================================================
-- READ
-- ============================================================

--- Central memory read dispatcher. All reads should go through this.
---@param addr integer | string
---@param size integer  1, 2, 3, or 4 bytes
---@param memOverride string?  Optional domain override (e.g. "ROM", "EWRAM")
---@return integer
function memoryio.readMemory(addr, size, memOverride)
    if type(addr) == "string" then
        local memFromAddr, offsetFromAddr = memoryio.addrToDomainAndOffset(addr)
        if memOverride == nil then memOverride = memFromAddr end
        addr = offsetFromAddr
    end

    local memdomain = 0
    if not memOverride then
        if addr > 0xFFFFFF then
            memdomain = (addr >> 24) & 0xFF
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

    addr = addr & 0xFFFFFF

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

---@param addr integer | string
---@param memOverride string?
---@return integer
function memoryio.read8(addr, memOverride)
    return memoryio.readMemory(addr, 1, memOverride)
end

---@param addr integer | string
---@param memOverride string?
---@return integer
function memoryio.read16(addr, memOverride)
    return memoryio.readMemory(addr, 2, memOverride)
end

---@param addr integer | string
---@param memOverride string?
---@return integer
function memoryio.read32(addr, memOverride)
    return memoryio.readMemory(addr, 4, memOverride)
end

--- Read `size` bytes starting at `startAddr` into an array (1-indexed).
---@param startAddr integer | string
---@param size integer
---@param memOverride string?
---@return integer[]
function memoryio.readBytes(startAddr, size, memOverride)
    local bytes = {}
    for i = 0, size - 1 do
        table.insert(bytes, memoryio.read8(startAddr + i, memOverride))
    end
    return bytes
end

--- Read bytes from startAddr up to (and including) endAddr.
---@param startAddr integer
---@param endAddr integer
---@param memOverride string?
---@return integer[]
function memoryio.readByteRange(startAddr, endAddr, memOverride)
    local bytes = {}
    for i = startAddr, endAddr do
        table.insert(bytes, memoryio.read8(i, memOverride))
    end
    return bytes
end

--- Special ROM read for CFRU/extended ROMs that use 28-bit addressing.
---@param startAddr integer
---@param size integer
---@return integer[]
function memoryio.readBytesCFRU(startAddr, size)
    local addr = startAddr & 0xFFFFFFF
    local bytes = {}
    for i = 0, size - 1 do
        table.insert(bytes, memory.read_u8((addr + i) & 0xFFFFFFF, "ROM"))
    end
    return bytes
end

--- Read bytes until the 0x50 end-of-string marker or maxLength is reached.
---@param startAddr integer
---@param maxLength integer
---@param memOverride string?
---@return integer[] bytes, integer length
function memoryio.readVariableLength(startAddr, maxLength, memOverride)
    local bytes = {}
    for i = 0, maxLength - 1 do
        local byte = memoryio.read8(startAddr + i, memOverride)
        if byte == 0x50 then
            break
        end
        table.insert(bytes, byte)
    end
    return bytes, #bytes
end

-- ============================================================
-- READ FROM BYTE ARRAYS
-- ============================================================

---@param byteArray integer[]
---@param offset integer  0-based offset
---@return integer?
function memoryio.read8FromBytes(byteArray, offset)
    if offset < 0 or offset >= #byteArray then return nil end
    return byteArray[offset + 1]
end

---@param byteArray integer[]
---@param offset integer  0-based offset
---@return integer?
function memoryio.read16FromBytes(byteArray, offset)
    if offset < 0 or offset + 1 >= #byteArray then return nil end
    return byteArray[offset + 1] | (byteArray[offset + 2] << 8)
end

---@param byteArray integer[]
---@param offset integer  0-based offset
---@return integer?
function memoryio.read24FromBytes(byteArray, offset)
    if offset < 0 or offset + 2 >= #byteArray then return nil end
    return byteArray[offset + 1] | (byteArray[offset + 2] << 8) | (byteArray[offset + 3] << 16)
end

---@param byteArray integer[]
---@param offset integer  0-based offset
---@return integer?
function memoryio.read32FromBytes(byteArray, offset)
    if offset < 0 or offset + 3 >= #byteArray then return nil end
    return byteArray[offset + 1] | (byteArray[offset + 2] << 8) | (byteArray[offset + 3] << 16) | (byteArray[offset + 4] << 24)
end

--- Extract `bitLength` bits from a byte array starting at bit position `byteOffset*8 + bitStart`.
---@param byteArray integer[]
---@param byteOffset integer  0-based byte offset
---@param bitStart integer    bit index within that byte
---@param bitLength integer
---@return integer?
function memoryio.readBitsFromBytes(byteArray, byteOffset, bitStart, bitLength)
    local totalBits = #byteArray * 8
    local startBitIndex = byteOffset * 8 + bitStart
    if startBitIndex + bitLength > totalBits then return nil end

    local value = 0
    for i = 0, bitLength - 1 do
        local currentBitIndex = startBitIndex + i
        local currentByteIndex = math.floor(currentBitIndex / 8) + 1
        local currentBitInByte = currentBitIndex % 8
        local bitValue = (byteArray[currentByteIndex] >> currentBitInByte) & 1
        value = value | (bitValue << i)
    end
    return value
end

-- ============================================================
-- WRITE
-- ============================================================

---@param startAddr integer
---@param value integer
---@param size integer  1, 2, 3, or 4 bytes
---@param memOverride string?
function memoryio.writeMemory(startAddr, value, size, memOverride)
    local mem = memOverride or ""
    if mem == "" then
        local memdomain = (startAddr >> 24) & 0xFF
        if memdomain == 0 then mem = "BIOS"
        elseif memdomain == 2 then mem = "EWRAM"
        elseif memdomain == 3 then mem = "IWRAM"
        elseif memdomain == 8 then mem = "ROM"
        else mem = "ROM" end
    end
    startAddr = startAddr & 0xFFFFFF

    if size == 1 then
        memory.write_u8(startAddr, value, mem)
    elseif size == 2 then
        memory.write_u16_le(startAddr, value, mem)
    elseif size == 3 then
        memory.write_u24_le(startAddr, value, mem)
    else
        memory.write_u32_le(startAddr, value, mem)
    end
end

---@param startAddr integer
---@param value integer
---@param memOverride string?
function memoryio.write8(startAddr, value, memOverride)
    memoryio.writeMemory(startAddr, value, 1, memOverride)
end

---@param startAddr integer
---@param value integer
---@param memOverride string?
function memoryio.write16(startAddr, value, memOverride)
    memoryio.writeMemory(startAddr, value, 2, memOverride)
end

---@param startAddr integer
---@param value integer
---@param memOverride string?
function memoryio.write24(startAddr, value, memOverride)
    memoryio.writeMemory(startAddr, value, 3, memOverride)
end

---@param startAddr integer
---@param value integer
---@param memOverride string?
function memoryio.write32(startAddr, value, memOverride)
    memoryio.writeMemory(startAddr, value, 4, memOverride)
end

---@param startAddr integer
---@param byteArray integer[]
---@param memOverride string?
function memoryio.writeBytes(startAddr, byteArray, memOverride)
    for i = 0, #byteArray - 1 do
        memoryio.write8(startAddr + i, byteArray[i + 1], memOverride)
    end
end

return memoryio

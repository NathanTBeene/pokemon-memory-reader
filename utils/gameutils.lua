-- Game Utility Functions
-- Higher-level game helpers: BizHawk API wrappers, database lookups, and data transformations.
-- Memory I/O lives in utils.memoryio; debug printing lives in utils.debugutils.
-- Re-exports from both modules are provided here for backward compatibility.

local gamesDB = require("data.gamesdb")
local memoryio = require("utils.memoryio")
local debugutils = require("utils.debugutils")

local gameUtils = {}

-- ============================================================
-- BIZHAWK API
-- ============================================================

--- Returns the system ID of the currently loaded core (GB, GBC, GBA, NDS, etc.).
---@return string
function gameUtils.getSystem()
    return emu.getsystemid()
end

--- Returns the ROM hash provided by BizHawk.
---@return string
function gameUtils.getROMHash()
    return gameinfo.getromhash()
end

-- ============================================================
-- DATABASE LOOKUPS
-- ============================================================

--- Get the GameEntry for the currently loaded ROM.
---@return GameEntry?
function gameUtils.getGameData()
    local romHash = gameUtils.getROMHash()
    return gamesDB.getGameByHash(romHash)
end

--- Get a GameEntry by game code.
---@param gameCode integer | string
---@return GameEntry?
function gameUtils.getGameDataByCode(gameCode)
    return gamesDB.getGameByCode(gameCode)
end

-- ============================================================
-- CONVERSION HELPERS
-- ============================================================

--- Convert a numeric 4-byte game code to its string representation.
---@param gameCodeNum integer | string | nil
---@return string?
function gameUtils.gameCodeToString(gameCodeNum)
    if not gameCodeNum then return nil end
    if type(gameCodeNum) == "string" then return gameCodeNum end
    return string.char(
        gameCodeNum % 256,
        (gameCodeNum >> 8) % 256,
        (gameCodeNum >> 16) % 256,
        (gameCodeNum >> 24) % 256
    )
end

-- ============================================================
-- DATA HELPERS
-- ============================================================

--- Extract `length` bits from `value` starting at bit position `start`.
---@param value integer
---@param start integer
---@param length integer
---@return integer
function gameUtils.getBits(value, start, length)
    return (value >> start) & ((1 << length) - 1)
end

--- Decode a BCD-encoded byte array to a decimal integer (used for Gen 1/2 money).
---@param bcdBytes integer[]
---@return integer
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

--- Convert a big-endian byte array to an integer.
---@param byteArray integer[]
---@return integer
function gameUtils.bytesToNumber(byteArray)
    local number = 0
    for i = 1, #byteArray do
        number = (number << 8) | byteArray[i]
    end
    return number
end

--- Return true if `table` contains `value`.
---@param t table
---@param value any
---@return boolean
function gameUtils.hasValue(t, value)
    for _, v in ipairs(t) do
        if v == value then return true end
    end
    return false
end

--- Clamp `value` to the range [min, max].
---@param value number
---@param min number
---@param max number
---@return number
function gameUtils.clamp(value, min, max)
    if value < min then return min
    elseif value > max then return max
    else return value end
end

-- ============================================================
-- BACKWARD-COMPATIBILITY RE-EXPORTS
-- (existing code that requires utils.gameutils keeps working)
-- ============================================================

gameUtils.addrToDomainAndOffset  = memoryio.addrToDomainAndOffset
gameUtils.hexToNumber            = memoryio.hexToNumber

gameUtils.readMemory             = memoryio.readMemory
gameUtils.read8                  = memoryio.read8
gameUtils.read16                 = memoryio.read16
gameUtils.read32                 = memoryio.read32
gameUtils.readBytes              = memoryio.readBytes
gameUtils.readByteRange          = memoryio.readByteRange
gameUtils.readBytesCFRU          = memoryio.readBytesCFRU
gameUtils.readVariableLength     = memoryio.readVariableLength
gameUtils.read8FromBytes         = memoryio.read8FromBytes
gameUtils.read16FromBytes        = memoryio.read16FromBytes
gameUtils.read24FromBytes        = memoryio.read24FromBytes
gameUtils.read32FromBytes        = memoryio.read32FromBytes
gameUtils.readBitsFromBytes      = memoryio.readBitsFromBytes

gameUtils.writeMemory            = memoryio.writeMemory
gameUtils.write8                 = memoryio.write8
gameUtils.write16                = memoryio.write16
gameUtils.write24                = memoryio.write24
gameUtils.write32                = memoryio.write32
gameUtils.writeBytes             = memoryio.writeBytes

gameUtils.printTable             = debugutils.printTable
gameUtils.printHex               = debugutils.printHex
gameUtils.printHexTable          = debugutils.printHexTable
gameUtils.printHexBytes          = debugutils.printHexBytes

return gameUtils

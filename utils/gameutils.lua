-- Game Utility Functions
-- Common utilities for game code conversion, address handling, etc.

local gameUtils = {}

-- Convert numeric game code to string
function gameUtils.gameCodeToString(gameCodeNum)
    if not gameCodeNum then
        return nil
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
function gameUtils.readROMByte(address)
    return memory.read_u8(address & 0xFFFFFF, "ROM")
end

function gameUtils.readROMWord(address)
    return memory.read_u16_le(address & 0xFFFFFF, "ROM")
end

function gameUtils.readROMDword(address)
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

return gameUtils
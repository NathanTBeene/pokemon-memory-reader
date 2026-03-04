-- Character mapping tables for different Pokemon game generations
-- These tables convert byte values to readable characters

---@alias Charmap tablelib<integer, string>
---@enum CharmapName
local CharmapName = {
    GB = "GB",
    GBA = "GBA",
    NDS = "NDS"
}

---@type Charmap
local GBCharmap = { [0]=
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", " ",
	"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P",
	"Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "(", ")", ":", ";", "[", "]",
	"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p",
	"q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "é", "'d", "'l", "'s", "'t", "'v",
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	"'", "Pk", "Mn", "-", "'r", "'m", "?", "!", ".", "ァ", "ゥ", "ェ", "▹", "▸", "▾", "♂",
	"$", "×", ".", "/", ",", "♀", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
}

---@type Charmap
local GBACharmap = { [0]=
	" ", "À", "Á", "Â", "Ç", "È", "É", "Ê", "Ë", "Ì", "こ", "Î", "Ï", "Ò", "Ó", "Ô",
	"Œ", "Ù", "Ú", "Û", "Ñ", "ß", "à", "á", "ね", "ç", "è", "é", "ê", "ë", "ì", "ま",
	"î", "ï", "ò", "ó", "ô", "œ", "ù", "ú", "û", "ñ", "º", "ª", "", "&", "+", "あ",
	"ぃ", "ぅ", "ぇ", "ぉ", "v", "=", "ょ", "が", "ぎ", "ぐ", "げ", "ご", "ざ", "じ", "ず", "ぜ",
	"ぞ", "だ", "ぢ", "づ", "で", "ど", "ば", "び", "ぶ", "べ", "ぼ", "ぱ", "ぴ", "ぷ", "ぺ", "ぽ",
	"っ", "¿", "¡", "Pk", "Mn", "Po", "Ké", "", "", "", "Í", "%", "(", ")", "セ", "ソ",
	"タ", "チ", "ツ", "テ", "ト", "ナ", "ニ", "ヌ", "â", "ノ", "ハ", "ヒ", "フ", "ヘ", "ホ", "í",
	"ミ", "ム", "メ", "モ", "ヤ", "ユ", "ヨ", "ラ", "リ", "↑", "↓", "←", "→", "ヲ", "ン", "ァ",
	"ィ", "ゥ", "ェ", "ォ", "ャ", "ュ", "ョ", "ガ", "ギ", "グ", "ゲ", "ゴ", "ザ", "ジ", "ズ", "ゼ",
	"ゾ", "ダ", "ヂ", "ヅ", "デ", "ド", "バ", "ビ", "ブ", "ベ", "ボ", "パ", "ピ", "プ", "ペ", "ポ",
	"ッ", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "!", "?", ".", "-", "・",
	"…", "\"", "\"", "'", "'", "♂", "♀", "$", ",", "×", "/", "A", "B", "C", "D", "E",
	"F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U",
	"V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k",
	"l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "▶",
	":", "Ä", "Ö", "Ü", "ä", "ö", "ü", "↑", "↓", "←", "", "", "", "", "", ""
}

-- The NDS charmap is really large, so we only take the characters we typically care about.
---@type Charmap
local NDSCharmap = {
      -- Common characters
      [0x0000] = "",
      [0x0001] = " ", -- Full-width space

      -- Numbers (full-width)
      [0x00A2] = "0", [0x00A3] = "1", [0x00A4] = "2", [0x00A5] = "3",
      [0x00A6] = "4", [0x00A7] = "5", [0x00A8] = "6", [0x00A9] = "7",
      [0x00AA] = "8", [0x00AB] = "9",

      -- Uppercase letters (full-width)
      [0x00AC] = "A", [0x00AD] = "B", [0x00AE] = "C", [0x00AF] = "D",
      [0x00B0] = "E", [0x00B1] = "F", [0x00B2] = "G", [0x00B3] = "H",
      [0x00B4] = "I", [0x00B5] = "J", [0x00B6] = "K", [0x00B7] = "L",
      [0x00B8] = "M", [0x00B9] = "N", [0x00BA] = "O", [0x00BB] = "P",
      [0x00BC] = "Q", [0x00BD] = "R", [0x00BE] = "S", [0x00BF] = "T",
      [0x00C0] = "U", [0x00C1] = "V", [0x00C2] = "W", [0x00C3] = "X",
      [0x00C4] = "Y", [0x00C5] = "Z",

      -- Lowercase letters (full-width)
      [0x00C6] = "a", [0x00C7] = "b", [0x00C8] = "c", [0x00C9] = "d",
      [0x00CA] = "e", [0x00CB] = "f", [0x00CC] = "g", [0x00CD] = "h",
      [0x00CE] = "i", [0x00CF] = "j", [0x00D0] = "k", [0x00D1] = "l",
      [0x00D2] = "m", [0x00D3] = "n", [0x00D4] = "o", [0x00D5] = "p",
      [0x00D6] = "q", [0x00D7] = "r", [0x00D8] = "s", [0x00D9] = "t",
      [0x00DA] = "u", [0x00DB] = "v", [0x00DC] = "w", [0x00DD] = "x",
      [0x00DE] = "y", [0x00DF] = "z",

      -- Numbers (normal width)
      [0x0121] = "0", [0x0122] = "1", [0x0123] = "2", [0x0124] = "3",
      [0x0125] = "4", [0x0126] = "5", [0x0127] = "6", [0x0128] = "7",
      [0x0129] = "8", [0x012A] = "9",

      -- Uppercase letters (normal width)
      [0x012B] = "A", [0x012C] = "B", [0x012D] = "C", [0x012E] = "D",
      [0x012F] = "E", [0x0130] = "F", [0x0131] = "G", [0x0132] = "H",
      [0x0133] = "I", [0x0134] = "J", [0x0135] = "K", [0x0136] = "L",
      [0x0137] = "M", [0x0138] = "N", [0x0139] = "O", [0x013A] = "P",
      [0x013B] = "Q", [0x013C] = "R", [0x013D] = "S", [0x013E] = "T",
      [0x013F] = "U", [0x0140] = "V", [0x0141] = "W", [0x0142] = "X",
      [0x0143] = "Y", [0x0144] = "Z",

      -- Lowercase letters (normal width)
      [0x0145] = "a", [0x0146] = "b", [0x0147] = "c", [0x0148] = "d",
      [0x0149] = "e", [0x014A] = "f", [0x014B] = "g", [0x014C] = "h",
      [0x014D] = "i", [0x014E] = "j", [0x014F] = "k", [0x0150] = "l",
      [0x0151] = "m", [0x0152] = "n", [0x0153] = "o", [0x0154] = "p",
      [0x0155] = "q", [0x0156] = "r", [0x0157] = "s", [0x0158] = "t",
      [0x0159] = "u", [0x015A] = "v", [0x015B] = "w", [0x015C] = "x",
      [0x015D] = "y", [0x015E] = "z",

      -- Special characters
      [0x01AB] = "!", [0x01AC] = "?", [0x01AD] = ",", [0x01AE] = ".",
      [0x01AF] = "…", [0x01B0] = "·", [0x01B1] = "/", [0x01B2] = "'",
      [0x01B9] = "(", [0x01BA] = ")", [0x01BB] = "♂", [0x01BC] = "♀",
      [0x01BD] = "+", [0x01BE] = "-", [0x01BF] = "*", [0x01C1] = "=",
      [0x01C2] = "&", [0x01C4] = ":", [0x01D2] = "%",
      [0x01E8] = "°", [0x01E9] = "_",

      -- Accented characters
      [0x015F] = "À", [0x0160] = "Á", [0x0161] = "Â", [0x0162] = "Ã",
      [0x0163] = "Ä", [0x0166] = "Ç", [0x0167] = "È", [0x0168] = "É",
      [0x0169] = "Ê", [0x016A] = "Ë", [0x016B] = "Ì", [0x016C] = "Í",
      [0x016D] = "Î", [0x016E] = "Ï", [0x0170] = "Ñ", [0x0171] = "Ò",
      [0x0172] = "Ó", [0x0173] = "Ô", [0x0174] = "Õ", [0x0175] = "Ö",
      [0x0178] = "Ù", [0x0179] = "Ú", [0x017A] = "Û", [0x017B] = "Ü",

      [0x017F] = "à", [0x0180] = "á", [0x0181] = "â", [0x0182] = "ã",
      [0x0183] = "ä", [0x0186] = "ç", [0x0187] = "è", [0x0188] = "é",
      [0x0189] = "ê", [0x018A] = "ë", [0x018B] = "ì", [0x018C] = "í",
      [0x018D] = "î", [0x018E] = "ï", [0x0190] = "ñ", [0x0191] = "ò",
      [0x0192] = "ó", [0x0193] = "ô", [0x0194] = "õ", [0x0195] = "ö",
      [0x0198] = "ù", [0x0199] = "ú", [0x019A] = "û", [0x019B] = "ü",

      -- Terminators
      [0xE000] = "\n",
      [0x25BC] = "\r",
      [0xFFFF] = "" -- String terminator
  }

--- Converts a byte array representing a Gen 4 string into a Lua string using the provided charmap.
---@param data any
---@param charmap Charmap
---@return unknown
local function decodeGen4Text(data, charmap)
    local result = ""
    local maxLength = 11

    -- Supports both 0-based and 1-based byte tables from NLua/C# interop.
    local function readByte(index0)
        -- Prefer 0-based if present; otherwise fallback to 1-based.
        local b = data[index0]
        if b == nil then
            b = data[index0 + 1]
        end
        return b
    end

    for i = 0, maxLength - 1 do
        local lo = readByte(i * 2)
        local hi = readByte(i * 2 + 1)

        -- Stop safely if we ran out of bytes.
        if lo == nil or hi == nil then
            break
        end

        local charCode = lo + (hi << 8) -- Little-endian
        if charCode == 0xFFFF then
            break
        end

        local char = charmap[charCode] or "?"
        result = result .. char
    end

    return result
end


local function decryptText(data)
	local gameData = MemoryReader.currentGame
    local generation = gameData.gameInfo.generation
	local charmap = gameData.gameInfo.charmap
	local decrypted = ""

    if generation == 4 then
        return decodeGen4Text(data, charmap)
    end

	for i = 1, #data do
		local byte = data[i]  -- Access table element directly, not string byte
		if byte == 0xFF then  -- GBA string terminator
			break
		elseif byte ~= 0 then
			decrypted = decrypted .. (charmap[byte] or "?")
		end
	end

	-- Remove trailing spaces
	decrypted = decrypted:gsub("%s*$", "")

	return decrypted
end

local function encryptGen4Text(text, reverseMap)
    -- Gen 4 stores each character as a 2-byte value (UTF-16LE / little-endian).
    local maxLength = 11
    local bytes = {}

    for i = 1, #text do
        local char = text:sub(i, i)
        local charCode = reverseMap[char]

        if charCode then
            -- Store as little-endian 2-byte value (LSB first)
            table.insert(bytes, charCode & 0xFF)         -- LSB
            table.insert(bytes, (charCode >> 8) & 0xFF)  -- MSB
        else
            -- Unknown character, use 0x00 0x00
            console.log(string.format("Warning: Character '%s' not in charmap, using 0x0000", char))
            table.insert(bytes, 0x00)
            table.insert(bytes, 0x00)
        end
    end

    -- Add string terminator (0xFFFF)
    table.insert(bytes, 0xFF)
    table.insert(bytes, 0xFF)

    -- Pad with 0x00 0x00 if shorter than maxLength
    while #bytes < (maxLength + 1) * 2 do  -- +1 for terminator
          table.insert(bytes, 0x00)
      end

    return bytes
end

local function encryptText(text)
    local gameData = MemoryReader.currentGame
    local generation = gameData.gameInfo.generation
    local charmap = gameData.gameInfo.charmap
    local reverseMap = {}
    for byte, char in pairs(charmap) do
        reverseMap[char] = byte
    end

    if generation == 4 then
        return encryptGen4Text(text, reverseMap)
    end

    local encrypted = {}
    for char in text:gmatch(".") do
        local byte = reverseMap[char] or 0x00  -- Default to 0x00 for unknown chars
        table.insert(encrypted, byte)
    end
    table.insert(encrypted, 0xFF)  -- Append string terminator

    return encrypted
end
return {
	GBCharmap = GBCharmap,
	GBACharmap = GBACharmap,
	NDSCharmap = NDSCharmap,
	decryptText = decryptText,
	encryptText = encryptText
}

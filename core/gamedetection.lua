-- Game Detection Module for Pokemon Memory Reader
-- This module handles detecting which Pokemon game is currently loaded in BizHawk

local gameDetection = {}

-- Game Boy/Game Boy Color detection addresses
local GB_ADDRESSES = {
    VERSION_CODE = 0x13C,  -- 16-bit version identifier
    LANGUAGE = 0x14E       -- 8-bit language identifier  
}

-- Game Boy/Game Boy Color version codes
local GB_VERSION_CODES = {
    [0x414C] = "Crystal",
    [0x424C] = "Blue", 
    [0x474C] = "Gold",
    [0x5245] = "Red",
    [0x4752] = "Green", 
    [0x534C] = "Silver",
    [0x5945] = "Yellow"
}

-- Game signature data for detection
-- Each game has a unique GameCode that can be found at a specific ROM address
local gameSignatures = {
    -- Pokemon Ruby versions
    {
        name = "Pokemon Ruby v1.0",
        pattern = "AXVE",
        gameCode = 1162627413, -- "AXVE" as 32-bit int
    },
    {
        name = "Pokemon Ruby v1.1", 
        pattern = "AXVE01",
        gameCode = 1162627413,
    },
    {
        name = "Pokemon Ruby v1.2",
        pattern = "AXVE01", 
        gameCode = 1162627413,
    },
    
    -- Pokemon Sapphire versions
    {
        name = "Pokemon Sapphire v1.0",
        pattern = "AXPE",
        gameCode = 1162624581, -- "AXPE" as 32-bit int
    },
    {
        name = "Pokemon Sapphire v1.1",
        pattern = "AXPE01",
        gameCode = 1162624581,
    },
    {
        name = "Pokemon Sapphire v1.2",
        pattern = "AXPE01",
        gameCode = 1162624581,
    },
    
    -- Pokemon Emerald
    {
        name = "Pokemon Emerald",
        pattern = "BPEE",
        gameCode = 1112556869, -- "BPEE" as 32-bit int  
    },
    
    -- Pokemon FireRed versions
    {
        name = "Pokemon FireRed v1.0",
        pattern = "BPRE",
        gameCode = 1112560197, -- "BPRE" as 32-bit int
    },
    {
        name = "Pokemon FireRed v1.1",
        pattern = "BPRE01",
        gameCode = 1112560197,
    },
    
    -- Pokemon LeafGreen versions
    {
        name = "Pokemon LeafGreen v1.0",
        pattern = "BPGE",
        gameCode = 1112558661, -- "BPGE" as 32-bit int
    },
    {
        name = "Pokemon LeafGreen v1.1",
        pattern = "BPGE01",
        gameCode = 1112558661,
    },
    
    -- International versions
    {
        name = "Pokemon FireRed J",
        pattern = "BPRJ",
        gameCode = 1246444614, -- "BPRJ" as 32-bit int
    }
}

-- ROM header addresses for GBA games
local ROM_ADDRESSES = {
    GAME_CODE = 0x0AC,    -- Game code location in ROM (relative to ROM start)
    GAME_TITLE = 0x0A0,   -- Game title location in ROM  
    MAKER_CODE = 0x0B0,   -- Maker code location in ROM
    VERSION = 0x0BC       -- Version number location in ROM
}

-- Helper function to read game code from ROM
local function readGameCode()
    -- Try different methods to read the game code
    local success, gameCode = pcall(function()
        -- First try with ROM domain
        return memory.read_u32_le(ROM_ADDRESSES.GAME_CODE, "ROM")
    end)
    
    if success and gameCode and gameCode ~= 0 then
        return gameCode
    end
    
    -- Try with System Bus domain
    success, gameCode = pcall(function()
        return memory.read_u32_le(0x08000000 + ROM_ADDRESSES.GAME_CODE, "System Bus")
    end)
    
    if success and gameCode and gameCode ~= 0 then
        return gameCode
    end
    
    -- Try with CARTROM domain 
    success, gameCode = pcall(function()
        return memory.read_u32_le(ROM_ADDRESSES.GAME_CODE, "CARTROM")
    end)
    
    if success and gameCode and gameCode ~= 0 then
        return gameCode
    end
    
    -- Try reading as bytes and combining them
    success, gameCode = pcall(function()
        local byte1 = memory.read_u8(ROM_ADDRESSES.GAME_CODE, "ROM")
        local byte2 = memory.read_u8(ROM_ADDRESSES.GAME_CODE + 1, "ROM") 
        local byte3 = memory.read_u8(ROM_ADDRESSES.GAME_CODE + 2, "ROM")
        local byte4 = memory.read_u8(ROM_ADDRESSES.GAME_CODE + 3, "ROM")
        
        return byte1 + (byte2 * 256) + (byte3 * 65536) + (byte4 * 16777216)
    end)
    
    if success then
        return gameCode
    end
    
    return nil
end

-- Helper function to read game title from ROM
local function readGameTitle()
    local title = ""
    local success, result = pcall(function()
        for i = 0, 11 do -- Game titles are 12 bytes
            local byte = memory.read_u8(ROM_ADDRESSES.GAME_TITLE + i, "ROM")
            if byte == 0 then break end -- Null terminator
            title = title .. string.char(byte)
        end
        return title
    end)
    
    if success then
        return result
    end
    
    -- Try with System Bus
    success, result = pcall(function()
        title = ""
        for i = 0, 11 do
            local byte = memory.read_u8(0x08000000 + ROM_ADDRESSES.GAME_TITLE + i, "System Bus")
            if byte == 0 then break end
            title = title .. string.char(byte)
        end
        return title
    end)
    
    if success then
        return result
    end
    
    return nil
end

-- Helper function to read version number
local function readVersion()
    local success, version = pcall(function()
        return memory.read_u8(ROM_ADDRESSES.VERSION, "ROM")
    end)
    
    if success then
        return version
    else
        return nil
    end
end

-- Helper function to read GB/GBC version code
local function readGBVersionCode()
    local success, versionCode = pcall(function()
        return memory.read_u16_be(GB_ADDRESSES.VERSION_CODE)
    end)
    
    if success then
        return versionCode
    end
    
    return nil
end

-- Helper function to read GB/GBC language
local function readGBLanguage()
    local success, languageCode = pcall(function()
        return memory.read_u8(GB_ADDRESSES.LANGUAGE)
    end)
    
    if success then
        -- Determine language based on code (from the example script)
        if languageCode == 0x04 or languageCode == 0x91 or languageCode == 0x9D then
            return "USA"
        elseif languageCode == 0xB8 or languageCode == 0xD9 or languageCode == 0xDC or languageCode == 0xF5 then
            return "JPN" 
        else
            return "EUR"
        end
    end
    
    return nil
end

-- Load game data from JSON file
local function loadGameData(jsonPath)
    local file = io.open(jsonPath, "r")
    if not file then
        console.log("Error: Could not open game data file: " .. jsonPath)
        return nil
    end
    
    local jsonContent = file:read("*all")
    file:close()
    
    -- Simple JSON parsing for our specific structure
    -- In a real implementation, you'd want a proper JSON parser
    local success, gameData = pcall(function()
        return json.parse(jsonContent)
    end)
    
    if success then
        return gameData
    else
        console.log("Error: Could not parse game data file: " .. jsonPath)
        return nil
    end
end

-- Simple JSON parser (basic implementation)
local function parseJSON(str)
    -- Remove whitespace
    str = str:gsub("%s+", "")
    
    -- This is a very basic JSON parser - for production use a proper library
    -- For now, return nil to indicate we need the JSON data to be pre-loaded
    return nil
end

-- Helper function to get GB/GBC addresses based on game and language
local function getGBAddresses(version, language)
    local addresses = {}
    
    if language == "USA" then
        if version == "Blue" or version == "Red" then
            addresses = {
                partyAddr = 0xD16B,
                partySlotsCounterAddr = 0xD163,
                partyNicknamesAddr = 0xD2B5,
                wildDVsAddr = 0xCFF1,
                fishedSpeciesAddr = 0xD059,
                tidAddr = 0xD359
            }
        elseif version == "Yellow" then
            addresses = {
                partyAddr = 0xD16A,
                partySlotsCounterAddr = 0xD162,
                partyNicknamesAddr = 0xD2B4,
                wildDVsAddr = 0xCFF0,
                fishedSpeciesAddr = 0xD058,
                tidAddr = 0xD358
            }
        elseif version == "Crystal" then
            -- Crystal addresses (USA)
            addresses = {
                partyAddr = 0xDCDF,  -- Party Data
                partySlotsCounterAddr = 0xDCD7,  -- Party Count
                partyNicknamesAddr = 0xDE41,  -- Party Names
                partyOTAddr = 0xDDFF,  -- Party OT
                wildDVsAddr = 0xC6F0,  -- Wild Pokemon DVs (estimated)
                tidAddr = 0xDCDF  -- Trainer ID (estimated)
            }
        elseif version == "Gold" or version == "Silver" then
            -- Gold/Silver addresses (USA)
            addresses = {
                partyAddr = 0xDA2A,  -- Party Data
                partySlotsCounterAddr = 0xDA22,  -- Party Count  
                partyNicknamesAddr = 0xDB8C,  -- Party Names
                partyOTAddr = 0xDB4A,  -- Party OT
                wildDVsAddr = 0xC6F0,  -- Wild Pokemon DVs (estimated)
                tidAddr = 0xDA2A  -- Trainer ID (estimated)
            }
        end
    elseif language == "JPN" then
        addresses = {
            partyAddr = 0xD12B,
            partySlotsCounterAddr = 0xD123,
            partyNicknamesAddr = 0xD275,
            wildDVsAddr = 0xCFD8,
            fishedSpeciesAddr = 0xD036,
            tidAddr = 0xD2D8
        }
    else -- EUR
        if version == "Blue" or version == "Red" then
            addresses = {
                partyAddr = 0xD170,
                partySlotsCounterAddr = 0xD168,
                partyNicknamesAddr = 0xD2BA,
                wildDVsAddr = 0xCFF6,
                fishedSpeciesAddr = 0xD05E,
                tidAddr = 0xD35E
            }
        elseif version == "Yellow" then
            addresses = {
                partyAddr = 0xD16F,
                partySlotsCounterAddr = 0xD167,
                partyNicknamesAddr = 0xD2B9,
                wildDVsAddr = 0xCFF5,
                fishedSpeciesAddr = 0xD05D,
                tidAddr = 0xD35D
            }
        elseif version == "Crystal" then
            -- Crystal addresses (EUR) - may need adjustment
            addresses = {
                partyAddr = 0xDCDF,  -- Party Data
                partySlotsCounterAddr = 0xDCD7,  -- Party Count
                partyNicknamesAddr = 0xDE41,  -- Party Names
                partyOTAddr = 0xDDFF,  -- Party OT
                wildDVsAddr = 0xC6F0,  -- Wild Pokemon DVs (estimated)
                tidAddr = 0xDCDF  -- Trainer ID (estimated)
            }
        elseif version == "Gold" or version == "Silver" then
            -- Gold/Silver addresses (EUR) - may need adjustment
            addresses = {
                partyAddr = 0xDA2A,  -- Party Data
                partySlotsCounterAddr = 0xDA22,  -- Party Count  
                partyNicknamesAddr = 0xDB8C,  -- Party Names
                partyOTAddr = 0xDB4A,  -- Party OT
                wildDVsAddr = 0xC6F0,  -- Wild Pokemon DVs (estimated)
                tidAddr = 0xDA2A  -- Trainer ID (estimated)
            }
        end
    end
    
    return addresses
end

-- Function to detect GB/GBC games
local function detectGBGame()
    local versionCode = readGBVersionCode()
    if not versionCode then
        return nil
    end
    
    local version = GB_VERSION_CODES[versionCode]
    if not version then
        return nil
    end
    
    local language = readGBLanguage() or "Unknown"
    local addresses = getGBAddresses(version, language)
    
    -- Determine generation
    local generation = 1
    local gameNumber = 1
    if version == "Gold" or version == "Silver" or version == "Crystal" then
        generation = 2
        gameNumber = 2
    end
    
    return {
        GameInfo = {
            GameCode = versionCode,
            GameName = "Pokemon " .. version .. " (" .. language .. ")",
            GameNumber = gameNumber,
            Generation = generation,
            Language = language,
            VersionColor = version,
            VersionGroup = generation,
            VersionName = "Pokémon " .. version .. " (" .. language .. ")"
        },
        Addresses = addresses
    }
end

-- Pre-loaded game data (since we don't have a JSON parser)
local preloadedGameData = {
    -- GBA Games
    [1112560197] = { -- Pokemon FireRed v1.0 (one variant)
        GameInfo = {
            GameCode = 1112560197,
            GameName = "Pokemon FireRed (U)",
            GameNumber = 3,
            Generation = 3,
            Language = "English",
            VersionColor = "FireRed", 
            VersionGroup = 2,
            VersionName = "Pokémon FireRed v1.0"
        },
        Addresses = {
            pstats = "02024284",
            estats = "0202402C", 
            gBattleMons = "02023BE4",
            gPlayerPartyCount = "02024029",
            gBaseStats = "08254784",
            gLevelUpLearnsets = "0825D7B4"
        }
    },
    [1163022402] = { -- Pokemon FireRed (detected variant - BPRE)
        GameInfo = {
            GameCode = 1163022402,
            GameName = "Pokemon FireRed (U)",
            GameNumber = 3,
            Generation = 3,
            Language = "English",
            VersionColor = "FireRed", 
            VersionGroup = 2,
            VersionName = "Pokémon FireRed"
        },
        Addresses = {
            pstats = "02024284",
            estats = "0202402C", 
            gBattleMons = "02023BE4",
            gPlayerPartyCount = "02024029",
            gBaseStats = "08254784",
            gLevelUpLearnsets = "0825D7B4"
        }
    },
    [1112556869] = { -- Pokemon Emerald
        GameInfo = {
            GameCode = 1112556869,
            GameName = "Pokemon Emerald (U)", 
            GameNumber = 2,
            Generation = 3,
            Language = "English",
            VersionColor = "Emerald",
            VersionGroup = 1,
            VersionName = "Pokémon Emerald"
        },
        Addresses = {
            pstats = "20244EC",
            estats = "2024744",
            gBattleMons = "2024084", 
            gPlayerPartyCount = "20244E9",
            gBaseStats = "83203CC",
            gLevelUpLearnsets = "832937C"
        }
    }
}

-- Main detection function
function gameDetection.detectGame()
    
    -- First try to detect Game Boy / Game Boy Color games
    local gbGame = detectGBGame()
    if gbGame then
        return gbGame
    end
    
    -- Check if we have a ROM loaded
    local gameCode = readGameCode()
    if not gameCode then
        return nil
    end
    
    -- Convert game code to string for debugging
    local codeStr = string.char(
        gameCode % 256,
        math.floor(gameCode / 256) % 256,
        math.floor(gameCode / 65536) % 256,
        math.floor(gameCode / 16777216) % 256
    )
    
    -- Look up the game data
    local gameData = preloadedGameData[gameCode]
    if gameData then
        return gameData
    end
    
    -- Try to identify by reading the title
    local gameTitle = readGameTitle()
    local version = readVersion()
    
    
    -- Check if it matches any known patterns by game code string
    if codeStr and gameTitle and gameTitle:find("POKEMON") then
        
        if codeStr == "BPRE" then -- FireRed
            return {
                GameInfo = {
                    GameCode = gameCode,
                    GameName = "Pokemon FireRed (U)",
                    VersionName = "Pokémon FireRed",
                    Language = "English",
                    VersionColor = "FireRed",
                    GameNumber = 3,
                    Generation = 3,
                    VersionGroup = 2
                },
                Addresses = {
                    pstats = "02024284",
                    estats = "0202402C", 
                    gBattleMons = "02023BE4",
                    gPlayerPartyCount = "02024029",
                    gBaseStats = "08254784",
                    gLevelUpLearnsets = "0825D7B4"
                }
            }
        elseif codeStr == "BPGE" then -- LeafGreen
            return {
                GameInfo = {
                    GameCode = gameCode,
                    GameName = "Pokemon LeafGreen (U)",
                    VersionName = "Pokémon LeafGreen", 
                    Language = "English",
                    VersionColor = "LeafGreen",
                    GameNumber = 3,
                    Generation = 3,
                    VersionGroup = 2
                },
                Addresses = {
                    -- Using FireRed addresses as base - may need adjustment
                    pstats = "02024284",
                    estats = "0202402C", 
                    gBattleMons = "02023BE4",
                    gPlayerPartyCount = "02024029",
                    gBaseStats = "08254784",
                    gLevelUpLearnsets = "0825D7B4"
                }
            }
        elseif codeStr == "BPEE" then -- Emerald
            return {
                GameInfo = {
                    GameCode = gameCode,
                    GameName = "Pokemon Emerald (U)",
                    VersionName = "Pokémon Emerald",
                    Language = "English", 
                    VersionColor = "Emerald",
                    GameNumber = 2,
                    Generation = 3,
                    VersionGroup = 1
                },
                Addresses = {
                    pstats = "20244EC",
                    estats = "2024744",
                    gBattleMons = "2024084", 
                    gPlayerPartyCount = "20244E9",
                    gBaseStats = "83203CC",
                    gLevelUpLearnsets = "832937C"
                }
            }
        elseif codeStr == "AXVE" then -- Ruby
            return {
                GameInfo = {
                    GameCode = gameCode,
                    GameName = "Pokemon Ruby (U)",
                    VersionName = "Pokémon Ruby",
                    Language = "English",
                    VersionColor = "Ruby", 
                    GameNumber = 3,
                    Generation = 3,
                    VersionGroup = 1
                },
                Addresses = {
                    pstats = "03004360",
                    estats = "2024744",
                    gBattleMons = "2024084", 
                    gPlayerPartyCount = "20244E9",
                    gBaseStats = "83203CC",
                    gLevelUpLearnsets = "832937C"
                }
            }
        elseif codeStr == "AXPE" then -- Sapphire
            return {
                GameInfo = {
                    GameCode = gameCode,
                    GameName = "Pokemon Sapphire (U)",
                    VersionName = "Pokémon Sapphire",
                    Language = "English",
                    VersionColor = "Sapphire",
                    GameNumber = 3, 
                    Generation = 3,
                    VersionGroup = 1
                },
                Addresses = {
                    pstats = "03004360",
                    estats = "2024744",
                    gBattleMons = "2024084", 
                    gPlayerPartyCount = "20244E9",
                    gBaseStats = "83203CC",
                    gLevelUpLearnsets = "832937C"
                }
            }
        end
    end
    
    console.log("Unknown game detected with code: " .. gameCode .. " (" .. (codeStr or "unknown") .. ")")
    return nil
end

-- Function to get supported games list
function gameDetection.getSupportedGames()
    local games = {}
    
    -- Add GB/GBC games
    for code, version in pairs(GB_VERSION_CODES) do
        table.insert(games, "Pokemon " .. version)
    end
    
    -- Add GBA games
    for _, signature in ipairs(gameSignatures) do
        table.insert(games, signature.name)
    end
    
    return games
end

-- Function to validate if current game is supported
function gameDetection.isGameSupported()
    -- Try GB/GBC first
    local gbGame = detectGBGame()
    if gbGame then
        return true
    end
    
    -- Try GBA
    local gameCode = readGameCode()
    return gameCode and preloadedGameData[gameCode] ~= nil
end

return gameDetection
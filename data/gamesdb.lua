-- Pokemon Games Database
-- Consolidated database containing all game information and memory addresses

local GamesDB = {}

GamesDB.games = {
    
    -- ===== GENERATION 1 GAMES =====
    
    -- MARK: Red (USA)
    ["EA9BCAE617FDF159B045185467AE58B2E4A48B9A"] = {
        gameInfo = {
            gameCode = 0x5245,
            gameName = "Pokemon Red (USA)",
            versionName = "Pokemon Red",
            versionColor = "Red",
            generation = 1,
            platform = "GB",
            isRomhack = false
        },
        addresses = {
            partyAddr = 0xD16B,
            partySlotsCounterAddr = 0xD163,
            partyNicknamesAddr = 0xD2B5,
            wildDVsAddr = 0xCFF1,
            trainerID = 0xD359,
            itemNameTable = 0x472B
        },
        trainerOffsets = {
            name = 0xD158, -- 11 bytes,
            badges = 0xD356, -- 1 byte, 1 bit per badge
            money = 0xD347, -- 3 bytes, BCD encoded
            coins = 0xD5A4, -- 2 bytes, binary encoded
            bagCount = 0xD31D, -- 1 byte,
            bagItems = 0xD31E, -- 2 bytes per item, up to 40 items
            pcCount = 0xD53A, -- 1 byte,
            pcItems = 0xD53B  -- 2 bytes per item, up to 50 items
        }
    },
    

    --MARK: Blue (USA)
    ["D7037C83E1AE5B39BDE3C30787637BA1D4C48CE2"] = {
        gameInfo = {
            gameCode = 0x424C,
            gameName = "Pokemon Blue (USA)",
            versionName = "Pokemon Blue",
            versionColor = "Blue",
            generation = 1,
            platform = "GB",
            isRomhack = false
        },
        addresses = {
            partyAddr = 0xD16B,
            partySlotsCounterAddr = 0xD163,
            partyNicknamesAddr = 0xD2B5,
            wildDVsAddr = 0xCFF1,
            trainerID = 0xD359,
            itemNameTable = 0x472B
        },
        trainerOffsets = {
            name = 0xD158, -- 11 bytes,
            badges = 0xD356, -- 1 byte, 1 bit per badge
            money = 0xD347, -- 3 bytes, BCD encoded
            coins = 0xD5A4, -- 2 bytes, binary encoded
            bagCount = 0xD31D, -- 1 byte,
            bagItems = 0xD31E, -- 2 bytes per item, up to 40 items
            pcCount = 0xD53A, -- 1 byte,
            pcItems = 0xD53B  -- 2 bytes per item, up to 50 items
        }
    },
    
    --MARK: Yellow (USA)
    ["CC7D03262EBFAF2F06772C1A480C7D9D5F4A38E1"] = {
        gameInfo = {
            gameCode = 0x5945,
            gameName = "Pokemon Yellow (USA)",
            versionName = "Pokemon Yellow",
            versionColor = "Yellow",
            generation = 1,
            platform = "GB",
            isRomhack = false
        },
        addresses = {
            partyAddr = 0xD16A,
            partySlotsCounterAddr = 0xD162,
            partyNicknamesAddr = 0xD2B4,
            wildDVsAddr = 0xCFF0,
            trainerID = 0xD358,
            itemNameTable = 0x45B9
        },
        trainerOffsets = {
            name = 0xD157, -- 11 bytes,
            badges = 0xD355, -- 1 byte, 1 bit per badge
            money = 0xD346, -- 3 bytes, BCD encoded
            coins = 0xD5A3, -- 2 bytes, binary encoded
            bagCount = 0xD31C, -- 1 byte,
            bagItems = 0xD31D, -- 2 bytes per item, up to 40 items
            pcCount = 0xD539, -- 1 byte,
            pcItems = 0xD53A  -- 2 bytes per item, up to 50 items
        }
    },
    
    -- ===== GENERATION 2 GAMES =====

    -- MARK: Gold (USA)
    ["D8B8A3600A465308C9953DFA04F0081C05BDCB94"] = {
        gameInfo = {
            gameCode = 0x474C,
            gameName = "Pokemon Gold (USA)",
            versionName = "Pokemon Gold",
            versionColor = "Gold",
            generation = 2,
            platform = "GBC",
            isRomhack = false
        },
        addresses = {
            partyAddr = 0xDA2A,
            partySlotsCounterAddr = 0xDA22,
            partyNicknamesAddr = 0xDB8C,
            partyOTAddr = 0xDB4A,
            wildDVsAddr = 0xC6F0,
            trainerID = 0xDA2A,
            tmToMoveTable = 0x11A66,
            moveNamesTable = 0x1B1574,
        },
        pocketSize = {
            pcCount = 50,
            itemsPocket = 20,
            keyItemsPocket = 25,
            ballsPocket = 12,
            tmhmPocket = 57,
        },
        trainerOffsets = {
            trainerID = 0xD1A1, -- 2 bytes
            name = 0xD1A3, -- 10 bytes
            money = 0xD573, -- 3 bytes
            momMoney = 0xD576, -- 3 bytes 
            coins = 0xD57A, -- 2 bytes binary
            johtoBadges = 0xD57C, -- 1 byte, 1 bit per badge
            kantoBadges = 0xD57D, -- 1 byte, 1 bit per badge

            -- Bag Info
            itemCount = 0xD5B7, -- 1 byte
            itemsPocket = 0xD5B8, -- 2 bytes per item, up to 20 items
            keyItemCount = 0xD5E1, -- 1 byte
            keyItemsPocket = 0xD5E2, -- 2 bytes per item, up to 25 items
            ballCount = 0xD5FC, -- 1 byte
            ballsPocket = 0xD5FD, -- 2 bytes per item, up to 12 items
            tmhmPocket = 0xD57E,
        }
    },

    -- MARK: Silver (USA)
    ["49B163F7E57702BC939D642A18F591DE55D92DAE"] = {
        gameInfo = {
            gameCode = 0x534C,
            gameName = "Pokemon Silver (USA)",
            versionName = "Pokemon Silver",
            versionColor = "Silver",
            generation = 2,
            platform = "GBC",
            isRomhack = false
        },
        addresses = {
            partyAddr = 0xDA2A,
            partySlotsCounterAddr = 0xDA22,
            partyNicknamesAddr = 0xDB8C,
            partyOTAddr = 0xDB4A,
            wildDVsAddr = 0xC6F0,
            trainerID = 0xDA2A,
            tmToMoveTable = 0x11A66,
            moveNamesTable = 0x1B1574,
        },
        pocketSize = {
            pcCount = 50,
            itemsPocket = 20,
            keyItemsPocket = 25,
            ballsPocket = 12,
            tmhmPocket = 57,
        },
        trainerOffsets = {
            trainerID = 0xD1A1, -- 2 bytes
            name = 0xD1A3, -- 10 bytes
            money = 0xD573, -- 3 bytes
            momMoney = 0xD576, -- 3 bytes 
            coins = 0xD57A, -- 2 bytes binary
            johtoBadges = 0xD57C, -- 1 byte, 1 bit per badge
            kantoBadges = 0xD57D, -- 1 byte, 1 bit per badge

            -- Bag Info
            itemCount = 0xD5B7, -- 1 byte
            itemsPocket = 0xD5B8, -- 2 bytes per item, up to 20 items
            keyItemCount = 0xD5E1, -- 1 byte
            keyItemsPocket = 0xD5E2, -- 2 bytes per item, up to 25 items
            ballCount = 0xD5FC, -- 1 byte
            ballsPocket = 0xD5FD, -- 2 bytes per item, up to 12 items
            tmhmPocket = 0xD57E,
        }
    },

    -- MARK: Crystal (USA)
    ["F4CD194BDEE0D04CA4EAC29E09B8E4E9D818C133"] = {
        gameInfo = {
            gameCode = 0x414C,
            gameName = "Pokemon Crystal (USA)",
            versionName = "Pokemon Crystal",
            versionColor = "Crystal",
            generation = 2,
            platform = "GBC",
            isRomhack = false
        },
        addresses = {
            partyAddr = 0xDCDF,
            partySlotsCounterAddr = 0xDCD7,
            partyNicknamesAddr = 0xDE41,
            partyOTAddr = 0xDDFF,
            wildDVsAddr = 0xC6F0,
            trainerID = 0xDCDF,
            speciesNameTable = 0x53384,-- 11 bytes per name
            itemNameTable = 0x1C8000, -- Variable with 0x50 terminator
            moveNamesTable = 0x1C9F29, -- Variable with 0x50 terminator
            tmToMoveTable = 0x1167A, -- 1 byte per TM/hm, 60 entries total.
        },
        pocketSize = {
            pcCount = 50,
            itemsPocket = 20,
            keyItemsPocket = 25,
            ballsPocket = 12,
            tmhmPocket = 57,
        },
        trainerOffsets = {
            trainerID = 0xD47B, -- 2 bytes
            name = 0xD47D, -- 10 bytes
            money = 0xD84F, -- 3 bytes
            momMoney = 0xD852, -- 3 bytes
            coins = 0xD855, -- 2 bytes binary
            johtoBadges = 0xD857, -- 1 byte, 1 bit per badge
            kantoBadges = 0xD858, -- 1 byte, 1 bit per badge

            -- Bag Info
            itemCount = 0xD893,
            keyItemCount = 0xD8BC,
            ballCount = 0xD8D7,
            pcCount = 0xD8F1,

            itemsPocket = 0xD893, -- 2 bytes per item, up to 20 items
            keyItemsPocket = 0xD8BD, -- 2 bytes per item, up to 25 items
            ballsPocket = 0xD8D8, -- 2 bytes per item, up to 12 items
            tmhmPocket = 0xD859,
            pcItems = 0xD8F2, -- 2 bytes per item, up to 50 items
        }
    },
    
    -- ===== GENERATION 3 GAMES =====

    -- MARK: Ruby (USA)
    ["F28B6FFC97847E94A6C21A63CACF633EE5C8DF1E"] = {
        gameInfo = {
            gameCode = "AXVE",
            gameName = "Pokemon Ruby (USA)",
            versionName = "Pokemon Ruby",
            versionColor = "Ruby",
            generation = 3,
            platform = "GBA",
            isRomhack = false
        },
        addresses = {
            -- First 2 numbers determine domain
            -- 02 = EWRAM, 08 = ROM
            partyAddr = "02004360",
            enemyPartyAddr = "02024744",
            gBattleMons = "02024084",
            speciesDataTable = "081FEC34",
            speciesNameTable = "081F716C",
            itemNameTable =     "083C5564",
            naturePointersAddr = "083C1004"
        },
        trainerPointers = {
            isPointer = false,
            saveBlock1 = "02025734",
            saveBlock2 = "02024EA4",
        },
        pocketSize = {
            pcCount = 50,
            itemsPocket = 20,
            keyItemsPocket = 20,
            ballsPocket = 16,
            tmhmPocket = 64,
            berriesPocket = 46
        },
        trainerOffsets = {
            -- Info
            trainerID = 0x0A,
            name = 0x00,
            gender = 0x08,
            -- Currency
            money = 0x490,
            coins = 0x494,
            -- Bags
            pcItems = 0x498,
            itemsPocket = 0x560,
            keyItemsPocket = 0x5B0,
            ballsPocket = 0x600,
            tmhmPocket = 0x640,
            berriesPocket = 0x740,
            -- Flags
            flags = 0x1220,
            -- Badge Offset
            -- Offset from flags address
            -- Each badge is 1 bit
            badgeFlags = 0x100
        }
    },

    -- MARK: Sapphire (USA)
    ["3CCBBD45F8553C36463F13B938E833F652B793E4"] = {
        gameInfo = {
            gameCode = "AXPE",
            gameName = "Pokemon Sapphire (USA)",
            versionName = "Pokemon Sapphire",
            versionColor = "Sapphire",
            generation = 3,
            platform = "GBA",
            isRomhack = false
        },
        addresses = {
            -- First 2 numbers determine domain
            -- 02 = EWRAM, 08 = ROM
            partyAddr = "02004360",
            enemyPartyAddr = "02024744",
            gBattleMons = "02024084",
            speciesDataTable = "081FEC34",
            speciesNameTable = "081F716C",
            itemNameTable =     "083C5564",
            naturePointersAddr = "083C1004"
        },
        trainerPointers = {
            isPointer = false,
            saveBlock1 = "02025734",
            saveBlock2 = "02024EA4",
        },
        pocketSize = {
            pcCount = 50,
            itemsPocket = 20,
            keyItemsPocket = 20,
            ballsPocket = 16,
            tmhmPocket = 64,
            berriesPocket = 46
        },
        trainerOffsets = {
            -- Info
            trainerID = 0x0A,
            name = 0x00,
            gender = 0x08,
            -- Currency
            money = 0x490,
            coins = 0x494,
            -- Bags
            pcItems = 0x498,
            itemsPocket = 0x560,
            keyItemsPocket = 0x5B0,
            ballsPocket = 0x600,
            tmhmPocket = 0x640,
            berriesPocket = 0x740,
            -- Flags
            flags = 0x1220,
            -- Badge Offset
            -- Offset from flags address
            -- Each badge is 1 bit
            badgeFlags = 0x100
        }
    },

    -- MARK: Emerald (USA)
    ["F3AE088181BF583E55DAF962A92BB46F4F1D07B7"] = {
        gameInfo = {
            gameCode = "BPEE",
            gameName = "Pokemon Emerald (USA)",
            versionName = "Pokemon Emerald",
            versionColor = "Emerald",
            generation = 3,
            platform = "GBA",
            isRomhack = false
        },
        addresses = {
            -- First 2 numbers determine domain
            -- 02 = EWRAM, 03 = IWRAM, 08 = ROM
            partyAddr =             "020244EC",
            enemyPartyAddr =        "02024744",
            gBattleMons =           "02024084", 
            speciesDataTable =      "083203CC",
            speciesNameTable =      "083185C8",
            itemTable =             "0858399E",
            naturePointersAddr =    "0861CB50",
            abilityNameTable =      "0831B6DB",
            moveNamesTable =         "0831977C",
            -- 58 moves 2 bytes each
            tmToMoveTable =         "08616040"
        },
        trainerPointers = {
            isPointer = true,
            saveBlock1 = "03005D8C",
            saveBlock2 = "03005D90",
        },
        pocketSize = {
            pcCount = 50,
            itemsPocket = 20,
            keyItemsPocket = 30,
            ballsPocket = 16,
            tmhmPocket = 64,
            berriesPocket = 46
        },
        trainerOffsets = {
            -- Info
            name = 0x00,
            gender = 0x08,
            trainerID = 0x0A,
            encryptionKey = 0xAC,
            -- Currency
            money = 0x490,
            coins = 0x494,
            -- Bags
            pcItems = 0x498,
            itemsPocket = 0x560,
            keyItemsPocket = 0x5D8,
            ballsPocket = 0x650,
            tmhmPocket = 0x690,
            berriesPocket = 0x790,
            -- Flags
            flags = 0x1270,
            -- Badge Offset
            -- Offset from flags address
            badgeFlags = 0x10C
        }
    },

    -- MARK: FireRed (USA)
    ["41CB23D8DCCC8EBD7C649CD8FBB58EEACE6E2FDC"] = {
        gameInfo = {
            gameCode = "BPRE",
            gameName = "Pokemon FireRed (USA)",
            versionName = "Pokemon FireRed",
            versionColor = "FireRed",
            generation = 3,
            platform = "GBA",
            isRomhack = false
        },
        addresses = {
            -- First 2 numbers determine domain
            -- 02 = EWRAM, 08 = ROM
            partyAddr =             "02024284",
            enemyPartyAddr =        "0202402C",
            gBattleMons =           "02023BE4",
            speciesDataTable =      "082547A0",
            speciesNameTable =      "08245EE0",
            itemNameTable =         "083DB028",
            naturePointersAddr =    "08463E60",
            abilityNameTable =      "0824FC40",
            moveNameTable =         "08247094"
        },
        trainerPointers = {
            isPointer = true,
            saveBlock1 = "03005008",
            saveBlock2 = "0300500C",
        },
        pocketSize = {
            pcCount = 30,
            itemsPocket = 42,
            keyItemsPocket = 30,
            ballsPocket = 13,
            tmhmPocket = 58,
            berriesPocket = 43
        },
        trainerOffsets = {
            -- Info
            name = 0x00,
            gender = 0x08,
            trainerID = 0x0A,
            encryptionKey = 0xF20,
            -- Currency
            money = 0x290,
            coins = 0x294,
            -- Bags
            pcItems = 0x298,
            itemsPocket = 0x310,
            keyItemsPocket = 0x3B8,
            ballsPocket = 0x430,
            tmhmPocket = 0x464,
            berriesPocket = 0x54C,
            -- Flags
            flags = 0x0EE0,
            -- Badge Offset
            -- Offset from flags address
            badgeFlags = 0x104
        }
    },

    -- MARK: LeafGreen (USA)
    ["574FA542FFEBB14BE69902D1D36F1EC0A4AFD71E"] = {
        gameInfo = {
            gameCode = "BPGE",
            gameName = "Pokemon LeafGreen (USA)",
            versionName = "Pokemon LeafGreen",
            versionColor = "LeafGreen",
            generation = 3,
            platform = "GBA",
            isRomhack = false
        },
        addresses = {
            -- First 2 numbers determine domain
            -- 02 = EWRAM, 08 = ROM
            partyAddr =             "02024284",
            enemyPartyAddr =        "0202402C",
            gBattleMons =           "02023BE4",
            speciesDataTable =      "0825477C",
            speciesNameTable =      "08245EBC",
            itemNameTable =         "083DAE64",
            naturePointersAddr =    "08463880",
            abilityNameTable =      "0824FC40",
            moveNameTable =         "08247094"
        },
        trainerPointers = {
            isPointer = true,
            saveBlock1 = "03005008",
            saveBlock2 = "0300500C",
        },
        pocketSize = {
            pcCount = 30,
            itemsPocket = 42,
            keyItemsPocket = 30,
            ballsPocket = 13,
            tmhmPocket = 58,
            berriesPocket = 43
        },
        trainerOffsets = {
            -- Info
            name = 0x00,
            gender = 0x08,
            trainerID = 0x0A,
            encryptionKey = 0xF20,
            -- Currency
            money = 0x290,
            coins = 0x294,
            -- Bags
            pcItems = 0x298,
            itemsPocket = 0x310,
            keyItemsPocket = 0x3B8,
            ballsPocket = 0x430,
            tmhmPocket = 0x464,
            berriesPocket = 0x54C,
            -- Flags
            flags = 0x0EE0,
            -- Badge Offset
            -- Offset from flags address
            badgeFlags = 0x104
        }
    },

    -- MARK: Radical Red
    ["964F951A0FDAF209E4EA1344883EF0D557BB3A80"] = {
        gameInfo = {
            gameCode = "BPRE",
            gameName = "Pokemon Radical Red",
            versionName = "Pokemon Radical Red",
            versionColor = "RadicalRed",
            generation = "CFRU",
            platform = "GBA",
            isRomhack = true
        },
        addresses = {
            -- First 2 numbers determine domain
            -- 02 = EWRAM, 08 = ROM
            partyAddr = "02024284",
            enemyPartyAddr = "0202402C", 
            gBattleMons = "02023BE4",
            speciesDataTable = "0817B9908",
            speciesNameTable = "0814042D7",
            moveNamesTable = "0810EEEDC",
            pockets = { -- CFRU Items are 4 bytes each, 2 for ID and 2 for quantity
                itemsPocket = "0203BB20",
                keyItemsPocket = "0203C228",
                ballsPocket = "0203C354",
                tmhmPocket = "0203C41C",
                berriesPocket = "0203C61C"
            }
        },
        trainerPointers = {
            isPointer = false,
            saveBlock1 = "0202552C",
            saveBlock2 = "02024588",
        },
        pocketSize = {
            pcCount = 30,
            itemsPocket = 42,
            keyItemsPocket = 30,
            ballsPocket = 13,
            tmhmPocket = 58,
            berriesPocket = 43
        },
        trainerOffsets = {
            -- Info
            name = 0x00,
            gender = 0x08,
            trainerID = 0x0A,
            encryptionKey = 0xF20,
            -- Currency
            money = 0x290,
            coins = 0x294,
            -- Bags
            pcItems = 0x298,
        }
    },
}

-- Helper function to get game data by hash
function GamesDB.getGameByHash(romHash)
    return GamesDB.games[romHash]
end

function GamesDB.getGameByCode(gameCode)
    for code, game in pairs(GamesDB.games) do
        if game.gameInfo.gameCode == gameCode then
            return game
        end
    end
    return nil
end

-- Helper function to get all games by generation
function GamesDB.getGamesByGeneration(generation)
    local result = {}
    for code, game in pairs(GamesDB.games) do
        if game.gameInfo.generation == generation then
            result[code] = game
        end
    end
    return result
end

-- Helper function to get all games by platform
function GamesDB.getGamesByPlatform(platform)
    local result = {}
    for code, game in pairs(GamesDB.games) do
        if game.gameInfo.platform == platform then
            result[code] = game
        end
    end
    return result
end

-- Helper function to get supported games list
function GamesDB.getSupportedGamesList()
    local games = {}
    for code, game in pairs(GamesDB.games) do
        table.insert(games, game.gameInfo.gameName)
    end
    return games
end

-- Helper function to check if a game is supported
function GamesDB.isGameSupported(romHash)
    return GamesDB.games[romHash] ~= nil
end

return GamesDB
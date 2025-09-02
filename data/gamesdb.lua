-- Pokemon Games Database
-- Consolidated database containing all game information and memory addresses

local GamesDB = {}

GamesDB.games = {
    
    -- ===== GENERATION 1 GAMES =====
    
    -- Pokemon Red (USA)
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
            fishedSpeciesAddr = 0xD059,
            tidAddr = 0xD359
        }
    },
    
    -- Pokemon Blue (USA)
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
            fishedSpeciesAddr = 0xD059,
            tidAddr = 0xD359
        }
    },
    
    -- Pokemon Yellow (USA)
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
            fishedSpeciesAddr = 0xD058,
            tidAddr = 0xD358
        }
    },
    
    -- ===== GENERATION 2 GAMES =====
    
    -- Pokemon Gold (USA)
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
            tidAddr = 0xDA2A
        }
    },
    
    -- Pokemon Silver (USA)
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
            tidAddr = 0xDA2A
        }
    },
    
    -- Pokemon Crystal (USA)
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
            tidAddr = 0xDCDF
        }
    },
    
    -- ===== GENERATION 3 GAMES =====
    
    -- Pokemon Ruby (USA)
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
            partyAddr = "03004360",
            enemyPartyAddr = "2024744",
            gBattleMons = "2024084", 
            speciesDataTable = "81FEC34",
        }
    },
    
    -- Pokemon Sapphire (USA)
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
            partyAddr = "03004360",
            enemyPartyAddr = "2024744",
            gBattleMons = "2024084", 
            speciesDataTable = "81FEBA8",
        }
    },
    
    -- Pokemon Emerald (USA)
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
            partyAddr = "20244EC",
            enemyPartyAddr = "2024744",
            gBattleMons = "2024084", 
            speciesDataTable = "83203CC",
        }
    },
    
    -- Pokemon FireRed (USA)
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
            partyAddr = "02024284",
            enemyPartyAddr = "0202402C", 
            gBattleMons = "02023BE4",
            speciesDataTable = "082547A0",
        }
    },
    
    -- Pokemon LeafGreen (USA)
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
            partyAddr = "02024284",
            enemyPartyAddr = "0202402C",
            gBattleMons = "02023BE4",
            speciesDataTable = "0825477C",
        }
    },

    -- Pokemon Radical Red
    ["964F951A0FDAF209E4EA1344883EF0D557BB3A80"] = {
        gameInfo = {
            gameCode = "BPRE",
            gameName = "Pokemon Radical Red",
            versionName = "Pokemon Radical Red",
            versionColor = "RadicalRed",
            generation = 3,
            platform = "GBA",
            isRomhack = true
        },
        addresses = {
            partyAddr = "02024284",
            enemyPartyAddr = "0202402C", 
            gBattleMons = "02023BE4",
            speciesDataTable = "082547A0",
            speciesNameTable = "814042CC",
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
-- Game Configuration
-- ROM addresses and settings for supported Pokemon games

local gameConfig = {
    games = {
        ["BPRE"] = {
            name = "Pokemon FireRed (USA)",
            generation = 3,
            addresses = {
                speciesNameTable = 0x8245EE0,
                speciesDataTable = 0x82547A0
            }
        },
        ["BPGE"] = {
            name = "Pokemon LeafGreen (USA)",
            generation = 3,
            addresses = {
                speciesNameTable = 0x8245ebc,
                speciesDataTable = 0x825477C
            }
        },
        ["AXVE"] = {
            name = "Pokemon Ruby (USA)",
            generation = 3,
            addresses = {
                speciesNameTable = 0x81F7184,
                speciesDataTable = 0x81FEC34
            }
        },
        ["AXPE"] = {
            name = "Pokemon Sapphire (USA)",
            generation = 3,
            addresses = {
                speciesNameTable = 0x81f70fc,
                speciesDataTable = 0x81FEBC4
            }
        },
        ["BPEE"] = {
            name = "Pokemon Emerald (USA)",
            generation = 3,
            addresses = {
                speciesNameTable = 0x83185C8,
                speciesDataTable = 0x83203E8
            }
        }
    },
    
    dataStructures = {
        generation3 = {
            pokemonSize = 100,
            speciesDataSize = 28,
            speciesNameLength = 11
        }
    }
}

return gameConfig
local PartyReader = require("readers.partyreader")
local MemoryReader = require("core.memoryreader")
local gameUtils = require("utils.gameutils")
local charmaps = require("data.charmaps")
local constants = require("data.constants")

local Gen2PartyReader = {}
Gen2PartyReader.__index = Gen2PartyReader
setmetatable(Gen2PartyReader, {__index = PartyReader})


function Gen2PartyReader:new()
    local obj = PartyReader:new()
    setmetatable(obj, Gen2PartyReader)
    return obj
end

function Gen2PartyReader:readParty(addresses, gameCode)
    if not addresses.partyAddr or not addresses.partySlotsCounterAddr then
        return {}
    end
    
    -- Use addresses directly as they're already numbers in the game detection
    local partyAddr = addresses.partyAddr
    local partySlotsCounterAddr = addresses.partySlotsCounterAddr
    local partyNicknamesAddr = addresses.partyNicknamesAddr
    
    local partySlotsCounter = memory.readbyte(partySlotsCounterAddr)
    local party = {}
    
    for i = 0, math.min(partySlotsCounter - 1, 5) do
        party[i + 1] = self:readPokemon(partyAddr, i, gameCode, partyNicknamesAddr)
    end
    
    return party
end

function Gen2PartyReader:readPokemon(partyAddr, slot, gameCode, partyNicknamesAddr)
    -- Gen2 party structure: each Pokemon is 0x30 (48) bytes
    local pokemonStart = partyAddr + (slot * 0x30)
    
    -- Read species ID
    local speciesId = memory.readbyte(pokemonStart)
    if speciesId == 0 then
        return {pokemonID = 0}
    end
    
    -- Read basic data
    local heldItem = memory.readbyte(pokemonStart + 0x1)
    local move1 = memory.readbyte(pokemonStart + 0x2)
    local move2 = memory.readbyte(pokemonStart + 0x3)
    local move3 = memory.readbyte(pokemonStart + 0x4)
    local move4 = memory.readbyte(pokemonStart + 0x5)
    local otid = memory.read_u16_be(pokemonStart + 0x6)
    
    -- Experience (3 bytes, big endian)
    local expAddr = pokemonStart + 0x8
    local experience = (0x10000 * memory.readbyte(expAddr)) + 
                      (0x100 * memory.readbyte(expAddr + 0x1)) + 
                      memory.readbyte(expAddr + 0x2)
    
    -- HP EVs (called Stat Experience in Gen2) - 2 bytes each
    local hpEV = memory.read_u16_be(pokemonStart + 0xB)
    local attackEV = memory.read_u16_be(pokemonStart + 0xD)
    local defenseEV = memory.read_u16_be(pokemonStart + 0xF)
    local speedEV = memory.read_u16_be(pokemonStart + 0x11)
    local specialEV = memory.read_u16_be(pokemonStart + 0x13)
    
    -- DVs (Determinant Values) - 2 bytes
    local dvsAddr = pokemonStart + 0x15
    local atkDV, defDV, speDV, spcDV = self:getDVs(dvsAddr)
    local hpDV = self:calculateHPDV(atkDV, defDV, speDV, spcDV)
    
    -- PP (4 bytes)
    local pp1 = memory.readbyte(pokemonStart + 0x17)
    local pp2 = memory.readbyte(pokemonStart + 0x18)
    local pp3 = memory.readbyte(pokemonStart + 0x19)
    local pp4 = memory.readbyte(pokemonStart + 0x1A)
    
    -- Friendship (Gen2 introduced this)
    local friendship = memory.readbyte(pokemonStart + 0x1B)
    
    -- Pokerus
    local pokerus = memory.readbyte(pokemonStart + 0x1C)
    
    -- Caught data (2 bytes)
    local caughtData = memory.read_u16_be(pokemonStart + 0x1D)
    
    -- Level
    local level = memory.readbyte(pokemonStart + 0x1F)
    
    -- Status condition
    local status = memory.readbyte(pokemonStart + 0x20)
    
    -- Current HP
    local curHP = memory.read_u16_be(pokemonStart + 0x22)
    local maxHP = memory.read_u16_be(pokemonStart + 0x24)
    local attack = memory.read_u16_be(pokemonStart + 0x26)
    local defense = memory.read_u16_be(pokemonStart + 0x28)
    local speed = memory.read_u16_be(pokemonStart + 0x2A)
    local special = memory.read_u16_be(pokemonStart + 0x2C)
    
    -- Get species name  
    local speciesName = constants.pokemonData.species[speciesId + 1] or "Unknown"
    
    -- Get types from species lookup (since ROM addresses aren't easily accessible)
    local type1, type2 = self:getSpeciesTypes(speciesId)
    
    -- Read nickname from separate nickname area
    local nickname = ""
    if partyNicknamesAddr then
        local nicknameAddr = partyNicknamesAddr + (slot * 11) -- Each nickname is 11 bytes
        for i = 0, 10 do
            local byte = memory.readbyte(nicknameAddr + i)
            if byte == 0x50 then -- Gen2 string terminator
                break
            elseif byte ~= 0 then
                local char = charmaps.GBCharmap[byte] or ""
                nickname = nickname .. char
            end
        end
    end
    
    -- Use species name as fallback if nickname is empty
    if nickname == "" then
        nickname = speciesName
    end
    
    -- Calculate nature from experience (for compatibility with Gen3+ display)
    local nature = experience % 25
    local natureName = constants.pokemonData.nature[nature + 1] or "Hardy"
    
    -- Check if shiny (Gen2 shiny determination - same as Gen1)
    local isShiny = self:isShinyGen2(atkDV, defDV, speDV, spcDV)
    
    return {
        pokemonID = speciesId,
        speciesName = speciesName,
        nickname = nickname,
        level = level,
        curHP = curHP,
        maxHP = maxHP,
        attack = attack,
        defense = defense,
        speed = speed,
        spAttack = special,
        spDefense = special, -- Gen2 still uses same stat for SpAtk and SpDef
        type1 = type1,
        type2 = type2,
        type1Name = self:getTypeName(type1),
        type2Name = self:getTypeName(type2),
        status = status,
        experience = experience,
        nature = 0,          -- Gen2 doesn't have natures,
        natureName = "None", -- Gen2 doesn't have natures
        move1 = move1,
        move2 = move2,
        move3 = move3,
        move4 = move4,
        pp1 = pp1,
        pp2 = pp2,
        pp3 = pp3,
        pp4 = pp4,
        evHP = hpEV,
        evAttack = attackEV,
        evDefense = defenseEV,
        evSpeed = speedEV,
        evSpAttack = specialEV,
        evSpDefense = specialEV,
        ivHP = hpDV,
        ivAttack = atkDV,
        ivDefense = defDV,
        ivSpeed = speDV,
        ivSpAttack = spcDV,
        ivSpDefense = spcDV,
        tid = otid,
        sid = 0, -- Gen2 doesn't have SID
        isShiny = isShiny,
        heldItem = constants.getItemName(heldItem, 2),
        heldItemId = heldItem,
        friendship = friendship,
        ability = 0, -- Gen2 doesn't have abilities
        abilityName = "None",
        abilityID = 0,
        hiddenPower = 0, -- Gen2 doesn't have hidden power
        hiddenPowerName = "None",
        pokerus = pokerus
    }
end

function Gen2PartyReader:getDVs(dvsAddr)
    -- Read the 2-byte DV value (same structure as Gen1)
    local atkDefDVs = memory.readbyte(dvsAddr)
    local speSpcDVs = memory.readbyte(dvsAddr + 0x1)
    
    local atkDV = atkDefDVs >> 4
    local defDV = atkDefDVs & 0xF
    local speDV = speSpcDVs >> 4
    local spcDV = speSpcDVs & 0xF
    
    return atkDV, defDV, speDV, spcDV
end

function Gen2PartyReader:calculateHPDV(atkDV, defDV, speDV, spcDV)
    return ((atkDV % 2) * 8) + ((defDV % 2) * 4) + ((speDV % 2) * 2) + (spcDV % 2)
end

function Gen2PartyReader:isShinyGen2(atkDV, defDV, speDV, spcDV)
    -- Gen2 shiny determination (same as Gen1)
    return defDV == 0xA and speDV == 0xA and spcDV == 0xA and
           (atkDV == 0x2 or atkDV == 0x3 or atkDV == 0x6 or atkDV == 0x7 or
            atkDV == 0xA or atkDV == 0xB or atkDV == 0xE or atkDV == 0xF)
end

function Gen2PartyReader:getTypeName(typeId)
    return constants.pokemonData.type[typeId + 1] or "Unknown"
end

function Gen2PartyReader:getSpeciesTypes(speciesId)
    -- Gen2 Pokemon type mapping (Pokedex order 1-251)
    -- Format: [speciesId] = {type1, type2} using 0-based type indices
    local speciesTypes = {
        [1] = {12, 3}, [2] = {12, 3}, [3] = {12, 3}, [4] = {10, 10}, [5] = {10, 10},
        [6] = {10, 2}, [7] = {11, 11}, [8] = {11, 11}, [9] = {11, 11}, [10] = {6, 6},
        [11] = {6, 6}, [12] = {6, 2}, [13] = {6, 3}, [14] = {6, 3}, [15] = {6, 3},
        [16] = {0, 2}, [17] = {0, 2}, [18] = {0, 2}, [19] = {0, 0}, [20] = {0, 0},
        [21] = {0, 2}, [22] = {0, 2}, [23] = {3, 3}, [24] = {3, 3}, [25] = {13, 13},
        [26] = {13, 13}, [27] = {4, 4}, [28] = {4, 4}, [29] = {3, 3}, [30] = {3, 3},
        [31] = {3, 4}, [32] = {3, 3}, [33] = {3, 3}, [34] = {3, 4}, [35] = {0, 0},
        [36] = {0, 0}, [37] = {10, 10}, [38] = {10, 10}, [39] = {0, 0}, [40] = {0, 0},
        [41] = {3, 2}, [42] = {3, 2}, [43] = {12, 3}, [44] = {12, 3}, [45] = {12, 3},
        [46] = {6, 12}, [47] = {6, 12}, [48] = {6, 3}, [49] = {6, 3}, [50] = {4, 4},
        [51] = {4, 4}, [52] = {0, 0}, [53] = {0, 0}, [54] = {11, 11}, [55] = {11, 14},
        [56] = {1, 1}, [57] = {1, 1}, [58] = {10, 10}, [59] = {10, 10}, [60] = {11, 11},
        [61] = {11, 11}, [62] = {11, 1}, [63] = {14, 14}, [64] = {14, 14}, [65] = {14, 14},
        [66] = {1, 1}, [67] = {1, 1}, [68] = {1, 1}, [69] = {12, 3}, [70] = {12, 3},
        [71] = {12, 3}, [72] = {11, 3}, [73] = {11, 3}, [74] = {5, 4}, [75] = {5, 4},
        [76] = {5, 4}, [77] = {10, 10}, [78] = {10, 10}, [79] = {11, 14}, [80] = {11, 14},
        [81] = {13, 8}, [82] = {13, 8}, [83] = {0, 2}, [84] = {0, 2}, [85] = {0, 2},
        [86] = {11, 11}, [87] = {11, 15}, [88] = {3, 3}, [89] = {3, 3}, [90] = {11, 11},
        [91] = {11, 15}, [92] = {7, 3}, [93] = {7, 3}, [94] = {7, 3}, [95] = {5, 4},
        [96] = {14, 14}, [97] = {14, 14}, [98] = {11, 11}, [99] = {11, 11}, [100] = {13, 13},
        [101] = {13, 13}, [102] = {12, 14}, [103] = {12, 14}, [104] = {4, 4}, [105] = {4, 4},
        [106] = {1, 1}, [107] = {1, 1}, [108] = {0, 0}, [109] = {3, 3}, [110] = {3, 3},
        [111] = {4, 5}, [112] = {4, 5}, [113] = {0, 0}, [114] = {12, 12}, [115] = {0, 0},
        [116] = {11, 11}, [117] = {11, 11}, [118] = {11, 11}, [119] = {11, 11}, [120] = {11, 11},
        [121] = {11, 14}, [122] = {14, 14}, [123] = {6, 2}, [124] = {15, 14}, [125] = {13, 13},
        [126] = {10, 10}, [127] = {6, 6}, [128] = {0, 0}, [129] = {11, 11}, [130] = {11, 2},
        [131] = {11, 15}, [132] = {0, 0}, [133] = {0, 0}, [134] = {11, 11}, [135] = {13, 13},
        [136] = {10, 10}, [137] = {0, 0}, [138] = {5, 11}, [139] = {5, 11}, [140] = {5, 11},
        [141] = {5, 11}, [142] = {5, 2}, [143] = {0, 0}, [144] = {15, 2}, [145] = {13, 2},
        [146] = {10, 2}, [147] = {16, 16}, [148] = {16, 16}, [149] = {16, 2}, [150] = {14, 14},
        [151] = {14, 14},
        -- Gen 2 Pokemon (152-251)
        [152] = {12, 12}, [153] = {12, 12}, [154] = {12, 12}, [155] = {10, 10}, [156] = {10, 10},
        [157] = {10, 10}, [158] = {11, 11}, [159] = {11, 11}, [160] = {11, 11}, [161] = {0, 0},
        [162] = {0, 0}, [163] = {0, 2}, [164] = {0, 2}, [165] = {6, 2}, [166] = {6, 2},
        [167] = {6, 3}, [168] = {6, 3}, [169] = {3, 2}, [170] = {11, 13}, [171] = {11, 13},
        [172] = {13, 13}, [173] = {0, 0}, [174] = {0, 0}, [175] = {0, 0}, [176] = {0, 2},
        [177] = {14, 2}, [178] = {14, 2}, [179] = {13, 13}, [180] = {13, 13}, [181] = {13, 13},
        [182] = {12, 12}, [183] = {11, 11}, [184] = {11, 11}, [185] = {5, 5}, [186] = {11, 11},
        [187] = {12, 2}, [188] = {12, 2}, [189] = {12, 2}, [190] = {0, 0}, [191] = {12, 12},
        [192] = {12, 12}, [193] = {6, 2}, [194] = {11, 4}, [195] = {11, 4}, [196] = {14, 14},
        [197] = {17, 17}, [198] = {17, 2}, [199] = {11, 14}, [200] = {7, 7}, [201] = {14, 14},
        [202] = {14, 14}, [203] = {0, 14}, [204] = {6, 6}, [205] = {6, 8}, [206] = {0, 0},
        [207] = {4, 2}, [208] = {8, 4}, [209] = {0, 0}, [210] = {0, 0}, [211] = {11, 3},
        [212] = {6, 8}, [213] = {6, 5}, [214] = {1, 6}, [215] = {17, 15}, [216] = {0, 0},
        [217] = {0, 0}, [218] = {10, 10}, [219] = {10, 5}, [220] = {15, 4}, [221] = {15, 4},
        [222] = {11, 5}, [223] = {11, 11}, [224] = {11, 11}, [225] = {15, 2}, [226] = {11, 2},
        [227] = {8, 2}, [228] = {17, 10}, [229] = {17, 10}, [230] = {11, 16}, [231] = {4, 4},
        [232] = {4, 4}, [233] = {0, 0}, [234] = {0, 0}, [235] = {0, 0}, [236] = {1, 1},
        [237] = {1, 1}, [238] = {15, 14}, [239] = {13, 13}, [240] = {10, 10}, [241] = {0, 0},
        [242] = {0, 0}, [243] = {13, 13}, [244] = {10, 10}, [245] = {11, 11}, [246] = {5, 4},
        [247] = {5, 4}, [248] = {5, 17}, [249] = {14, 2}, [250] = {10, 2}, [251] = {14, 12}
    }
    
    local types = speciesTypes[speciesId]
    if types then
        return types[1], types[2]
    else
        return 0, 0 -- Default to Normal/Normal
    end
end

return Gen2PartyReader
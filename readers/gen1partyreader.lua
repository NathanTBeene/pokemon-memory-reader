local PartyReader = require("readers.partyreader")
local MemoryReader = require("core.memoryreader")
local gameUtils = require("utils.gameutils")
local charmaps = require("data.charmaps")
local constants = require("data.constants")

local Gen1PartyReader = {}
Gen1PartyReader.__index = Gen1PartyReader
setmetatable(Gen1PartyReader, {__index = PartyReader})

-- Gen1 species list (based on internal species order, not Pokedex order)
local speciesNamesList = {
    "Rhydon", "Kangaskhan", "Nidoran♂", "Clefairy", "Spearow", "Voltorb", "Nidoking", "Slowbro",
    "Ivysaur", "Exeggutor", "Lickitung", "Exeggcute", "Grimer", "Gengar", "Nidoran♀", "Nidoqueen",
    "Cubone", "Rhyhorn", "Lapras", "Arcanine", "Mew", "Gyarados", "Shellder", "Tentacool", "Gastly",
    "Scyther", "Staryu", "Blastoise", "Pinsir", "Tangela", "MissingNo.", "MissingNo.", "Growlithe",
    "Onix", "Fearow", "Pidgey", "Slowpoke", "Kadabra", "Graveler", "Chansey", "Machoke", "Mr. Mime",
    "Hitmonlee", "Hitmonchan", "Arbok", "Parasect", "Psyduck", "Drowzee", "Golem", "MissingNo.",
    "Magmar", "MissingNo.", "Electabuzz", "Magneton", "Koffing", "MissingNo.", "Mankey", "Seel",
    "Diglett", "Tauros", "MissingNo.", "MissingNo.", "MissingNo.", "Farfetch'd", "Venonat",
    "Dragonite", "MissingNo.", "MissingNo.", "MissingNo.", "Doduo", "Poliwag", "Jynx", "Moltres",
    "Articuno", "Zapdos", "Ditto", "Meowth", "Krabby", "MissingNo.", "MissingNo.", "MissingNo.",
    "Vulpix", "Ninetales", "Pikachu", "Raichu", "MissingNo.", "MissingNo.", "Dratini", "Dragonair",
    "Kabuto", "Kabutops", "Horsea", "Seadra", "MissingNo.", "MissingNo.", "Sandshrew", "Sandslash",
    "Omanyte", "Omastar", "Jigglypuff", "Wigglytuff", "Eevee", "Flareon", "Jolteon", "Vaporeon",
    "Machop", "Zubat", "Ekans", "Paras", "Poliwhirl", "Poliwrath", "Weedle", "Kakuna", "Beedrill",
    "MissingNo.", "Dodrio", "Primeape", "Dugtrio", "Venomoth", "Dewgong", "MissingNo.", "MissingNo.",
    "Caterpie", "Metapod", "Butterfree", "Machamp", "MissingNo.", "Golduck", "Hypno", "Golbat",
    "Mewtwo", "Snorlax", "Magikarp", "MissingNo.", "MissingNo.", "Muk", "MissingNo.", "Kingler",
    "Cloyster", "MissingNo.", "Electrode", "Clefable", "Weezing", "Persian", "Marowak", "MissingNo.",
    "Haunter", "Abra", "Alakazam", "Pidgeotto", "Pidgeot", "Starmie", "Bulbasaur", "Venusaur",
    "Tentacruel", "MissingNo.", "Goldeen", "Seaking", "MissingNo.", "MissingNo.", "MissingNo.",
    "MissingNo.", "Ponyta", "Rapidash", "Rattata", "Raticate", "Nidorino", "Nidorina", "Geodude",
    "Porygon", "Aerodactyl", "MissingNo.", "Magnemite", "MissingNo.", "MissingNo.", "Charmander",
    "Squirtle", "Charmeleon", "Wartortle", "Charizard", "MissingNo.", "MissingNo.", "MissingNo.",
    "MissingNo.", "Oddish", "Gloom", "Vileplume", "Bellsprout", "Weepinbell", "Victreebel"
}

function Gen1PartyReader:new()
    local obj = PartyReader:new()
    setmetatable(obj, Gen1PartyReader)
    return obj
end

function Gen1PartyReader:readParty(addresses, gameCode)
    if not addresses.partyAddr or not addresses.partySlotsCounterAddr then
        return {}
    end
    
    -- Use addresses directly as they're already numbers in the game detection
    local partyAddr = addresses.partyAddr
    local partySlotsCounterAddr = addresses.partySlotsCounterAddr
    local partyNicknamesAddr = addresses.partyNicknamesAddr
    
    local partySlotsCounter = memory.readbyte(partySlotsCounterAddr) - 1
    local party = {}
    
    for i = 0, math.min(partySlotsCounter, 5) do
        party[i + 1] = self:readPokemon(partyAddr, i, gameCode, partyNicknamesAddr)
    end
    
    return party
end

function Gen1PartyReader:readPokemon(partyAddr, slot, gameCode, partyNicknamesAddr)
    -- Gen1 party structure: each Pokemon is 0x2C (44) bytes
    local pokemonStart = partyAddr + (slot * 0x2C)
    
    -- Read species ID
    local speciesId = memory.readbyte(pokemonStart)
    if speciesId == 0 then
        return {pokemonID = 0}
    end
    
    -- Read basic data
    local curHP = memory.read_u16_be(pokemonStart + 0x1)
    local level = memory.readbyte(pokemonStart + 0x21) -- Actual level, not false level at 0x3
    local status = memory.readbyte(pokemonStart + 0x4)
    local type1 = memory.readbyte(pokemonStart + 0x5)
    local type2 = memory.readbyte(pokemonStart + 0x6)
    local catchRate = memory.readbyte(pokemonStart + 0x7)
    local move1 = memory.readbyte(pokemonStart + 0x8)
    local move2 = memory.readbyte(pokemonStart + 0x9)
    local move3 = memory.readbyte(pokemonStart + 0xA)
    local move4 = memory.readbyte(pokemonStart + 0xB)
    local otid = memory.read_u16_be(pokemonStart + 0xC)
    
    -- Experience (3 bytes, big endian) - following working example
    local expAddr = pokemonStart + 0xE
    local experience = (0x10000 * memory.readbyte(expAddr)) + 
                      (0x100 * memory.readbyte(expAddr + 0x1)) + 
                      memory.readbyte(expAddr + 0x2)
    
    -- HP EVs and stats (2 bytes each)
    local hpEV = memory.read_u16_be(pokemonStart + 0x11)
    local attackEV = memory.read_u16_be(pokemonStart + 0x13)
    local defenseEV = memory.read_u16_be(pokemonStart + 0x15)
    local speedEV = memory.read_u16_be(pokemonStart + 0x17)
    local specialEV = memory.read_u16_be(pokemonStart + 0x19)
    
    -- DVs (Determinant Values) - 2 bytes
    local dvsAddr = pokemonStart + 0x1B
    local atkDV, defDV, speDV, spcDV = self:getDVs(dvsAddr)
    local hpDV = self:calculateHPDV(atkDV, defDV, speDV, spcDV)
    
    -- PP (4 bytes)
    local pp1 = memory.readbyte(pokemonStart + 0x1D)
    local pp2 = memory.readbyte(pokemonStart + 0x1E)
    local pp3 = memory.readbyte(pokemonStart + 0x1F)
    local pp4 = memory.readbyte(pokemonStart + 0x20)
    
    -- Stats
    local maxHP = memory.read_u16_be(pokemonStart + 0x22)
    local attack = memory.read_u16_be(pokemonStart + 0x24)
    local defense = memory.read_u16_be(pokemonStart + 0x26)
    local speed = memory.read_u16_be(pokemonStart + 0x28)
    local special = memory.read_u16_be(pokemonStart + 0x2A)
    
    -- Get species name
    local speciesName = speciesNamesList[speciesId] or "Unknown"
    
    -- Read nickname from separate nickname area
    local nickname = ""
    if partyNicknamesAddr then
        local nicknameAddr = partyNicknamesAddr + (slot * 11) -- Each nickname is 11 bytes
        for i = 0, 10 do
            local byte = memory.readbyte(nicknameAddr + i)
            if byte == 0x50 then -- Gen1 string terminator
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

    -- Check if shiny (Gen1 shiny determination)
    local isShiny = self:isShinyGen1(atkDV, defDV, speDV, spcDV)
    
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
        spDefense = special, -- Gen1 uses same stat for SpAtk and SpDef
        type1 = type1,
        type2 = type2,
        type1Name = self:getTypeName(type1),
        type2Name = self:getTypeName(type2),
        status = status,
        experience = experience,
        nature = 0,          -- Gen1 doesn't have natures
        natureName = "None", -- Gen1 doesn't have natures
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
        sid = 0, -- Gen1 doesn't have SID
        isShiny = isShiny,
        heldItem = "None", -- Gen1 doesn't have held items
        friendship = 0, -- Gen1 doesn't have friendship
        ability = 0, -- Gen1 doesn't have abilities
        abilityName = "None",
        abilityID = 0,
        hiddenPower = 0, -- Gen1 doesn't have hidden power
        hiddenPowerName = "None"
    }
end

function Gen1PartyReader:getDVs(dvsAddr)
    -- Read the 2-byte DV value
    local atkDefDVs = memory.readbyte(dvsAddr)
    local speSpcDVs = memory.readbyte(dvsAddr + 0x1)
    
    local atkDV = atkDefDVs >> 4
    local defDV = atkDefDVs & 0xF
    local speDV = speSpcDVs >> 4
    local spcDV = speSpcDVs & 0xF
    
    return atkDV, defDV, speDV, spcDV
end

function Gen1PartyReader:calculateHPDV(atkDV, defDV, speDV, spcDV)
    return ((atkDV % 2) * 8) + ((defDV % 2) * 4) + ((speDV % 2) * 2) + (spcDV % 2)
end

function Gen1PartyReader:isShinyGen1(atkDV, defDV, speDV, spcDV)
    -- Gen1 shiny determination (same as Gen2 since shiny was retroactive)
    return defDV == 0xA and speDV == 0xA and spcDV == 0xA and
           (atkDV == 0x2 or atkDV == 0x3 or atkDV == 0x6 or atkDV == 0x7 or
            atkDV == 0xA or atkDV == 0xB or atkDV == 0xE or atkDV == 0xF)
end

function Gen1PartyReader:getTypeName(typeId)
    -- Gen1 type IDs (different from later generations)
    local typeNames = {
        [0x00] = "Normal",
        [0x01] = "Fighting", 
        [0x02] = "Flying",
        [0x03] = "Poison",
        [0x04] = "Ground",
        [0x05] = "Rock",
        [0x07] = "Bug",
        [0x08] = "Ghost",
        [0x14] = "Fire",
        [0x15] = "Water", 
        [0x16] = "Grass",
        [0x17] = "Electric",
        [0x18] = "Psychic",
        [0x19] = "Ice",
        [0x1A] = "Dragon"
    }
    return typeNames[typeId] or ("Unknown(" .. typeId .. ")")
end



return Gen1PartyReader
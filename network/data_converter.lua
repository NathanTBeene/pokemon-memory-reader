-- Data Converter - Transforms internal Pokemon data to API format
-- Handles reading party data from memory and converting to JSON-friendly format

local DataConverter = {}

function DataConverter.getPartyData(memoryReader)
    -- Read party based on game generation
    local gameCode = memoryReader.currentGame and 
        require("utils.gameutils").gameCodeToString(memoryReader.currentGame.gameInfo.gameCode) or ""
    local party
    
    if memoryReader.currentGame.gameInfo.generation == 1 or memoryReader.currentGame.gameInfo.generation == 2 then
        -- Gen1 and Gen2 use similar address structure
        party = memoryReader.partyReader:readParty(memoryReader.currentGame.addresses, gameCode)
    else
        -- Gen3 and CFRU use partyAddr address
        if not memoryReader.currentGame.addresses.partyAddr then
            return {error = "Player party address not available"}
        end
        local gameUtils = require("utils.gameutils")
        local partyAddr = gameUtils.hexToNumber(memoryReader.currentGame.addresses.partyAddr)
        party = memoryReader.partyReader:readParty({partyAddr = partyAddr}, gameCode)
    end
    
    -- Convert to API format
    local apiParty = {}
    local pokemonData = require("readers.pokemondata")
    
    for i = 1, 6 do
        local pokemon = party[i]
        if pokemon and pokemon.speciesID > 0 then
            -- Build moves arrays (only include non-zero moves)
            local moves = {}
            local moveNames = {}
            if pokemon.move1 and pokemon.move1 > 0 then 
                table.insert(moves, pokemon.move1)
                table.insert(moveNames, pokemonData.getMoveName(pokemon.move1))
            end
            if pokemon.move2 and pokemon.move2 > 0 then 
                table.insert(moves, pokemon.move2)
                table.insert(moveNames, pokemonData.getMoveName(pokemon.move2))
            end
            if pokemon.move3 and pokemon.move3 > 0 then 
                table.insert(moves, pokemon.move3)
                table.insert(moveNames, pokemonData.getMoveName(pokemon.move3))
            end
            if pokemon.move4 and pokemon.move4 > 0 then 
                table.insert(moves, pokemon.move4)
                table.insert(moveNames, pokemonData.getMoveName(pokemon.move4))
            end
            
            -- Build types array
            local types = {pokemon.type1Name}
            if pokemon.type2Name and pokemon.type2Name ~= pokemon.type1Name then
                table.insert(types, pokemon.type2Name)
            end
            
            local apiPokemon = {
                nickname = pokemon.nickname or pokemon.speciesName,
                species = pokemon.speciesName,
                speciesId = pokemon.speciesID,
                level = pokemon.level,
                nature = pokemon.natureName,
                currentHP = pokemon.curHP,
                maxHP = pokemon.maxHP,
                IVs = {
                    hp = pokemon.ivHP,
                    attack = pokemon.ivAttack,
                    defense = pokemon.ivDefense,
                    specialAttack = pokemon.ivSpAttack,
                    specialDefense = pokemon.ivSpDefense,
                    speed = pokemon.ivSpeed
                },
                EVs = {
                    hp = pokemon.evHP,
                    attack = pokemon.evAttack,
                    defense = pokemon.evDefense,
                    specialAttack = pokemon.evSpAttack,
                    specialDefense = pokemon.evSpDefense,
                    speed = pokemon.evSpeed
                },
                moves = moves,
                moveNames = moveNames,
                heldItem = pokemon.heldItem,
                heldItemId = pokemon.heldItemId,
                status = DataConverter.getStatusName(pokemon.status),
                friendship = pokemon.friendship,
                abilityIndex = pokemon.ability,
                abilityId = pokemon.abilityID,
                ability = pokemon.abilityName,
                hiddenPower = pokemon.hiddenPowerName,
                isShiny = pokemon.isShiny or false,
                types = types
            }
            
            table.insert(apiParty, apiPokemon)
        end
    end
    
    return apiParty
end

function DataConverter.getStatusName(statusValue)
    if not statusValue or statusValue == 0 then
        return "Healthy"
    end

    local statusNames = {"Asleep", "Poisoned", "Burned", "Frozen", "Paralyzed", "Toxic"}
    return statusNames[statusValue] or "Unknown"
end

function DataConverter.getBagData(memoryReader)
    if not memoryReader.playerReader then
        return {error = "Player reader not available"}
    end

    local playerReader = memoryReader.playerReader
    if not playerReader.trainerInfo then
        return {error = "Trainer info not available"}
    end

    local bag = playerReader:readBag()
    local apiBag = {
        items = {},
        keyItems = {},
        pokeballs = {},
        tmsHms = {},
        pcItems = {}
    }
    for _, item in ipairs(bag.items or {}) do
        if item.id and item.id > 0 then
            table.insert(apiBag.items, {id = item.id, name = item.name, quantity = item.quantity})
        end
    end
    for _, keyItem in ipairs(bag.keyItems or {}) do
        if keyItem.id and keyItem.id > 0 then
            table.insert(apiBag.keyItems, {id = keyItem.id, name = keyItem.name, quantity = keyItem.quantity})
        end
    end
    for _, pcItem in ipairs(bag.pcItems or {}) do
        if pcItem.id and pcItem.id > 0 then
            table.insert(apiBag.pcItems, {id = pcItem.id, name = pcItem.name, quantity = pcItem.quantity})
        end
    end
    for _, ball in ipairs(bag.pokeballs or {}) do
        if ball.id and ball.id > 0 then
            table.insert(apiBag.pokeballs, {id = ball.id, name = ball.name, quantity = ball.quantity})
        end
    end
    for _, pcItem in ipairs(bag.berries or {}) do
        if pcItem.id and pcItem.id > 0 then
            table.insert(apiBag.berries, {id = pcItem.id, name = pcItem.name, quantity = pcItem.quantity})
        end
    end

    -- TM's and HM's are tms and hms arrays
    local tms = {}
    for _, tm in ipairs(bag.tmsHms.tms or {}) do
        if tm.id and tm.id > 0 then
            table.insert(tms, {id = tm.id, name = tm.name, quantity = tm.quantity})
        end
    end
    local hms = {}
    for _, hm in ipairs(bag.tmsHms.hms or {}) do
        if hm.id and hm.id > 0 then
            table.insert(hms, {id = hm.id, name = hm.name, quantity = hm.quantity})
        end
    end
    apiBag.tmsHms = {tms = tms, hms = hms}
    return apiBag
end

return DataConverter
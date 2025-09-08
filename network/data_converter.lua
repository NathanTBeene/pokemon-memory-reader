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

return DataConverter
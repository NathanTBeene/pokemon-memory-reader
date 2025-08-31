-- Base class for party readers (no direct memory access needed)

local PartyReader = {}
PartyReader.__index = PartyReader

function PartyReader:new()
    local obj = {}
    setmetatable(obj, PartyReader)
    return obj
end

function PartyReader:readParty(addresses)
    error("readParty must be implemented by subclass")
end

function PartyReader:readPokemon(startAddress, slot)
    error("readPokemon must be implemented by subclass")
end

function PartyReader:validatePokemonData(pokemonData)
    if not pokemonData then
        return false
    end
    
    if pokemonData.pokemonID < 0 or pokemonData.pokemonID > 412 then
        return false
    end
    
    if pokemonData.heldItem and (pokemonData.heldItem < 0 or pokemonData.heldItem > 376) then
        return false
    end
    
    local moves = {pokemonData.move1, pokemonData.move2, pokemonData.move3, pokemonData.move4}
    for _, move in ipairs(moves) do
        if move and (move < 0 or move > 354) then
            return false
        end
    end
    
    return true
end

function PartyReader:getPartyCount(addresses)
    return 6
end

return PartyReader
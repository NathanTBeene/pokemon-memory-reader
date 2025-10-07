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

return PartyReader
-- Base class for all generation-specific party readers.

---@class PartyReader
---@field gameEntry GameEntry
local PartyReader = {}
PartyReader.__index = PartyReader

---@generic T : PartyReader
---@param self T
---@param gameEntry GameEntry
---@return T
function PartyReader:new(gameEntry)
    local obj = { gameEntry = gameEntry }
    setmetatable(obj, self)
    return obj
end

--- Read all party slots and return them as an array of up to 6 Pokemon (nil = empty slot).
--- Note: extra arguments accepted temporarily; will be removed in Phase 5 when all
--- readers receive gameEntry on construction and readParty() takes no args.
---@param ... any
---@return (Pokemon?)[]
function PartyReader:readParty(...)
    local _ = {...}  -- absorbed; subclass overrides this
    error("readParty must be implemented by subclass")
end

--- Read a single Pokemon from the given slot (1-based).
---@param slot integer
---@return Pokemon?
---@diagnostic disable-next-line: unused-local
function PartyReader:readPokemon(slot)
    error("readPokemon must be implemented by subclass")
end

return PartyReader

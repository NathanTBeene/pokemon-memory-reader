-- Base class for all generation-specific player/trainer readers.

---@class PlayerReader
---@field gameEntry GameEntry
---@field trainerInfo TrainerInfo
---@field bag Bag
local PlayerReader = {}
PlayerReader.__index = PlayerReader

---@generic T : PlayerReader
---@param self T
---@param gameEntry GameEntry
---@return T
function PlayerReader:new(gameEntry)
    local obj = {
        gameEntry = gameEntry,
        trainerInfo = {
            trainerId = { public = 0, private = 0 },
            name = "",
            gender = "",
            money = 0,
            momMoney = 0,
            coins = 0,
            badges = {},
            encryptionKey = 0,
        },
        bag = {
            pcItems = {},
            items = {},
            keyItems = {},
            pokeballs = {},
            tmhms = {},
            berries = {},
        },
    }
    setmetatable(obj, self)
    return obj
end

--- Read and update trainerInfo from memory.
function PlayerReader:updateTrainerInfo()
    error("updateTrainerInfo must be implemented by subclass")
end

--- Read and update bag from memory.
function PlayerReader:readBag()
    error("readBag must be implemented by subclass")
end

--- Read save sections (Gen 3 only — override in subclass, default is no-op).
function PlayerReader:getSaveSections()
    error("getSaveSections must be implemented by subclass")
end

--- Set player money (Gen 3+ only — not available on all readers).
---@param amount integer
---@return boolean
---@diagnostic disable-next-line: unused-local
function PlayerReader:setMoney(amount)
    error("setMoney is not implemented for this game")
end

--- Print all non-empty bag pockets to the console.
function PlayerReader:printBag()
    self:readBag()
    for pocketName, items in pairs(self.bag) do
        if #items > 0 then
            console.log(pocketName .. ":")
            for _, item in ipairs(items) do
                console.log(string.format("  - %s (ID: %d, Qty: %d)", item.name, item.id, item.quantity))
            end
        end
    end
end

return PlayerReader

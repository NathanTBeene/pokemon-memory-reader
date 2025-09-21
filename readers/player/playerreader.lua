

local PlayerReader = {}
PlayerReader.__index = PlayerReader

function PlayerReader:new()
    local obj = {
      sections = nil,  -- To be defined in subclass
      trainerInfo = {
        trainerId = {id = 0, public = 0, private = 0},
        name = "",
        gender = "",
        money = 0,
        momMoney = 0,
        coins = 0,
        badges = {},
        encryptionKey = 0
      },
      bag = {
        pcItems = {},
        items = {},
        keyItems = {},
        pokeballs = {},
        tmhms = {},
        berries = {}
      }
    }
    setmetatable(obj, PlayerReader)
    return obj
end

function PlayerReader:updateTrainerInfo()
    error("updateTrainerInfo must be implemented by subclass")
end

function PlayerReader:readBag()
    error("readBag must be implemented by subclass")
end

function PlayerReader:getSaveSections()
    error("getSaveSections must be implemented by subclass")
end

-- If pocket is empty, don't print anything
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
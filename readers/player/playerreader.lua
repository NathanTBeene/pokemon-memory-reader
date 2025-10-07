

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

function PlayerReader:printTrainerInfo()
    self:updateTrainerInfo()
    if self.trainerInfo then
        console.log("Trainer Name: " .. self.trainerInfo.name)
        console.log("Money: " .. self.trainerInfo.money)
        if self.trainerINfo.momMoney then
            console.log("Mom's Money: " .. self.trainerInfo.momMoney)
        end
        console.log("Coins: " .. self.trainerInfo.coins)
        console.log("Badges:")
        for _, badge in ipairs(self.trainerInfo.badges) do
            console.log("  - " .. badge.name .. (badge.earned and " (Earned)" or " (Not Earned)"))
        end
        if self.trainerInfo.trainerID then
            console.log("Trainer ID: " .. self.trainerInfo.trainerID.id)
            console.log("Public ID: " .. self.trainerInfo.trainerID.public)
            console.log("Secret ID: " .. self.trainerInfo.trainerID.secret)
        end
    else
        console.log("No trainer info available.")
    end
end

return PlayerReader
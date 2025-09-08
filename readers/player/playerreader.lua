

local PlayerReader = {}
PlayerReader.__index = PlayerReader

function PlayerReader:new()
    local obj = {
      sections = nil,  -- To be defined in subclass
      trainerInfo = nil,
      bag = nil
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

return PlayerReader
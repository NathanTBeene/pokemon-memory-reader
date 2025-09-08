local PlayerReader = require("readers.player.playerreader")

local Gen2PlayerReader = {}
Gen2PlayerReader.__index = Gen2PlayerReader
setmetatable(Gen2PlayerReader, {__index = PlayerReader})

function Gen2PlayerReader:new()
    local obj = PlayerReader:new()
    setmetatable(obj, Gen2PlayerReader)
    return obj
end
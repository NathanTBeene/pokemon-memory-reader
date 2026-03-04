-- Pokemon Memory Reader - Main Script
-- This script initializes the application and manages the game detection system

require("core.memoryreader")   -- establishes the MemoryReader global
local UserCommands = require("commands.usercommands")

-- Register user commands
for name, func in pairs(UserCommands) do
    if type(func) == "function" then
        _G[name] = func
    end
end

-- Initialize on script start
if MemoryReader.initialize() then
    console.log("----- PMR Ready -----")
    console.log("Type help() for a list of commands!")

    -- Register event callbacks
    event.onexit(MemoryReader.shutdown)

    -- Main execution loop
    while true do
        MemoryReader.update()
        emu.frameadvance()
    end
else
    console.log("Initialization failed!")
end

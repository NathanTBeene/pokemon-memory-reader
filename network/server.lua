-- HTTP Server for Pokemon Memory Reader
-- Main server entry point that orchestrates the modular HTTP server components

-- Add LuaSocket path to package path
package.path = package.path .. ";./modules/LuaSocket/?.lua"
package.cpath = package.cpath .. ";./modules/LuaSocket/socket/?.dll;./modules/LuaSocket/mime/?.dll"

local HttpServer = require("network.http_server")

---@class Server
---@field httpServer table
local Server = {}
Server.__index = Server

---@param memoryReader MemoryReader
---@param port? integer
---@param host? string
---@return Server
function Server:new(memoryReader, port, host)
    local obj = setmetatable({}, Server)
    obj.httpServer = HttpServer:new(memoryReader, port, host)
    return obj
end

---@return boolean
function Server:start()
    return self.httpServer:start()
end

---@return boolean
function Server:stop()
    return self.httpServer:stop()
end

function Server:update()
    self.httpServer:update()
end

return Server
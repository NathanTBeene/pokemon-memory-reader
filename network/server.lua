-- HTTP Server for Pokemon Memory Reader
-- Main server entry point that orchestrates the modular HTTP server components

-- Add LuaSocket path to package path
package.path = package.path .. ";./modules/LuaSocket/?.lua"
package.cpath = package.cpath .. ";./modules/LuaSocket/socket/?.dll;./modules/LuaSocket/mime/?.dll"

local HttpServer = require("network.http_server")

local Server = {}
Server.__index = Server

function Server:new(memoryReader, port, host)
    local obj = setmetatable({}, Server)
    obj.httpServer = HttpServer:new(memoryReader, port, host)
    return obj
end

function Server:start()
    return self.httpServer:start()
end

function Server:stop()
    return self.httpServer:stop()
end

function Server:update()
    self.httpServer:update()
end

return Server
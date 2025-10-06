-- HTTP Server Core - Server lifecycle management and request routing
-- Handles socket management, connection handling, and basic HTTP request routing

local socket = require("socket")
local httpUtils = require("network.http_utils")
local apiHandlers = require("network.api_handlers")

local HttpServer = {}
HttpServer.__index = HttpServer

-- Server configuration
local DEFAULT_PORT = 8080
local DEFAULT_HOST = "localhost"

function HttpServer:new(memoryReader, port, host)
    local obj = setmetatable({}, HttpServer)
    obj.memoryReader = memoryReader
    obj.port = port or DEFAULT_PORT
    obj.host = host or DEFAULT_HOST
    obj.server = nil
    obj.isRunning = false
    obj.clients = {}
    
    return obj
end

-- MARK: Control

function HttpServer:start()
    if self.isRunning then
        console.log("Server already running on " .. self.host .. ":" .. self.port)
        return true
    end
    
    self.server = socket.tcp()
    if not self.server then
        console.log("Failed to create server socket")
        return false
    end
    
    -- Set socket to non-blocking mode
    self.server:settimeout(0)
    
    -- Allow address reuse
    self.server:setoption("reuseaddr", true)
    
    local success, err = self.server:bind(self.host, self.port)
    if not success then
        console.log("Failed to bind server to " .. self.host .. ":" .. self.port .. " - " .. (err or "unknown error"))
        self.server:close()
        self.server = nil
        return false
    end
    
    success, err = self.server:listen(5)
    if not success then
        console.log("Failed to listen on server socket - " .. (err or "unknown error"))
        self.server:close()
        self.server = nil
        return false
    end
    
    self.isRunning = true
    console.log("Pokemon Memory Reader API server started on http://" .. self.host .. ":" .. self.port)
    console.log("Available endpoints:")
    console.log("  GET /party - Get current party information")
    console.log("  GET /player - Get current player/trainer information")
    console.log("  GET /status - Get server status")
    console.log("  GET / - API documentation")
    -- console.log("  POST /setMoney - Set player's money amount")
    
    return true
end

function HttpServer:stop()
    if not self.isRunning then
        return true
    end
    
    -- Close all client connections
    for i = #self.clients, 1, -1 do
        self.clients[i]:close()
        table.remove(self.clients, i)
    end
    
    -- Close server socket
    if self.server then
        self.server:close()
        self.server = nil
    end
    
    self.isRunning = false
    console.log("Pokemon Memory Reader API server stopped")
    return true
end

-- Main server loop.
function HttpServer:update()
    if not self.isRunning or not self.server then
        return
    end
    
    -- Accept new connections (non-blocking)
    local client = self.server:accept()
    if client then
        client:settimeout(0)
        table.insert(self.clients, client)
    end
    
    -- Process existing client connections
    for i = #self.clients, 1, -1 do
        local client = self.clients[i]
        local request, err = client:receive("*l")
        
        if request then
            self:handleRequest(client, request)
            client:close()
            table.remove(self.clients, i)
        elseif err == "closed" then
            client:close()
            table.remove(self.clients, i)
        end
        -- If err == "timeout", keep the connection open for next frame
    end
end

-- MARK: Request

function HttpServer:handleRequest(client, requestLine)
    -- Parse HTTP request line
    local method, path, protocol = requestLine:match("^(%S+)%s+(%S+)%s+(%S+)")
    
    if not method or not path then
        httpUtils.sendResponse(client, 400, "Bad Request", "text/plain", "Invalid HTTP request")
        return
    end
    
    -- Read remaining headers (we don't need them but should consume them)
    local headers = {}
    while true do
        local line, err = client:receive("*l")
        if not line or line == "" then break end
        local key, value = line:match("^([^:]+):%s*(.+)")
        if key and value then
            headers[key:lower()] = value
        end
    end
    
    -- Route requests
    if method == "GET" then
        if path == "/party" then
            apiHandlers.handlePartyRequest(client, self.memoryReader)
        elseif path == "/player" then
            apiHandlers.handlePlayerRequest(client, self.memoryReader)
        elseif path == "/status" then
            apiHandlers.handleStatusRequest(client, self.memoryReader, self.port, self.host, self.isRunning)
        elseif path == "/" then
            apiHandlers.handleRootRequest(client, self.port, self.host)
        else
            httpUtils.sendResponse(client, 404, "Not Found", "text/plain", "Endpoint not found")
        end
    elseif method == "POST" then
        -- Read request body for POST requests
        local contentLength = tonumber(headers["content-length"]) or 0
        local body = ""
        if contentLength > 0 then
            body = client:receive(contentLength) or ""
        end
        
        if path == "/setMoney" then
            apiHandlers.handleSetMoneyRequest(client, self.memoryReader, body)
        else
            httpUtils.sendResponse(client, 404, "Not Found", "text/plain", "Endpoint not found")
        end
    else
        httpUtils.sendResponse(client, 405, "Method Not Allowed", "text/plain", "Method not supported")
    end
end

return HttpServer
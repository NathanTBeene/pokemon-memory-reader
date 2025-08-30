-- HTTP Server for Pokemon Memory Reader
-- Provides REST API to get Pokemon party data in JSON format

-- Add LuaSocket path to package path
package.path = package.path .. ";./modules/LuaSocket/?.lua"
package.cpath = package.cpath .. ";./modules/LuaSocket/socket/?.dll;./modules/LuaSocket/mime/?.dll"

local socket = require("socket")
local json = require("modules.dkjson")

local Server = {}
Server.__index = Server

-- Server configuration
local DEFAULT_PORT = 8080
local DEFAULT_HOST = "localhost"

function Server:new(memoryReader, port, host)
    local obj = setmetatable({}, Server)
    obj.memoryReader = memoryReader
    obj.port = port or DEFAULT_PORT
    obj.host = host or DEFAULT_HOST
    obj.server = nil
    obj.isRunning = false
    obj.clients = {}
    
    return obj
end

function Server:start()
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
    console.log("  GET /status - Get server status")
    console.log("  GET / - API documentation")
    
    return true
end

function Server:stop()
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

function Server:update()
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

function Server:handleRequest(client, requestLine)
    -- Parse HTTP request line
    local method, path, protocol = requestLine:match("^(%S+)%s+(%S+)%s+(%S+)")
    
    if not method or not path then
        self:sendResponse(client, 400, "Bad Request", "text/plain", "Invalid HTTP request")
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
            self:handlePartyRequest(client)
        elseif path == "/status" then
            self:handleStatusRequest(client)
        elseif path == "/" then
            self:handleRootRequest(client)
        else
            self:sendResponse(client, 404, "Not Found", "text/plain", "Endpoint not found")
        end
    else
        self:sendResponse(client, 405, "Method Not Allowed", "text/plain", "Method not supported")
    end
end

function Server:handlePartyRequest(client)
    if not self.memoryReader.isInitialized then
        self:sendResponse(client, 503, "Service Unavailable", "application/json", 
            json.encode({error = "Memory reader not initialized", message = "No Pokemon game detected"}))
        return
    end
    
    if not self.memoryReader.partyReader then
        self:sendResponse(client, 503, "Service Unavailable", "application/json",
            json.encode({error = "Party reader not available", message = "Game not supported"}))
        return
    end
    
    -- Get party data
    local party = self:getPartyData()
    
    -- Send JSON response
    local jsonData = json.encode(party, {indent = true})
    self:sendResponse(client, 200, "OK", "application/json", jsonData)
end

function Server:handleStatusRequest(client)
    local status = {
        server = {
            running = self.isRunning,
            port = self.port,
            host = self.host,
            type = "HTTP Server"
        },
        game = {
            initialized = self.memoryReader.isInitialized,
            name = self.memoryReader.currentGame and self.memoryReader.currentGame.GameInfo.GameName or "None",
            generation = self.memoryReader.currentGame and self.memoryReader.currentGame.GameInfo.Generation or 0,
            version = self.memoryReader.currentGame and self.memoryReader.currentGame.GameInfo.VersionColor or "None"
        }
    }
    
    local jsonData = json.encode(status, {indent = true})
    self:sendResponse(client, 200, "OK", "application/json", jsonData)
end

function Server:handleRootRequest(client)
    local html = [[
<!DOCTYPE html>
<html>
<head>
    <title>Pokemon Memory Reader API</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .endpoint { background: #f5f5f5; padding: 10px; margin: 10px 0; border-radius: 5px; }
        .method { color: #0066cc; font-weight: bold; }
        pre { background: #f0f0f0; padding: 15px; border-radius: 5px; overflow-x: auto; }
        .json-example { background: #e8f5e8; }
    </style>
</head>
<body>
    <h1>Pokemon Memory Reader API</h1>
    <p>Welcome to the Pokemon Memory Reader HTTP API server.</p>
    
    <h2>Available Endpoints:</h2>
    
    <div class="endpoint">
        <span class="method">GET</span> <code>/party</code><br>
        Returns the current Pokemon party data in JSON format.
    </div>
    
    <div class="endpoint">
        <span class="method">GET</span> <code>/status</code><br>
        Returns server and game status information.
    </div>
    
    <h2>Example Usage:</h2>
    <pre>curl http://localhost:]] .. self.port .. [[/party</pre>
    <pre>curl http://localhost:]] .. self.port .. [[/status</pre>
    
    <h2>Response Formats:</h2>
    
    <h3>GET /party - Party Data Fields:</h3>
    <p>Returns an array of Pokemon objects. Each Pokemon object contains:</p>
    <table border="1" cellpadding="8" cellspacing="0" style="border-collapse: collapse; width: 100%;">
        <tr style="background-color: #f0f0f0;">
            <th>Field</th>
            <th>Type</th>
            <th>Description</th>
            <th>Example</th>
        </tr>
        <tr>
            <td><code>nickname</code></td>
            <td>string</td>
            <td>Pokemon's nickname (falls back to species name if no nickname)</td>
            <td>"Bulby"</td>
        </tr>
        <tr>
            <td><code>species</code></td>
            <td>string</td>
            <td>Pokemon species name</td>
            <td>"Bulbasaur"</td>
        </tr>
        <tr>
            <td><code>speciesId</code></td>
            <td>number</td>
            <td>Pokemon species ID (Pokedex number)</td>
            <td>1</td>
        </tr>
        <tr>
            <td><code>level</code></td>
            <td>number</td>
            <td>Pokemon's current level (1-100)</td>
            <td>5</td>
        </tr>
        <tr>
            <td><code>nature</code></td>
            <td>string</td>
            <td>Pokemon's nature name (affects stat growth)</td>
            <td>"Hardy"</td>
        </tr>
        <tr>
            <td><code>currentHP</code></td>
            <td>number</td>
            <td>Current hit points</td>
            <td>45</td>
        </tr>
        <tr>
            <td><code>maxHP</code></td>
            <td>number</td>
            <td>Maximum hit points</td>
            <td>45</td>
        </tr>
        <tr>
            <td><code>IVs</code></td>
            <td>object</td>
            <td>Individual Values for each stat (0-31)</td>
            <td>{"hp": 31, "attack": 31, "defense": 31, "specialAttack": 31, "specialDefense": 31, "speed": 31}</td>
        </tr>
        <tr>
            <td><code>EVs</code></td>
            <td>object</td>
            <td>Effort Values for each stat (0-252)</td>
            <td>{"hp": 0, "attack": 0, "defense": 0, "specialAttack": 0, "specialDefense": 0, "speed": 0}</td>
        </tr>
        <tr>
            <td><code>moves</code></td>
            <td>array</td>
            <td>Array of move IDs (not move names)</td>
            <td>[33, 45, 73, 22]</td>
        </tr>
        <tr>
            <td><code>heldItem</code></td>
            <td>string</td>
            <td>Name of held item</td>
            <td>"Rindo Berry"</td>
        </tr>
        <tr>
            <td><code>heldItemId</code></td>
            <td>number</td>
            <td>Numerical ID of held item</td>
            <td>187</td>
        </tr>
        <tr>
            <td><code>status</code></td>
            <td>string</td>
            <td>Current status condition</td>
            <td>"Normal", "Sleep", "Poison", "Burn", "Freeze", "Paralysis"</td>
        </tr>
        <tr>
            <td><code>friendship</code></td>
            <td>number</td>
            <td>Friendship/happiness value (0-255)</td>
            <td>70</td>
        </tr>
        <tr>
            <td><code>abilityIndex</code></td>
            <td>number</td>
            <td>Which ability slot the Pokemon has (0 or 1)</td>
            <td>0</td>
        </tr>
        <tr>
            <td><code>ability</code></td>
            <td>string</td>
            <td>Pokemon's ability name</td>
            <td>"Overgrow"</td>
        </tr>
        <tr>
            <td><code>hiddenPower</code></td>
            <td>string</td>
            <td>Hidden Power type based on IVs</td>
            <td>"Psychic"</td>
        </tr>
        <tr>
            <td><code>isShiny</code></td>
            <td>boolean</td>
            <td>Whether the Pokemon is shiny</td>
            <td>false</td>
        </tr>
        <tr>
            <td><code>types</code></td>
            <td>array</td>
            <td>Pokemon's types (1 or 2 strings)</td>
            <td>["Grass", "Poison"] or ["Fire"]</td>
        </tr>
    </table>
    
    <h3>GET /status - Server Status Fields:</h3>
    <table border="1" cellpadding="8" cellspacing="0" style="border-collapse: collapse; width: 100%;">
        <tr style="background-color: #f0f0f0;">
            <th>Field</th>
            <th>Type</th>
            <th>Description</th>
            <th>Example</th>
        </tr>
        <tr>
            <td><code>server.running</code></td>
            <td>boolean</td>
            <td>Whether the server is currently running</td>
            <td>true</td>
        </tr>
        <tr>
            <td><code>server.port</code></td>
            <td>number</td>
            <td>Port number the server is listening on</td>
            <td>]] .. self.port .. [[</td>
        </tr>
        <tr>
            <td><code>server.host</code></td>
            <td>string</td>
            <td>Host address the server is bound to</td>
            <td>"]] .. self.host .. [["</td>
        </tr>
        <tr>
            <td><code>server.type</code></td>
            <td>string</td>
            <td>Type of server</td>
            <td>"HTTP Server"</td>
        </tr>
        <tr>
            <td><code>game.initialized</code></td>
            <td>boolean</td>
            <td>Whether a Pokemon game has been detected</td>
            <td>true</td>
        </tr>
        <tr>
            <td><code>game.name</code></td>
            <td>string</td>
            <td>Name of the detected Pokemon game</td>
            <td>"Pokemon Ruby"</td>
        </tr>
        <tr>
            <td><code>game.generation</code></td>
            <td>number</td>
            <td>Pokemon game generation (1, 2, or 3)</td>
            <td>3</td>
        </tr>
        <tr>
            <td><code>game.version</code></td>
            <td>string</td>
            <td>Specific version/color of the game</td>
            <td>"Ruby"</td>
        </tr>
    </table>
    
    <h2>Important Notes:</h2>
    <ul>
        <li>Empty party slots are not included in the /party response</li>
        <li>Move IDs correspond to internal game values, not move names</li>
        <li>IVs range from 0-31, EVs range from 0-252</li>
        <li>Status "Normal" indicates no status condition</li>
        <li>If no nickname is set, the nickname field will contain the species name</li>
    </ul>
</body>
</html>]]
    
    self:sendResponse(client, 200, "OK", "text/html", html)
end

function Server:getPartyData()
    -- Read party based on game generation
    local gameCode = self.memoryReader.currentGame and 
        require("utils.gameutils").gameCodeToString(self.memoryReader.currentGame.GameInfo.GameCode) or ""
    local party
    
    if self.memoryReader.currentGame.GameInfo.Generation == 1 or self.memoryReader.currentGame.GameInfo.Generation == 2 then
        -- Gen1 and Gen2 use similar address structure
        party = self.memoryReader.partyReader:readParty(self.memoryReader.gameAddresses, gameCode)
    else
        -- Gen3 uses pstats address
        if not self.memoryReader.gameAddresses.pstats then
            return {error = "Player party address not available"}
        end
        local gameUtils = require("utils.gameutils")
        local playerStatsAddr = gameUtils.hexToNumber(self.memoryReader.gameAddresses.pstats)
        party = self.memoryReader.partyReader:readParty({playerStats = playerStatsAddr}, gameCode)
    end
    
    -- Convert to API format
    local apiParty = {}
    
    for i = 1, 6 do
        local pokemon = party[i]
        if pokemon and pokemon.pokemonID > 0 then
            -- Build moves array (only include non-zero moves)
            local moves = {}
            if pokemon.move1 and pokemon.move1 > 0 then table.insert(moves, pokemon.move1) end
            if pokemon.move2 and pokemon.move2 > 0 then table.insert(moves, pokemon.move2) end
            if pokemon.move3 and pokemon.move3 > 0 then table.insert(moves, pokemon.move3) end
            if pokemon.move4 and pokemon.move4 > 0 then table.insert(moves, pokemon.move4) end
            
            -- Build types array
            local types = {pokemon.type1Name}
            if pokemon.type2Name and pokemon.type2Name ~= pokemon.type1Name then
                table.insert(types, pokemon.type2Name)
            end
            
            local apiPokemon = {
                nickname = pokemon.nickname or pokemon.speciesName,
                species = pokemon.speciesName,
                speciesId = pokemon.pokemonID,
                level = pokemon.level,
                nature = pokemon.natureName,
                currentHP = pokemon.curHP,
                maxHP = pokemon.maxHP,
                IVs = {
                    hp = pokemon.ivHP,
                    attack = pokemon.ivAttack,
                    defense = pokemon.ivDefense,
                    specialAttack = pokemon.ivSpAttack,
                    specialDefense = pokemon.ivSpDefense,
                    speed = pokemon.ivSpeed
                },
                EVs = {
                    hp = pokemon.evHP,
                    attack = pokemon.evAttack,
                    defense = pokemon.evDefense,
                    specialAttack = pokemon.evSpAttack,
                    specialDefense = pokemon.evSpDefense,
                    speed = pokemon.evSpeed
                },
                moves = moves,
                heldItem = pokemon.heldItem,
                heldItemId = pokemon.heldItemId,
                status = self:getStatusName(pokemon.status),
                friendship = pokemon.friendship,
                abilityIndex = pokemon.ability,
                ability = pokemon.abilityName,
                hiddenPower = pokemon.hiddenPowerName,
                isShiny = pokemon.isShiny or false,
                types = types
            }
            
            table.insert(apiParty, apiPokemon)
        end
    end
    
    return apiParty
end

function Server:getStatusName(statusValue)
    if not statusValue or statusValue == 0 then
        return "Healthy"
    end

    local statusNames = {"Asleep", "Poisoned", "Burned", "Frozen", "Paralyzed", "Toxic"}
    return statusNames[statusValue] or "Unknown"
end

function Server:sendResponse(client, code, status, contentType, body)
    local response = "HTTP/1.1 " .. code .. " " .. status .. "\r\n" ..
                     "Content-Type: " .. contentType .. "\r\n" ..
                     "Content-Length: " .. #body .. "\r\n" ..
                     "Connection: close\r\n" ..
                     "Access-Control-Allow-Origin: *\r\n" ..
                     "Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n" ..
                     "Access-Control-Allow-Headers: Content-Type\r\n" ..
                     "\r\n" ..
                     body
    
    client:send(response)
end

return Server
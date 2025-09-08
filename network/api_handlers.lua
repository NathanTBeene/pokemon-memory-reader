-- API Handlers - HTTP endpoint handlers for the Pokemon Memory Reader API
-- Contains handlers for /party, /status, and root documentation endpoints

local json = require("modules.dkjson")
local httpUtils = require("network.http_utils")
local dataConverter = require("network.data_converter")
local htmlDocs = require("network.html_docs")

local ApiHandlers = {}

function ApiHandlers.handlePartyRequest(client, memoryReader)
    if not memoryReader.isInitialized then
        httpUtils.sendResponse(client, 503, "Service Unavailable", "application/json", 
            json.encode({error = "Memory reader not initialized", message = "No Pokemon game detected"}))
        return
    end
    
    if not memoryReader.partyReader then
        httpUtils.sendResponse(client, 503, "Service Unavailable", "application/json",
            json.encode({error = "Party reader not available", message = "Game not supported"}))
        return
    end
    
    -- Get party data
    local party = dataConverter.getPartyData(memoryReader)
    
    -- Send JSON response
    local jsonData = json.encode(party, {indent = true})
    httpUtils.sendResponse(client, 200, "OK", "application/json", jsonData)
end

function ApiHandlers.handleStatusRequest(client, memoryReader, port, host, isRunning)
    local status = {
        server = {
            running = isRunning,
            port = port,
            host = host,
            type = "HTTP Server"
        },
        game = {
            initialized = memoryReader.isInitialized,
            name = memoryReader.currentGame and memoryReader.currentGame.gameInfo.gameName or "None",
            generation = memoryReader.currentGame and memoryReader.currentGame.gameInfo.generation or 0,
            version = memoryReader.currentGame and memoryReader.currentGame.gameInfo.versionColor or "None"
        }
    }
    
    local jsonData = json.encode(status, {indent = true})
    httpUtils.sendResponse(client, 200, "OK", "application/json", jsonData)
end

function ApiHandlers.handleRootRequest(client, port, host)
    local html = htmlDocs.getDocumentationHtml(port, host)
    httpUtils.sendResponse(client, 200, "OK", "text/html", html)
end

function ApiHandlers.handleSetMoneyRequest(client, memoryReader, body)
    if not memoryReader.isInitialized then
        httpUtils.sendResponse(client, 503, "Service Unavailable", "application/json", 
            json.encode({error = "Memory reader not initialized", message = "No Pokemon game detected"}))
        return
    end
    
    if not memoryReader.playerReader then
        httpUtils.sendResponse(client, 503, "Service Unavailable", "application/json",
            json.encode({error = "Player reader not available", message = "Game not supported"}))
        return
    end
    
    -- Parse JSON body to get the amount
    local requestData, err = json.decode(body)
    if not requestData then
        httpUtils.sendResponse(client, 400, "Bad Request", "application/json",
            json.encode({error = "Invalid JSON", message = "Failed to parse request body"}))
        return
    end
    
    -- Validate amount parameter
    local amount = requestData.amount
    if not amount or type(amount) ~= "number" then
        httpUtils.sendResponse(client, 400, "Bad Request", "application/json",
            json.encode({error = "Invalid amount", message = "Amount must be a number"}))
        return
    end
    
    -- Validate amount range (assuming Pokemon games use 32-bit unsigned integers)
    if amount < 0 or amount > 999999 then
        httpUtils.sendResponse(client, 400, "Bad Request", "application/json",
            json.encode({error = "Amount out of range", message = "Amount must be between 0 and 999999"}))
        return
    end
    
    -- Call the setMoney function
    local success, errorMsg = pcall(function()
        memoryReader.playerReader:setMoney(amount)
    end)
    
    if not success then
        httpUtils.sendResponse(client, 500, "Internal Server Error", "application/json",
            json.encode({error = "Failed to set money", message = errorMsg or "Unknown error"}))
        return
    end
    
    -- Return success response
    httpUtils.sendResponse(client, 200, "OK", "application/json",
        json.encode({success = true, message = "Money set to " .. amount}))
end

return ApiHandlers
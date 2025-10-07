-- HTTP Utilities - Common HTTP response building and utility functions
-- Handles HTTP response formatting with proper headers and CORS support

local HttpUtils = {}

function HttpUtils.sendResponse(client, code, status, contentType, body)
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

return HttpUtils
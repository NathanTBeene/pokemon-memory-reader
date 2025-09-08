-- HTML Documentation - Static HTML content for API documentation
-- Contains the complete documentation page served at the root endpoint

local HtmlDocs = {}

function HtmlDocs.getDocumentationHtml(port, host)
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
    
    <div class="endpoint">
        <span class="method">POST</span> <code>/setMoney</code><br>
        Sets the player's money to the specified amount. Requires JSON body with "amount" field.
    </div>
    
    <h2>Example Usage:</h2>
    <pre>curl http://localhost:]] .. port .. [[/party</pre>
    <pre>curl http://localhost:]] .. port .. [[/status</pre>
    <pre>curl -X POST -H "Content-Type: application/json" -d '{"amount": 500000}' http://localhost:]] .. port .. [[/setMoney</pre>
    
    <h2>Response Formats:</h2>
    
    <h3>POST /setMoney - Set Player Money:</h3>
    <p><strong>Request Body (JSON):</strong></p>
    <table border="1" cellpadding="8" cellspacing="0" style="border-collapse: collapse; width: 100%;">
        <tr style="background-color: #f0f0f0;">
            <th>Field</th>
            <th>Type</th>
            <th>Required</th>
            <th>Description</th>
            <th>Example</th>
        </tr>
        <tr>
            <td><code>amount</code></td>
            <td>number</td>
            <td>Yes</td>
            <td>The amount to set player's money to (0-999999)</td>
            <td>500000</td>
        </tr>
    </table>
    
    <p><strong>Success Response (200 OK):</strong></p>
    <pre class="json-example">{"success": true, "message": "Money set to 500000"}</pre>
    
    <p><strong>Error Responses:</strong></p>
    <ul>
        <li><strong>400 Bad Request:</strong> Invalid JSON or amount parameter</li>
        <li><strong>503 Service Unavailable:</strong> Game not detected or not supported</li>
        <li><strong>500 Internal Server Error:</strong> Failed to modify game memory</li>
    </ul>
    
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
            <td>Pokemon species ID (Internal Pokedex number)</td>
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
            <td>Array of move IDs (<a href="https://bulbapedia.bulbagarden.net/wiki/List_of_moves" target="_blank">Source</a>)</td>
            <td>[33, 45, 73, 22]</td>
        </tr>
        <tr>
            <td><code>moveNames</code></td>
            <td>array</td>
            <td>Array of move Names based on ID</td>
            <td>["Tackle", "Growl"]</td>
        </tr>
        <tr>
            <td><code>heldItem</code></td>
            <td>string</td>
            <td>Name of held item. "None" for a blank item.</td>
            <td>"Rindo Berry"</td>
        </tr>
        <tr>
            <td><code>heldItemId</code></td>
            <td>number</td>
            <td>Numerical ID of held item. (<a href="https://bulbapedia.bulbagarden.net/wiki/List_of_items" target="_blank">Source</a>)</td>
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
            <td><code>abilityId</code></td>
            <td>number</td>
            <td>The numerical ID of the ability. List can be found <a href="https://bulbapedia.bulbagarden.net/wiki/Ability" target="_blank">here</a>.</td>
            <td>65 (Overgrow)</td>
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
            <td>]] .. port .. [[</td>
        </tr>
        <tr>
            <td><code>server.host</code></td>
            <td>string</td>
            <td>Host address the server is bound to</td>
            <td>"]] .. host .. [["</td>
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
        <li>Move IDs correspond to internal game values - move names are also provided in moveNames field</li>
        <li>IVs range from 0-31, EVs range from 0-252</li>
        <li>Status "Normal" indicates no status condition</li>
        <li>If no nickname is set, the nickname field will contain the species name</li>
    </ul>
</body>
</html>]]
    
    return html
end

return HtmlDocs
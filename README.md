# Pokemon Memory Reader

A BizHawk Lua script that reads live game data from Pokemon ROMs, providing real-time access to party information, stats, and more without needing to save and exit the game.

## Features

- **Live Data Reading**: Access Pokemon party data in real-time while playing
- **Multi-Generation Support**: Works with Gen 1-3 Pokemon games
- **HTTP API**: Built-in REST API server for external tool integration
- **Comprehensive Data**: Full stats including IVs, EVs, moves, abilities, and more

## Supported Games

### Generation 1
- Pokemon Red
- Pokemon Blue  
- Pokemon Green
- Pokemon Yellow

### Generation 2
- Pokemon Gold
- Pokemon Silver
- Pokemon Crystal

### Generation 3
- Pokemon Ruby (v1.0, v1.1, v1.2)
- Pokemon Sapphire (v1.0, v1.1, v1.2)
- Pokemon Emerald
- Pokemon FireRed
- Pokemon LeafGreen

## Installation

1. Download and install [BizHawk](https://github.com/TASVideos/BizHawk/releases)
2. Clone or download this repository
3. Load a supported Pokemon ROM in BizHawk
4. Open the Lua Console in BizHawk (Tools → Lua Console)
5. Load `main.lua` in the Lua Console

## Usage

### Basic Commands

After loading the script, use these commands in the Lua Console:

```lua
-- Show current party information
showParty()

-- Show available commands
help()
```

### HTTP API Server

The script includes a built-in HTTP server that provides JSON data:

```lua
-- Start the API server (runs on localhost:8080 by default)
startServer()

-- Stop the API server
stopServer()

-- Toggle server on/off
toggleServer()
```

#### API Endpoints

When the server is running, you can access:

- `GET http://localhost:8080/party` - Get party data in JSON format
- `GET http://localhost:8080/status` - Get server status
- `GET http://localhost:8080/` - Get API documentation

### Debug Commands

For development and troubleshooting:

```lua
-- Debug party data structure
debugParty()

-- Debug ability data for specific Pokemon slot (1-6)
debugAbility(1)

-- Debug ability name mappings
debugAbilityNames(1, 10)
```

## Data Structure

The script provides comprehensive Pokemon data including:

- **Basic Info**: Nickname, species, level, type(s)
- **Stats**: Current/Max HP, nature
- **Individual Values (IVs)**: All stat IVs
- **Effort Values (EVs)**: All stat EVs  
- **Movesets**: Up to 4 moves
- **Status**: Current status condition
- **Items**: Held item information
- **Abilities**: Pokemon ability data
- **Hidden Power**: Type and power
- **Friendship**: Friendship/happiness value

## Architecture

The project is organized into several modules:

- **`main.lua`**: Main script entry point and command interface
- **`core/`**: Core functionality (game detection, memory reading)
- **`readers/`**: Generation-specific party readers
- **`data/`**: Game data constants and character mappings
- **`utils/`**: Utility functions (config loading, game utilities)
- **`network/`**: HTTP server implementation
- **`debug/`**: Debugging tools and utilities

## Requirements

- BizHawk emulator (latest stable version recommended)
- Supported Pokemon ROM file
- LuaSocket (included in modules directory)

## Contributing

This project is designed for educational and research purposes. When contributing:

1. Follow the existing code structure and naming conventions
2. Test with multiple game versions when possible
3. Update documentation for any new features
4. Ensure compatibility with BizHawk's Lua environment

## License

This project is licensed under the **GNU General Public License v3.0 with Creative Commons Non-Commercial ShareAlike terms**.

**Key License Terms:**
- **BY (Attribution)**: You must give appropriate credit and indicate if changes were made
- **NC (Non-Commercial)**: You may not use this work for commercial purposes
- **SA (ShareAlike)**: If you remix, transform, or build upon this material, you must distribute your contributions under the same license

This ensures the project remains free and open source while preventing commercial exploitation. Any derivatives must also be non-commercial and use this same license.

**Note:** This project is for educational and research purposes. Please respect the intellectual property rights of Pokemon and related franchises.

## Troubleshooting

### Common Issues

**"No supported Pokemon game detected!"**
- Ensure you've loaded a supported ROM in BizHawk
- Check that the game is fully loaded (past the title screen)
- Try restarting the script after the game is loaded

**Server won't start**
- Check if port 8080 is already in use
- Ensure LuaSocket modules are properly included
- Try restarting BizHawk

**Party data shows as empty**
- Make sure you have Pokemon in your party
- Try using the `debugParty()` command to see raw data
- Verify the game version is supported

### Debug Mode

Use the debug commands to troubleshoot data reading issues:

```lua
-- See raw party data structure
debugParty()

-- Test specific Pokemon slot
debugAbility(1)  -- For slot 1
```

## API Integration

The HTTP API returns JSON data that can be integrated with external tools.

### Party Data Fields

The `/party` endpoint returns an array of Pokemon objects. Each Pokemon object contains:

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `nickname` | string | Pokemon's nickname (falls back to species name if no nickname) | "Bulby" |
| `species` | string | Pokemon species name | "Bulbasaur" |
| `speciesId` | number | Pokemon species ID (Pokedex number) | 1 |
| `level` | number | Pokemon's current level (1-100) | 5 |
| `nature` | string | Pokemon's nature name (affects stat growth) | "Hardy" |
| `currentHP` | number | Current hit points | 45 |
| `maxHP` | number | Maximum hit points | 45 |
| `IVs` | object | Individual Values for each stat (0-31) | `{"hp": 31, "attack": 31, ...}` |
| `EVs` | object | Effort Values for each stat (0-252) | `{"hp": 0, "attack": 0, ...}` |
| `moves` | array | Array of move IDs (not move names) | `[33, 45, 73, 22]` |
| `heldItem` | string | Name of held item | "Rindo Berry" |
| `heldItemId` | number | Numerical ID of held item | 187 |
| `status` | string | Current status condition | "Normal", "Sleep", "Poison", etc. |
| `friendship` | number | Friendship/happiness value (0-255) | 70 |
| `abilityIndex` | number | Which ability slot the Pokemon has (0 or 1) | 0 |
| `ability` | string | Pokemon's ability name | "Overgrow" |
| `hiddenPower` | string | Hidden Power type based on IVs | "Psychic" |
| `isShiny` | boolean | Whether the Pokemon is shiny | false |
| `types` | array | Pokemon's types (1 or 2 strings) | `["Grass", "Poison"]` or `["Fire"]` |

### Status Endpoint Fields

The `/status` endpoint returns server and game information:

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `server.running` | boolean | Whether the server is currently running | true |
| `server.port` | number | Port number the server is listening on | 8080 |
| `server.host` | string | Host address the server is bound to | "localhost" |
| `server.type` | string | Type of server | "HTTP Server" |
| `game.initialized` | boolean | Whether a Pokemon game has been detected | true |
| `game.name` | string | Name of the detected Pokemon game | "Pokemon Ruby" |
| `game.generation` | number | Pokemon game generation (1, 2, or 3) | 3 |
| `game.version` | string | Specific version/color of the game | "Ruby" |

### Example Party Data Structure

```json
{
  "nickname": "Bulby",
  "species": "Bulbasaur",
  "speciesId": 1,
  "level": 5,
  "nature": "Hardy",
  "currentHP": 45,
  "maxHP": 45,
  "IVs": {
    "hp": 31,
    "attack": 31,
    "defense": 31,
    "specialAttack": 31,
    "specialDefense": 31,
    "speed": 31
  },
  "EVs": {
    "hp": 0,
    "attack": 0,
    "defense": 0,
    "specialAttack": 0,
    "specialDefense": 0,
    "speed": 0
  },
  "moves": [
    "Tackle",
    "Growl", 
    "Leech Seed",
    "Vine Whip"
  ],
  "heldItem": "Rindo Berry",
  "status": "Normal",
  "friendship": 70,
  "ability": "Overgrow",
  "hiddenPower": "Psychic",
  "types": ["Grass", "Poison"]
}
```
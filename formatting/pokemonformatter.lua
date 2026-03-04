
local json = require("modules.dkjson")

local PokemonFormatter = {}

---@param party (Pokemon?)[]
---@return string
function PokemonFormatter.formatPartyData(party)
  local output = {}
  table.insert(output, "=== PARTY INFORMATION ===")

  for i = 1, 6 do
    local pokemon = party[i]
    if pokemon and pokemon.speciesID > 0 then
      table.insert(output, PokemonFormatter.formatPokemonSlot(i, pokemon))
    else
      table.insert(output, "Slot " .. i .. ": Empty")
    end
  end

  table.insert(output, "=== END PARTY INFO ===")
  return table.concat(output, "\n")
end

---@param slot integer
---@param pokemon Pokemon
---@return string
function PokemonFormatter.formatPokemonSlot(slot, pokemon)
  local lines = {}
  table.insert(lines, "Slot " .. slot .. ":")
  table.insert(lines, "  Nickname: " .. (pokemon.nickname or pokemon.speciesName or ""))
  table.insert(lines, "  Species: " .. (pokemon.speciesName or "") .. " (" .. (pokemon.speciesID or 0) .. ")")
  table.insert(lines, "  Type: " .. (pokemon.type1Name or "") .. (pokemon.type1Name ~= pokemon.type2Name and "/" .. (pokemon.type2Name or "") or ""))
  table.insert(lines, "  Level: " .. (pokemon.level or 0))
  table.insert(lines, "  Nature: " .. (pokemon.natureName or "") .. " (" .. (pokemon.nature or 0) .. ")")
  table.insert(lines, "  HP: " .. (pokemon.curHP or 0) .. "/" .. (pokemon.maxHP or 0))

  -- EVs
  table.insert(lines, "  EVs: HP:" .. (pokemon.evHP or 0) .. " ATK:" .. (pokemon.evAttack or 0) .. " DEF:" .. (pokemon.evDefense or 0) ..
               " SPA:" .. (pokemon.evSpAttack or 0) .. " SPD:" .. (pokemon.evSpDefense or 0) .. " SPE:" .. (pokemon.evSpeed or 0))

  -- IVs
  table.insert(lines, "  IVs: HP:" .. (pokemon.ivHP or 0) .. " ATK:" .. (pokemon.ivAttack or 0) .. " DEF:" .. (pokemon.ivDefense or 0) ..
               " SPA:" .. (pokemon.ivSpAttack or 0) .. " SPD:" .. (pokemon.ivSpDefense or 0) .. " SPE:" .. (pokemon.ivSpeed or 0))

  -- Moves array
  local moves = {}
  if pokemon.move1 and pokemon.move1 > 0 then table.insert(moves, pokemon.move1) end
  if pokemon.move2 and pokemon.move2 > 0 then table.insert(moves, pokemon.move2) end
  if pokemon.move3 and pokemon.move3 > 0 then table.insert(moves, pokemon.move3) end
  if pokemon.move4 and pokemon.move4 > 0 then table.insert(moves, pokemon.move4) end
  table.insert(lines, "  Moves: [" .. table.concat(moves, ", ") .. "]")

  -- Status
  if pokemon.status and pokemon.status > 0 then
    local statusNames = {"Sleep", "Poison", "Burn", "Freeze", "Paralysis", "Bad Poison"}
    table.insert(lines, "  Status: " .. (statusNames[pokemon.status] or "Unknown"))
  else
    table.insert(lines, "  Status: Normal")
  end

  -- Held Item
  table.insert(lines, "  Held Item: " .. (pokemon.heldItem or "") .. " (ID: " .. (pokemon.heldItemId or 0) .. ")")

  -- Friendship
  table.insert(lines, "  Friendship: " .. (pokemon.friendship or 0))

  -- Ability
  table.insert(lines, "  Ability: " .. (pokemon.abilityName or "") .. " (slot " .. ((pokemon.ability or 0) + 1) .. ")")

  -- Hidden Power
  table.insert(lines, "  Hidden Power: " .. (pokemon.hiddenPowerName or "") .. " (" .. (pokemon.hiddenPower or "") .. ")")

  table.insert(lines, "")
  return table.concat(lines, "\n")
end

---@param party (Pokemon?)[]
---@return string
function PokemonFormatter.formatPartyJSON(party)
  return json.encode(party) --[[@as string]]
end

return PokemonFormatter

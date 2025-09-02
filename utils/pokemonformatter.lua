
local PokemonFormatter = {}

function PokemonFormatter.formatPartyData(party)
  local output = {}
  table.insert(output, "=== PARTY INFORMATION ===")

  for i = 1, 6 do
    local pokemon = party[i]
    if pokemon and pokemon.pokemonID > 0 then
      table.insert(output, PokemonFormatter.formatPokemonSlot(i, pokemon))
    else
      table.insert(output, "Slot " .. i .. ": Empty")
    end
  end

  table.insert(output, "=== END PARTY INFO ===")
  return table.concat(output, "\n")
end

function PokemonFormatter.formatPokemonSlot(slot, pokemon)
  local lines = {}
  table.insert(lines, "Slot " .. slot .. ":")
  table.insert(lines, "  Nickname: " .. (pokemon.nickname ~= "" and pokemon.nickname or pokemon.speciesName))
  table.insert(lines, "  Species: " .. pokemon.speciesName .. " (" .. pokemon.pokemonID .. ")")
  table.insert(lines, "  Type: " .. pokemon.type1Name .. (pokemon.type1Name ~= pokemon.type2Name and "/" .. pokemon.type2Name or ""))
  table.insert(lines, "  Level: " .. pokemon.level)
  table.insert(lines, "  Nature: " .. pokemon.natureName .. " (" .. pokemon.nature .. ")")
  table.insert(lines, "  HP: " .. pokemon.curHP .. "/" .. pokemon.maxHP)
  
  -- EVs
  table.insert(lines, "  EVs: HP:" .. pokemon.evHP .. " ATK:" .. pokemon.evAttack .. " DEF:" .. pokemon.evDefense .. 
               " SPA:" .. pokemon.evSpAttack .. " SPD:" .. pokemon.evSpDefense .. " SPE:" .. pokemon.evSpeed)
  
  -- IVs
  table.insert(lines, "  IVs: HP:" .. pokemon.ivHP .. " ATK:" .. pokemon.ivAttack .. " DEF:" .. pokemon.ivDefense .. 
               " SPA:" .. pokemon.ivSpAttack .. " SPD:" .. pokemon.ivSpDefense .. " SPE:" .. pokemon.ivSpeed)
  
  -- Moves array
  local moves = {}
  if pokemon.move1 > 0 then table.insert(moves, pokemon.move1) end
  if pokemon.move2 > 0 then table.insert(moves, pokemon.move2) end
  if pokemon.move3 > 0 then table.insert(moves, pokemon.move3) end
  if pokemon.move4 > 0 then table.insert(moves, pokemon.move4) end
  table.insert(lines, "  Moves: [" .. table.concat(moves, ", ") .. "]")
  
  -- Status
  if pokemon.status > 0 then
    local statusNames = {"Sleep", "Poison", "Burn", "Freeze", "Paralysis", "Bad Poison"}
    table.insert(lines, "  Status: " .. statusNames[pokemon.status])
  else
    table.insert(lines, "  Status: Normal")
  end
  
  -- Held Item
  table.insert(lines, "  Held Item: " .. pokemon.heldItem .. " (ID: " .. (pokemon.heldItemId or 0) .. ")")
  
  -- Friendship
  table.insert(lines, "  Friendship: " .. pokemon.friendship)
  
  -- Ability
  table.insert(lines, "  Ability: " .. pokemon.abilityName .. " (slot " .. (pokemon.ability + 1) .. ")")
  
  -- Hidden Power
  table.insert(lines, "  Hidden Power: " .. pokemon.hiddenPowerName .. " (" .. pokemon.hiddenPower .. ")")
  
  table.insert(lines, "")
  return table.concat(lines, "\n")
end

-- Unimplemented
function PokemonFormatter.formatPartyAsJSON(party)
end

return PokemonFormatter
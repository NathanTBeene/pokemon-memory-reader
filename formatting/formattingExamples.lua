local pokemonFormat = {
  nickname = "Bulby",
  species = "Bulbasaur",
  speciesId = 1,
  level = 5,
  nature = "Hardy",
  currentHP = 45,
  maxHP = 45,
  IVs = {
    hp = 31,
    attack = 31,
    defense = 31,
    specialAttack = 31,
    specialDefense = 31,
    speed = 31
  },
  EVs = {
    hp = 0,
    attack = 0,
    defense = 0,
    specialAttack = 0,
    specialDefense = 0,
    speed = 0
  },
  moves = {
    "Tackle",
    "Growl",
    "LeechSeed",
    "VineWhip"
  },
  heldItem = "Rindo Berry",
  heldItemId = 12,
  status = "Normal",
  friendship = 70,
  abilityIndex = 0,
  ability = "Overgrow",
  hiddenPower = "Psychic",
  types = {"Grass", "Poison"}
}

local trainerInfoFormat = {
  trainerId = {
    public = 12345,
    private = 12345
  },
  name = "Devin",
  gender = "Male",
  money = 123456,
  momMoney = 0,
  coins = 0,
  badges = {
    {badgeNum = 0, name = "Boulder Badge", earned = true},
    {badgeNum = 1, name = "Cascade Badge", earned = false},
  }
}

local battlerFormat = {
  name = "Devin",
  items = {
    {id = 1, name = "Master Ball", quantity = 1},
    {id = 5, name = "Potion", quantity = 5},
  },
  party = {
    -- Six Pokemon max
  },
  money = 123456,
}

local bagFormat = {
  pcItems = {
    {id = 1, name = "Master Ball", quantity = 1},
    {id = 5, name = "Potion", quantity = 5},
  },
  items = {
    {id = 1, name = "Master Ball", quantity = 1},
    {id = 5, name = "Potion", quantity = 5},
  },
  keyItems = {
    {id = 101, name = "Bicycle", quantity = 1},
    {id = 102, name = "Town Map", quantity = 1},
  },
  pokeballs = {
    {id = 4, name = "Great Ball", quantity = 10},
    {id = 1, name = "Master Ball", quantity = 1},
  },
  tmhm = {
    {id = 15, name = "Hyper Beam", quantity = 1},
    {id = 29, name = "Psychic", quantity = 1},
  },
  berries = {
    {id = 201, name = "Oran Berry", quantity = 5},
    {id = 202, name = "Sitrus Berry", quantity = 3},
  }
}
--@meta

-- ============================================================
-- POKEMON TYPES
-- ============================================================

---@class Pokemon
---@field speciesID integer
---@field speciesName string
---@field nickname string?
---@field level integer
---@field nature integer?           Gen 1 doesn't have natures
---@field natureName string?        Gen 1 doesn't have natures
---@field curHP integer
---@field maxHP integer
---@field evHP integer?
---@field evAttack integer?
---@field evDefense integer?
---@field evSpAttack integer?
---@field evSpDefense integer?
---@field evSpeed integer?
---@field ivHP integer?
---@field ivAttack integer?
---@field ivDefense integer?
---@field ivSpAttack integer?
---@field ivSpDefense integer?
---@field ivSpeed integer?
---@field move1 integer?
---@field move2 integer?
---@field move3 integer?
---@field move4 integer?
---@field status integer
---@field heldItemId integer?       Gen 1 doesn't have held items
---@field heldItem string?          Gen 1 doesn't have held items
---@field friendship integer?       Gen 1 doesn't have friendship
---@field ability integer?          Gen 1/2 doesn't have abilities (slot index)
---@field abilityName string?       Gen 1/2 doesn't have abilities
---@field hiddenPower string?       Gen 1/2 doesn't have Hidden Power
---@field hiddenPowerName string?   Gen 1/2 doesn't have Hidden Power
---@field type1Name string?
---@field type2Name string?
---@field experience integer?
---@field isShiny boolean?
---@field otid integer

-- ============================================================
-- TRAINER / PLAYER TYPES
-- ============================================================

---@class TrainerID
---@field public integer
---@field private integer

---@class Badge
---@field badgeNum integer
---@field name string
---@field earned boolean

---@class TrainerInfo
---@field trainerId TrainerID
---@field name string
---@field gender string
---@field money integer
---@field momMoney integer?
---@field coins integer?
---@field badges Badge[]

---@class Item
---@field id integer
---@field name string
---@field quantity integer

---@class Battler
---@field name string
---@field items Item[]
---@field party Pokemon[]
---@field money integer

---@class Bag
---@field pcItems Item[]
---@field items Item[]
---@field keyItems Item[]
---@field balls Item[]
---@field berries Item[]
---@field tmhm Item[]
---@field battleItems Item[]

-- ============================================================
-- GAME / DATABASE TYPES
-- ============================================================

---@class GameInfo
---@field gameCode integer | string
---@field gameName string
---@field versionName string
---@field versionColor? string      -- "Red", "Gold", "Ruby", etc.
---@field generation integer        -- Always an integer (1-4). Use romHackType for variants.
---@field platform string           -- "GB", "GBC", "GBA", "NDS"
---@field charmap Charmap
---@field isRomHack boolean
---@field romHackType? string       -- e.g. "CFRU" for Complete Fire Red Upgrade hacks

---@class GameAddresses
---@field partyAddr integer | string
---@field partySlotsCounterAddr integer
---@field partyNicknamesAddr? integer
---@field wildDVsAddr? integer
---@field trainerID? integer
---@field itemNameTable? integer
---@field partyPointer? string      -- Gen 4: pointer to party address
---@field moveTable? string
---@field natureTable? string
---@field speciesTable? string
---@field abilityTable? string
---@field itemTable? string
---@field tmTable? string
---@field speciesNameTable? string   -- CFRU: species name ROM table
---@field speciesDataTable? string   -- CFRU: species base-stat ROM table
---@field moveNamesTable? string     -- CFRU: move name ROM table

---@class GameTrainerOffsets
---@field name integer
---@field badges integer
---@field money integer
---@field coins? integer
---@field bagCount? integer
---@field bagItems? integer
---@field pcCount? integer
---@field pcItems? integer

---@class GamePointers
---@field saveBlock1? string       -- Gen 3: save block 1 pointer address
---@field saveBlock2? string       -- Gen 3: save block 2 pointer address
---@field isPointer? boolean       -- Gen 3: whether saveBlock addresses are pointers
---@field partyPointer? string     -- Gen 4: pointer to party base address

---@class GameOffsets              -- Gen 4: address offsets derived from pointers
---@field partyOffset? string

---@class PocketSizes
---@field items integer
---@field keyItems integer
---@field balls integer
---@field tmhm integer
---@field berries integer

---@class GameEntry
---@field gameInfo GameInfo
---@field addresses GameAddresses
---@field trainerOffsets? GameTrainerOffsets   -- Gen 1/2
---@field trainerPointers? GamePointers        -- Gen 3 (named trainerPointers in DB)
---@field pointers? GamePointers               -- Gen 3 alias / Gen 4
---@field offsets? GameOffsets                 -- Gen 4 address offsets
---@field pocketSizes? PocketSizes

-- ============================================================
-- READER / GENERATION TYPES
-- (PartyReader and PlayerReader are fully defined in readers/base/)
-- ============================================================

---@class PartyReader
---@class PlayerReader

---@class GenerationConfig
---@field partyReader fun(gameEntry: GameEntry): PartyReader
---@field playerReader (fun(gameEntry: GameEntry): PlayerReader)?

-- Grats! Level Up: suggested places, keyed by level range.
-- DRAFT from common Classic Era level ranges. Jim to confirm against WoW: Forever charts.
-- Dungeons can be replaced with Bar Check's Dungeons.lua data (same fields).
-- Fields: name, min, max, faction ("Alliance"/"Horde"/nil = both).
-- A place is suggested on the level-up where the player first reaches its `min`.
local _, ns = ...

ns.Places = {
  zones = {
    { name = "Silverpine Forest",     min = 10, max = 20, faction = "Horde" },
    { name = "The Barrens",           min = 10, max = 25, faction = "Horde" },
    { name = "Westfall",              min = 10, max = 20, faction = "Alliance" },
    { name = "Loch Modan",            min = 10, max = 20, faction = "Alliance" },
    { name = "Darkshore",             min = 10, max = 20, faction = "Alliance" },
    { name = "Redridge Mountains",    min = 15, max = 25, faction = "Alliance" },
    { name = "Stonetalon Mountains",  min = 15, max = 27 },
    { name = "Ashenvale",             min = 18, max = 30 },
    { name = "Duskwood",              min = 18, max = 30, faction = "Alliance" },
    { name = "Hillsbrad Foothills",   min = 20, max = 30 },
    { name = "Wetlands",              min = 20, max = 30, faction = "Alliance" },
    { name = "Thousand Needles",      min = 25, max = 35 },
    { name = "Alterac Mountains",     min = 30, max = 40 },
    { name = "Arathi Highlands",      min = 30, max = 40 },
    { name = "Desolace",              min = 30, max = 40 },
    { name = "Stranglethorn Vale",    min = 30, max = 45 },
    { name = "Dustwallow Marsh",      min = 35, max = 45 },
    { name = "Badlands",              min = 35, max = 45 },
    { name = "Swamp of Sorrows",      min = 35, max = 45 },
    { name = "Feralas",               min = 40, max = 50 },
    { name = "The Hinterlands",       min = 40, max = 50 },
    { name = "Tanaris",               min = 40, max = 50 },
    { name = "Searing Gorge",         min = 43, max = 50 },
    { name = "Azshara",               min = 45, max = 55 },
    { name = "Blasted Lands",         min = 45, max = 55 },
    { name = "Un'Goro Crater",        min = 48, max = 55 },
    { name = "Felwood",               min = 48, max = 55 },
    { name = "Burning Steppes",       min = 50, max = 58 },
    { name = "Western Plaguelands",   min = 51, max = 58 },
    { name = "Eastern Plaguelands",   min = 53, max = 60 },
    { name = "Winterspring",          min = 53, max = 60 },
    { name = "Silithus",              min = 55, max = 60 },
  },
  dungeons = {
    { name = "Ragefire Chasm",        min = 13, max = 18, faction = "Horde" },
    { name = "Wailing Caverns",       min = 15, max = 25 },
    { name = "The Deadmines",         min = 17, max = 26, faction = "Alliance" },
    { name = "Shadowfang Keep",       min = 22, max = 30 },
    { name = "The Stockade",          min = 22, max = 30, faction = "Alliance" },
    { name = "Blackfathom Deeps",     min = 24, max = 32 },
    { name = "Gnomeregan",            min = 29, max = 38 },
    { name = "Razorfen Kraul",        min = 29, max = 38 },
    { name = "Scarlet Monastery",     min = 28, max = 45 },
    { name = "Razorfen Downs",        min = 37, max = 46 },
    { name = "Uldaman",               min = 41, max = 51 },
    { name = "Zul'Farrak",            min = 44, max = 54 },
    { name = "Maraudon",              min = 46, max = 55 },
    { name = "Sunken Temple",         min = 50, max = 56 },
    { name = "Blackrock Depths",      min = 52, max = 60 },
    { name = "Lower Blackrock Spire", min = 55, max = 60 },
    { name = "Dire Maul",             min = 55, max = 60 },
    { name = "Scholomance",           min = 58, max = 60 },
    { name = "Stratholme",            min = 58, max = 60 },
    { name = "Upper Blackrock Spire", min = 58, max = 60 },
  },
  battlegrounds = {
    { name = "Warsong Gulch",  min = 10, max = 60 },
    { name = "Arathi Basin",   min = 20, max = 60 },
    { name = "Alterac Valley", min = 51, max = 60 },
  },
  raids = {
    { name = "Molten Core",            min = 60, max = 60 },
    { name = "Onyxia's Lair",          min = 60, max = 60 },
    { name = "Zul'Gurub",              min = 60, max = 60 },
    { name = "Blackwing Lair",         min = 60, max = 60 },
    { name = "Ruins of Ahn'Qiraj",     min = 60, max = 60 },
    { name = "Temple of Ahn'Qiraj",    min = 60, max = 60 },
    { name = "Naxxramas",              min = 60, max = 60 },
  },
}

-- Milestone banner lines (extra flourish at these levels).
ns.Milestones = {
  [10] = "Talent points unlocked",
  [20] = "Twenty levels strong",
  [30] = "Halfway to the summit",
  [40] = "Riding training available",
  [50] = "The final stretch begins",
  [60] = "Maximum level reached",
}

-- Grats! Level Up: builds the data shown in a review (stats, training, places).
local _, ns = ...

local function playerInfo()
  local _, classToken = UnitClass("player")
  local raceName, raceToken, raceId = UnitRace("player")
  local faction = UnitFactionGroup("player")
  return classToken, raceToken, raceId, faction, raceName
end

-- Spell name, rank text and icon. Newer clients (WoW: Forever) use C_Spell and only know a
-- spell's details once they are loaded, so this returns nil until then; RequestSpell asks for it.
local function spellNameRank(id)
  local name, rank, icon
  if C_Spell and C_Spell.GetSpellInfo then
    local info = C_Spell.GetSpellInfo(id)
    if type(info) == "table" then name, icon = info.name, info.iconID or info.originalIconID end
  end
  if not name and GetSpellInfo then
    local n, r, i = GetSpellInfo(id)
    name, rank, icon = n, r, icon or i
  end
  local sub = (C_Spell and C_Spell.GetSpellSubtext and C_Spell.GetSpellSubtext(id)) or (GetSpellSubtext and GetSpellSubtext(id))
  if sub and sub ~= "" then rank = sub end
  if type(rank) ~= "string" then rank = nil end
  if not icon then
    icon = (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id)) or (GetSpellTexture and GetSpellTexture(id)) or nil
  end
  return name, rank, icon
end
ns.SpellNameRank = spellNameRank

function ns:RequestSpell(id)
  if C_Spell and C_Spell.RequestLoadSpellData then pcall(C_Spell.RequestLoadSpellData, id) end
end

-- Ask the client to load every trainer spell for the player's class (called at login),
-- so names and icons are ready by the time the player levels.
function ns:PrecacheClassSpells()
  local _, classToken = UnitClass("player")
  local byLevel = ns.Training and ns.Training[classToken]
  if not byLevel then return end
  for _, entries in pairs(byLevel) do
    for _, e in ipairs(entries) do
      self:RequestSpell(e[1])
      if e.talent then self:RequestSpell(e.talent) end
    end
  end
end

local function known(id)
  if IsPlayerSpell and IsPlayerSpell(id) then return true end
  if IsSpellKnown and IsSpellKnown(id) then return true end
  return false
end

local function raceMatches(entry, raceId)
  if entry.race and entry.race ~= raceId then return false end
  if entry.races then
    for _, r in ipairs(entry.races) do if r == raceId then return true end end
    return false
  end
  return true
end

-- Trainer spells for levels fromLevel..toLevel. With `leftover`, the range is earlier levels
-- and only spells the player can train right now are listed ("Still at your trainer").
-- With `includeKnown` (replays), spells already learned are kept and marked known = true.
function ns:GetNewTraining(fromLevel, toLevel, leftover, includeKnown)
  if toLevel < fromLevel then return {}, "none" end
  local list = {}
  -- 1) What's Training? is installed and ready: use its live data (respects ignores and discounts).
  local api = _G.WT_API
  if ns.db and ns.db.useWhatsTraining == false then api = nil end
  if api and api.IsReady and api.IsReady() and api.GetSpells then
    local ok, spells = pcall(api.GetSpells)
    if ok and type(spells) == "table" then
      -- Its statuses may not have caught up with the new level yet, so filter by level and
      -- leave out only what the player can never train now (known, ignored, talent missing, pets, weapons).
      local St = api.Status or {}
      local skip = {}
      for _, key in ipairs({ "KNOWN", "KNOWN_PET", "IGNORED", "IGNORED_PET", "MISSINGTALENT", "PET",
                             "WEAPON_AVAILABLE", "WEAPON_NEXTLEVEL", "WEAPON_NOTLEVEL", "WEAPON_KNOWN", "WEAPON_IGNORED" }) do
        if St[key] then skip[St[key]] = true end
      end
      for _, s in ipairs(spells) do
        local statusOk
        if leftover then statusOk = (s.status == St.AVAILABLE)
        elseif includeKnown and (s.status == St.KNOWN) then statusOk = true
        else statusOk = not skip[s.status] end
        if s.level and s.level >= fromLevel and s.level <= toLevel and statusOk and not s.isItem then
          table.insert(list, { id = s.id, name = s.name, rank = s.subText, icon = s.icon, cost = s.cost or 0, level = s.level,
                               known = (St.KNOWN ~= nil and s.status == St.KNOWN) or nil })
        end
      end
      if #list > 0 or leftover then return self:SortTraining(list), "WhatsTraining" end
    end
  end
  -- 2) Built-in table.
  local classToken, _, raceId, faction = playerInfo()
  local byLevel = ns.Training and ns.Training[classToken]
  if not byLevel then return list, "none" end
  local seen = {}
  for lvl = fromLevel, toLevel do
    for _, e in ipairs(byLevel[lvl] or {}) do
      local id, cost = e[1], e[2]
      local ok = not seen[id] and raceMatches(e, raceId)
        and not (leftover and e.quest)                    -- "Still at your trainer" is trainer-only
        and (not e.faction or e.faction == faction)
        and (not e.talent or known(e.talent))
        and (includeKnown or not known(id))
      if ok then
        local name, rank, icon = spellNameRank(id)
        if not name then self:RequestSpell(id) end           -- shown as "Loading..." until the client has it
        seen[id] = true
        table.insert(list, { id = id, name = name, rank = rank, icon = icon, cost = cost or 0, level = lvl,
                             quest = e.quest or nil,       -- taught by a class quest, not the trainer
                             known = (includeKnown and known(id)) or nil })
      end
    end
  end
  if leftover then list = self:DropSupersededRanks(list, byLevel) end
  return self:SortTraining(list), "builtin"
end

-- A skipped Rank 2 is not worth listing when Rank 3 is already known: keep only ranks
-- above the highest known rank of the same spell name.
function ns:DropSupersededRanks(list)
  local out = {}
  for _, s in ipairs(list) do
    local superseded = false
    if s.name and self.knownHigher and self.knownHigher[s.name] and (self.knownHigher[s.name] > (s.level or 0)) then superseded = true end
    if not superseded then table.insert(out, s) end
  end
  return out
end

function ns:SortTraining(list)
  table.sort(list, function(a, b)
    if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) < (b.level or 0) end
    if (a.name or "") ~= (b.name or "") then return (a.name or "") < (b.name or "") end
    return (a.id or 0) < (b.id or 0)
  end)
  return list
end

-- Places whose minimum level was reached in fromLevel..toLevel.
function ns:GetNewPlaces(fromLevel, toLevel)
  local _, _, _, faction = playerInfo()
  local out = {}
  local kinds = { { "dungeons", "Dungeon" }, { "zones", "Zone" }, { "battlegrounds", "Battleground" }, { "raids", "Raid" } }
  for _, k in ipairs(kinds) do
    for _, p in ipairs((ns.Places and ns.Places[k[1]]) or {}) do
      if p.min >= fromLevel and p.min <= toLevel and (not p.faction or p.faction == faction) then
        table.insert(out, { kind = k[2], name = p.name, min = p.min, max = p.max })
      end
    end
  end
  return out
end

function ns:BuildReview(g)
  local classToken, raceToken, _, faction, raceName = playerInfo()
  local className = UnitClass("player")
  local r = {
    fromLevel = g.level, level = g.level,
    hp = g.hp, power = g.power, talents = g.talents,
    str = g.str, agi = g.agi, sta = g.sta, int = g.int, spi = g.spi,
    class = classToken, className = className, race = raceToken, raceName = raceName, faction = faction,
    powerType = UnitPowerType and select(2, UnitPowerType("player")) or "MANA",
    time = time and time() or 0,
    char = ns:CharKey(), charName = UnitName and UnitName("player") or nil,
  }
  self:FillDetails(r)
  return r
end

function ns:MergeReview(r, g)
  r.level = math.max(r.level, g.level)
  for _, k in ipairs({ "hp", "power", "talents", "str", "agi", "sta", "int", "spi" }) do
    r[k] = (r[k] or 0) + (g[k] or 0)
  end
  self:FillDetails(r)
  return r
end

function ns:FillDetails(r, forReplay)
  r.spells = self:GetNewTraining(r.fromLevel, r.level, false, forReplay)
  self:BuildKnownHigher(r)
  r.leftover = self:GetNewTraining(1, r.fromLevel - 1, true)
  r.places = self:GetNewPlaces(r.fromLevel, r.level)
  r.milestone = nil
  for lvl = r.fromLevel, r.level do
    if ns.Milestones[lvl] then r.milestone = ns.Milestones[lvl]; r.milestoneLevel = lvl end
  end
  local total = 0
  for _, s in ipairs(r.spells) do if not s.known then total = total + (s.cost or 0) end end
  for _, s in ipairs(r.leftover) do total = total + (s.cost or 0) end
  r.trainingCost = total
end

-- Highest level at which the player already knows each spell name (built-in data), so a
-- skipped low rank is not nagged about once a higher rank is learned.
function ns:BuildKnownHigher(r)
  self.knownHigher = {}
  local byLevel = ns.Training and ns.Training[r.class]
  if not byLevel then return end
  for lvl, entries in pairs(byLevel) do
    for _, e in ipairs(entries) do
      if known(e[1]) then
        local name = spellNameRank(e[1])
        if name and lvl > (self.knownHigher[name] or 0) then self.knownHigher[name] = lvl end
      end
    end
  end
end

-- Replays are rebuilt with the current version's data, so an old saved level-up shows what it
-- should have shown. Stat gains stay as recorded; training, places and milestone are refreshed.
function ns:RefreshReview(r)
  local ok = pcall(self.FillDetails, self, r, true)
  r.replay = true
  return r, ok
end

function ns:LevelText(r)
  if r.fromLevel ~= r.level then return "Levels " .. r.fromLevel .. "-" .. r.level end
  return "Level " .. r.level
end

function ns:MoneyText(copper)
  copper = math.floor(copper or 0)
  local g, s, c = math.floor(copper / 10000), math.floor((copper % 10000) / 100), copper % 100
  local parts = {}
  if g > 0 then table.insert(parts, g .. "|cffffd700g|r") end
  if s > 0 then table.insert(parts, s .. "|cffc7c7cfs|r") end
  if c > 0 or #parts == 0 then table.insert(parts, c .. "|cffeda55fc|r") end
  return table.concat(parts, " ")
end

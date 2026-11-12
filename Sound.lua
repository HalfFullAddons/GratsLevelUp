-- Grats! Level Up: fanfares, combat chime, race interludes and music ducking.
-- v1 note: the original orchestral fanfares are not bundled yet. Grats! tries the
-- bundled files in Media\ first and falls back to the game's own sounds.
local _, ns = ...
local Sound = {}
ns.Sound = Sound

local MEDIA = "Interface\\AddOns\\GratsLevelUp\\Media\\"
local LOCKOUT = 8          -- seconds after a combat chime when the full fanfare is replaced by a soft swell
local INTERLUDE_SECONDS = 12
local FADE_MS = 2000

-- Built-in fallbacks (sound kit ids that exist in Classic clients).
local KIT_LEVELUP = 888                                   -- the game's own level-up "ding"
local KIT_QUEST = (SOUNDKIT and SOUNDKIT.IG_QUEST_LIST_COMPLETE) or 878
local KIT_CHIME = (SOUNDKIT and SOUNDKIT.MAP_PING) or 3175

-- Level-up sound choices (Options > Level-up sound). To add one: append an entry.
--   kit   = a game sound kit id; files = bundled files in Media\ (Horde/Alliance, milestone)
--   ready = false keeps it listed but greyed out until its files ship.
Sound.CHOICES = {
  { key = "wow", name = "WoW level-up (default)", kit = KIT_LEVELUP },
  { key = "quest", name = "WoW quest complete", kit = KIT_QUEST },
  { key = "fanfare", name = "Grats! fanfare (coming soon)", ready = false,
    files = { Horde = "Fanfare_Horde.ogg", Alliance = "Fanfare_Alliance.ogg",
              HordeMilestone = "Fanfare_Horde_Milestone.ogg", AllianceMilestone = "Fanfare_Alliance_Milestone.ogg" } },
  { key = "none", name = "None" },
}
local CHOICE_BY_KEY = {}
for _, c in ipairs(Sound.CHOICES) do CHOICE_BY_KEY[c.key] = c end

-- Race interludes: the client's own city music. Paths are tried in order; any that do not
-- exist in this client are skipped silently. VERIFY in WoW: Forever (or swap in FileDataIDs).
local CITY = {
  Orgrimmar = { "Sound\\Music\\CityMusic\\Orgrimmar\\orgrimmar01-moment.mp3", "Sound\\Music\\CityMusic\\Orgrimmar\\orgrimmar01-zone.mp3" },
  ThunderBluff = { "Sound\\Music\\CityMusic\\Thunderbluff\\thunderbluff01-moment.mp3", "Sound\\Music\\CityMusic\\Thunderbluff\\thunderbluff walking 01.mp3" },
  Undercity = { "Sound\\Music\\CityMusic\\Undercity\\undercity01-moment.mp3", "Sound\\Music\\CityMusic\\Undercity\\undercity01-zone.mp3" },
  Stormwind = { "Sound\\Music\\CityMusic\\Stormwind\\stormwind01-moment.mp3", "Sound\\Music\\CityMusic\\Stormwind\\stormwind04-zone.mp3" },
  Ironforge = { "Sound\\Music\\CityMusic\\Ironforge\\ironforge-walking01.mp3", "Sound\\Music\\CityMusic\\Ironforge\\ironforge walking 01.mp3" },
  Darnassus = { "Sound\\Music\\CityMusic\\Darnassus\\darnassus walking 1.mp3", "Sound\\Music\\CityMusic\\Darnassus\\darnassus01-moment.mp3" },
}
local RACE_CITY = {
  Orc = "Orgrimmar", Troll = "Orgrimmar", Tauren = "ThunderBluff", Scourge = "Undercity", Undead = "Undercity",
  Human = "Stormwind", Dwarf = "Ironforge", Gnome = "Ironforge", NightElf = "Darnassus",
}

local function playFile(path)
  if not PlaySoundFile then return nil end
  local willPlay, handle = PlaySoundFile(path, "Master")
  if willPlay then return handle or true end
  return nil
end

local function playKit(kit)
  if PlaySound then PlaySound(kit, "Master") end
end

function Sound:Enabled() return ns.db and ns.db.sound end

-- Short chime when leveling in combat (or a strip-only level-up).
function Sound:Chime()
  if not self:Enabled() or not ns.db.combatChime then return end
  ns.lastChime = GetTime()
  if not playFile(MEDIA .. "Chime.ogg") then playKit(KIT_CHIME) end
end

-- Plays a level-up sound choice once (also used by the options menu to preview a choice).
function Sound:PlayChoice(key, review)
  local c = CHOICE_BY_KEY[key or "wow"] or CHOICE_BY_KEY.wow
  if c.ready == false then c = CHOICE_BY_KEY.wow end
  if c.files then
    local fac = (review and review.faction == "Alliance") and "Alliance" or "Horde"
    local file = c.files[fac .. ((review and review.milestone) and "Milestone" or "")] or c.files[fac]
    if file and playFile(MEDIA .. file) then return end
    playKit(KIT_LEVELUP)
  elseif c.kit then
    playKit(c.kit)
  end
end

-- Sound for the full review: the chosen level-up sound, or a soft swell instead when a
-- combat chime played moments ago, so the two never stack.
function Sound:Fanfare(review, isReplay)
  if not self:Enabled() then return end
  if not isReplay and (GetTime() - (ns.lastChime or -100)) < LOCKOUT then
    if not playFile(MEDIA .. "Swell.ogg") then playKit(KIT_CHIME) end
    return
  end
  local key = ns.db.levelSound
  -- On a real level-up the client is busy with its own level-up effects that same moment;
  -- a short delay keeps our sound from being lost under them.
  if isReplay then self:PlayChoice(key, review)
  else C_Timer.After(0.25, function() Sound:PlayChoice(key, review) end) end
end

-- Race interlude while the review plays, with the game's music lowered.
function Sound:StartInterlude(review)
  self:StopInterlude(true)
  if not self:Enabled() or not ns.db.interlude then return end
  local city = RACE_CITY[review.race or ""]
  local paths = city and CITY[city]
  if not paths then return end
  self:DuckMusic()
  for _, path in ipairs(paths) do
    local h = playFile(path)
    if h then
      self.handle = h
      local token = {}
      self.token = token
      C_Timer.After(INTERLUDE_SECONDS, function() if self.token == token then self:StopInterlude() end end)
      return
    end
  end
  self:RestoreMusic()   -- nothing played
end

function Sound:StopInterlude(quick)
  self.token = nil
  if self.handle and type(self.handle) ~= "boolean" and StopSound then
    StopSound(self.handle, quick and 300 or FADE_MS)
  end
  self.handle = nil
  if quick then self:RestoreMusic() else C_Timer.After(FADE_MS / 1000, function() Sound:RestoreMusic() end) end
end

-- Lowers the game music while Grats! plays and restores it exactly afterwards.
-- The original value is kept in SavedVariables so a crash or /reload mid-review restores it next login.
function Sound:DuckMusic()
  if not ns.db.duckMusic or not GetCVar or not SetCVar then return end
  if ns.db.duckSaved then return end
  local v = tonumber(GetCVar("Sound_MusicVolume"))
  if not v then return end
  ns.db.duckSaved = v
  SetCVar("Sound_MusicVolume", tostring(v * 0.2))
end

function Sound:RestoreMusic()
  local db = ns.db or GratsDB
  if db and db.duckSaved and SetCVar then
    SetCVar("Sound_MusicVolume", tostring(db.duckSaved))
    db.duckSaved = nil
  end
end

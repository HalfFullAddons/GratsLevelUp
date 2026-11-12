-- Grats! Level Up: core state, saved settings, event flow and slash commands.
-- MIT License. Unofficial fan tool. World of Warcraft is a trademark of Blizzard Entertainment.
local ADDON, ns = ...
_G.Grats = ns
-- The version comes from the .toc, where the release tag replaces @project-version@.
-- A copy that was not built from a tag (a test zip or the repository itself) shows "dev".
do
  local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  local v = get and get("GratsLevelUp", "Version")
  if type(v) ~= "string" or v == "" or v:find("@", 1, true) then v = "dev" end
  ns.VERSION = v
end

local defaults = {
  theme = "auto",             -- auto (your race) | race:<key> | parchment | dark | class | faction
  atmosphere = true,          -- drifting motes/embers on race pages
  mode = "full",              -- full | quick | strip
  position = "right",         -- right | left | center | custom
  size = "medium",            -- small | medium | large
  scale = 1.0,
  opacity = 1.0,
  combatOpacity = 0.7,        -- condensed strip while in combat
  watermarkOpacity = 0.25,    -- full review when combat starts mid-animation
  autoAdvance = true,
  useWhatsTraining = true,    -- use What's Training? data when that addon is installed
  textAnim = true,           -- presentation-style fade-in, count-ups and level glow
  pageSeconds = 6,
  fadeAfter = 8,              -- seconds after the last page finishes before the panel fades away (0 = never)
  sound = true,
  levelSound = "wow",         -- wow | quest | fanfare | none (Sound.CHOICES)
  volume = 1.0,               -- reserved for bundled fanfares
  combatChime = true,
  interlude = true,
  duckMusic = true,
  hideChatLines = true,
  keepGameText = false,
  bgStripOnly = true,
  stripLocked = true,
  minimap = { hide = false, angle = 200 },
  versionNotice = true,
  history = {},
}
ns.defaults = defaults

local function fill(dst, src)
  for k, v in pairs(src) do
    if dst[k] == nil then
      if type(v) == "table" then dst[k] = {}; fill(dst[k], v) else dst[k] = v end
    elseif type(v) == "table" and type(dst[k]) == "table" and k ~= "history" then
      fill(dst[k], v)
    end
  end
end

ns.db = nil
ns.pending = nil          -- review waiting for the full animation
ns.current = nil          -- review on screen
ns.lastChime = -100

function ns:Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cffffd100Grats!|r " .. tostring(msg))
end

-- Strict combat check. (UnitAffectingCombat lags behind the "combat ended" event, so a
-- level-up from a killing blow could look like combat after combat had already ended.)
function ns:InCombat()
  if InCombatLockdown then return InCombatLockdown() and true or false end
  return (UnitAffectingCombat and UnitAffectingCombat("player")) and true or false
end

-- Safety net: while a review is waiting, check once a second and play it as soon as the
-- player is out of combat (and out of a battleground, if that option is on). This covers
-- any missed or out-of-order combat events.
function ns:WatchPending()
  if self.watching then return end
  self.watching = true
  local function tick()
    if not self.pending or self.db.mode == "strip" then self.watching = false return end
    local blockedByBG = self.db.bgStripOnly and self:InstanceType() == "pvp"
    if not self:InCombat() and not blockedByBG then
      self.watching = false
      self:PlayPending()
      return
    end
    C_Timer.After(1, tick)
  end
  C_Timer.After(1, tick)
end

function ns:InstanceType()
  if not IsInInstance then return "none" end
  local inInstance, kind = IsInInstance()
  return inInstance and kind or "none"
end

---------------------------------------------------------------------------
-- Level-up handling
---------------------------------------------------------------------------
-- PLAYER_LEVEL_UP in Classic: level, health, power, talents, str, agi, sta, int, spi.
-- Later clients insert a PvP talent slot count as the 5th value (10 values total).
function ns:ParseLevelUp(...)
  local n = select("#", ...)
  local level, hp, power, talents = ...
  local base = (n >= 10) and 6 or 5
  local str, agi, sta, int, spi = select(base, ...)
  return {
    level = tonumber(level) or UnitLevel("player"),
    hp = tonumber(hp) or 0, power = tonumber(power) or 0,
    talents = tonumber(talents) or 0,
    str = tonumber(str) or 0, agi = tonumber(agi) or 0, sta = tonumber(sta) or 0,
    int = tonumber(int) or 0, spi = tonumber(spi) or 0,
  }
end

---------------------------------------------------------------------------
-- Detecting level-ups. Clients differ in which signal they send (PLAYER_LEVEL_UP,
-- PLAYER_LEVEL_CHANGED, UNIT_LEVEL, or only the "Congratulations" system line), so Grats!
-- listens to all of them and acts once per new level. Stat gains come from the
-- PLAYER_LEVEL_UP values when present, otherwise from a before/after stat snapshot.
---------------------------------------------------------------------------
function ns:Snapshot()
  local s = { level = UnitLevel("player") or 0 }
  s.hp = UnitHealthMax and UnitHealthMax("player") or 0
  s.power = UnitPowerMax and UnitPowerMax("player") or 0
  local keys = { "str", "agi", "sta", "int", "spi" }
  for i, k in ipairs(keys) do
    local base = UnitStat and select(2, UnitStat("player", i)) or nil   -- base value, ignores buffs
    s[k] = tonumber(base) or 0
  end
  self.snap = s
  return s
end

function ns:MeasuredGains(level)
  local before = self.snap or { level = level - 1 }
  local after = self:Snapshot()
  local g = { level = level, talents = (level >= 10) and math.max(0, level - math.max(before.level or (level - 1), 9)) or 0 }
  for _, k in ipairs({ "hp", "power", "str", "agi", "sta", "int", "spi" }) do
    g[k] = math.max(0, (after[k] or 0) - (before[k] or 0))
  end
  return g
end

-- A level signal arrived. `gains` is set only when PLAYER_LEVEL_UP supplied the values.
function ns:LevelSignal(newLevel, gains)
  newLevel = tonumber(newLevel)
  if not newLevel or newLevel <= (self.handledLevel or 0) then return end
  self.handledLevel = newLevel
  self.leveledAt = GetTime()
  self:HookGameText()
  self:HideGameTextNow()
  C_Timer.After(0.1, function() ns:HideGameTextNow() end)
  if gains then
    self:Snapshot()                                      -- keep the baseline current for next time
    self:SafeLevelUp(gains)
  else
    -- Give the client a moment to update max health and stats, then measure.
    C_Timer.After(0.6, function() ns:SafeLevelUp(ns:MeasuredGains(newLevel)) end)
  end
end

-- Builds and presents the review; on any error it still shows a basic review and says why.
function ns:SafeLevelUp(gains)
  local ok, err = pcall(self.HandleGains, self, gains)
  if ok then return end
  self.db.lastError = tostring(err)
  if not self.toldError then
    self.toldError = true
    self:Print("hit an error building this level-up and showed a simple version. Type /gratz error to see it.")
  end
  local fallback = { fromLevel = gains.level, level = gains.level, hp = gains.hp or 0, power = gains.power or 0,
    talents = gains.talents or 0, str = gains.str or 0, agi = gains.agi or 0, sta = gains.sta or 0,
    int = gains.int or 0, spi = gains.spi or 0, spells = {}, leftover = {}, places = {}, trainingCost = 0 }
  pcall(function()
    local _, classToken = UnitClass("player")
    fallback.class, fallback.className = classToken, (UnitClass("player"))
    fallback.faction = UnitFactionGroup("player")
    fallback.char, fallback.charName = ns:CharKey(), UnitName("player")
  end)
  self.pending = fallback
  self:Present(fallback)
end

function ns:HandleGains(gains)
  local review
  if self.pending then
    review = self:MergeReview(self.pending, gains)      -- leveled again before the review played
  else
    review = self:BuildReview(gains)
  end
  self.pending = review
  self:Present(review)
end

-- Direct entry used by /gratz test (always shows, no once-per-level check).
function ns:OnLevelUp(...)
  local gains = self:ParseLevelUp(...)
  self.leveledAt = GetTime()
  self:HideGameTextNow()
  self:SafeLevelUp(gains)
end

-- Decide how to show a fresh (or merged) review.
function ns:Present(review)
  local db = self.db
  if db.mode == "strip" then
    self.pending = nil
    self:PushHistory(review)
    self.Strip:Show(review)
    self.Sound:Chime()
    return
  end
  -- In combat the full panel opens straight away as a faded watermark with working buttons
  -- (Panel:Play fades it); it turns solid and starts paging when combat ends.
  if db.bgStripOnly and self:InstanceType() == "pvp" then
    self.Strip:Show(review)
    self.Sound:Chime()
    self:WatchPending()
    return                                              -- full review after leaving the battleground
  end
  self:PlayPending()
end

function ns:PlayPending()
  local review = self.pending
  if not review then return end
  local wasReplay = self.pendingReplay
  self.pending, self.pendingReplay = nil, nil
  self.Strip:Hide()
  if not wasReplay then self:PushHistory(review) end
  self.Panel:Play(review, false)          -- not flagged as replay, so the post-combat swell rule applies too
end

-- "Name-Realm" for the character being played; saved on each level-up.
function ns:CharKey()
  local name = UnitName and UnitName("player") or "?"
  local realm = GetRealmName and GetRealmName() or ""
  return name .. "-" .. realm
end

-- This character's saved level-ups, newest first, as indexes into db.history.
function ns:CharHistory()
  local me, list = self:CharKey(), {}
  for i, r in ipairs(self.db.history) do
    if r.char == me then table.insert(list, i) end
  end
  return list
end

-- Replay a saved level-up. With no index: this character's latest one.
-- `index` is a position in db.history (the minimap list can replay other characters too).
function ns:Replay(index)
  local h = self.db.history
  if not index then
    index = self:CharHistory()[1]
    if not index then
      self:Print("No level-ups saved for " .. ((UnitName and UnitName("player")) or "this character") .. " yet.")
      return
    end
  end
  local review = h[index]
  if not review then self:Print("No level-ups saved yet.") return end
  self:RefreshReview(review)
  -- A replay behaves exactly like a real level-up: faded panel in combat, strip where the
  -- strip is the chosen style (handy for testing those versions).
  if (self.db.bgStripOnly and self:InstanceType() == "pvp") or self.db.mode == "strip" then
    if self.db.mode ~= "strip" then self.pending, self.pendingReplay = review, true; self:WatchPending() end
    self.Strip:Show(review)
    self.Sound:Chime()
    return
  end
  self.Strip:Hide()
  self.Panel:Play(review, true)
end

-- Saves from before 1.2 have no character name. Each character claims the old ones that
-- fit it (same class and race, not above its level) the first time it logs in.
function ns:ClaimOldHistory()
  local _, classToken = UnitClass("player")
  local _, raceToken = UnitRace("player")
  local level = UnitLevel("player") or 0
  for _, r in ipairs(self.db.history) do
    if not r.char and r.class == classToken and (not r.race or r.race == raceToken) and (r.level or 0) <= level then
      r.char, r.charName = self:CharKey(), UnitName and UnitName("player") or nil
    end
  end
end

-- Keeps the last 5 level-ups per character (40 in all), newest first.
local PER_CHAR, TOTAL = 5, 40
function ns:PushHistory(review)
  local h = self.db.history
  for i = #h, 1, -1 do if h[i] == review then table.remove(h, i) end end
  table.insert(h, 1, review)
  local seen = {}
  for i = 1, #h do
    local k = h[i] and (h[i].char or "?")
    if k then
      seen[k] = (seen[k] or 0) + 1
      if seen[k] > PER_CHAR then h[i] = false end
    end
  end
  for i = #h, 1, -1 do if h[i] == false then table.remove(h, i) end end
  while #h > TOTAL do table.remove(h) end
end

---------------------------------------------------------------------------
-- Default level-up chat lines (CHAT_MSG_SYSTEM)
---------------------------------------------------------------------------
local chatPatterns
local function toPattern(fmt)
  local p = fmt:gsub("([%%%(%)%.%+%-%*%?%[%]%^%$])", "%%%1")
  p = p:gsub("%%%%%d%$d", "%%d+"):gsub("%%%%%d%$s", ".+")
  p = p:gsub("%%%%d", "%%d+"):gsub("%%%%s", ".+")
  return "^" .. p .. "$"
end

function ns:BuildChatPatterns()
  chatPatterns = {}
  local names = { "LEVEL_UP", "LEVEL_UP_HEALTH_MANA", "LEVEL_UP_HEALTH", "LEVEL_UP_STAT",
                  "LEVEL_UP_TALENT_MAIN", "LEVEL_UP_TALENTS", "LEVEL_UP_TALENT_SUB",
                  "LEVEL_UP_SKILL_POINTS", "LEVEL_UP_CHAR_POINTS" }
  for _, name in ipairs(names) do
    local fmt = _G[name]
    if type(fmt) == "string" and fmt ~= "" then table.insert(chatPatterns, toPattern(fmt)) end
  end
end

function ns.ChatFilter(_, _, msg)
  if type(msg) == "string" and LEVEL_UP and chatPatterns and chatPatterns[1] and msg:match(chatPatterns[1]) then
    local lvl = tonumber(msg:match("%d+"))
    if lvl then C_Timer.After(0.3, function() ns:LevelSignal(lvl) end) end   -- backup signal
  end
  if not ns.db or not ns.db.hideChatLines or type(msg) ~= "string" then return false end
  for _, p in ipairs(chatPatterns or {}) do
    if msg:match(p) then return true end
  end
  return false
end

---------------------------------------------------------------------------
-- The game's own centre-screen level-up text
---------------------------------------------------------------------------
-- The game can draw its big level-up text in different frames depending on the client:
-- a dedicated level-up display, an event toast, or the centre-screen message frames.
-- Grats! hides only level-up text, and only in the few seconds after a level-up.
local MESSAGE_FRAMES = { "RaidWarningFrame", "RaidBossEmoteFrame", "UIErrorsFrame" }
local TOAST_FRAMES = { "LevelUpDisplay", "EventToastManagerFrame" }

function ns:IsLevelUpText(msg)
  if type(msg) ~= "string" then return false end
  for _, p in ipairs(chatPatterns or {}) do if msg:match(p) then return true end end
  return false
end

local hooked = {}
function ns:HookGameText()
  for _, name in ipairs(TOAST_FRAMES) do
    local fr = _G[name]
    if fr and fr.HookScript and not hooked[fr] then
      hooked[fr] = true
      fr:HookScript("OnShow", function(frame)
        if ns.db and not ns.db.keepGameText and ns:JustLeveled() then frame:Hide() end
      end)
    end
  end
  if hooksecurefunc then
    for _, name in ipairs(MESSAGE_FRAMES) do
      local fr = _G[name]
      if fr and fr.AddMessage and not hooked[fr] then
        hooked[fr] = true
        hooksecurefunc(fr, "AddMessage", function(frame, msg)
          if ns.db and not ns.db.keepGameText and ns:JustLeveled() and ns:IsLevelUpText(msg) and frame.Clear then
            frame:Clear()
          end
        end)
      end
    end
  end
end

function ns:JustLeveled()
  return self.leveledAt and (GetTime() - self.leveledAt) < 4
end

-- Called on PLAYER_LEVEL_UP: hide any game level-up display that is already up.
function ns:HideGameTextNow()
  if not self.db or self.db.keepGameText then return end
  for _, name in ipairs(TOAST_FRAMES) do
    local fr = _G[name]
    if fr and fr.IsShown and fr:IsShown() then fr:Hide() end
  end
end

---------------------------------------------------------------------------
-- Newer-version notice over addon messages (opt-out)
---------------------------------------------------------------------------
local PREFIX = "GratsLU"
local function versionNumber(v)
  local a, b, c = tostring(v):match("(%d+)%.(%d+)%.(%d+)")
  return (tonumber(a) or 0) * 10000 + (tonumber(b) or 0) * 100 + (tonumber(c) or 0)
end

function ns:SendVersion()
  if ns.VERSION == "dev" then return end
  if not (C_ChatInfo and C_ChatInfo.SendAddonMessage) then return end
  if IsInGuild and IsInGuild() then C_ChatInfo.SendAddonMessage(PREFIX, ns.VERSION, "GUILD") end
  if IsInGroup and IsInGroup() then
    local chan = (IsInRaid and IsInRaid()) and "RAID" or "PARTY"
    C_ChatInfo.SendAddonMessage(PREFIX, ns.VERSION, chan)
  end
end

function ns:OnAddonMessage(prefix, msg)
  if prefix ~= PREFIX or not self.db.versionNotice or self.toldNewer then return end
  if versionNumber(msg) > versionNumber(ns.VERSION) then
    self.toldNewer = true
    self:Print("A newer version (" .. msg .. ") is available on CurseForge.")
  end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local events = CreateFrame("Frame")
ns.eventFrame = events
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_LEVEL_UP")
events:RegisterEvent("UNIT_LEVEL")
pcall(events.RegisterEvent, events, "PLAYER_LEVEL_CHANGED")   -- newer clients only
pcall(events.RegisterEvent, events, "SPELL_DATA_LOAD_RESULT") -- newer clients only
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("CHAT_MSG_ADDON")
events:RegisterEvent("PLAYER_LOGOUT")

events:SetScript("OnEvent", function(_, event, ...)
  if event == "ADDON_LOADED" then
    if ... ~= ADDON then return end
    GratsDB = GratsDB or {}
    fill(GratsDB, defaults)
    if not GratsDB.themeVersion then
      -- 1.2: race themes arrive. Anyone still on the old default moves to "your race".
      if GratsDB.theme == "parchment" then GratsDB.theme = "auto" end
      GratsDB.themeVersion = 2
    end
    ns.db = GratsDB
    GratsCharDB = GratsCharDB or {}
    ns.Sound:RestoreMusic()                           -- in case the last session ended mid-duck
    ns:BuildChatPatterns()
    if ChatFrame_AddMessageEventFilter then ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", ns.ChatFilter) end
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then C_ChatInfo.RegisterAddonMessagePrefix(PREFIX) end
  elseif event == "PLAYER_LOGIN" then
    ns.handledLevel = UnitLevel("player") or 0
    ns:ClaimOldHistory()
    ns:Snapshot()
    ns:PrecacheClassSpells()
    ns:HookGameText()
    ns.Options:Create()
    ns.Minimap:Create()
    ns.Strip:Create()
    ns.Panel:Create()
    ns:SendVersion()
  elseif event == "PLAYER_LEVEL_UP" then
    ns:LevelSignal((...), ns:ParseLevelUp(...))
  elseif event == "PLAYER_LEVEL_CHANGED" then
    local _, newLevel = ...
    ns:LevelSignal(newLevel)
  elseif event == "UNIT_LEVEL" then
    if ... == "player" then ns:LevelSignal(UnitLevel("player")) end
  elseif event == "PLAYER_REGEN_DISABLED" then
    ns.Panel:SetWatermark(true)
  elseif event == "PLAYER_REGEN_ENABLED" then
    ns.Panel:SetWatermark(false)
    if ns.pending and not (ns.db.bgStripOnly and ns:InstanceType() == "pvp") and ns.db.mode ~= "strip" then
      ns:PlayPending()
    end
  elseif event == "PLAYER_ENTERING_WORLD" then
    ns:HookGameText()
    if ns.pending and ns:InstanceType() ~= "pvp" and not ns:InCombat() and ns.db.mode ~= "strip" then
      C_Timer.After(2, function() if ns.pending and not ns:InCombat() then ns:PlayPending() end end)
    end
  elseif event == "SPELL_DATA_LOAD_RESULT" then
    ns.Panel:OnSpellDataLoaded()
  elseif event == "CHAT_MSG_ADDON" then
    ns:OnAddonMessage(...)
  elseif event == "PLAYER_LOGOUT" then
    ns.Sound:RestoreMusic()
  end
end)

---------------------------------------------------------------------------
-- Slash commands: /gratz (always) and /grats (only if no other addon owns it)
---------------------------------------------------------------------------
local function slash(msg)
  local cmd, arg = (msg or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")
  if cmd == "" or cmd == "options" or cmd == "config" then
    ns.Options:Open()
  elseif cmd == "replay" then
    local n = tonumber(arg)
    ns:Replay(n and ns:CharHistory()[n] or nil)
  elseif cmd == "test" then
    local lvl = math.max(2, math.min(60, tonumber(arg) or (UnitLevel("player") or 1)))
    ns:OnLevelUp(lvl, 18, 10, lvl >= 10 and 1 or 0, 2, 1, 2, 0, 1)
  elseif cmd == "strip" then
    local r = ns.db.history[1] or ns:BuildReview(ns:ParseLevelUp(UnitLevel("player"), 18, 10, 1, 2, 1, 2, 0, 1))
    ns.Strip:Show(r)
  elseif cmd == "error" then
    ns:Print(ns.db.lastError and ("last error: " .. ns.db.lastError) or "no errors recorded.")
  elseif cmd == "reset" then
    ns.Panel:ResetPosition(); ns.Strip:ResetPosition()
    ns:Print("Positions reset.")
  else
    ns:Print("/gratz - options, /gratz replay [1-5], /gratz test [level], /gratz strip, /gratz reset")
  end
end

SLASH_GRATZ1 = "/gratz"
SLASH_GRATZ2 = "/grz"
SlashCmdList["GRATZ"] = slash
do
  local taken = false
  for key, _ in pairs(SlashCmdList) do
    local i = 1
    while _G["SLASH_" .. key .. i] do
      if _G["SLASH_" .. key .. i]:lower() == "/grats" then taken = true end
      i = i + 1
    end
  end
  if not taken then SLASH_GRATZ3 = "/grats" end
end

BINDING_HEADER_GRATS = "Grats! Level Up"
BINDING_NAME_GRATS_REPLAY = "Replay last level-up"
BINDING_NAME_GRATS_OPTIONS = "Open Grats! options"

-- Grats! Level Up: visual themes. Uses the Grats! art in Media\ (frame, parchment, gems,
-- plate, buttons, strip, divider, glow, dots). If those files are missing it falls back to
-- the game's own textures, so the addon always draws something sensible.
local _, ns = ...
local Theme = {}
ns.Theme = Theme

local locale = GetLocale and GetLocale() or "enUS"
local nonLatin = { ruRU = true, koKR = true, zhCN = true, zhTW = true }
Theme.titleFont = nonLatin[locale] and STANDARD_TEXT_FONT or "Fonts\\MORPHEUS.TTF"
Theme.bodyFont = nonLatin[locale] and STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"

-- Parchment sources with the crop that holds only clean paper (QuestBG's page sits in the
-- top-left of its 512x512 file; the rest is transparent with torn edges).
local PARCHMENT_TEXTURES = {
  { path = "Interface\\QuestFrame\\QuestBG", coords = { 0.02, 0.56, 0.02, 0.61 } },
  { path = "Interface\\Stationery\\StationeryTest1", coords = { 0, 1, 0, 1 } },
}
local DARK_TEXTURE = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark"
local BORDER = "Interface\\DialogFrame\\UI-DialogBox-Border"

local GOLD = { 0.79, 0.64, 0.29 }
local MEDIA = "Interface\\AddOns\\GratsLevelUp\\Media\\"
Theme.MEDIA = MEDIA
local FACTION = {
  Horde = { border = { 0.60, 0.11, 0.07 }, title = { 0.48, 0.08, 0.05 }, gem = { 0.95, 0.30, 0.20 }, wood = { 0.20, 0.05, 0.03 } },
  Alliance = { border = { 0.23, 0.44, 0.77 }, title = { 0.09, 0.24, 0.48 }, gem = { 0.35, 0.60, 1.00 }, wood = { 0.06, 0.14, 0.30 } },
}

-- Race themes: a full custom frame, page and atmosphere per homeland.
-- To add a race: convert its art with tools/convert_race.py (Grats_Frame_<key>,
-- Grats_Page_<key>, Grats_Atmos_<key>) and add one entry here. Races whose art is not
-- in Media\ are left out of the menu automatically.
-- Coordinates are in the source art's 1024x1536 pixels:
--   inner  = the frame's opening (the page sits just under it)
--   safe   = where text can go without touching the frame
--   sockets = corner socket centre x, y and diameter
--   gem    = corner gem colour (Media\\Grats_Gem_<gem>)
--   size   = drawn larger when a thick border leaves less writing room (text stays the same size)
Theme.RACES = {
  { key = "Human", gem = "Blue", name = "Human", faction = "Alliance", match = { "Human" },
    inner = { 88, 92, 936, 1440 }, safe = { 106, 112, 916, 1422 },
    sockets = { { 64.6, 71.0, 62.6 }, { 958.3, 71.1, 62.7 }, { 64.8, 1463.7, 63.1 }, { 958.6, 1463.7, 63.3 } },
    ink = { 0.32, 0.27, 0.20 }, sub = { 0.47, 0.40, 0.29 }, gain = { 0.16, 0.43, 0.16 }, lightInk = false },
  { key = "Dwarf", gem = "Amber", name = "Dwarf", faction = "Alliance", match = { "Dwarf" },
    inner = { 94, 95, 930, 1440 }, safe = { 130, 131, 894, 1404 },
    sockets = { { 73.2, 77.6, 71.1 }, { 950.3, 77.6, 71.1 }, { 73.1, 1458.2, 70.7 }, { 950.4, 1458.2, 70.6 } },
    ink = { 0.98, 0.93, 0.84 }, sub = { 0.92, 0.79, 0.67 }, gain = { 0.72, 0.88, 0.74 }, lightInk = true },
  { key = "Gnome", gem = "Pink", size = 1.05, name = "Gnome", faction = "Alliance", match = { "Gnome" },
    inner = { 123, 136, 899, 1401 }, safe = { 165, 178, 857, 1361 },
    sockets = { { 107.1, 107.2, 106.6 }, { 914.5, 107.1, 106.8 }, { 106.9, 1433.8, 106.7 }, { 914.5, 1433.8, 107.3 } },
    ink = { 0.75, 0.79, 0.84 }, sub = { 0.60, 0.67, 0.75 }, gain = { 0.32, 0.70, 0.36 }, lightInk = true },
  { key = "NightElf", gem = "Purple", size = 1.3, name = "Night Elf", faction = "Alliance", match = { "NightElf" },
    inner = { 137, 134, 903, 1382 }, safe = { 229, 238, 799, 1318 },
    sockets = { { 103.9, 123.4, 103.0 }, { 919.1, 124.0, 102.6 }, { 102.1, 1441.1, 104.3 }, { 921.5, 1441.3, 103.9 } },
    ink = { 0.14, 0.12, 0.15 }, sub = { 0.26, 0.23, 0.28 }, gain = { 0.10, 0.29, 0.10 }, lightInk = false },
  { key = "HighOrder", gem = "White", name = "High Order", faction = "Alliance", match = { "HighOrder", "SkyborneHighOrder" },
    inner = { 88, 95, 936, 1441 }, safe = { 98, 105, 926, 1433 },
    sockets = { { 50.2, 54.1, 67.6 }, { 973.1, 54.1, 67.5 }, { 50.1, 1481.5, 67.8 }, { 973.2, 1481.4, 67.5 } },
    ink = { 0.34, 0.31, 0.27 }, sub = { 0.48, 0.44, 0.38 }, gain = { 0.16, 0.43, 0.16 }, lightInk = false },
  { key = "Orc", gem = "Red", name = "Orc", faction = "Horde", match = { "Orc" },
    inner = { 104, 128, 920, 1415 }, safe = { 128, 148, 896, 1391 },
    sockets = { { 75.6, 89.6, 72.3 }, { 948.5, 89.7, 72.6 }, { 75.6, 1447.0, 74.3 }, { 948.7, 1446.9, 74.4 } },
    ink = { 0.13, 0.07, 0.03 }, sub = { 0.28, 0.16, 0.06 }, gain = { 0.07, 0.21, 0.07 }, lightInk = false },
  { key = "Troll", gem = "Green", size = 1.2, name = "Troll", faction = "Horde", match = { "Troll" },
    inner = { 94, 119, 926, 1422 }, safe = { 198, 225, 820, 1380 },
    sockets = { { 65.1, 69.8, 71.0 }, { 957.9, 69.7, 70.9 }, { 65.6, 1455.5, 72.5 }, { 957.7, 1455.1, 72.5 } },
    ink = { 0.25, 0.16, 0.05 }, sub = { 0.40, 0.27, 0.09 }, gain = { 0.12, 0.34, 0.12 }, lightInk = false },
  { key = "Tauren", gem = "Teal", size = 1.1, name = "Tauren", faction = "Horde", match = { "Tauren" },
    inner = { 87, 93, 935, 1440 }, safe = { 172, 112, 857, 1420 },
    sockets = { { 57.3, 57.3, 64.2 }, { 966.4, 57.1, 63.7 }, { 57.8, 1468.5, 65.7 }, { 965.5, 1468.5, 66.1 } },
    ink = { 0.19, 0.10, 0.03 }, sub = { 0.35, 0.22, 0.08 }, gain = { 0.08, 0.26, 0.08 }, lightInk = false },
  { key = "Undead", gem = "Lime", name = "Undead", faction = "Horde", match = { "Scourge", "Undead", "Forsaken" },
    inner = { 88, 150, 934, 1428 }, safe = { 104, 166, 918, 1375 },
    sockets = { { 68.8, 90.5, 68.0 }, { 953.6, 90.7, 67.7 }, { 68.8, 1454.1, 67.9 }, { 953.8, 1454.1, 67.6 } },
    ink = { 0.89, 0.87, 0.78 }, sub = { 0.73, 0.72, 0.65 }, gain = { 0.59, 0.84, 0.59 }, lightInk = true },
  { key = "Windshaper", gem = "Cyan", size = 1.1, name = "Windshaper", faction = "Horde", match = { "Windshaper", "SkyborneWindshaper" },
    inner = { 103, 120, 919, 1405 }, safe = { 132, 147, 890, 1380 },
    sockets = { { 82.0, 90.2, 92.1 }, { 940.9, 90.2, 92.2 }, { 81.8, 1442.9, 92.5 }, { 940.9, 1442.9, 92.5 } },
    ink = { 0.17, 0.20, 0.25 }, sub = { 0.32, 0.34, 0.36 }, gain = { 0.09, 0.33, 0.13 }, lightInk = false },
}
local RACE_BY_KEY = {}
for _, r in ipairs(Theme.RACES) do RACE_BY_KEY[r.key] = r end

-- The Dark theme's own frame and page (not a race: it never appears in the race list).
Theme.DARK = { key = "Dark", name = "Dark", faction = nil, match = {}, atmos = false,
    inner = { 87, 86, 937, 1449 }, safe = { 103, 102, 921, 1433 },
    sockets = { { 51.2, 54.8, 65.7 }, { 971.7, 54.9, 65.8 }, { 51.2, 1476.8, 65.6 }, { 971.8, 1476.9, 65.6 } },
    ink = { 0.91, 0.88, 0.82 }, sub = { 0.73, 0.71, 0.66 }, gain = { 0.43, 0.88, 0.50 }, lightInk = true }

local function norm(s) return s and (s:gsub("[%s%-']", ""):lower()) or "" end

-- True when this race's art is in the client (checked once per race).
function Theme:RaceAvailable(key)
  local r = RACE_BY_KEY[key] or (key == "Dark" and self.DARK)
  if not r then return false end
  if r.available == nil then
    local probe = UIParent:CreateTexture(nil, "BACKGROUND")
    r.available = probe:SetTexture(MEDIA .. "Grats_Frame_" .. key) ~= false
                  and probe:SetTexture(MEDIA .. "Grats_Page_" .. key) ~= false
    probe:Hide()
  end
  return r.available
end

function Theme:AvailableRaces()
  local list = {}
  for _, r in ipairs(self.RACES) do if self:RaceAvailable(r.key) then table.insert(list, r) end end
  return list
end

-- The race theme that matches a player (race token or name), or nil.
function Theme:RaceFor(raceToken, raceName)
  local t, n = norm(raceToken), norm(raceName)
  -- If the client reports both Skyborne peoples as plain "Skyborne", the faction tells them apart.
  if t == "skyborne" and n ~= "highorder" and n ~= "windshaper" then
    local fac = UnitFactionGroup and UnitFactionGroup("player")
    return RACE_BY_KEY[(fac == "Alliance") and "HighOrder" or "Windshaper"]
  end
  for _, r in ipairs(self.RACES) do
    for _, m in ipairs(r.match) do
      if norm(m) == t or norm(m) == n then return r end
    end
  end
end

-- Turns the saved theme choice into a concrete one: "auto" picks the player's race
-- (or classic parchment if that race has no art yet); "race:<key>" is any race.
function Theme:Resolve(themeKey, raceToken, raceName)
  if themeKey == "auto" or themeKey == nil then
    local r = self:RaceFor(raceToken, raceName)
    if r and self:RaceAvailable(r.key) then return "race", r end
    return "parchment"
  end
  local key = type(themeKey) == "string" and themeKey:match("^race:(.+)$")
  if key then
    if self:RaceAvailable(key) then return "race", RACE_BY_KEY[key] end
    return "parchment"
  end
  return themeKey
end

-- Returns a resolved palette for the chosen theme and the review's player.
function Theme:Palette(themeKey, classToken, faction, raceToken, raceName)
  local race
  themeKey, race = self:Resolve(themeKey, raceToken or (UnitRace and select(2, UnitRace("player"))), raceName)
  local fac = FACTION[faction or "Horde"] or FACTION.Horde
  local p = {
    page = "parchment",
    border = GOLD, title = { 0.35, 0.10, 0.07 }, text = { 0.23, 0.14, 0.07 },
    sub = { 0.48, 0.35, 0.16 }, up = { 0.11, 0.42, 0.16 }, gem = fac.gem,
    wood = { 0.22, 0.15, 0.09 }, edge = { 0.43, 0.32, 0.14 },
    tint = { 1, 1, 1 },                                   -- multiplies the gold frame art
    faction = (faction == "Alliance") and "Alliance" or "Horde",
  }
  if themeKey == "race" and race then
    p.page = "race"; p.race = race
    p.text = race.ink; p.title = race.ink; p.sub = race.sub; p.up = race.gain
    p.lightInk = race.lightInk
    p.faction = race.faction                              -- gems follow the frame's art
    p.skin = race.key; p.gemArt = race.gem and ("Grats_Gem_" .. race.gem)
    p.border = race.ink; p.edge = race.sub
  elseif themeKey == "dark" then
    p.page = "dark"
    p.border = { 0.66, 0.67, 0.72 }; p.title = { 1.0, 0.82, 0.0 }; p.text = { 0.91, 0.88, 0.82 }
    p.sub = { 0.70, 0.70, 0.74 }; p.up = { 0.43, 0.88, 0.50 }
    p.wood = { 0.12, 0.13, 0.16 }; p.edge = { 0.30, 0.31, 0.35 }
    p.tint = { 0.80, 0.82, 0.88 }
    if self:RaceAvailable("Dark") then                    -- its own frame and page; else the tinted gold frame
      p.frame = self.DARK
      p.skin = "Dark"
      p.text = self.DARK.ink; p.sub = self.DARK.sub; p.up = self.DARK.gain; p.lightInk = true
    end
  elseif themeKey == "class" then
    local c = RAID_CLASS_COLORS and classToken and RAID_CLASS_COLORS[classToken]
    if c then
      p.border = { c.r, c.g, c.b }
      p.title = { c.r * 0.55, c.g * 0.55, c.b * 0.55 }
      p.tint = { 0.45 + 0.55 * c.r, 0.45 + 0.55 * c.g, 0.45 + 0.55 * c.b }
    end
  elseif themeKey == "faction" then
    p.border = fac.border; p.title = fac.title; p.wood = fac.wood
    p.tint = (p.faction == "Alliance") and { 0.60, 0.75, 1.00 } or { 1.00, 0.55, 0.45 }
  end
  return p
end

local function setColor(fs, c) fs:SetTextColor(c[1], c[2], c[3]) end
Theme.SetColor = setColor

function Theme:Font(fs, kind, size)
  local path = (kind == "title") and self.titleFont or self.bodyFont
  if fs:SetFont(path, size, "") == false or not fs:GetFont() then fs:SetFont(STANDARD_TEXT_FONT, size, "") end
end


---------------------------------------------------------------------------
-- Grats! art
---------------------------------------------------------------------------
-- Socket centres and gem size in the source art's pixels (measured by fitting circles to
-- each socket ring; the corners are not quite symmetric). Gem art's visible centre is (31, 31.5) of 64.
local ART = {
  panel = { w = 1024, h = 1536, v = 0.75, rim = 78, file = "Grats_Frame", gem = 74,
            sockets = { { 50.8, 50.7 }, { 970.1, 51.1 }, { 50.7, 1476.6 }, { 970.8, 1476.8 } } },
  strip = { w = 1024, h = 128, v = 1, rim = 0, file = "Grats_Strip", gem = 26,
            sockets = { { 13, 15 }, { 1011, 15 }, { 12.5, 110 }, { 1010, 110 } } },
}

local function artTex(t, name)
  return t:SetTexture(MEDIA .. name) ~= false
end

-- Builds the art layers once. Returns false if the art files are not in the client.
function Theme:BuildArt(f, kind)
  if f.grats_art ~= nil then return f.grats_art end
  local spec = ART[kind]
  local frame = f:CreateTexture(nil, "BORDER", nil, 2)
  frame:SetAllPoints(f)
  if not artTex(frame, spec.file) then
    frame:Hide()
    f.grats_art = false
    return false
  end
  frame:SetTexCoord(0, 1, 0, spec.v)
  f.grats_frameTex = frame
  if kind == "panel" then
    local page = f:CreateTexture(nil, "BACKGROUND")
    f.grats_artPage = page
  end
  f.grats_artGems = {}
  for i = 1, 4 do f.grats_artGems[i] = f:CreateTexture(nil, "OVERLAY") end
  f.grats_art = true
  f.grats_kind = kind
  return true
end

-- Positions page, atmosphere and gems for the frame's current size (call after SetSize).
function Theme:LayoutArt(f)
  local spec = ART[f.grats_kind]
  local W, H = f:GetWidth() or 0, f:GetHeight() or 0
  if W <= 0 or H <= 0 then return end
  local race = f.grats_race
  local kx, ky = W / spec.w, H / spec.h
  if f.grats_artPage then
    f.grats_artPage:ClearAllPoints()
    if race then
      local L, T, R, B = race.inner[1], race.inner[2], race.inner[3], race.inner[4]
      local pad = 5                                         -- tuck the page just under the rim
      f.grats_artPage:SetPoint("TOPLEFT", f, "TOPLEFT", L * kx - pad, -(T * ky - pad))
      f.grats_artPage:SetPoint("BOTTOMRIGHT", f, "TOPLEFT", R * kx + pad, -(B * ky + pad))
    else
      local inset = spec.rim * kx - 6
      f.grats_artPage:SetPoint("TOPLEFT", f, "TOPLEFT", inset, -inset)
      f.grats_artPage:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -inset, inset)
    end
  end
  if f.grats_atmos then
    f.grats_atmos:ClearAllPoints()
    f.grats_atmos:SetAllPoints(f.grats_artPage)
  end
  local sockets = race and race.sockets or spec.sockets
  for i, c in ipairs(sockets) do
    local g = (race and c[3] * 1.12 or spec.gem) * kx
    local s = g / 64
    local t = f.grats_artGems[i]
    t:SetSize(g, g)
    t:ClearAllPoints()
    t:SetPoint("TOPLEFT", f, "TOPLEFT", c[1] * kx - 31.0 * s, -(c[2] * ky - 31.5 * s))
  end
end

-- The text-safe rectangle in frame pixels: left, top, right, bottom insets.
function Theme:SafeInsets(f)
  local race = f.grats_race
  local W, H = f:GetWidth() or 0, f:GetHeight() or 0
  if not race or W <= 0 then return nil end
  local kx, ky = W / 1024, H / 1536
  return race.safe[1] * kx, race.safe[2] * ky, W - race.safe[3] * kx, H - race.safe[4] * ky
end

-- Atmosphere: the race's soft motes/embers/snow, added over the page and drifting slowly upward.
local function atmosUpdate(self, elapsed)
  local t = self.tex
  t.grats_off = ((t.grats_off or 0) + elapsed * 0.012) % 1
  local w, h = t:GetWidth() or 1, t:GetHeight() or 1
  local vspan = (w > 0) and (h / w) or 1
  t:SetTexCoord(0, 1, t.grats_off, t.grats_off + vspan)
end

function Theme:SetAtmosphere(f, on)
  local a = f.grats_atmos
  if not a then return end
  on = on and f.grats_race and f.grats_race.atmos ~= false and ns.db and ns.db.atmosphere ~= false
  if on then
    a:Show()
    a.driver:SetScript("OnUpdate", atmosUpdate)
  else
    a:Hide()
    a.driver:SetScript("OnUpdate", nil)
  end
end

function Theme:ApplyArt(f, palette)
  local race = (f.grats_kind == "panel") and (palette.race or palette.frame) or nil
  f.grats_race = race
  local spec = ART[f.grats_kind]
  artTex(f.grats_frameTex, race and ("Grats_Frame_" .. race.key) or spec.file)
  f.grats_frameTex:SetTexCoord(0, 1, 0, spec.v)
  local t = race and { 1, 1, 1 } or palette.tint
  f.grats_frameTex:SetVertexColor(t[1], t[2], t[3])
  if f.grats_artPage then
    local pageFile = race and ("Grats_Page_" .. race.key)
                     or (palette.page == "dark" and "Grats_Parchment_Dark" or "Grats_Parchment")
    artTex(f.grats_artPage, pageFile)
    f.grats_artPage:SetTexCoord(0, 1, 0, race and 1 or 0.75)
    if race and race.atmos ~= false and not f.grats_atmos then
      local a = f:CreateTexture(nil, "BACKGROUND", nil, 2)
      if a.SetBlendMode then a:SetBlendMode("ADD") end
      a.driver = CreateFrame("Frame", nil, f)
      a.driver.tex = a
      f.grats_atmos = a
    end
    if f.grats_atmos then
      if race and race.atmos ~= false then
        if f.grats_atmos:SetTexture(MEDIA .. "Grats_Atmos_" .. race.key, "REPEAT", "REPEAT") == false then
          f.grats_atmos:SetTexture(nil)
        end
        f.grats_atmos:SetVertexColor(0.35, 0.35, 0.35)
      end
      self:SetAtmosphere(f, race ~= nil and race.atmos ~= false)
    end
  end
  local gem = (palette.faction == "Alliance") and "Grats_Gem_Blue" or "Grats_Gem_Red"
  for _, g in ipairs(f.grats_artGems) do
    if not (palette.gemArt and artTex(g, palette.gemArt)) then artTex(g, gem) end
    g:SetVertexColor(1, 1, 1)
  end
  if f.SetBackdrop then f:SetBackdrop(nil) end
  self:LayoutArt(f)
end

---------------------------------------------------------------------------
-- Buttons: the red lacquer button art as a three-part (left cap, middle, right cap) skin
-- so it keeps its shape at any width. Art rows 14..49 of 64 hold the button.
---------------------------------------------------------------------------
local BTN_V1, BTN_V2, BTN_CAP = 14 / 64, 49 / 64, 24 / 256
local BTN_STATES = { normal = "Grats_Button_Normal", hover = "Grats_Button_Hover",
                     pressed = "Grats_Button_Pressed", disabled = "Grats_Button_Disabled" }

local function setBtnState(b, state)
  if not b.grats_parts then return end
  if not b:IsEnabled() then state = "disabled" end
  b.grats_state = state
  local own = b.grats_skin and BTN_STATES[state]:gsub("Grats_Button_", "Grats_Button_" .. b.grats_skin .. "_")
  for _, part in ipairs(b.grats_parts) do
    if not (own and artTex(part, own)) then artTex(part, BTN_STATES[state]) end
  end
  b.grats_parts[1]:SetTexCoord(0, BTN_CAP, BTN_V1, BTN_V2)
  b.grats_parts[2]:SetTexCoord(BTN_CAP, 1 - BTN_CAP, BTN_V1, BTN_V2)
  b.grats_parts[3]:SetTexCoord(1 - BTN_CAP, 1, BTN_V1, BTN_V2)
end
Theme.SetButtonState = setBtnState

-- Dresses a button in the theme's own colours (palette.skin), or the shared red when it has none.
function Theme:SkinButton(b, palette)
  if not b or not b.grats_parts then return end
  b.grats_skin = palette and palette.skin or nil
  setBtnState(b, b.grats_state or "normal")
end

-- Creates a Grats! button; falls back to the game's red button if the art is missing.
function Theme:MakeButton(parent, w, h, label)
  local probe = parent:CreateTexture(nil, "BACKGROUND")
  local hasArt = artTex(probe, BTN_STATES.normal)
  probe:Hide()
  if not hasArt then
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, h); b:SetText(label or "")
    return b
  end
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(w, h)
  local cap = h * (BTN_CAP * 256) / ((BTN_V2 - BTN_V1) * 64)   -- keep the end caps' proportions
  local L = b:CreateTexture(nil, "BACKGROUND"); L:SetPoint("TOPLEFT"); L:SetPoint("BOTTOMLEFT"); L:SetWidth(cap)
  local R = b:CreateTexture(nil, "BACKGROUND"); R:SetPoint("TOPRIGHT"); R:SetPoint("BOTTOMRIGHT"); R:SetWidth(cap)
  local M = b:CreateTexture(nil, "BACKGROUND"); M:SetPoint("TOPLEFT", L, "TOPRIGHT"); M:SetPoint("BOTTOMRIGHT", R, "BOTTOMLEFT")
  b.grats_parts = { L, M, R }
  local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fs:SetPoint("CENTER", 0, 1)
  b:SetFontString(fs)
  b:SetNormalFontObject("GameFontNormal")
  b:SetHighlightFontObject("GameFontHighlight")
  b:SetDisabledFontObject("GameFontDisable")
  b:SetText(label or "")
  b:SetScript("OnEnter", function(self) setBtnState(self, "hover") end)
  b:SetScript("OnLeave", function(self) setBtnState(self, "normal") end)
  b:SetScript("OnMouseDown", function(self) setBtnState(self, "pressed") end)
  b:SetScript("OnMouseUp", function(self) setBtnState(self, (self.IsMouseOver and self:IsMouseOver()) and "hover" or "normal") end)
  b:HookScript("OnEnable", function(self) setBtnState(self, "normal") end)
  b:HookScript("OnDisable", function(self) setBtnState(self, "disabled") end)
  setBtnState(b, "normal")
  return b
end

-- Small art helpers used by the panel.
function Theme:Divider(t, width)
  if artTex(t, "Grats_Divider") then
    t:SetTexCoord(50 / 512, 452 / 512, 4 / 32, 26 / 32)   -- trim the empty ends
    t:SetSize(width, width * (22 / 402))
    t:SetVertexColor(1, 1, 1, 1)
    return true
  end
  return false
end

function Theme:Dot(t, on, palette)
  if artTex(t, on and "Grats_Dot_On" or "Grats_Dot_Off") then
    t:SetTexCoord(0, 1, 0, 1); t:SetVertexColor(1, 1, 1, 1)
    -- On a race page the plain gold "off" dot can vanish into the paper: ink it instead.
    if not on and palette and palette.race and not palette.lightInk then
      local c = palette.text
      t:SetVertexColor(0.25 + c[1], 0.25 + c[2], 0.25 + c[3], 1)
    end
    return true
  end
  return false
end

function Theme:Glow(t)
  return artTex(t, "Grats_Glow")
end

function Theme:Plate(t, palette)
  if palette and palette.skin and artTex(t, "Grats_TitlePlate_" .. palette.skin) then return true end
  return artTex(t, "Grats_TitlePlate")
end

-- Fallback when the art files are missing:
-- Builds the framed look once: gold outer edge, a dark wood band, an inner edge and a
-- parchment page that fills the whole inside, plus corner gems. `inset` sizes the band.
function Theme:Decorate(f, inset)
  if f.grats_decorated then return end
  f.grats_decorated = true
  inset = inset or 14
  if f.SetBackdrop then
    f:SetBackdrop({ edgeFile = BORDER, edgeSize = 24, insets = { left = 6, right = 6, top = 6, bottom = 6 } })
  end
  local wood = f:CreateTexture(nil, "BACKGROUND", nil, 0)
  wood:SetPoint("TOPLEFT", 5, -5); wood:SetPoint("BOTTOMRIGHT", -5, 5)
  f.grats_wood = wood
  local page = f:CreateTexture(nil, "BACKGROUND", nil, 1)
  page:SetPoint("TOPLEFT", inset, -inset); page:SetPoint("BOTTOMRIGHT", -inset, inset)
  f.grats_page = page
  local shade = f:CreateTexture(nil, "BORDER")
  shade:SetAllPoints(page)
  f.grats_shade = shade
  -- inner edge: four thin lines around the page
  f.grats_edges = {}
  local function line(p1, p2, w, h)
    local t = f:CreateTexture(nil, "BORDER", nil, 1)
    t:SetPoint(p1, page, p1, 0, 0); t:SetPoint(p2, page, p2, 0, 0)
    if w then t:SetWidth(w) else t:SetHeight(h) end
    table.insert(f.grats_edges, t)
  end
  line("TOPLEFT", "TOPRIGHT", nil, 2); line("BOTTOMLEFT", "BOTTOMRIGHT", nil, 2)
  line("TOPLEFT", "BOTTOMLEFT", 2, nil); line("TOPRIGHT", "BOTTOMRIGHT", 2, nil)
  f.grats_gems = {}
  local gemSize = (inset >= 12) and 18 or 12
  for i, pt in ipairs({ "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }) do
    local g = f:CreateTexture(nil, "OVERLAY")
    g:SetSize(gemSize, gemSize)
    g:SetPoint("CENTER", f, pt, 0, 0)
    f.grats_gems[i] = g
  end
end

function Theme:Apply(f, palette, inset)
  if self:BuildArt(f, (inset or 14) >= 12 and "panel" or "strip") then
    return self:ApplyArt(f, palette)
  end
  self:Decorate(f, inset)
  local page, shade, wood = f.grats_page, f.grats_shade, f.grats_wood
  wood:SetColorTexture(palette.wood[1], palette.wood[2], palette.wood[3], 0.97)
  if palette.page == "dark" then
    page:SetTexCoord(0, 1, 0, 1)
    if page:SetTexture(DARK_TEXTURE) == false then page:SetColorTexture(0.08, 0.08, 0.10, 0.96) end
    page:SetVertexColor(1, 1, 1)
    shade:SetColorTexture(0, 0, 0, 0.35)
  else
    local ok = false
    for _, src in ipairs(PARCHMENT_TEXTURES) do
      if page:SetTexture(src.path) ~= false then
        page:SetTexCoord(src.coords[1], src.coords[2], src.coords[3], src.coords[4])
        ok = true
        break
      end
    end
    if ok then page:SetVertexColor(1, 0.97, 0.9) else page:SetTexCoord(0, 1, 0, 1); page:SetColorTexture(0.90, 0.82, 0.62, 1) end
    shade:SetColorTexture(0.35, 0.22, 0.08, 0.08)
  end
  for _, e in ipairs(f.grats_edges) do e:SetColorTexture(palette.edge[1], palette.edge[2], palette.edge[3], 1) end
  if f.SetBackdropBorderColor then
    f:SetBackdropBorderColor(palette.border[1], palette.border[2], palette.border[3], 1)
  end
  for _, g in ipairs(f.grats_gems) do
    if g:SetTexture("Interface\\COMMON\\Indicator-Gray") == false then g:SetColorTexture(1, 1, 1, 1) end
    g:SetVertexColor(palette.gem[1], palette.gem[2], palette.gem[3])
  end
end

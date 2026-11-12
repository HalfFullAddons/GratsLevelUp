-- Grats! Level Up: options panel (Interface > AddOns > Grats! Level Up, or /gratz).
local _, ns = ...
local Options = {}
ns.Options = Options

local panel, category
local refreshers = {}

local function label(parent, text, size, x, y, color)
  local fs = parent:CreateFontString(nil, "OVERLAY", size == "big" and "GameFontNormalLarge" or "GameFontHighlightSmall")
  fs:SetPoint("TOPLEFT", x, y)
  fs:SetText(text)
  if color then fs:SetTextColor(color[1], color[2], color[3]) end
  return fs
end

local function check(parent, text, key, x, y, onChange)
  local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  cb:SetPoint("TOPLEFT", x, y)
  local t = cb.text or cb.Text
  if not t then t = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); t:SetPoint("LEFT", cb, "RIGHT", 2, 0) end
  t:SetText(text)
  cb:SetScript("OnClick", function(self)
    ns.db[key] = self:GetChecked() and true or false
    if onChange then onChange(ns.db[key]) end
  end)
  table.insert(refreshers, function() cb:SetChecked(ns.db[key]) end)
  return cb
end

local sliderCount = 0
local function slider(parent, text, key, minV, maxV, step, x, y, fmt)
  sliderCount = sliderCount + 1
  local name = "GratsOptionsSlider" .. sliderCount
  local ok, sl = pcall(CreateFrame, "Slider", name, parent, "OptionsSliderTemplate")
  if not ok then sl = CreateFrame("Slider", name, parent) end
  sl:SetPoint("TOPLEFT", x, y)
  sl:SetWidth(200)
  sl:SetMinMaxValues(minV, maxV)
  sl:SetValueStep(step)
  if sl.SetObeyStepOnDrag then sl:SetObeyStepOnDrag(true) end
  local title = _G[name .. "Text"] or sl:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  if _G[name .. "Low"] then _G[name .. "Low"]:SetText("") end
  if _G[name .. "High"] then _G[name .. "High"]:SetText("") end
  local function show(v) title:SetText(text .. ": " .. string.format(fmt or "%d%%", (fmt and v) or math.floor(v * 100 + 0.5))) end
  sl:SetScript("OnValueChanged", function(_, v)
    v = math.floor(v / step + 0.5) * step
    ns.db[key] = v
    show(v)
    if key == "scale" or key == "opacity" then
      local f = ns.Panel.frame
      if f and f:IsShown() then ns.Panel:Position(); f:SetAlpha(ns.db.opacity) end
    end
  end)
  table.insert(refreshers, function() sl:SetValue(ns.db[key]); show(ns.db[key]) end)
  return sl
end

local ddCount = 0
-- choices: a list of { value, text } or a function returning one (rebuilt each time it opens).
-- onHover(value) / onHover(nil) lets a menu preview a choice while the mouse is over it.
local function dropdown(parent, text, key, choices, x, y, onChange, onHover)
  ddCount = ddCount + 1
  label(parent, text, nil, x + 18, y)
  local dd = CreateFrame("Frame", "GratsOptionsDropdown" .. ddCount, parent, "UIDropDownMenuTemplate")
  dd:SetPoint("TOPLEFT", x, y - 12)
  UIDropDownMenu_SetWidth(dd, 140)
  local function list() return type(choices) == "function" and choices() or choices end
  local function textFor(v) for _, c in ipairs(list()) do if c[1] == v then return c[2] end end return v end
  UIDropDownMenu_Initialize(dd, function()
    for _, c in ipairs(list()) do
      local info = UIDropDownMenu_CreateInfo()
      if c.header then
        info.text, info.isTitle, info.notCheckable = c[2], true, true
      elseif c.disabled then
        info.text, info.disabled, info.notCheckable = c[2], true, true
      else
        info.text, info.value, info.checked = c[2], c[1], (ns.db[key] == c[1])
        info.func = function()
          ns.db[key] = c[1]
          UIDropDownMenu_SetText(dd, c[2])
          if onChange then onChange(c[1]) end
        end
        if onHover then
          info.funcOnEnter = function() onHover(c[1]) end
          info.funcOnLeave = function() onHover(nil) end
        end
      end
      UIDropDownMenu_AddButton(info)
    end
  end)
  table.insert(refreshers, function() UIDropDownMenu_SetText(dd, textFor(ns.db[key])) end)
  return dd
end

-- Theme menu: your race first, then every race whose art is installed, then the classic looks.
local function themeChoices()
  local Theme = ns.Theme
  local _, raceToken = UnitRace("player")
  local mine = Theme:RaceFor(raceToken, (UnitRace("player")))
  local auto = "My race"
  if mine and Theme:RaceAvailable(mine.key) then auto = "My race (" .. mine.name .. ")"
  else auto = "My race (classic until its art is ready)" end
  local list = { { "auto", auto }, { nil, "Race frames", header = true } }
  for _, r in ipairs(Theme:AvailableRaces()) do table.insert(list, { "race:" .. r.key, r.name }) end
  table.insert(list, { nil, "Classic", header = true })
  table.insert(list, { "parchment", "Parchment (light)" })
  table.insert(list, { "dark", "Dark" })
  table.insert(list, { "class", "Class colours" })
  table.insert(list, { "faction", "Faction colours" })
  return list
end

-- A small live preview of a theme: frame, page, gems and a line of sample ink.
local thumb
local function makeThumb(parent, x, y)
  thumb = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  thumb:SetSize(96, 144)                                 -- the panel at one-third size
  thumb:SetPoint("TOPLEFT", x, y)
  thumb.title = thumb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  thumb.line1 = thumb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  thumb.line2 = thumb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  thumb.caption = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  thumb.caption:SetPoint("TOP", thumb, "BOTTOM", 0, -3)
  thumb.caption:SetWidth(120)
  return thumb
end

local function showThumb(themeKey)
  if not thumb then return end
  local Theme = ns.Theme
  local _, classToken = UnitClass("player")
  local faction = UnitFactionGroup and UnitFactionGroup("player") or "Horde"
  local raceName, raceToken = UnitRace("player")
  local p = Theme:Palette(themeKey or ns.db.theme, classToken, faction, raceToken, raceName)
  Theme:Apply(thumb, p, 14)
  local L, T, R = Theme:SafeInsets(thumb)
  L, T, R = L or 10, T or 10, R or 10
  local cx = (L - R) / 2
  local sw = thumb:GetWidth() - L - R
  thumb.title:SetWidth(sw); thumb.line1:SetWidth(sw); thumb.line2:SetWidth(sw)
  Theme:Font(thumb.title, "title", 15); Theme.SetColor(thumb.title, p.title)
  thumb.title:ClearAllPoints(); thumb.title:SetPoint("TOP", thumb, "TOP", cx, -(T + 14))
  thumb.title:SetText("GRATS!")
  Theme:Font(thumb.line1, "body", 8); Theme.SetColor(thumb.line1, p.text)
  thumb.line1:ClearAllPoints(); thumb.line1:SetPoint("TOP", thumb.title, "BOTTOM", 0, -8)
  thumb.line1:SetText("+18 Health")
  Theme:Font(thumb.line2, "body", 8); Theme.SetColor(thumb.line2, p.up)
  thumb.line2:ClearAllPoints(); thumb.line2:SetPoint("TOP", thumb.line1, "BOTTOM", 0, -4)
  thumb.line2:SetText("2 new spells")
  thumb.caption:SetText(((p.race or p.frame) and ((p.race or p.frame).name .. " frame")) or "Classic frame")
end
Options.ShowThumb = showThumb

function Options:Create()
  if panel then return end
  panel = CreateFrame("Frame", "GratsOptionsPanel")
  panel.name = "Grats! Level Up"
  panel:Hide()

  local bg = panel:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0, 0, 0, 0.35)

  local header = panel:CreateTexture(nil, "BORDER")        -- carved wood title bar (Grats_OptionsHeader)
  header:SetSize(360, 45)
  header:SetPoint("TOPLEFT", 6, -6)
  if header:SetTexture("Interface\\AddOns\\GratsLevelUp\\Media\\Grats_OptionsHeader") == false then header:Hide() end
  label(panel, "Grats! Level Up", "big", 28, -20)
  label(panel, (ns.VERSION == "dev" and "dev build" or ns.VERSION:gsub("^v?", "v", 1)) .. "  ·  /gratz", nil, 200, -24, { 0.7, 0.7, 0.7 })

  -- Column 1: look and placement
  label(panel, "LOOK & PLACEMENT", nil, 18, -66, { 1, 0.82, 0 })
  dropdown(panel, "Theme", "theme", themeChoices, 0, -84,
    function() showThumb(); if ns.Panel.Restyle then ns.Panel:Restyle() end end,
    function(v) showThumb(v) end)
  makeThumb(panel, 196, -72)
  table.insert(refreshers, function() showThumb() end)
  dropdown(panel, "Celebration", "mode", { { "full", "Full" }, { "quick", "Quick (one panel)" }, { "strip", "Strip only" } }, 0, -134)
  dropdown(panel, "Position", "position", { { "right", "Right (beside quest tracker)" }, { "left", "Left" }, { "center", "Center" }, { "custom", "Custom (drag it)" } }, 0, -184)
  dropdown(panel, "Size", "size", { { "small", "Small" }, { "medium", "Medium" }, { "large", "Large" } }, 0, -234)
  slider(panel, "Scale", "scale", 0.7, 1.5, 0.05, 20, -300, "%.2f")
  slider(panel, "Opacity", "opacity", 0.3, 1.0, 0.05, 20, -345)
  slider(panel, "Strip opacity", "combatOpacity", 0.2, 1.0, 0.05, 20, -390)
  slider(panel, "Fade out after (0 = never)", "fadeAfter", 0, 15, 1, 20, -435, "%d s")

  -- Column 2: behaviour and sound
  local x2 = 300
  label(panel, "BEHAVIOUR", nil, x2, -66, { 1, 0.82, 0 })
  check(panel, "Auto-advance pages", "autoAdvance", x2, -82)
  check(panel, "Animate text (fade-in, count-ups)", "textAnim", 16, -462)
  check(panel, "Race atmosphere (drifting motes, embers, snow)", "atmosphere", 16, -488, function()
    showThumb()
    if ns.Panel.frame then ns.Theme:SetAtmosphere(ns.Panel.frame, not ns.Panel.watermark) end
  end)
  check(panel, "Battlegrounds: strip only, full review after", "bgStripOnly", x2, -108)
  check(panel, "Lock the strip in place", "stripLocked", x2, -134, function() ns.Strip:UpdateLock() end)
  check(panel, "Hide the default level-up chat lines", "hideChatLines", x2, -160)
  check(panel, "Keep the game's own level-up text", "keepGameText", x2, -186)
  check(panel, "Tell me when a newer version is out", "versionNotice", x2, -212)
  label(panel, "SOUND", nil, x2, -246, { 1, 0.82, 0 })
  check(panel, "Play sounds", "sound", x2, -262)
  dropdown(panel, "Level-up sound", "levelSound", function()
    local list = {}
    for _, c in ipairs(ns.Sound.CHOICES) do table.insert(list, { c.key, c.name, disabled = (c.ready == false) }) end
    return list
  end, x2 - 16, -290, function(v) if ns.db.sound then ns.Sound:PlayChoice(v) end end)
  check(panel, "Short chime when leveling in combat", "combatChime", x2, -334)
  check(panel, "Race music interlude", "interlude", x2, -360)
  check(panel, "Lower game music during Grats!", "duckMusic", x2, -386)

  local mm = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
  mm:SetPoint("TOPLEFT", x2, -412)
  local mmText = mm.text or mm.Text
  if mmText then mmText:SetText("Show minimap button") end
  mm:SetScript("OnClick", function(self) ns.db.minimap.hide = not self:GetChecked(); ns.Minimap:Update() end)
  table.insert(refreshers, function() mm:SetChecked(not ns.db.minimap.hide) end)

  -- What's Training? integration: available only when that addon is installed.
  label(panel, "TRAINING DATA", nil, x2, -446, { 1, 0.82, 0 })
  local wt = check(panel, "Use What's Training? data", "useWhatsTraining", x2, -462)
  local wtNote = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  wtNote:SetPoint("TOPLEFT", x2 + 30, -488)
  wtNote:SetWidth(260)
  wtNote:SetJustifyH("LEFT")
  table.insert(refreshers, function()
    local loaded
    if C_AddOns and C_AddOns.IsAddOnLoaded then loaded = C_AddOns.IsAddOnLoaded("WhatsTraining")
    elseif IsAddOnLoaded then loaded = IsAddOnLoaded("WhatsTraining") end
    local t = wt.text or wt.Text
    if loaded then
      wt:Enable()
      if t then t:SetTextColor(1, 1, 1) end
      wtNote:SetText("Uses its ignore list and discounted prices. Grats! has its own built-in list either way.")
    else
      wt:Disable()
      wt:SetChecked(false)
      if t then t:SetTextColor(0.5, 0.5, 0.5) end
      wtNote:SetText("Install What's Training? to unlock this: its ignore list and discounted prices. Grats! lists your training either way.")
    end
  end)

  local preview = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  preview:SetSize(120, 24); preview:SetPoint("TOPLEFT", 20, -522); preview:SetText("Preview")
  preview:SetScript("OnClick", function()
    -- Close the game's options window first so the preview isn't hidden (and unclickable) behind it.
    if SettingsPanel and SettingsPanel:IsShown() and HideUIPanel then HideUIPanel(SettingsPanel) end
    if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() and HideUIPanel then HideUIPanel(InterfaceOptionsFrame) end
    SlashCmdList["GRATZ"]("test")
  end)
  local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  reset:SetSize(140, 24); reset:SetPoint("LEFT", preview, "RIGHT", 10, 0); reset:SetText("Reset positions")
  reset:SetScript("OnClick", function() SlashCmdList["GRATZ"]("reset") end)

  label(panel, "Training data includes work from What's Training? by fusionpit (MIT).", nil, 18, -556, { 0.6, 0.6, 0.6 })
  label(panel, "Unofficial fan tool, World of Warcraft is a trademark of Blizzard.", nil, 18, -572, { 0.6, 0.6, 0.6 })

  panel:SetScript("OnShow", function() for _, fn in ipairs(refreshers) do fn() end end)

  if Settings and Settings.RegisterCanvasLayoutCategory then
    category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
  elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
  end
end

function Options:Open()
  self:Create()
  if Settings and Settings.OpenToCategory and category then
    Settings.OpenToCategory(category.GetID and category:GetID() or category.ID or panel.name)
  elseif InterfaceOptionsFrame_OpenToCategory then
    InterfaceOptionsFrame_OpenToCategory(panel)
    InterfaceOptionsFrame_OpenToCategory(panel)   -- first call only opens the frame in older clients
  end
end

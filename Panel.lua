-- Grats! Level Up: the review panel (intro, stats, training, where to next).
local _, ns = ...
local Theme = ns.Theme
local Panel = {}
ns.Panel = Panel

local W, H = 290, 435
local CW = W - 60                -- content width; narrower on race frames with wide borders
local SIZE_SCALE = { small = 0.85, medium = 1.0, large = 1.2 }
local MAX_SPELL_ROWS = 7
local MAX_PLACE_ROWS = 6
local POWER_NAMES = { MANA = "Mana", RAGE = "Rage", ENERGY = "Energy", FOCUS = "Focus" }
local CLASS_NAMES_FALLBACK = "Adventurer"

local f                    -- main frame
local setInteractive       -- defined below
local pool = { fs = {}, tex = {}, used = { fs = 0, tex = 0 } }

---------------------------------------------------------------------------
-- Small widget pool so pages can be rebuilt without leaking regions
---------------------------------------------------------------------------
-- Presentation-style reveal: each "beat" fades in and rises a few pixels, one after another.
local reveal = { list = {}, counts = {}, beat = 0 }
local BEAT, FADE, RISE = 0.14, 0.35, 6

local function beat(n) reveal.beat = n or (reveal.beat + 1) end

-- Numbers that count up from zero when their beat arrives.
local function countUp(fs, fmt, target)
  table.insert(reveal.counts, { fs = fs, fmt = fmt, target = target or 0, beat = reveal.beat })
  fs:SetText(fmt(target or 0))
end

local function resetPool()
  reveal.list, reveal.counts, reveal.beat, reveal.glowBeat = {}, {}, 0, nil
  for _, fs in ipairs(pool.fs) do fs:Hide(); fs:ClearAllPoints() end
  for _, t in ipairs(pool.tex) do t:Hide(); t:ClearAllPoints() end
  pool.used.fs, pool.used.tex = 0, 0
end

local function text(kind, size, color, justify)
  pool.used.fs = pool.used.fs + 1
  local fs = pool.fs[pool.used.fs]
  if not fs then
    fs = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pool.fs[pool.used.fs] = fs
  end
  Theme:Font(fs, kind, size)
  Theme.SetColor(fs, color)
  fs:SetJustifyH(justify or "LEFT")
  fs:SetWordWrap(true)
  fs:SetWidth(0)
  fs:SetAlpha(1)
  fs:Show()
  table.insert(reveal.list, { r = fs, beat = reveal.beat })
  return fs
end

local function tex()
  pool.used.tex = pool.used.tex + 1
  local t = pool.tex[pool.used.tex]
  if not t then
    t = f.content:CreateTexture(nil, "ARTWORK")
    pool.tex[pool.used.tex] = t
  end
  t:SetTexCoord(0, 1, 0, 1)
  t:SetVertexColor(1, 1, 1, 1)
  if t.SetDesaturated then t:SetDesaturated(false) end
  t:SetAlpha(1)
  t:Show()
  table.insert(reveal.list, { r = t, beat = reveal.beat })
  return t
end

---------------------------------------------------------------------------
-- Frame
---------------------------------------------------------------------------
-- Centred navigation layout (same rule as the race mockups)
local NAV = { gap = 4, margin = 14, maxW = 64, h = 25, bottom = 30, dotStep = 16, dotLift = 6 }
ns.NAV = NAV

-- safeW: usable text width of the current frame art (defaults to the content width).
function Panel:LayoutNav(safeW)
  local f = self.frame
  if not f then return end
  safeW = safeW or CW
  local bw = math.floor(math.min(NAV.maxW, (safeW - 2 * NAV.margin - 2 * NAV.gap) / 3))
  local total = 3 * bw + 2 * NAV.gap
  if not f.navAnchor then
    f.navAnchor = CreateFrame("Frame", nil, f)
  end
  f.navAnchor:ClearAllPoints()
  f.navAnchor:SetSize(total, NAV.h)
  f.navAnchor:SetPoint("BOTTOM", f, "BOTTOM", NAV.cx or 0, NAV.bottom)
  local prev
  for _, b in ipairs({ f.back, f.skip, f.next }) do
    b:SetSize(bw, NAV.h)
    b:ClearAllPoints()
    if prev then b:SetPoint("LEFT", prev, "RIGHT", NAV.gap, 0)
    else b:SetPoint("LEFT", f.navAnchor, "LEFT", 0, 0) end
    prev = b
  end
  f.barcheck:SetSize(math.min(W - 70, safeW - 2 * NAV.margin), 24)
  f.barcheck:ClearAllPoints()
  f.barcheck:SetPoint("BOTTOM", f.navAnchor, "TOP", 0, 19)
end

-- Fits the plate, content and buttons inside the current frame art's text-safe area.
function Panel:LayoutFrame()
  local race = self.palette and (self.palette.race or self.palette.frame)
  for _, b in ipairs({ f.back, f.skip, f.next, f.barcheck }) do Theme:SkinButton(b, self.palette) end
  if f.plate.art then Theme:Plate(f.plate.art, self.palette) end
  local m = race and race.size or 1
  f:SetSize(W * m, H * m)
  local FW = W * m
  local L, T, R, B = Theme:SafeInsets(f)
  local plateW
  if L then
    local safeW = FW - L - R
    CW = math.floor(safeW - 8)
    plateW = math.min(196, safeW)
    f.plate:ClearAllPoints()
    f.plate:SetPoint("TOP", f, "TOPLEFT", L + safeW / 2, -(T + 2))
    f.content:ClearAllPoints()
    f.content:SetPoint("TOPLEFT", f, "TOPLEFT", L + 4, -(T + plateW / 4 + 10))
    f.content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -(R + 4), B + 4 + 68)
    NAV.bottom = B + 4
    NAV.cx = (L - R) / 2
    self:LayoutNav(safeW)
  else
    CW = W - 60
    plateW = 196
    f.plate:ClearAllPoints()
    f.plate:SetPoint("TOP", f, "TOP", 0, -14)
    f.content:ClearAllPoints()
    f.content:SetPoint("TOPLEFT", 30, -60)
    f.content:SetPoint("BOTTOMRIGHT", -30, 98)
    NAV.bottom = 30
    NAV.cx = 0
    self:LayoutNav()
  end
  if f.plate.art then f.plate:SetSize(plateW, plateW / 4) end
  if f.grats_art then Theme:LayoutArt(f) end
end

function Panel:Create()
  if f then return end
  f = CreateFrame("Frame", "GratsPanel", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  self.frame = f
  f:SetSize(W, H)
  f:SetFrameStrata("MEDIUM")
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(self) self.grats_dragging = true; self:StartMoving() end)
  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    self.grats_dragging = nil
    local point, _, rel, x, y = self:GetPoint()
    ns.db.custom = { point = point, rel = rel, x = x, y = y }
    ns.db.position = "custom"
  end)
  f:Hide()
  table.insert(UISpecialFrames, "GratsPanel")          -- Esc closes it
  f:SetScript("OnHide", function() Panel:OnClosed() end)

  -- Title plate
  local plate = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate" or nil)
  plate:SetSize(196, 49)
  plate:SetPoint("TOP", f, "TOP", 0, -14)            -- inside the frame, on the parchment
  local plateTex = plate:CreateTexture(nil, "BACKGROUND")
  plateTex:SetAllPoints()
  if Theme:Plate(plateTex) then
    plate.art = plateTex
  elseif plate.SetBackdrop then
    plateTex:Hide()
    plate:SetSize(190, 28)
    plate:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    plate:SetBackdropColor(0.30, 0.07, 0.05, 1)
  end
  plate.text = plate:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  plate.text:SetPoint("CENTER")
  f.plate = plate

  f.content = CreateFrame("Frame", nil, f)
  f.content:SetPoint("TOPLEFT", 30, -60)
  f.content:SetPoint("BOTTOMRIGHT", -30, 98)

  -- Navigation: Back / Skip / Next are one group centred on the page.
  -- Buttons share one width and shrink to fit narrow frames (Panel:LayoutNav).
  f.back = Theme:MakeButton(f, 64, 26, "Back")
  f.back:SetScript("OnClick", function() Panel:Back() end)
  f.skip = Theme:MakeButton(f, 64, 26, "Skip")
  f.skip:SetScript("OnClick", function() f:Hide() end)
  f.next = Theme:MakeButton(f, 64, 26, "Next")
  f.next:SetScript("OnClick", function() Panel:Next() end)
  f.barcheck = Theme:MakeButton(f, W - 70, 24, "View my Bar Check card")
  f.barcheck:SetScript("OnClick", function() Panel:OpenBarCheck() end)
  f.dots = {}
  for i = 1, 3 do
    local d = f:CreateTexture(nil, "OVERLAY")
    d:SetSize(12, 12)
    f.dots[i] = d
  end
  self:LayoutNav()

  -- Golden flash behind the big level number
  local glow = f:CreateTexture(nil, "ARTWORK", nil, 7)
  glow:SetSize(120, 120)
  if not Theme:Glow(glow) and glow:SetTexture("Interface\\Cooldown\\star4") == false then glow:SetColorTexture(1, 0.85, 0.4, 0.5) end
  if glow.SetBlendMode then glow:SetBlendMode("ADD") end
  glow:SetVertexColor(1, 1, 1)
  glow:Hide()
  f.glow = glow
  f.revealer = CreateFrame("Frame", nil, f)
  f.fader = CreateFrame("Frame", nil, f)

  f.slider = CreateFrame("Frame", nil, f)                 -- drives the slide-in (Panel:SlideIn)
end

function Panel:Position()
  local db = ns.db
  f:ClearAllPoints()
  f:SetScale((SIZE_SCALE[db.size] or 1) * (db.scale or 1))
  if db.position == "custom" and db.custom then
    f:SetPoint(db.custom.point or "CENTER", UIParent, db.custom.rel or "CENTER", db.custom.x or 0, db.custom.y or 0)
  elseif db.position == "left" then
    f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -110)
  elseif db.position == "center" then
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
  else
    -- Right (Jim's layout): dock 27 px left of the quest tracker, top 7 px below the tracker's top.
    -- Without a visible tracker, use the same spot as a share of the screen
    -- (right edge 277/1440 in from the screen's right, top 185/810 down).
    local tracker = _G.QuestWatchFrame or _G.WatchFrame
    if tracker and tracker:IsShown() and tracker:GetLeft() and tracker:GetTop() then
      f:SetPoint("TOPRIGHT", tracker, "TOPLEFT", -27, -7)
    else
      local w, h = UIParent:GetWidth() or 1440, UIParent:GetHeight() or 810
      local s = f:GetScale() or 1
      f:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -(w * 277 / 1440) / s, -(h * 185 / 810) / s)
    end
  end
end

function Panel:ResetPosition()
  ns.db.position = "right"; ns.db.custom = nil
  if f and f:IsShown() then self:Position() end
end

---------------------------------------------------------------------------
-- Playing a review
---------------------------------------------------------------------------
function Panel:Play(review, isReplay)
  self:Create()
  self.review = review
  self.manual = false
  self.pages = {}
  if ns.db.mode == "quick" then
    table.insert(self.pages, "quick")
  else
    table.insert(self.pages, "intro")
    table.insert(self.pages, "stats")
    if (review.spells and #review.spells > 0) or (review.leftover and #review.leftover > 0) then table.insert(self.pages, "training") end
    if review.places and #review.places > 0 then table.insert(self.pages, "where") end
  end
  self.palette = Theme:Palette(ns.db.theme, review.class, review.faction, review.race, review.raceName)
  Theme:Apply(f, self.palette, 14)
  self:LayoutFrame()
  self:Position()
  f:SetAlpha(ns.db.opacity or 1)
  self.watermark = false
  setInteractive(true)                                   -- always start clickable, whatever happened last time
  f:Show()
  ns.Sound:Fanfare(review, isReplay)
  ns.Sound:StartInterlude(review)
  self:ShowPage(1)
  if ns:InCombat() then self:SetWatermark(true) end
  self:SlideIn()                                         -- last, so nothing shows solid for a frame first
end

-- The opening move: the panel glides in from the right while fading up, over about a third of
-- a second. Done by hand each frame (the client's animation groups never showed it, and left the
-- panel solid afterwards). It fades up only as far as the panel should be: faint in combat.
local SLIDE_TIME, SLIDE_DIST = 0.35, 40
function Panel:SlideIn()
  local point, rel, relPoint, x, y = f:GetPoint(1)
  if not point or not f.slider then return end
  local function restAlpha() return self.watermark and (ns.db.watermarkOpacity or 0.25) or (ns.db.opacity or 1) end
  local start = GetTime()
  f:SetAlpha(0)
  f:ClearAllPoints()
  f:SetPoint(point, rel, relPoint, (x or 0) + SLIDE_DIST, y or 0)
  f.slider:SetScript("OnUpdate", function(driver)
    local t = (GetTime() - start) / SLIDE_TIME
    if t >= 1 or not f:IsShown() or f.grats_dragging then
      driver:SetScript("OnUpdate", nil)
      if not f.grats_dragging then f:ClearAllPoints(); f:SetPoint(point, rel, relPoint, x, y) end
      f:SetAlpha(restAlpha())
      return
    end
    local e = 1 - (1 - t) * (1 - t)                       -- ease out
    f:ClearAllPoints()
    f:SetPoint(point, rel, relPoint, (x or 0) + SLIDE_DIST * (1 - e), y or 0)
    f:SetAlpha(restAlpha() * e)
  end)
end

-- Re-dress an open panel after the theme changes in the options.
function Panel:Restyle()
  if not (f and f:IsShown() and self.review) then return end
  self.palette = Theme:Palette(ns.db.theme, self.review.class, self.review.faction, self.review.race, self.review.raceName)
  Theme:Apply(f, self.palette, 14)
  self:LayoutFrame()
  if self.watermark then Theme:SetAtmosphere(f, false) end
  self:ShowPage(self.index or 1)
end

function Panel:ShowPage(i)
  self.index = i
  self.waitingForSpells = false
  self.fadeToken = nil
  if f.fader then f.fader:SetScript("OnUpdate", nil); f:SetAlpha(self.watermark and (ns.db.watermarkOpacity or 0.25) or (ns.db.opacity or 1)) end
  local kind = self.pages[i]
  resetPool()
  local p, r = self.palette, self.review
  f.plate.text:SetText("Grats! · " .. ns:LevelText(r))
  if kind == "intro" then f.plate:Hide() else f.plate:Show() end
  Theme:Font(f.plate.text, "title", 14)
  f.plate.text:SetTextColor(1, 0.82, 0.3)
  f.barcheck:Hide()

  if kind == "intro" then self:BuildIntro(p, r)
  elseif kind == "stats" then self:BuildStats(p, r)
  elseif kind == "training" then self:BuildTraining(p, r)
  elseif kind == "where" then self:BuildWhere(p, r)
  else self:BuildQuick(p, r) end

  local last = (i == #self.pages)
  f.next:SetText(last and "Done" or "Next")
  if i > 1 then f.back:Enable() else f.back:Disable() end
  if last and self:BarCheckAvailable() then f.barcheck:Show() end

  -- Page dots for the content pages (not the intro)
  local contentPages = #self.pages - ((self.pages[1] == "intro") and 1 or 0)
  local current = i - ((self.pages[1] == "intro") and 1 or 0)
  local shown = (contentPages > 1) and math.min(contentPages, 3) or 0
  for d = 1, 3 do
    local dot = f.dots[d]
    dot:ClearAllPoints()
    dot:SetPoint("BOTTOM", f.navAnchor, "TOP", (d - (shown + 1) / 2) * NAV.dotStep, NAV.dotLift)
    if d <= shown then
      if not Theme:Dot(dot, d == current, p) then
        dot:SetColorTexture(p.title[1], p.title[2], p.title[3], (d == current) and 1 or 0.3)
      end
      dot:Show()
    else
      dot:Hide()
    end
  end
  self:StartReveal()
  self:ScheduleAdvance(kind)
end

local function ease(x) if x <= 0 then return 0 elseif x >= 1 then return 1 end return 1 - (1 - x) * (1 - x) end

local function savePoints(item)
  local n = item.r.GetNumPoints and item.r:GetNumPoints() or 0
  if not n or n == 0 then return end
  item.points = {}
  for i = 1, n do item.points[i] = { item.r:GetPoint(i) } end
end

local function placeAt(item, dy)
  if not item.points then return end
  item.r:ClearAllPoints()
  for _, pt in ipairs(item.points) do item.r:SetPoint(pt[1], pt[2], pt[3], pt[4] or 0, (pt[5] or 0) + dy) end
end

function Panel:StartReveal()
  local items, counts = reveal.list, reveal.counts
  f.glow:Hide()
  if not ns.db.textAnim then
    for _, c in ipairs(counts) do c.fs:SetText(c.fmt(c.target)) end
    self:ArmTimeout()
    return
  end
  local last = 0
  for _, it in ipairs(items) do
    savePoints(it)
    it.r:SetAlpha(0)
    placeAt(it, -RISE)
    if it.beat > last then last = it.beat end
  end
  for _, c in ipairs(counts) do c.fs:SetText(c.fmt(0)) end
  local glowBeat, glowAnchor = reveal.glowBeat, reveal.glowAnchor
  if glowBeat and glowAnchor then
    f.glow:ClearAllPoints(); f.glow:SetPoint("CENTER", glowAnchor, "CENTER", 0, 0)
    f.glow:SetAlpha(0); f.glow:Show()
  end
  local start = GetTime()
  local finish = last * BEAT + FADE + 0.9
  f.revealer:SetScript("OnUpdate", function(frame)
    local now = GetTime() - start
    for _, it in ipairs(items) do
      local e = ease((now - it.beat * BEAT) / FADE)
      it.r:SetAlpha(e)
      placeAt(it, -RISE * (1 - e))
    end
    for _, c in ipairs(counts) do
      local e = ease((now - c.beat * BEAT - 0.1) / 0.6)
      c.fs:SetText(c.fmt(math.floor(c.target * e + 0.5)))
    end
    if glowBeat then
      local g = now - glowBeat * BEAT
      if g >= 0 and g < 0.9 then
        f.glow:SetAlpha(g < 0.15 and (g / 0.15) or (1 - (g - 0.15) / 0.75))
        f.glow:SetSize(120 + g * 140, 120 + g * 140)
      else
        f.glow:SetAlpha(0)
      end
    end
    if now > finish then
      frame:SetScript("OnUpdate", nil)
      for _, it in ipairs(items) do it.r:SetAlpha(1); placeAt(it, 0) end
      for _, c in ipairs(counts) do c.fs:SetText(c.fmt(c.target)) end
      f.glow:Hide()
      Panel:ArmTimeout()
    end
  end)
end

---------------------------------------------------------------------------
-- Idle timeout: once the last page has finished animating (or the player is paging by hand),
-- wait `fadeAfter` seconds, then fade out. Hovering the panel or combat watermark holds it.
---------------------------------------------------------------------------
local FADE_OUT = 1.2

function Panel:ArmTimeout()
  self.fadeToken = nil
  local secs = ns.db.fadeAfter or 8
  if secs <= 0 or not f:IsShown() then return end
  local lastPage = self.index == #self.pages
  if not (lastPage or self.manual or not ns.db.autoAdvance) then return end
  local token = {}
  self.fadeToken = token
  local function check()
    if self.fadeToken ~= token or not f:IsShown() then return end
    if self.watermark or (f.IsMouseOver and f:IsMouseOver()) then
      C_Timer.After(2, check)                               -- held: look again shortly
      return
    end
    self:FadeOut(token)
  end
  C_Timer.After(secs, check)
end

function Panel:FadeOut(token)
  local startAlpha = f:GetAlpha() or 1
  local start = GetTime()
  f.fader:SetScript("OnUpdate", function(frame)
    if self.fadeToken ~= token or not f:IsShown() then frame:SetScript("OnUpdate", nil) return end
    if f.IsMouseOver and f:IsMouseOver() then              -- player reached for it: cancel and wait again
      frame:SetScript("OnUpdate", nil)
      f:SetAlpha(ns.db.opacity or 1)
      self:ArmTimeout()
      return
    end
    local t = (GetTime() - start) / FADE_OUT
    if t >= 1 then
      frame:SetScript("OnUpdate", nil)
      f:Hide()
      f:SetAlpha(ns.db.opacity or 1)
    else
      f:SetAlpha(startAlpha * (1 - t))
    end
  end)
end

function Panel:ScheduleAdvance(kind)
  local token = {}
  self.advanceToken = token
  if not ns.db.autoAdvance or self.manual then return end
  local secs = ns.db.pageSeconds or 6
  if kind == "intro" then secs = (self.review.milestone and 7) or 4 end
  if kind == "quick" then return end
  C_Timer.After(secs, function()
    if self.advanceToken ~= token or not f:IsShown() then return end
    if self.watermark then self:ScheduleAdvance(kind) return end   -- wait out combat
    if self.index < #self.pages then self:ShowPage(self.index + 1) end
  end)
end

-- Going back means the player is reading: stop auto-advancing for the rest of this review.
-- The client finished loading a spell's details: redraw the training page once (debounced).
function Panel:OnSpellDataLoaded()
  if not self.waitingForSpells or self.refreshQueued then return end
  self.refreshQueued = true
  C_Timer.After(0.3, function()
    self.refreshQueued = false
    if not f or not f:IsShown() or self.pages[self.index] ~= "training" then return end
    self.waitingForSpells = false
    local keepAnim = ns.db.textAnim
    ns.db.textAnim = false                                       -- redraw in place, no second fade-in
    self:ShowPage(self.index)
    ns.db.textAnim = keepAnim
  end)
end

function Panel:Back()
  if self.index and self.index > 1 then
    self.manual = true
    self:ShowPage(self.index - 1)
  end
end

function Panel:Next()
  if self.index and self.index < #self.pages then self:ShowPage(self.index + 1) else f:Hide() end
end

function Panel:OnClosed()
  self.advanceToken = nil
  self.fadeToken = nil
  if f.fader then f.fader:SetScript("OnUpdate", nil) end
  self.watermark = false
  setInteractive(true)
  ns.Sound:StopInterlude(true)
end

-- Turns clicks on or off for the panel's body (dragging, hover). The buttons always stay
-- clickable, so a faded panel can still be skipped or paged through in combat.
function setInteractive(on)
  f:EnableMouse(on)
  for _, b in ipairs({ f.next, f.skip, f.back, f.barcheck }) do b:EnableMouse(true) end
end

-- Combat started while the review is up: fade to a see-through watermark. Clicks pass through
-- the page to the game world; Back / Skip / Next still work.
function Panel:SetWatermark(on)
  if not f or not f:IsShown() then return end
  self.watermark = on
  Theme:SetAtmosphere(f, not on)
  if on then
    f:SetAlpha(ns.db.watermarkOpacity or 0.25)
    setInteractive(false)
    -- Never leave it stuck faint: if the "combat ended" event was missed or arrived early,
    -- clear the watermark as soon as the player is out of combat.
    local token = {}
    self.watermarkToken = token
    local function check()
      if self.watermarkToken ~= token or not self.watermark or not f:IsShown() then return end
      if not ns:InCombat() then self:SetWatermark(false) return end
      C_Timer.After(1, check)
    end
    C_Timer.After(1, check)
  else
    self.watermarkToken = nil
    f:SetAlpha(ns.db.opacity or 1)
    setInteractive(true)
  end
end

---------------------------------------------------------------------------
-- Pages
---------------------------------------------------------------------------
local function header(p, s, anchor)
  beat(0)
  local h = text("title", 19, p.title, "CENTER")
  h:SetPoint("TOP", anchor or f.content, anchor and "BOTTOM" or "TOP", 0, anchor and -6 or -8)
  h:SetWidth(CW + 8)
  h:SetText(s)
  local rule = tex()
  if not Theme:Divider(rule, CW - 30) then
    rule:SetColorTexture(p.border[1], p.border[2], p.border[3], 0.7)
    rule:SetSize(CW - 30, 1)
  end
  rule:SetPoint("TOP", h, "BOTTOM", 0, -4)
  return rule
end

local function row(p, prev, left, right, rightColor, value)
  beat()
  local l = text("body", 13, p.text)
  l:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -7)
  if prev == f.content then l:SetPoint("TOPLEFT", f.content, "TOPLEFT", 0, -7) end
  l:SetText(left)
  local r = text("title", 14, rightColor or p.up, "RIGHT")
  r:SetPoint("RIGHT", f.content, "RIGHT", 0, 0)
  r:SetPoint("TOP", l, "TOP", 0, 0)
  r:SetText(right)
  if value then countUp(r, function(v) return "+" .. v end, value) end
  return l
end

function Panel:BuildIntro(p, r)
  -- GRATS! is the first thing seen, with the golden flash behind it.
  beat(0)
  local grats = text("title", 46, p.title, "CENTER")
  grats:SetPoint("TOP", f.content, "TOP", 0, 18)
  grats:SetText("GRATS!")
  reveal.glowBeat, reveal.glowAnchor = 0, grats
  beat(4)
  local you = text("title", 13, p.sub, "CENTER")
  you:SetPoint("TOP", grats, "BOTTOM", 0, -16)
  you:SetText("YOU HAVE REACHED")
  beat(6)
  local big = text("title", 34, p.title, "CENTER")
  big:SetPoint("TOP", you, "BOTTOM", 0, -8)
  big:SetText(ns:LevelText(r))
  beat(8)
  local rule = tex()
  if not Theme:Divider(rule, CW - 30) then
    rule:SetColorTexture(p.border[1], p.border[2], p.border[3], 0.8)
    rule:SetSize(CW - 50, 1)
  end
  rule:SetPoint("TOP", big, "BOTTOM", 0, -10)
  beat(9)
  local who = text("body", 14, p.text, "CENTER")
  who:SetPoint("TOP", rule, "BOTTOM", 0, -10)
  local cls = r.className or CLASS_NAMES_FALLBACK
  who:SetText((r.raceName and (r.raceName .. " ") or "") .. cls)
  local fac = text("body", 12, p.sub, "CENTER")
  fac:SetPoint("TOP", who, "BOTTOM", 0, -4)
  fac:SetText(r.faction == "Alliance" and "For the Alliance" or (r.faction == "Horde" and "For the Horde" or ""))
  if r.milestone then
    beat(12)
    local m = text("title", 15, { 0.75, 0.55, 0.10 }, "CENTER")
    m:SetPoint("TOP", fac, "BOTTOM", 0, -16)
    m:SetWidth(CW)
    m:SetText(r.milestone)
  end
end

function Panel:BuildStats(p, r)
  local prev = header(p, "Stronger Than Before")
  local function add(label, v)
    if v and v ~= 0 then prev = row(p, prev, label, "+" .. v, nil, v) end
  end
  add("Health", r.hp)
  add(POWER_NAMES[r.powerType or "MANA"] or "Power", r.power)
  add("Strength", r.str); add("Agility", r.agi); add("Stamina", r.sta)
  add("Intellect", r.int); add("Spirit", r.spi)
  add("Talent points", r.talents)
end

local function spellRow(p, prev, s, first)
  beat()
  local icon = tex()
  icon:SetSize(22, 22)
  if first then icon:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", -20, -10) else icon:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -6) end
  if not s.icon or icon:SetTexture(s.icon) == false then icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") end
  icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  local name = text("body", 12, p.text)
  name:SetPoint("LEFT", icon, "RIGHT", 6, 0)
  name:SetWidth(CW - 80)
  name:SetWordWrap(false)
  if not s.name then                                          -- fill in late-loading spell details
    local n, rk, ic = ns.SpellNameRank(s.id)
    if n then s.name, s.rank, s.icon = n, s.rank or rk, s.icon or ic end
    if s.icon and icon:SetTexture(s.icon) ~= false then icon:SetTexCoord(0.07, 0.93, 0.07, 0.93) end
  end
  if s.name then
    name:SetText(s.name .. (s.rank and ("  |cff7a5a2a" .. s.rank .. "|r") or ""))
  else
    name:SetText("|cff7a5a2aLoading...|r")
    Panel.waitingForSpells = true
  end
  local cost = text("body", 11, p.text, "RIGHT")
  cost:SetPoint("RIGHT", f.content, "RIGHT", 0, 0)
  cost:SetPoint("TOP", icon, "TOP", 0, -4)
  if s.known then
    cost:SetText("|cff8a8a8aLearned|r")
    name:SetTextColor(0.5, 0.5, 0.5)                       -- colour, not alpha: the fade-in resets alpha
    if icon.SetDesaturated then icon:SetDesaturated(true) end
    icon:SetVertexColor(0.6, 0.6, 0.6)
  elseif s.quest then
    cost:SetText("Class quest")                            -- not sold by the trainer
  else
    cost:SetText(ns:MoneyText(s.cost))
  end
  return icon
end

function Panel:BuildTraining(p, r)
  local new, left = r.spells or {}, r.leftover or {}
  local prev = header(p, #new > 0 and "New Training Available" or "Still at Your Trainer")
  local rows, budget, first = 0, MAX_SPELL_ROWS, true
  for i = 1, math.min(#new, budget) do
    prev = spellRow(p, prev, new[i], first); first = false; rows = rows + 1
  end
  local hidden = #new - rows
  if #left > 0 then
    local room = budget - rows - ((#new > 0) and 1 or 0)        -- the sub-heading takes a row
    if #new > 0 and room > 0 then
      beat()
      local sub = text("title", 12, p.title)
      sub:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -10)
      sub:SetText("Still at your trainer")
      prev = sub
    end
    local shownLeft = math.max(0, math.min(#left, room))
    for i = 1, shownLeft do
      prev = spellRow(p, prev, left[i], first); first = false
    end
    hidden = hidden + (#left - shownLeft)
  end
  if hidden > 0 then
    beat()
    local more = text("body", 11, p.sub)
    more:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -6)
    more:SetText("+" .. hidden .. " more at your trainer")
    prev = more
  end
  beat()
  local total = text("body", 12, p.text)
  total:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -12)
  countUp(total, function(v) return "Total: " .. ns:MoneyText(v) end, r.trainingCost)
  local have = text("body", 12, p.sub, "RIGHT")
  have:SetPoint("RIGHT", f.content, "RIGHT", 0, 0)
  have:SetPoint("TOP", total, "TOP", 0, 0)
  have:SetText("You have: " .. ns:MoneyText(GetMoney and GetMoney() or 0))
end

function Panel:BuildWhere(p, r)
  local prev = header(p, "New Roads Open")
  beat()
  local intro = text("body", 12, p.sub)
  intro:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -8)
  intro:SetText("You are now ready to check out:")
  prev = intro
  for i = 1, math.min(#r.places, MAX_PLACE_ROWS) do
    local pl = r.places[i]
    beat()
    local kind = text("title", 10, p.border)
    kind:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -9)
    kind:SetText(pl.kind:upper())
    local name = text("body", 13, p.text)
    name:SetPoint("TOPLEFT", kind, "BOTTOMLEFT", 0, -2)
    name:SetText(pl.name)
    local lv = text("body", 11, p.sub, "RIGHT")
    lv:SetPoint("RIGHT", f.content, "RIGHT", 0, 0)
    lv:SetPoint("TOP", name, "TOP", 0, 0)
    lv:SetText(pl.min == pl.max and ("Lv " .. pl.min) or ("Lv " .. pl.min .. "-" .. pl.max))
    prev = name
  end
end

function Panel:BuildQuick(p, r)
  local prev = header(p, ns:LevelText(r) .. "!")
  local parts = {}
  local function add(label, v) if v and v ~= 0 then table.insert(parts, "+" .. v .. " " .. label) end end
  add("HP", r.hp); add(POWER_NAMES[r.powerType or "MANA"] or "Power", r.power)
  add("Str", r.str); add("Agi", r.agi); add("Sta", r.sta); add("Int", r.int); add("Spi", r.spi)
  add("talent", r.talents)
  beat()
  local stats = text("body", 13, p.text, "CENTER")
  stats:SetPoint("TOP", prev, "BOTTOM", 0, -10)
  stats:SetWidth(CW + 10)
  stats:SetText(table.concat(parts, "  ·  "))
  prev = stats
  if (r.spells and #r.spells > 0) or (r.leftover and #r.leftover > 0) then
    beat()
    local t = text("body", 13, p.text, "CENTER")
    t:SetPoint("TOP", prev, "BOTTOM", 0, -14)
    t:SetWidth(CW + 10)
    local waiting = (r.leftover and #r.leftover > 0) and (", +" .. #r.leftover .. " waiting") or ""
    t:SetText(#r.spells .. " new spell" .. (#r.spells == 1 and "" or "s") .. waiting .. " (" .. ns:MoneyText(r.trainingCost) .. ")")
    prev = t
  end
  if r.places and #r.places > 0 then
    local names = {}
    for i = 1, math.min(#r.places, 4) do table.insert(names, r.places[i].name) end
    beat()
    local t = text("body", 13, p.text, "CENTER")
    t:SetPoint("TOP", prev, "BOTTOM", 0, -14)
    t:SetWidth(CW + 10)
    t:SetText("Now open: " .. table.concat(names, ", "))
    prev = t
  end
  if r.milestone then
    beat()
    local m = text("title", 14, { 0.75, 0.55, 0.10 }, "CENTER")
    m:SetPoint("TOP", prev, "BOTTOM", 0, -16)
    m:SetWidth(CW + 10)
    m:SetText(r.milestone)
  end
end

---------------------------------------------------------------------------
-- Optional Bar Check link
---------------------------------------------------------------------------
local function addonLoaded(name)
  if C_AddOns and C_AddOns.IsAddOnLoaded then return C_AddOns.IsAddOnLoaded(name) end
  return IsAddOnLoaded and IsAddOnLoaded(name)
end

function Panel:BarCheckAvailable()
  return addonLoaded("BarCheck") and true or false
end

function Panel:OpenBarCheck()
  local bc = _G.BarCheck
  if type(bc) == "table" and type(bc.ShowCard) == "function" then bc:ShowCard() return end
  if SlashCmdList and SlashCmdList["BARCHECK"] then SlashCmdList["BARCHECK"]("") return end
  ns:Print("Bar Check is installed but its card could not be opened.")
end

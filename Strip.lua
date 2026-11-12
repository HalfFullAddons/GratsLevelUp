-- Grats! Level Up: the condensed strip shown in combat (or in strip-only mode).
-- Left-click: play the full review now. Right-click: dismiss. Drag to move when unlocked.
local _, ns = ...
local Theme = ns.Theme
local Strip = {}
ns.Strip = Strip

local s

function Strip:Create()
  if s then return end
  s = CreateFrame("Button", "GratsStrip", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  self.frame = s
  s:SetSize(344, 43)                      -- matches the strip art (8:1)
  s:SetFrameStrata("MEDIUM")
  s:SetClampedToScreen(true)
  s:SetMovable(true)
  s:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  s:RegisterForDrag("LeftButton")
  s:Hide()

  s.title = s:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  s.title:SetPoint("LEFT", 20, 0)
  s.body = s:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  s.body:SetPoint("LEFT", s.title, "RIGHT", 10, 0)
  s.body:SetPoint("RIGHT", -20, 0)
  s.body:SetJustifyH("LEFT")
  s.body:SetWordWrap(false)

  s.lock = CreateFrame("Button", nil, s)
  s.lock:SetSize(14, 14)
  s.lock:SetPoint("TOPRIGHT", -14, -3)
  s.lock.icon = s.lock:CreateTexture(nil, "OVERLAY")
  s.lock.icon:SetAllPoints()
  s.lock:SetScript("OnClick", function() ns.db.stripLocked = not ns.db.stripLocked; Strip:UpdateLock() end)
  s.lock:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(ns.db.stripLocked and "Locked: click to unlock and drag" or "Unlocked: drag to move, click to lock")
    GameTooltip:Show()
  end)
  s.lock:SetScript("OnLeave", function() GameTooltip:Hide() end)
  s.lock:Hide()

  s:SetScript("OnDragStart", function(self) if not ns.db.stripLocked then self:StartMoving() end end)
  s:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, rel, x, y = self:GetPoint()
    ns.db.stripPos = { point = point, rel = rel, x = x, y = y }
  end)
  s:SetScript("OnClick", function(_, button)
    if button == "RightButton" then
      s:Hide()
    else
      s:Hide()
      if ns.pending then ns:PlayPending()
      elseif Strip.review then ns:RefreshReview(Strip.review); ns.Panel:Play(Strip.review, true)   -- the full review for this strip
      else ns:Replay() end
    end
  end)
  s:SetScript("OnEnter", function(self)
    self.lock:Show()
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText("Grats!")
    GameTooltip:AddLine("Left-click: play the full review", 1, 1, 1)
    GameTooltip:AddLine("Right-click: dismiss", 1, 1, 1)
    GameTooltip:Show()
  end)
  s:SetScript("OnLeave", function(self)
    if not self.lock:IsMouseOver() then self.lock:Hide() end
    GameTooltip:Hide()
  end)
  self:Position()
end

function Strip:UpdateLock()
  if not s then return end
  local M = "Interface\\AddOns\\GratsLevelUp\\Media\\"
  if s.lock.icon:SetTexture(M .. (ns.db.stripLocked and "Grats_Lock" or "Grats_Unlock")) ~= false then return end
  if s.lock.icon:SetTexture(ns.db.stripLocked and "Interface\\Buttons\\LockButton-Locked-Up" or "Interface\\Buttons\\LockButton-Unlocked-Up") == false then
    s.lock.icon:SetColorTexture(1, 0.82, 0, 1)
  end
end

function Strip:Position()
  s:ClearAllPoints()
  local p = ns.db.stripPos
  if p then
    s:SetPoint(p.point or "TOP", UIParent, p.rel or "TOP", p.x or 0, p.y or -90)
  else
    s:SetPoint("TOP", UIParent, "TOP", 0, -90)
  end
end

function Strip:ResetPosition()
  ns.db.stripPos = nil
  if s then self:Position() end
end

function Strip:Show(review)
  self:Create()
  self.review = review
  local p = Theme:Palette(ns.db.theme, review.class, review.faction, review.race, review.raceName)
  if p.race then
    -- The strip keeps the classic parchment (race frames are panel-sized); only the gems follow the race.
    local gemFaction, gemArt = p.faction, p.gemArt
    p = Theme:Palette("parchment", review.class, review.faction)
    p.faction, p.gemArt = gemFaction, gemArt
  end
  Theme:Apply(s, p, 7)
  Theme:Font(s.title, "title", 14)
  Theme.SetColor(s.title, p.title)
  s.title:SetText("Grats! " .. review.level)
  Theme:Font(s.body, "body", 11)
  Theme.SetColor(s.body, p.text)
  local parts = {}
  if (review.hp or 0) > 0 then table.insert(parts, "+" .. review.hp .. " HP") end
  if (review.str or 0) > 0 then table.insert(parts, "+" .. review.str .. " Str") end
  if (review.agi or 0) > 0 then table.insert(parts, "+" .. review.agi .. " Agi") end
  if (review.sta or 0) > 0 then table.insert(parts, "+" .. review.sta .. " Sta") end
  if (review.int or 0) > 0 then table.insert(parts, "+" .. review.int .. " Int") end
  local n = 0
  for _, sp in ipairs(review.spells or {}) do if not sp.known then n = n + 1 end end
  if n > 0 then table.insert(parts, n .. " new spell" .. (n == 1 and "" or "s")) end
  s.body:SetText(table.concat(parts, " · "))
  self:UpdateLock()
  s:SetAlpha(ns.db.combatOpacity or 0.7)
  s:Show()
end

function Strip:Hide()
  if s then s:Hide() end
end

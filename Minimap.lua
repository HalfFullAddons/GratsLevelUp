-- Grats! Level Up: minimap button.
-- Left-click: replay the last level-up. Right-click: pick one of the last 5, or dismiss the strip.
-- Shift-click: options. Drag: move around the minimap.
local _, ns = ...
local Minimap = {}
ns.Minimap = Minimap

local btn, menu

local function updatePosition()
  local angle = math.rad(ns.db.minimap.angle or 200)
  -- Ride the minimap's actual rim (same rule as LibDBIcon): half its width plus 5,
  -- so it lines up with the other buttons whatever size or scale the minimap is.
  local radius = ((_G.Minimap:GetWidth() or 140) / 2) + 5
  btn:ClearAllPoints()
  btn:SetPoint("CENTER", _G.Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function showMenu()
  if not menu then
    menu = CreateFrame("Frame", "GratsMinimapMenu", UIParent, "UIDropDownMenuTemplate")
  end
  UIDropDownMenu_Initialize(menu, function()
    local info = UIDropDownMenu_CreateInfo()
    info.text, info.isTitle, info.notCheckable = "Grats! replays", true, true
    UIDropDownMenu_AddButton(info)
    local h = ns.db.history
    local mine = ns:CharHistory()
    local me = ns:CharKey()
    if #mine == 0 then
      info = UIDropDownMenu_CreateInfo()
      info.text, info.disabled, info.notCheckable = "No level-ups yet on " .. (UnitName("player") or "this character"), true, true
      UIDropDownMenu_AddButton(info)
    end
    for _, i in ipairs(mine) do
      local r = h[i]
      info = UIDropDownMenu_CreateInfo()
      info.text = ns:LevelText(r) .. ((r.className and (" · " .. r.className)) or "")
      info.notCheckable = true
      info.func = function() ns:Replay(i) end
      UIDropDownMenu_AddButton(info)
    end
    local others = false
    for i, r in ipairs(h) do
      if r.char ~= me then
        if not others then
          others = true
          info = UIDropDownMenu_CreateInfo()
          info.text, info.isTitle, info.notCheckable = "Other characters", true, true
          UIDropDownMenu_AddButton(info)
        end
        info = UIDropDownMenu_CreateInfo()
        info.text = (r.charName or "Earlier save") .. " · " .. ns:LevelText(r) .. ((r.className and (" · " .. r.className)) or "")
        info.notCheckable = true
        info.func = function() ns:Replay(i) end
        UIDropDownMenu_AddButton(info)
      end
    end
    info = UIDropDownMenu_CreateInfo()
    info.text, info.notCheckable = "Dismiss strip", true
    info.func = function() ns.Strip:Hide() end
    UIDropDownMenu_AddButton(info)
    info = UIDropDownMenu_CreateInfo()
    info.text, info.notCheckable = "Options", true
    info.func = function() ns.Options:Open() end
    UIDropDownMenu_AddButton(info)
  end, "MENU")
  ToggleDropDownMenu(1, nil, menu, btn, 0, 0)
end

function Minimap:Create()
  if btn or not _G.Minimap then return end
  btn = CreateFrame("Button", "GratsMinimapButton", _G.Minimap)
  btn:SetSize(31, 31)
  btn:SetFrameStrata("MEDIUM")
  btn:SetFrameLevel(8)
  btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  btn:RegisterForDrag("LeftButton")
  btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  local icon = btn:CreateTexture(nil, "BACKGROUND")
  icon:SetSize(20, 20)
  icon:SetPoint("CENTER", 0, 1)
  if icon:SetTexture("Interface\\AddOns\\GratsLevelUp\\Media\\Grats_MinimapIcon") ~= false then
    icon:SetSize(22, 22)
  elseif icon:SetTexture("Interface\\Icons\\Spell_Holy_SurgeOfLight") ~= false then
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  else
    icon:SetColorTexture(1, 0.82, 0, 1)
  end
  local border = btn:CreateTexture(nil, "OVERLAY")
  border:SetSize(53, 53)
  border:SetPoint("TOPLEFT")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

  btn:SetScript("OnClick", function(_, button)
    if IsShiftKeyDown() then ns.Options:Open()
    elseif button == "RightButton" then showMenu()
    else ns:Replay() end
  end)
  btn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
      local mx, my = _G.Minimap:GetCenter()
      local cx, cy = GetCursorPosition()
      local s = _G.Minimap:GetEffectiveScale()
      ns.db.minimap.angle = math.deg(math.atan2(cy / s - my, cx / s - mx))
      updatePosition()
    end)
  end)
  btn:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
  btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Grats! Level Up")
    GameTooltip:AddLine("Left-click: replay last level-up", 1, 1, 1)
    GameTooltip:AddLine("Right-click: replays and strip", 1, 1, 1)
    GameTooltip:AddLine("Shift-click: options", 1, 1, 1)
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
  _G.Minimap:HookScript("OnSizeChanged", function() if btn then updatePosition() end end)
  self:Update()
end

function Minimap:Update()
  if not btn then return end
  updatePosition()
  if ns.db.minimap.hide then btn:Hide() else btn:Show() end
end

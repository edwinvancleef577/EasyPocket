-- Lua 5.0: settings and diagnostics load independently of the spell pocket.
local ADDON = "EasyPocket"
EasyPocket = EasyPocket or {}
local EP = EasyPocket
local function L(key) return EP.L and EP.L(key) or key end
local function size(frame, width, height) frame:SetWidth(width); frame:SetHeight(height) end
EP.VERSION = "0.5.0-octowow-alpha"
local icon, statusWindow
local errorLog={}

local function say(message)
    local value = "|cff65d6c2EasyPocket:|r " .. message
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(value) else print(value) end
end

local function label(parent, value, x, y, font)
    local item = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
    item:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    item:SetText(value)
    return item
end

local function panel(name, width, height)
    if EP.Window then return EP.Window(name,width,height,"EasyPocket · "..L("Debug")) end
    local frame = CreateFrame("Frame", name, UIParent)
    size(frame, width, height)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=16,
        insets={left=4,right=4,top=4,bottom=4}})
    frame:SetBackdropColor(0.08,0.065,0.045,0.96)
    frame:SetBackdropBorderColor(0.85,0.77,0.6,1)
    frame:Hide()
    table.insert(UISpecialFrames, name)
    return frame
end

local function button(parent, name, caption, x, y, width, action)
    if EP.Button then return EP.Button(parent,name,caption,width,x,y,action) end
    local item = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    size(item, width, 28)
    item:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    item:SetText(caption)
    item:SetScript("OnClick", action)
    return item
end

local function statusText()
    local version, build = "unbekannt", "unbekannt"
    if GetBuildInfo then version, build = GetBuildInfo() end
    local interface = "11200 (OctoWoW / Vanilla)"
    local state = L(EP.ready and "Ready" or "Not started")
    if EP.waitingForCombat then state = "Wartet auf Kampfende" end
    if EP.lastError then state = L("Error") end
    local lines = {
        "EasyPocket " .. EP.VERSION,
        "WoW: " .. tostring(version) .. " / Build " .. tostring(build),
        "Interface: " .. tostring(interface),
        "Zielclient: OctoWoW / Vanilla-API",
        L("Status")..": " .. state,
        "Kern geladen: " .. (EP.coreLoaded and "Ja" or "Nein"),
        "",
    }
    if EP.lastError then
        table.insert(lines,table.concat(errorLog,"\n\n"))
    elseif not EP.coreLoaded then
        lines[table.getn(lines) + 1] = "EasyPocket.lua wurde nicht vollständig geladen. Bitte den kompletten Addon-Ordner ersetzen und WoW neu starten."
    elseif not EP.ready then
        lines[table.getn(lines) + 1] = EP.startupMessage or "Die Initialisierung ist noch nicht abgeschlossen."
    else
        lines[table.getn(lines) + 1] = "Taschen im Menü verwalten; Zauber direkt ins Taschenfenster ziehen."
    end
    return table.concat(lines, "\n")
end

function EP.ShowStatus()
    if not statusWindow then
        statusWindow = panel("EasyPocketStatus", 530, 390)
        statusWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        if not statusWindow.title then label(statusWindow,"EasyPocket · "..L("Debug"),18,-18,"GameFontNormalLarge") end
        statusWindow.hint=label(statusWindow,L("Select text, Ctrl+A, Ctrl+C to copy."),18,-47,"GameFontHighlightSmall")
        local scroll = CreateFrame("ScrollFrame", "EasyPocketStatusScroll", statusWindow, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", statusWindow, "TOPLEFT", 20, -76)
        scroll:SetPoint("BOTTOMRIGHT", statusWindow, "BOTTOMRIGHT", -42, 54)
        local edit = CreateFrame("EditBox", "EasyPocketStatusText", scroll)
        edit:SetMultiLine(true)
        edit:SetScript("OnMouseDown",function() if EP.Focus then EP.Focus(edit) end end)
        edit:SetAutoFocus(false)
        edit:SetFontObject(ChatFontNormal)
        edit:SetWidth(455)
        edit:SetHeight(260)
        edit:SetScript("OnEscapePressed", function() statusWindow:Hide() end)
        scroll:SetScrollChild(edit)
        statusWindow.edit = edit
        statusWindow.close=button(statusWindow,nil,L("Close"),18,-345,120,function() statusWindow:Hide() end)
    end
    statusWindow.edit:SetText(statusText())
    statusWindow:Show()
    if EP.Focus then EP.Focus(statusWindow) end
end
function EP.RefreshStatus()
    if not statusWindow then return end
    if statusWindow.title then statusWindow.title:SetText("EasyPocket · "..L("Debug")) end
    statusWindow.hint:SetText(L("Select text, Ctrl+A, Ctrl+C to copy."))
    statusWindow.close:SetText(L("Close")); statusWindow.edit:SetText(statusText())
end

function EP.ReportError(context, message)
    EP.lastError = context .. ":\n" .. tostring(message)
    table.insert(errorLog,EP.lastError)
    if table.getn(errorLog)>10 then table.remove(errorLog,1) end
    if statusWindow and statusWindow:IsShown() then statusWindow.edit:SetText(statusText()) end
    say(L("Error")..": "..context..". "..L("Error details: menu > Debug."))
end

function EP.SafeCallback(callback)
    return function(a,b)
        local ok,err=pcall(callback,a,b)
        if not ok then EP.ReportError("Bedienung",err) end
    end
end

function EP.Run(action, argument)
    if action == "ShowStatus" then EP.ShowStatus(); return end
    if not EP.ready or type(EP[action]) ~= "function" then
        EP.ShowStatus()
        return
    end
    local ok, err = xpcall(function() EP[action](argument) end, function(message)
        return tostring(message)
    end)
    if not ok then EP.ReportError(action, err); EP.ShowStatus() end
end

local function positionIcon()
    local angle = math.rad(EasyPocketMinimapDB.angle)
    local radius = math.max(Minimap:GetWidth(), Minimap:GetHeight()) / 2 + 6
    icon:ClearAllPoints()
    icon:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

function EP.UpdateMinimapIcon(texture)
    if icon and icon.texture then icon.texture:SetTexture(texture) end
end

local function createIcon()
    if icon or not Minimap then return end
    if type(EasyPocketMinimapDB) ~= "table" then EasyPocketMinimapDB = {} end
    local angle = tonumber(EasyPocketMinimapDB.angle)
    if not angle or angle ~= angle or math.abs(angle) > 1000000 then angle = 225 end
    EasyPocketMinimapDB.angle = math.mod(angle, 360)
    icon = CreateFrame("Button", "EasyPocketMinimapButton", Minimap)
    size(icon, 32, 32)
    icon:SetFrameStrata("MEDIUM")
    icon:SetFrameLevel(Minimap:GetFrameLevel() + 10)
    icon:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    icon:RegisterForDrag("LeftButton")
    local texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture = texture
    size(texture, 20, 20)
    texture:SetPoint("CENTER", icon, "CENTER", 0, 0)
    texture:SetTexture("Interface\\Icons\\INV_Misc_Bag_08")
    texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local border = icon:CreateTexture(nil, "OVERLAY")
    size(border, 54, 54)
    border:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    icon:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    icon:SetScript("OnClick", function()
        EP.Run("ToggleMenu")
    end)
    icon:SetScript("OnEnter", function(self)
        self = self or this
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("EasyPocket")
        GameTooltip:AddLine(L("Click: open menu"),1,1,1)
        GameTooltip:AddLine(L("Drag: move icon"),.7,.8,.8)
        GameTooltip:Show()
    end)
    icon:SetScript("OnLeave", function() GameTooltip:Hide() end)
    icon:SetScript("OnDragStart", function(self)
        self = self or this
        if self:GetParent() ~= Minimap then return end
        GameTooltip:Hide()
        self:SetScript("OnUpdate", function()
            local cx, cy = Minimap:GetCenter()
            if not cx or not cy then return end
            local x, y = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            EasyPocketMinimapDB.angle = math.mod(math.deg(math.atan2(y / scale - cy, x / scale - cx)), 360)
            positionIcon()
        end)
    end)
    icon:SetScript("OnDragStop", function(self) (self or this):SetScript("OnUpdate", nil) end)
    positionIcon()
    icon:Show()
end

-- Register before the core file is loaded; diagnostics still work if it fails.
SLASH_EASYPOCKET1 = "/ep"
SLASH_EASYPOCKET2 = "/easypocket"
SlashCmdList.EASYPOCKET = function(message)
    if string.find(message or "", "^%s*status%s*$") then EP.ShowStatus()
    else EP.Run("HandleCommand", message) end
end

local startup = CreateFrame("Frame")
startup:RegisterEvent("ADDON_LOADED")
startup:RegisterEvent("PLAYER_LOGIN")
startup:RegisterEvent("PLAYER_ENTERING_WORLD")
startup:SetScript("OnEvent", function(frame, eventName, name)
    eventName = eventName or event
    name = name or arg1
    if eventName == "ADDON_LOADED" and name ~= ADDON then return end
    local ok, err = pcall(createIcon)
    if not ok then EP.ReportError("Minimap-Start", err) end
end)

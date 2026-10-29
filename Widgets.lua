-- Shared Easy-style controls and explicit whole-window layer ordering.
local EP=EasyPocket
local roots={}
local white="Interface\\Buttons\\WHITE8X8"
local function size(f,w,h) f:SetWidth(w); f:SetHeight(h) end
EP.Size=size
function EP.Box(f,kind)
    if kind=="CLASSIC" then
        f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
            tile=true,tileSize=32,edgeSize=24,insets={left=7,right=7,top=7,bottom=7}})
        f:SetBackdropColor(1,1,1,1); f:SetBackdropBorderColor(1,1,1,1)
    elseif kind=="CURRENT" then
        f:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
            tile=true,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
        f:SetBackdropColor(.08,.065,.045,1); f:SetBackdropBorderColor(.85,.77,.6,1)
    else
        f:SetBackdrop({bgFile=white,edgeFile=white,tile=false,edgeSize=1,insets={left=1,right=1,top=1,bottom=1}})
        f:SetBackdropColor(.045,.051,.046,1)
        if kind=="PFUI" then f:SetBackdropBorderColor(.015,.015,.015,1)
        else f:SetBackdropBorderColor(.48,.41,.25,1) end
    end
end
local function layers(f,strata,level)
    f:SetFrameStrata(strata); f:SetFrameLevel(level)
    if f.GetChildren then for _,child in ipairs({f:GetChildren()}) do layers(child,strata,level+1) end end
end
function EP.FixLayers()
    for i,f in ipairs(roots) do layers(f,"DIALOG",100+i*32) end
end
function EP.Focus(frame)
    local root=frame
    while root and not root.epWindow do root=root:GetParent() end
    if not root then return end
    for i,f in ipairs(roots) do if f==root then table.remove(roots,i); break end end
    table.insert(roots,root)
    -- Floating pickers remain above their owner's complete subtree.
    local floating={}
    for _,f in ipairs(roots) do if f.owner==root and f:IsShown() then table.insert(floating,f) end end
    for _,f in ipairs(floating) do
        for i,v in ipairs(roots) do if v==f then table.remove(roots,i); break end end
        table.insert(roots,f)
    end
    EP.FixLayers()
end
function EP.Window(name,width,height,title)
    local f=CreateFrame("Frame",name,UIParent)
    size(f,width,height); f:SetClampedToScreen(true); f:EnableMouse(true)
    f.epWindow=true; table.insert(roots,f); EP.Box(f,"CLASSIC")
    f:SetScript("OnShow",function() EP.Focus(f) end)
    f:SetScript("OnMouseDown",function() EP.Focus(f) end)
    if title then
        local header=f:CreateTexture(nil,"ARTWORK")
        header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
        size(header,256,64); header:SetPoint("TOP",f,"TOP",0,12)
        f.title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
        size(f.title,220,24); f.title:SetJustifyH("CENTER")
        f.title:SetPoint("CENTER",header,"CENTER",0,12); f.title:SetText(title)
    end
    f:Hide(); table.insert(UISpecialFrames,name); EP.FixLayers()
    return f
end
function EP.Text(parent,value,x,y,font)
    local label=parent:CreateFontString(nil,"OVERLAY",font or "GameFontNormal")
    label:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y); label:SetText(value)
    return label
end
function EP.Button(parent,name,caption,width,x,y,action)
    local b=CreateFrame("Button",name,parent)
    size(b,width,28); b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y); EP.Box(b)
    b:SetFrameLevel(parent:GetFrameLevel()+1)
    b.face={.24,.21,.15}; b.label=b:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    b.label:SetPoint("CENTER",b,"CENTER",0,0); b.label:SetWidth(width-10); b.label:SetJustifyH("CENTER")
    b.SetText=function(self,value) self.label:SetText(value) end
    b.GetText=function(self) return self.label:GetText() end
    b:SetText(caption)
    local sheen=b:CreateTexture(nil,"ARTWORK"); sheen:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    sheen:SetPoint("TOPLEFT",b,"TOPLEFT",1,-1); sheen:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-1,1)
    local function paint(down,hover)
        local factor=down and .65 or 1
        b:SetBackdropColor(b.face[1]*factor,b.face[2]*factor,b.face[3]*factor,1)
        sheen:SetVertexColor(b.face[1]*factor,b.face[2]*factor,b.face[3]*factor,1)
        if hover then b:SetBackdropBorderColor(.88,.72,.35,1) else b:SetBackdropBorderColor(.48,.41,.25,1) end
    end
    b:RegisterForClicks("LeftButtonUp")
    b:SetScript("OnMouseDown",function() EP.Focus(b); paint(true,true) end)
    b:SetScript("OnMouseUp",function() paint(false,true) end)
    b:SetScript("OnEnter",function() paint(false,true) end)
    b:SetScript("OnLeave",function() paint(false,false) end)
    b:SetScript("OnClick",EP.SafeCallback(function() EP.Focus(b); action() end))
    paint(false,false)
    return b
end
function EP.CloseButton(parent)
    local b=CreateFrame("Button",nil,parent,"UIPanelCloseButton")
    size(b,26,26); b:SetPoint("TOPRIGHT",parent,"TOPRIGHT",-6,-6)
    b:SetScript("OnClick",function() parent:Hide() end)
    return b
end
function EP.CloseDropdown()
    if EP.dropdownLayer then EP.dropdownLayer:Hide() end
    EP.dropdownOwner=nil
end
function EP.UpdateDropdown(b)
    for _,entry in ipairs(b.options) do
        if entry[1]==b.value() then b:SetText(EP.L(entry[2])); return end
    end
    b:SetText("")
end
function EP.OpenDropdown(b)
    if EP.dropdownOwner==b and EP.dropdownLayer:IsShown() then EP.CloseDropdown(); return end
    EP.Focus(b)
    if not EP.dropdownLayer then
        local layer=CreateFrame("Button","EasyPocketDropdownLayer",UIParent)
        layer:SetAllPoints(UIParent); layer:EnableMouse(true); layer:RegisterForClicks("LeftButtonUp")
        layer:SetScript("OnClick",EP.CloseDropdown); layer:Hide()
        table.insert(UISpecialFrames,"EasyPocketDropdownLayer")
        EP.dropdownLayer=layer
        local menu=CreateFrame("Frame","EasyPocketDropdownMenu",layer)
        EP.Box(menu); menu:EnableMouse(true); menu:SetClampedToScreen(true); menu.rows={}; EP.dropdownMenu=menu
    end
    local layer,menu=EP.dropdownLayer,EP.dropdownMenu
    EP.dropdownOwner=b
    layer:SetFrameStrata("FULLSCREEN_DIALOG"); layer:SetFrameLevel(900)
    menu:SetFrameStrata("FULLSCREEN_DIALOG"); menu:SetFrameLevel(901)
    local width=math.max(180,b:GetWidth())
    size(menu,width,table.getn(b.options)*28+8); menu:ClearAllPoints()
    menu:SetScale(b:GetEffectiveScale()/UIParent:GetEffectiveScale())
    local bottom=b.GetBottom and b:GetBottom()
    if bottom and bottom*b:GetEffectiveScale()/UIParent:GetEffectiveScale()<menu:GetHeight()*menu:GetEffectiveScale()/UIParent:GetEffectiveScale()+10 then
        menu:SetPoint("BOTTOMRIGHT",b,"TOPRIGHT",0,3)
    else menu:SetPoint("TOPRIGHT",b,"BOTTOMRIGHT",0,-3) end
    for i,entry in ipairs(b.options) do
        local row=menu.rows[i]
        if not row then
            row=EP.Button(menu,"EasyPocketDropdownOption"..i,"",width-8,4,-4-(i-1)*28,function() end)
            row:SetScript("OnClick",EP.SafeCallback(function()
                local owner,value=EP.dropdownOwner,row.value
                EP.CloseDropdown()
                if owner then owner.choose(value); EP.UpdateDropdown(owner) end
            end))
            menu.rows[i]=row
        end
        row.value=entry[1]; row:SetWidth(width-8); row.label:SetWidth(width-18)
        row:SetText(EP.L(entry[2])); row:SetFrameStrata("FULLSCREEN_DIALOG"); row:SetFrameLevel(902); row:Show()
    end
    for i=table.getn(b.options)+1,table.getn(menu.rows) do menu.rows[i]:Hide() end
    layer:Show(); menu:Show()
end
function EP.Dropdown(parent,name,width,x,y,options,value,choose)
    local b
    b=EP.Button(parent,name,"",width,x,y,function() EP.OpenDropdown(b) end)
    b.options,b.value,b.choose=options,value,choose
    b.arrow=b:CreateTexture(nil,"OVERLAY"); b.arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    size(b.arrow,16,16); b.arrow:SetPoint("RIGHT",b,"RIGHT",-4,0)
    b.label:ClearAllPoints(); b.label:SetPoint("LEFT",b,"LEFT",8,0); b.label:SetWidth(width-30); b.label:SetJustifyH("LEFT")
    EP.UpdateDropdown(b)
    return b
end
function EP.StylePocket(window,p)
    EP.Box(window,p.design)
    for _,b in ipairs(window.buttons) do
        local normal=b:GetNormalTexture()
        if p.design=="PFUI" then
            EP.Box(b,"PFUI"); if normal then normal:Hide() end
        elseif p.design=="CLASSIC" then
            b:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
                tile=true,tileSize=16,edgeSize=12,insets={left=2,right=2,top=2,bottom=2}})
            b:SetBackdropColor(1,1,1,1); b:SetBackdropBorderColor(.75,.75,.75,1)
            if normal then normal:Show() end
        else
            b:SetBackdrop(nil); if normal then normal:Show() end
        end
    end
end

-- OctoWoW / Vanilla APIs; Lua 5.0, no ClassicAPI or SuperWoW dependency.
local EP = EasyPocket
local db, editor, iconPicker
local windows,rows={},{}
local deleteId=nil
local listOffset=0
local known, knownByName = {}, {}
local BOOK = BOOKTYPE_SPELL or "spell"
local refreshEditor, layoutPocket, refreshIconPicker
local pickerId
local iconPage, iconChoices = 1, {}
local function say(message)
    local value = "|cff65d6c2EasyPocket:|r " .. message
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(value) else print(value) end
end
local function size(frame, width, height) frame:SetWidth(width); frame:SetHeight(height) end
local function inCombat()
    if InCombatLockdown and InCombatLockdown() then return true end
    return UnitAffectingCombat and UnitAffectingCombat("player")
end
local function canEdit(silent)
    if inCombat() then if not silent then say(EP.L("Edit after combat.")) end; return false end
    return db ~= nil
end
EP.Say=say
EP.CanEdit=canEdit
local text,button=EP.Text,EP.Button
local function panel(name,width,height,title) return EP.Window(name,width,height,title) end
local function spellIcon(parent, name, width)
    local b = CreateFrame("Button", name, parent)
    size(b,width,width)
    b.icon = b:CreateTexture(nil,"BACKGROUND")
    b.icon:SetPoint("TOPLEFT",b,"TOPLEFT",2,-2); b.icon:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-2,2)
    b.icon:SetTexCoord(0.07,0.93,0.07,0.93)
    b:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
    local normal=b:GetNormalTexture()
    if normal then
        size(normal,width*66/36,width*66/36)
        normal:ClearAllPoints(); normal:SetPoint("CENTER",b,"CENTER",0,-1)
    end
    b:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
    b:SetFrameLevel(parent:GetFrameLevel()+1)
    b:SetScript("OnMouseDown",function() EP.Focus(b) end)
    b:SetScript("OnLeave",function() GameTooltip:Hide() end)
    b:SetScript("OnEnter",function(frame)
        frame = frame or this
        GameTooltip:SetOwner(frame,"ANCHOR_RIGHT")
        if not frame.spellName then
            if frame.dropTarget then
                GameTooltip:SetText(EP.L("Drop a spell here"))
                GameTooltip:AddLine(EP.L("Shift-drag or drag border: move window"),0.8,0.8,0.8)
                GameTooltip:Show()
            end
            return
        end
        local info = knownByName[frame.spellName]
        if info then GameTooltip:SetSpell(info.slot,BOOK)
        else GameTooltip:SetText(frame.spellName .. " — " .. EP.L("Spell not in spellbook.")) end
        GameTooltip:AddLine(EP.L("Right-click: remove; drag: move spell"),0.8,0.8,0.8)
        GameTooltip:AddLine(EP.L("Shift-drag or drag border: move window"),0.8,0.8,0.8)
        GameTooltip:Show()
    end)
    return b
end
function EP.GetSpellSlot(name)
    local info=knownByName[name]
    return info and info.slot
end
local function scanSpells()
    known, knownByName = {}, {}
    for slot = 1, 2048 do
        local name, rank = GetSpellName(slot,BOOK)
        if not name then break end
        local passive = IsSpellPassive and IsSpellPassive(slot,BOOK)
        if not passive then
            knownByName[name] = {name=name,rank=rank or "",slot=slot,icon=GetSpellTexture(slot,BOOK)}
        end
    end
    for _, info in pairs(knownByName) do table.insert(known,info) end
    table.sort(known,function(a,b) return a.name < b.name end)
end
local function center(frame)
    local x,y=frame:GetCenter()
    if not x or not y then return nil end
    local scale=frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
    return x*scale,y*scale
end
local function actionFor(button, fallback)
    if not button then return nil end
    if type(button.action)=="number" then return button.action end
    local name=button:GetName() or ""
    if string.find(name,"^ActionButton%d+$") and ActionButton_GetPagedID then
        return ActionButton_GetPagedID(button)
    end
    return fallback
end
local function matches(button,id,slot)
    return button and button.IsVisible and button:IsVisible() and
        type(slot)=="number" and EP.IsPocketAction(slot)==id
end
local function findAnchor(id,preferred)
    if matches(preferred,id,actionFor(preferred)) then return preferred end
    local w=windows[id]
    if w and matches(w.anchor,id,actionFor(w.anchor,w.anchorSlot)) then return w.anchor end
    local bars={{"ActionButton",0},{"MultiBarBottomLeftButton",60},{"MultiBarBottomRightButton",48},
        {"MultiBarRightButton",24},{"MultiBarLeftButton",36}}
    for _,bar in ipairs(bars) do
        for index=1,12 do
            local b=getglobal(bar[1]..index)
            local slot=actionFor(b,bar[2]+index)
            if matches(b,id,slot) then
                if w then w.anchorSlot=slot end
                return b
            end
        end
    end
    -- Custom bars may use their own names but expose the same action slot.
    if EnumerateFrames then
        local frame=EnumerateFrames()
        while frame do
            if matches(frame,id,actionFor(frame)) then return frame end
            frame=EnumerateFrames(frame)
        end
    end
end
local function rememberPosition(p,w)
    local x,y=center(w)
    if x then p.position={x=x,y=y} end
end
local function positionPocket(p,w,preferred)
    w:ClearAllPoints()
    if p.positionMode=="RELATIVE" then
        local anchor=findAnchor(p.id,preferred)
        w.anchor=anchor
        if anchor then
            if not p.relative then
                local x,y=center(anchor)
                local px,py
                if p.position then px,py=p.position.x,p.position.y else px,py=center(UIParent) end
                if x and px then p.relative={x=px-x,y=py-y} end
            end
            if p.relative then
                -- Offsets are stored in UIParent units, so bar scaling is harmless.
                w:SetPoint("CENTER",anchor,"CENTER",p.relative.x,p.relative.y)
                return
            end
        end
    end
    if p.position then w:SetPoint("CENTER",UIParent,"BOTTOMLEFT",p.position.x,p.position.y)
    else w:SetPoint("CENTER",UIParent,"CENTER",0,0) end
end
local function updateCooldowns()
    for _,w in pairs(windows) do
        if w:IsShown() then
            for _,b in ipairs(w.buttons) do
                local info=knownByName[b.spellName]
                if b.cooldown then
                    if info then
                        local start,duration,enabled=GetSpellCooldown(info.slot,BOOK)
                        CooldownFrame_SetTimer(b.cooldown,start,duration,enabled)
                    else b.cooldown:Hide() end
                end
            end
        end
    end
end
layoutPocket=function(p,w)
    local columns,rowCount=p.width,p.height
    for index,b in ipairs(w.buttons) do
        b.spellName=p.spells[index]
        local info=knownByName[b.spellName]
        b.icon:SetTexture(info and info.icon or (b.spellName and "Interface\\Icons\\INV_Misc_QuestionMark"))
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT",w,"TOPLEFT",10+math.mod(index-1,5)*42,-10-math.floor((index-1)/5)*42)
        if EP.IsCellVisible(p,index) then b:Show() else b:Hide() end
    end
    size(w,14+columns*42,14+rowCount*42)
    EP.StylePocket(w,p)
    EP.FixLayers()
end
local function createPocket(p)
    local id=p.id
    local w=panel("EasyPocketFlyout"..id,98,98)
    windows[id]=w; w.buttons={}; w.pocketId=id
    w:SetMovable(true); w:RegisterForDrag("LeftButton")
    local function startMove()
        if not canEdit() or p.positionMode=="FIXED" then return end
        w.moving=true; w:StartMoving()
    end
    local function stopMove()
        if not w.moving then return end
        w:StopMovingOrSizing(); w.moving=nil
        rememberPosition(p,w)
        if p.positionMode=="RELATIVE" then
            local anchor=findAnchor(id)
            if anchor then
                local x,y=center(anchor)
                if x then p.relative={x=p.position.x-x,y=p.position.y-y} end
            else p.relative=nil end
        end
        positionPocket(p,w)
    end
    w:SetScript("OnDragStart",EP.SafeCallback(startMove))
    w:SetScript("OnDragStop",EP.SafeCallback(stopMove))
    w:SetScript("OnHide",EP.SafeCallback(stopMove))
    w:SetScript("OnReceiveDrag",EP.SafeCallback(function() EP.ReceiveSpell(id) end))
    for index=1,EP.MAX_SPELLS do
        local slotIndex=index
        local b=spellIcon(w,"EasyPocketSpell"..id.."_"..index,36)
        b.dropTarget=true; b:RegisterForClicks("LeftButtonUp","RightButtonUp"); b:RegisterForDrag("LeftButton")
        b:SetScript("OnReceiveDrag",EP.SafeCallback(function(frame)
            if EP.ReceiveSpell(id,slotIndex) then (frame or this).dropAt=GetTime() end
        end))
        b:SetScript("OnDragStart",EP.SafeCallback(function(frame)
            frame=frame or this
            if IsShiftKeyDown and IsShiftKeyDown() or not frame.spellName then startMove()
            else
                frame.dropAt=GetTime()
                EP.StartSpellDrag(id,slotIndex)
            end
        end))
        b:SetScript("OnDragStop",EP.SafeCallback(stopMove))
        if CooldownFrame_SetTimer then
            b.cooldown=CreateFrame("Model","EasyPocketCooldown"..id.."_"..index,b,"CooldownFrameTemplate")
            b.cooldown:SetAllPoints(b.icon)
        end
        b:SetScript("OnClick",EP.SafeCallback(function(frame,mouse)
            frame=frame or this; mouse=mouse or arg1
            if frame.dropAt and GetTime()-frame.dropAt<0.2 then return end
            if CursorHasSpell and CursorHasSpell() then EP.ReceiveSpell(id,slotIndex); return end
            if mouse=="RightButton" then
                if canEdit() and p.spells[slotIndex] then p.spells[slotIndex]=nil; EP.ContentsChanged(id) end
                return
            end
            local info=knownByName[frame.spellName]
            if not info then
                if frame.spellName then say(EP.L("Spell not in spellbook.")) end
                return
            end
            CastSpell(info.slot,BOOK)
        end))
        w.buttons[index]=b
    end
    layoutPocket(p,w); positionPocket(p,w)
    return w
end
function EP.ContentsChanged(id)
    local p=EP.GetPocket(id); local w=p and windows[p.id]
    if w then layoutPocket(p,w) end
    if editor then refreshEditor() end
    updateCooldowns()
end
function EP.Toggle(id)
    if not EP.ready then EP.ShowStatus(); return end
    -- Old /script EasyPocket.Toggle() macros belong only to the migrated pocket.
    local p=EP.GetPocket(id or db.legacyId)
    if not p then say(EP.L("Pocket deleted.")); return end
    local w=windows[p.id] or createPocket(p)
    if w:IsShown() then w:Hide(); return end
    layoutPocket(p,w); positionPocket(p,w,this); w:Show(); updateCooldowns()
end
function EP.PickupMacro(id)
    local p=EP.GetPocket(id)
    if not p or not canEdit() then return end
    if (CursorHasItem and CursorHasItem()) or (CursorHasSpell and CursorHasSpell()) then
        say(EP.L("Clear the cursor first.")); return
    end
    local index,reason=EP.EnsureMacro(p.id)
    if not index then
        say(EP.L(reason=="full" and "No free macro slots." or "Could not create macro."))
        return
    end
    PickupMacro(index)
    EP.ShowCursorVisual(EP.GetPocketIcon(p.id),"macro")
end
function EP.NewPocket()
    if not canEdit() then return end
    local id=db.nextId; db.nextId=id+1
    local p={id=id,name=EP.L("Pocket").." "..id,spells={},width=2,height=2,design="CLASSIC",positionMode="FREE",iconTexture=EP.BAG_ICON}
    table.insert(db.pockets,p); EP.selectedId=id; deleteId=nil
    if editor then
        listOffset=math.max(0,math.floor(table.getn(db.pockets)/editor.rowsPerColumn)-3)
        refreshEditor()
    end
    return id
end
function EP.DeletePocket(id)
    local p=EP.GetPocket(id)
    if not p or not canEdit() then return end
    -- Remove only this pocket's macros, descending to avoid index shifts.
    if DeleteMacro and GetNumMacros then
        for index=GetNumMacros(),1,-1 do
            local _,_,body=GetMacroInfo(index)
            if body==EP.MacroBody(p.id) or (p.id==db.legacyId and body==EP.MACRO_BODY) then DeleteMacro(index) end
        end
    end
    if windows[p.id] then windows[p.id]:Hide(); windows[p.id]:SetScript("OnUpdate",nil); windows[p.id]=nil end
    for index,item in ipairs(db.pockets) do if item.id==p.id then table.remove(db.pockets,index); break end end
    if pickerId==p.id and iconPicker then iconPicker:Hide() end
    EP.selectedId=db.pockets[1] and db.pockets[1].id; deleteId=nil
    if editor then refreshEditor() end
end
function EP.SetPositionMode(id,mode)
    local p=EP.GetPocket(id)
    if not p or not canEdit() or (mode~="FREE" and mode~="FIXED" and mode~="RELATIVE") then return end
    local w=windows[p.id]
    if w then rememberPosition(p,w) end
    if p.positionMode~=mode then p.relative=nil end
    p.positionMode=mode
    if w then positionPocket(p,w) end
    if editor then refreshEditor() end
end
refreshIconPicker=function()
    local icons=EP.GetIconCatalog()
    local pages=math.max(1,math.ceil(table.getn(icons)/32)); iconPage=math.min(iconPage,pages)
    for i,b in ipairs(iconChoices) do
        local entry=icons[(iconPage-1)*32+i]
        if entry then b.iconIndex=entry.index; b.icon:SetTexture(entry.texture); b:Show()
        else b.iconIndex=nil; b:Hide() end
    end
    iconPicker.page:SetText(iconPage.." / "..pages)
end
function EP.OpenIconPicker(id)
    local p=EP.GetPocket(id)
    if not p or not canEdit() then return end
    pickerId=p.id
    if not iconPicker then
        iconPicker=panel("EasyPocketIconPicker",370,290,EP.L("Choose icon"))
        iconPicker.owner=editor
        iconPicker:SetPoint("CENTER",UIParent,"CENTER",0,0)
        EP.CloseButton(iconPicker)
        for index=1,32 do
            local b=spellIcon(iconPicker,"EasyPocketIconChoice"..index,32)
            b:SetPoint("TOPLEFT",iconPicker,"TOPLEFT",20+math.mod(index-1,8)*42,-56-math.floor((index-1)/8)*42)
            b:SetScript("OnClick",EP.SafeCallback(function(frame)
                EP.ChooseIcon((frame or this).iconIndex,pickerId); iconPicker:Hide()
            end))
            b:SetScript("OnEnter",function(frame)
                GameTooltip:SetOwner(frame or this,"ANCHOR_RIGHT")
                GameTooltip:SetText(EP.L("Use this icon")); GameTooltip:Show()
            end)
            iconChoices[index]=b
        end
        button(iconPicker,nil,"<",45,20,-244,function() iconPage=math.max(1,iconPage-1); refreshIconPicker() end)
        iconPicker.page=text(iconPicker,"",168,-252,"GameFontHighlightSmall")
        button(iconPicker,nil,">",45,306,-244,function() iconPage=iconPage+1; refreshIconPicker() end)
    end
    refreshIconPicker(); iconPicker:Show()
end
local function selectedPocket() return EP.GetPocket(EP.selectedId) end
function EP.ChangeDimensions(width,height)
    local p=selectedPocket()
    if not p or not canEdit() then return end
    if not EP.ResizePocket(p,width,height) then say(EP.L("Move occupied cells before shrinking.")) end
    EP.ContentsChanged(p.id)
end
function EP.ChangeDesign(design)
    local p=selectedPocket()
    if not p or not canEdit() then return end
    if design~="CURRENT" and design~="CLASSIC" and design~="PFUI" then return end
    p.design=design; EP.ContentsChanged(p.id)
end
function EP.SetLanguage(language)
    if not canEdit() then return end
    db.language=(language=="auto" or EP.translations[language]) and language or "auto"
    EP.CloseDropdown()
    if iconPicker then iconPicker.title:SetText(EP.L("Choose icon")) end
    refreshEditor()
    if EP.RefreshStatus then EP.RefreshStatus() end
end
local function saveName()
    if not editor or editor.refreshing or editor.saving or not canEdit(true) then return end
    editor.saving=true
    local p=EP.GetPocket(editor.editingId); local value=editor.name:GetText()
    if p and string.find(value,"%S") then p.name=value end
    editor.name:ClearFocus(); editor.saving=nil
end
local function makeListIcon(index)
    local b=spellIcon(editor,"EasyPocketListIcon"..index,44)
    b.selected=b:CreateTexture(nil,"OVERLAY")
    b.selected:SetAllPoints(b); b.selected:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    b.selected:SetBlendMode("ADD"); b.selected:Hide()
    b.plus=text(b,"+",12,-7,"GameFontNormalLarge"); b.plus:Hide()
    b:RegisterForDrag("LeftButton")
    b:SetScript("OnClick",EP.SafeCallback(function()
        if b.dragAt and GetTime()-b.dragAt<.2 then return end
        saveName(); EP.CloseDropdown(); deleteId=nil
        if b.isNew then EP.NewPocket()
        elseif b.pocketId then
            EP.selectedId=b.pocketId; refreshEditor(); EP.Toggle(b.pocketId)
        end
    end))
    b:SetScript("OnDragStart",EP.SafeCallback(function()
        if b.pocketId then saveName(); b.dragAt=GetTime(); EP.PickupMacro(b.pocketId) end
    end))
    b:SetScript("OnEnter",function()
        GameTooltip:SetOwner(b,"ANCHOR_RIGHT")
        if b.isNew then GameTooltip:SetText(EP.L("New pocket"))
        else
            local p=EP.GetPocket(b.pocketId)
            GameTooltip:SetText(p and p.name or "EasyPocket")
            GameTooltip:AddLine(EP.L("Click: select and open pocket"),1,1,1)
            GameTooltip:AddLine(EP.L("Drag: place on action bar"),.8,.8,.8)
        end
        GameTooltip:Show()
    end)
    rows[index]=b
    return b
end
refreshEditor=function()
    if not editor then return end
    editor.refreshing=true
    local count=table.getn(db.pockets)
    local perColumn=editor.rowsPerColumn
    local columns=math.ceil((count+1)/perColumn)
    local visibleColumns=math.min(4,columns)
    listOffset=math.max(0,math.min(listOffset,columns-visibleColumns))
    local sidebarWidth=visibleColumns*52+28
    editor:SetWidth(sidebarWidth+540)
    -- Column capacity is derived from the entire available height, not a small fixed list.
    for i=1,count+1 do
        local b=rows[i] or makeListIcon(i)
        local p=db.pockets[i]
        b.pocketId=p and p.id; b.isNew=not p
        b.icon:SetTexture(p and EP.GetPocketIcon(p.id) or nil)
        if p then b.plus:Hide() else b.plus:Show() end
        if p and p.id==EP.selectedId then b.selected:Show() else b.selected:Hide() end
        local column=math.floor((i-1)/perColumn)
        b:ClearAllPoints(); b:SetPoint("TOPLEFT",editor,"TOPLEFT",20+(column-listOffset)*52,-60-math.mod(i-1,perColumn)*52)
        if column>=listOffset and column<listOffset+visibleColumns then b:Show() else b:Hide() end
    end
    for i=count+2,table.getn(rows) do rows[i]:Hide() end
    editor.divider:ClearAllPoints()
    editor.divider:SetPoint("TOPLEFT",editor,"TOPLEFT",sidebarWidth-6,-48)
    editor.divider:SetPoint("BOTTOMRIGHT",editor,"BOTTOMLEFT",sidebarWidth-5,20)
    editor.details:ClearAllPoints(); editor.details:SetPoint("TOPLEFT",editor,"TOPLEFT",sidebarWidth+8,-56)
    editor.general:ClearAllPoints(); editor.general:SetPoint("TOPLEFT",editor,"TOPLEFT",sidebarWidth+8,-420)
    editor.empty:ClearAllPoints(); editor.empty:SetPoint("TOPLEFT",editor,"TOPLEFT",sidebarWidth+26,-80)
    for _,binding in ipairs(editor.bindings) do binding[1]:SetText(EP.L(binding[2])) end
    EP.UpdateDropdown(editor.language)
    local p=selectedPocket()
    if p then
        editor.details:Show(); editor.empty:Hide(); editor.editingId=p.id
        editor.name:SetText(p.name); editor.iconPreview.icon:SetTexture(EP.GetPocketIcon(p.id))
        editor.delete:SetText(EP.L(deleteId==p.id and "Really delete?" or "Delete pocket"))
        EP.UpdateDropdown(editor.position); EP.UpdateDropdown(editor.design)
        EP.UpdateDropdown(editor.widthControl); EP.UpdateDropdown(editor.heightControl)
    else editor.details:Hide(); editor.empty:Show(); editor.editingId=nil end
    editor.refreshing=nil
    EP.FixLayers()
end
local function createEditor()
    editor=panel("EasyPocketEditor",620,540,"EasyPocket")
    editor:SetPoint("CENTER",UIParent,"CENTER",0,0)
    -- Scale only to fit unusually small screens; list capacity still uses the full panel height.
    if UIParent:GetHeight()<580 then editor:SetScale(math.max(.5,(UIParent:GetHeight()-40)/540)) end
    editor.rowsPerColumn=math.max(1,math.floor((editor:GetHeight()-60-20+8)/52))
    editor:SetMovable(true); editor:RegisterForDrag("LeftButton")
    editor:SetScript("OnDragStart",function() EP.CloseDropdown(); EP.Focus(editor); editor:StartMoving() end)
    editor:SetScript("OnDragStop",function() editor:StopMovingOrSizing() end)
    editor:SetScript("OnHide",function()
        saveName(); EP.CloseDropdown(); if iconPicker then iconPicker:Hide() end
    end)
    editor:EnableMouseWheel(true)
    editor:SetScript("OnMouseWheel",function(frame,delta)
        EP.CloseDropdown(); listOffset=listOffset-(delta or arg1 or 0); refreshEditor()
    end)
    EP.CloseButton(editor)
    editor.bindings={}
    local function label(parent,key,x,y,font)
        local f=text(parent,EP.L(key),x,y,font); table.insert(editor.bindings,{f,key}); return f
    end
    editor.divider=editor:CreateTexture(nil,"ARTWORK"); editor.divider:SetTexture("Interface\\Buttons\\WHITE8X8")
    editor.divider:SetVertexColor(.48,.41,.25,1)
    local details=CreateFrame("Frame",nil,editor); editor.details=details
    size(details,510,350); EP.Box(details)
    label(details,"Pocket",16,-14,"GameFontNormalLarge")
    label(details,"Name",16,-62)
    local name=CreateFrame("EditBox","EasyPocketName",details)
    size(name,350,30); name:SetPoint("TOPLEFT",details,"TOPLEFT",142,-53); name:SetAutoFocus(false)
    name:SetFontObject(GameFontHighlight); name:SetMaxLetters(40); EP.Box(name)
    name:SetTextInsets(8,8,0,0); editor.name=name
    name:SetScript("OnMouseDown",function() EP.Focus(name) end)
    name:SetScript("OnEnterPressed",EP.SafeCallback(function() saveName(); refreshEditor() end))
    name:SetScript("OnEditFocusLost",EP.SafeCallback(saveName))
    name:SetScript("OnEscapePressed",function() name:ClearFocus(); refreshEditor() end)
    label(details,"Icon",16,-115)
    editor.iconPreview=spellIcon(details,"EasyPocketIconPreview",38)
    editor.iconPreview:SetPoint("TOPLEFT",details,"TOPLEFT",142,-101)
    editor.iconPreview:SetScript("OnClick",EP.SafeCallback(function() saveName(); EP.OpenIconPicker(EP.selectedId) end))
    editor.choose=button(details,"EasyPocketChooseIcon",EP.L("Choose icon"),143,192,-106,function() saveName(); EP.OpenIconPicker(EP.selectedId) end)
    table.insert(editor.bindings,{editor.choose,"Choose icon"})
    editor.delete=button(details,"EasyPocketDelete","",147,345,-106,function()
        saveName()
        if not canEdit() then return end
        if deleteId==EP.selectedId then EP.DeletePocket(EP.selectedId)
        else deleteId=EP.selectedId; refreshEditor() end
    end)
    editor.delete.face={.28,.065,.04}
    label(details,"Pocket window",16,-168,"GameFontNormalLarge")
    label(details,"Position",16,-217)
    editor.position=EP.Dropdown(details,"EasyPocketPosition",350,142,-208,
        {{"FREE","Free"},{"FIXED","Fixed"},{"RELATIVE","Relative to pocket"}},
        function() local p=selectedPocket(); return p and p.positionMode end,
        function(value) saveName(); EP.SetPositionMode(EP.selectedId,value) end)
    label(details,"Design",16,-259)
    editor.design=EP.Dropdown(details,"EasyPocketDesign",350,142,-250,
        {{"CURRENT","Current"},{"CLASSIC","Classic"},{"PFUI","pfUI style"}},
        function() local p=selectedPocket(); return p and p.design end,function(value) saveName(); EP.ChangeDesign(value) end)
    label(details,"Width",16,-305)
    local dimensions={{2,"2"},{3,"3"},{4,"4"},{5,"5"}}
    editor.widthControl=EP.Dropdown(details,"EasyPocketWidth",95,142,-296,dimensions,
        function() local p=selectedPocket(); return p and p.width end,
        function(value) saveName(); local p=selectedPocket(); if p then EP.ChangeDimensions(value,p.height) end end)
    label(details,"Height",270,-305)
    editor.heightControl=EP.Dropdown(details,"EasyPocketHeight",95,397,-296,dimensions,
        function() local p=selectedPocket(); return p and p.height end,
        function(value) saveName(); local p=selectedPocket(); if p then EP.ChangeDimensions(p.width,value) end end)
    local general=CreateFrame("Frame",nil,editor); editor.general=general; size(general,510,100); EP.Box(general)
    label(general,"General",16,-12,"GameFontNormalLarge"); label(general,"Language",16,-58)
    editor.language=EP.Dropdown(general,"EasyPocketLanguage",205,142,-49,EP.languages,function() return db.language end,
        function(value) saveName(); EP.SetLanguage(value) end)
    editor.debug=button(general,"EasyPocketDebug",EP.L("Debug"),130,362,-49,EP.ShowStatus)
    table.insert(editor.bindings,{editor.debug,"Debug"})
    editor.empty=label(editor,"Create a pocket with +.",100,-80,"GameFontHighlight")
end
function EP.OpenEditor()
    if not canEdit() then return end
    if not editor then createEditor() end
    deleteId=nil; refreshEditor(); editor:Show(); EP.Focus(editor)
end
function EP.ToggleMenu()
    if editor and editor:IsShown() then editor:Hide() else EP.OpenEditor() end
end
function EP.HandleCommand(message)
    local _,_,command=string.find(message or "","^%s*(%S*)")
    command=string.lower(command or "")
    if command=="macro" then EP.PickupMacro(EP.selectedId)
    elseif command=="icon" then EP.OpenIconPicker(EP.selectedId)
    elseif command=="toggle" then EP.Toggle(EP.selectedId)
    elseif command=="status" or command=="debug" then EP.ShowStatus()
    elseif command=="help" then say("Minimap / /ep: Taschen verwalten | /ep debug: Fehler anzeigen")
    else EP.OpenEditor() end
end
local events=CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN"); events:RegisterEvent("PLAYER_ENTERING_WORLD")
local function initialize()
    if EP.ready or EP.initFailed then return end
    if type(GetSpellName)~="function" or type(CastSpell)~="function" then
        EP.startupMessage="Diese Version benötigt die OctoWoW-/Vanilla-Zauberbuch-API."; return
    end
    db=EP.Normalize(EasyPocketDB); EasyPocketDB=db; EP.db=db
    EP.selectedId=db.pockets[1] and db.pockets[1].id
    scanSpells(); EP.InitializeActions()
    events:RegisterEvent("SPELLS_CHANGED"); events:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    events:RegisterEvent("PLAYER_REGEN_DISABLED")
    events:RegisterEvent("UPDATE_MACROS"); events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:RegisterEvent("ACTIONBAR_SLOT_CHANGED"); events:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    events:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
    EP.ready=true
    say(EP.VERSION.." · "..EP.L("Loaded. Open the minimap menu or /ep."))
end
events:SetScript("OnEvent",function(frame,eventName)
    eventName=eventName or event
    local ok,err=pcall(function()
        if eventName=="PLAYER_LOGIN" or eventName=="PLAYER_ENTERING_WORLD" then initialize()
        elseif not EP.ready then return
        elseif eventName=="SPELLS_CHANGED" then
            scanSpells(); for _,p in ipairs(db.pockets) do EP.ContentsChanged(p.id) end
        elseif eventName=="SPELL_UPDATE_COOLDOWN" then updateCooldowns()
        elseif eventName=="ACTIONBAR_SLOT_CHANGED" or eventName=="ACTIONBAR_PAGE_CHANGED" or eventName=="UPDATE_BONUS_ACTIONBAR" then
            for id,w in pairs(windows) do
                local p=EP.GetPocket(id)
                if p and p.positionMode=="RELATIVE" and w:IsShown() and not w.moving then
                    rememberPosition(p,w); positionPocket(p,w)
                end
            end
        elseif eventName=="UPDATE_MACROS" or eventName=="PLAYER_REGEN_ENABLED" then
            EP.SyncAllMacros(); if editor then refreshEditor() end
        elseif eventName=="PLAYER_REGEN_DISABLED" then
            EP.CloseDropdown()
            if editor then editor:Hide() end
            if iconPicker then iconPicker:Hide() end
        end
    end)
    if not ok then
        if not EP.ready then EP.initFailed=true end
        EP.ReportError(eventName,err)
    end
end)
EP.coreLoaded=true

-- Vanilla cursor and macro integration; all hooks preserve the original call.
local EP=EasyPocket
local catalog,dragged,installed={},nil,false
local function trimPath(texture)
    if type(texture)~="string" or texture=="" then return nil end
    texture=string.gsub(texture,"/","\\")
    if not string.find(texture,"\\",1,true) then texture="Interface\\Icons\\"..texture end
    return texture
end
local function key(texture)
    return string.lower(trimPath(texture) or "")
end
function EP.FindMacro(id)
    local pocket=EP.GetPocket(id)
    if not pocket then return nil end
    if not GetNumMacros or not GetMacroInfo then return nil end
    for index=1,GetNumMacros() do
        local name,texture,body=GetMacroInfo(index)
        if body==EP.MacroBody(pocket.id) or (pocket.id==EP.db.legacyId and body==EP.MACRO_BODY) then
            return index,name,trimPath(texture)
        end
    end
end
function EP.GetIconCatalog()
    return catalog
end
function EP.GetPocketIcon(id)
    local pocket=EP.GetPocket(id)
    return (pocket and pocket.iconTexture) or EP.BAG_ICON
end
local function iconIndexFor(texture)
    for _,info in ipairs(catalog) do if key(info.texture)==key(texture) then return info.index end end
end
local function blankName(index)
    local occupied={}
    for i=1,GetNumMacros() do
        if i~=index then local name=GetMacroInfo(i); if name then occupied[name]=true end end
    end
    local name=" "
    while occupied[name] do name=name.." " end
    return name
end
function EP.IsPocketAction(slot)
    if not EP.db then return nil end
    for _,pocket in ipairs(EP.db.pockets) do
        local index,name=EP.FindMacro(pocket.id)
        if index then
            local kind,actionId
            if GetActionInfo then kind,actionId=GetActionInfo(slot) end
            if (kind=="macro" and actionId==index) or
                (not kind and GetActionText and GetActionText(slot)==name) then return pocket.id end
        end
    end
end
function EP.ShowPocketTooltip(tooltip,id)
    local pocket=EP.GetPocket(id)
    tooltip:SetText((pocket and pocket.name) or "EasyPocket",1,0.82,0)
    tooltip:AddLine(EP.L("Click: open / close pocket"),1,1,1)
    tooltip:AddLine(EP.L("Drag from the spellbook into the pocket."),0.8,0.8,0.8)
    tooltip:Show()
end
function EP.SyncMacro(id,force)
    local pocket=EP.GetPocket(id)
    if not pocket or (EP.CanEdit and not EP.CanEdit(true)) then return end
    local index,name,texture=EP.FindMacro(pocket.id)
    if index then
        if not force and texture and pocket.lastMacroIconTexture
            and key(texture)~=key(pocket.lastMacroIconTexture) then
            -- Preserve a later icon edit made in Blizzard's own macro window.
            pocket.iconTexture=texture
        elseif not pocket.iconTexture then
            pocket.iconTexture=texture or EP.BAG_ICON
        end
        local desired=EP.GetPocketIcon(pocket.id)
        local iconIndex=iconIndexFor(desired)
        local _,_,body=GetMacroInfo(index)
        if EditMacro and (body~=EP.MacroBody(pocket.id) or not string.find(name or "","^%s+$") or (iconIndex and key(texture)~=key(desired))) then
            EditMacro(index,blankName(index),iconIndex,EP.MacroBody(pocket.id),1)
        end
        local _,_,actual=EP.FindMacro(pocket.id)
        pocket.lastMacroIconTexture=actual
    end
    if not pocket.iconTexture then pocket.iconTexture=EP.BAG_ICON end
end
function EP.ChooseIcon(index,id)
    local pocket=EP.GetPocket(id)
    if not pocket or not EP.CanEdit() then return end
    local texture
    for _,info in ipairs(catalog) do if info.index==index then texture=info.texture; break end end
    if not texture then return end
    pocket.iconTexture=texture
    EP.SyncMacro(pocket.id,true)
    if EP.ContentsChanged then EP.ContentsChanged(pocket.id) end
end
function EP.EnsureMacro(id)
    local pocket=EP.GetPocket(id)
    if not pocket then return nil,"missing" end
    EP.SyncMacro(pocket.id)
    local index=EP.FindMacro(pocket.id)
    if index then return index end
    if GetNumMacros()>=(MAX_MACROS or 18) then return nil,"full" end
    local iconIndex=iconIndexFor(EP.GetPocketIcon(pocket.id)) or iconIndexFor(EP.BAG_ICON) or 1
    CreateMacro(blankName(),iconIndex,EP.MacroBody(pocket.id),1)
    return EP.FindMacro(pocket.id)
end
function EP.DraggedSpell()
    if not dragged then return nil end
    if CursorHasSpell and not CursorHasSpell() then dragged=nil; return nil end
    return dragged
end
-- A mouse-transparent icon follows the native payload. Native PickupSpell/PickupMacro
-- still own placement on Blizzard action bars; this visual never consumes input.
local cursorVisual,cursorTexture,cursorKind
function EP.ClearCursorVisual()
    cursorTexture=nil; cursorKind=nil
    if cursorVisual then cursorVisual:Hide() end
end
function EP.ShowCursorVisual(texture,kind)
    if not texture then return end
    if not cursorVisual then
        cursorVisual=CreateFrame("Frame","EasyPocketCursorIcon",UIParent)
        cursorVisual:SetWidth(32); cursorVisual:SetHeight(32); cursorVisual:EnableMouse(false)
        cursorVisual:SetFrameStrata("TOOLTIP"); cursorVisual:SetFrameLevel(1000)
        cursorVisual.icon=cursorVisual:CreateTexture(nil,"OVERLAY"); cursorVisual.icon:SetAllPoints(cursorVisual)
        cursorVisual:SetScript("OnUpdate",function()
            local hasSpell=CursorHasSpell and CursorHasSpell()
            local hasItem=CursorHasItem and CursorHasItem()
            local hasMacro=CursorHasMacro and CursorHasMacro()
            if not hasSpell and not hasItem and not hasMacro then EP.ClearCursorVisual(); return end
            local x,y=GetCursorPosition(); local scale=UIParent:GetEffectiveScale()
            cursorVisual:ClearAllPoints(); cursorVisual:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x/scale,y/scale)
        end)
    end
    cursorTexture,cursorKind=texture,kind
    cursorVisual.icon:SetTexture(texture)
    local x,y=GetCursorPosition(); local scale=UIParent:GetEffectiveScale()
    cursorVisual:ClearAllPoints(); cursorVisual:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x/scale,y/scale)
    cursorVisual:Show()
end
function EP.ReceiveSpell(id,target)
    local pocket=EP.GetPocket(id)
    if not pocket or not EP.CanEdit() then return false end
    local name=EP.DraggedSpell()
    if not name then return false end
    local ok,displaced=EP.PutSpell(pocket,name,target)
    if not ok then EP.Say(EP.L("Pocket is full.")); return false end
    dragged=nil
    if ClearCursor then ClearCursor() end
    EP.ClearCursorVisual()
    -- Like an action bar: an occupied destination puts its previous spell on the cursor.
    if displaced then
        local slot=EP.GetSpellSlot(displaced)
        if slot and PickupSpell then PickupSpell(slot,BOOKTYPE_SPELL or "spell")
        else
            -- Unknown spells cannot be picked up by the native client. Undo the drop.
            pocket.spells[target]=displaced
            local incoming=EP.GetSpellSlot(name)
            if incoming and PickupSpell then PickupSpell(incoming,BOOKTYPE_SPELL or "spell") end
            EP.Say(EP.L("Spell not in spellbook.")); return false
        end
    end
    if EP.ContentsChanged then EP.ContentsChanged(pocket.id) end
    return true
end
function EP.StartSpellDrag(id,index)
    local p=EP.GetPocket(id)
    if not p or not EP.CanEdit() or not p.spells[index] then return false end
    if (CursorHasItem and CursorHasItem()) or (CursorHasSpell and CursorHasSpell()) then return false end
    local slot=EP.GetSpellSlot(p.spells[index])
    if not slot or not PickupSpell then EP.Say(EP.L("Spell not in spellbook.")); return false end
    PickupSpell(slot,BOOKTYPE_SPELL or "spell")
    if not EP.DraggedSpell() then return false end
    -- Remove exactly this cell only after native pickup succeeded. No compaction.
    p.spells[index]=nil
    if EP.ContentsChanged then EP.ContentsChanged(id) end
    return true
end
local function installCursorHooks()
    if PickupSpell then
        local previous=PickupSpell
        PickupSpell=function(slot,book)
            dragged=nil
            local name
            if book==nil or book==(BOOKTYPE_SPELL or "spell") then
                name=GetSpellName(slot,BOOKTYPE_SPELL or "spell")
                if IsSpellPassive and IsSpellPassive(slot,BOOKTYPE_SPELL or "spell") then name=nil end
            end
            local result=previous(slot,book)
            if name and (not CursorHasSpell or CursorHasSpell()) then
                dragged=name; EP.ShowCursorVisual(GetSpellTexture(slot,BOOKTYPE_SPELL or "spell"),"spell")
            else EP.ClearCursorVisual() end
            if EP.DragChanged then EP.DragChanged() end
            return result
        end
    end
    -- Cancel stale spell identity when the cursor is cleared or used elsewhere.
    for _,name in ipairs({"ClearCursor","PickupAction","PickupMacro","PickupItem","PickupContainerItem","PickupPetAction","PlaceAction"}) do
        local previous=getglobal(name)
        local hookName=name
        if type(previous)=="function" then
            _G[name]=function(a,b,c)
                local pocketId
                if hookName=="PickupAction" then pocketId=EP.IsPocketAction(a)
                elseif hookName=="PickupMacro" and EP.db then
                    for _,p in ipairs(EP.db.pockets) do if EP.FindMacro(p.id)==a then pocketId=p.id; break end end
                end
                dragged=nil; EP.ClearCursorVisual()
                local result=previous(a,b,c)
                if pocketId then EP.ShowCursorVisual(EP.GetPocketIcon(pocketId),"macro") end
                return result
            end
        end
    end
end
function EP.InitializeActions()
    catalog={}
    if GetNumMacroIcons and GetMacroIconInfo then
        for index=1,GetNumMacroIcons() do
            local texture=trimPath(GetMacroIconInfo(index))
            if texture then table.insert(catalog,{index=index,texture=texture}) end
        end
    end
    if not installed then
        installed=true
        installCursorHooks()
        if GetActionTexture then
            local previous=GetActionTexture
            GetActionTexture=function(slot)
                local id=EP.IsPocketAction(slot)
                if id then return EP.GetPocketIcon(id) end
                return previous(slot)
            end
        end
        if GameTooltip and GameTooltip.SetAction then
            local previous=GameTooltip.SetAction
            GameTooltip.SetAction=function(tooltip,slot)
                local result=previous(tooltip,slot)
                local id=EP.IsPocketAction(slot)
                if id then EP.ShowPocketTooltip(tooltip,id); return 1 end
                return result
            end
        end
    end
    EP.SyncAllMacros()
end

function EP.SyncAllMacros()
    if not EP.db or EP.syncing then return end
    EP.syncing=true
    local ok,err=pcall(function()
        for _,pocket in ipairs(EP.db.pockets) do EP.SyncMacro(pocket.id) end
    end)
    EP.syncing=nil
    if not ok then error(err) end
end

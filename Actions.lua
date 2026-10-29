-- Vanilla cursor and macro integration; all hooks preserve the original call.
local EP=EasyPocket
local catalog,dragged,installed={},nil,false
local syncingMacros={}
local function trimPath(texture)
    if type(texture)~="string" or texture=="" then return nil end
    texture=string.gsub(texture,"/","\\")
    if not string.find(texture,"\\",1,true) then texture="Interface\\Icons\\"..texture end
    return texture
end
local function key(texture)
    return string.lower(trimPath(texture) or "")
end
-- Some clients expose account and character banks separately (18 slots each).
function EP.MacroIndices()
    local result={}
    if not GetNumMacros then return result end
    local account,character=GetNumMacros()
    for i=1,account or 0 do table.insert(result,i) end
    if character~=nil then
        local base=MAX_ACCOUNT_MACROS or MAX_MACROS or 18
        for i=1,character do table.insert(result,base+i) end
    end
    return result
end
local function loadMacroUI()
    if MacroFrame_LoadUI then MacroFrame_LoadUI() end
end
function EP.FindMacro(id)
    local pocket=EP.GetPocket(id)
    if not pocket then return nil end
    if not GetNumMacros or not GetMacroInfo then return nil end
    for _,index in ipairs(EP.MacroIndices()) do
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
local function macroIconArgument(texture)
    loadMacroUI()
    if type(MACRO_ICON_FILENAMES)=="table" then
        local path=trimPath(texture) or EP.BAG_ICON
        local _,_,filename=string.find(path,"([^\\]+)$")
        return string.upper(filename or "INV_MISC_QUESTIONMARK")
    end
    return iconIndexFor(texture) or iconIndexFor(EP.BAG_ICON) or 1
end
local function blankName(index)
    local occupied={}
    for _,i in ipairs(EP.MacroIndices()) do
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
local function syncMacro(id,force)
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
        local iconArgument=macroIconArgument(desired)
        local _,_,body=GetMacroInfo(index)
        if EditMacro and (body~=EP.MacroBody(pocket.id) or not string.find(name or "","^%s+$") or key(texture)~=key(desired)) then
            EditMacro(index,blankName(index),iconArgument,EP.MacroBody(pocket.id),1)
        end
        local _,_,actual=EP.FindMacro(pocket.id)
        pocket.lastMacroIconTexture=actual
    end
    if not pocket.iconTexture then pocket.iconTexture=EP.BAG_ICON end
end
function EP.SyncMacro(id,force)
    if syncingMacros[id] then return end
    syncingMacros[id]=true
    local ok,err=pcall(syncMacro,id,force)
    syncingMacros[id]=nil
    if not ok then error(err) end
end
function EP.RefreshActionIcons(id)
    local seen={}
    local function refresh(b,slot)
        if not b or seen[b] then return end
        seen[b]=true
        slot=type(b.action)=="number" and b.action or slot
        if not slot then return end
        local pocketId=EP.IsPocketAction(slot)
        if not pocketId or (id and pocketId~=id) then return end
        local name=b.GetName and b:GetName()
        local texture=EP.GetPocketIcon(pocketId)
        for _,field in ipairs({"icon","iconTexture","Icon","IconTexture"}) do
            local region=b[field]
            if (type(region)=="table" or type(region)=="userdata") and region.SetTexture then region:SetTexture(texture) end
        end
        if name then
            for _,suffix in ipairs({"Icon","IconTexture"}) do
                local region=getglobal(name..suffix)
                if region and region.SetTexture then region:SetTexture(texture) end
            end
        end
    end
    for _,bar in ipairs({{"ActionButton",0},{"BonusActionButton",0},{"MultiBarBottomLeftButton",60},
        {"MultiBarBottomRightButton",48},{"MultiBarRightButton",24},{"MultiBarLeftButton",36}}) do
        for i=1,12 do
            local b=getglobal(bar[1]..i)
            local slot=bar[2]+i
            if b and ActionButton_GetPagedID and (bar[1]=="ActionButton" or bar[1]=="BonusActionButton") then
                slot=ActionButton_GetPagedID(b)
            end
            refresh(b,slot)
        end
    end
    if EnumerateFrames then
        local f=EnumerateFrames()
        while f do refresh(f); f=EnumerateFrames(f) end
    end
end
function EP.ChooseIcon(index,id)
    local pocket=EP.GetPocket(id)
    if not pocket or not EP.CanEdit() then return end
    local texture
    for _,info in ipairs(catalog) do if info.index==index then texture=info.texture; break end end
    if not texture then return end
    pocket.iconTexture=texture
    EP.SyncMacro(pocket.id,true)
    EP.RefreshActionIcons(pocket.id)
    if EP.ContentsChanged then EP.ContentsChanged(pocket.id) end
end
function EP.EnsureMacro(id)
    local pocket=EP.GetPocket(id)
    if not pocket then return nil,"missing" end
    EP.SyncMacro(pocket.id)
    local index=EP.FindMacro(pocket.id)
    if index then return index end
    local account,character=GetNumMacros()
    local used=character~=nil and character or account
    local limit=character~=nil and (MAX_CHARACTER_MACROS or 18) or (MAX_MACROS or 18)
    if used>=limit then return nil,"full" end
    local icon=macroIconArgument(EP.GetPocketIcon(pocket.id))
    if character~=nil then CreateMacro(blankName(),icon,EP.MacroBody(pocket.id),1,1)
    else CreateMacro(blankName(),icon,EP.MacroBody(pocket.id),1) end
    return EP.FindMacro(pocket.id)
end
function EP.DraggedSpell()
    if not dragged then return nil end
    if CursorHasSpell and not CursorHasSpell() then dragged=nil; return nil end
    return dragged
end
-- PickupSpell and PickupMacro own the native cursor; never draw a second icon.
function EP.ReceiveSpell(id,target)
    local pocket=EP.GetPocket(id)
    if not pocket or not EP.CanEdit() then return false end
    local name=EP.DraggedSpell()
    if not name then return false end
    local ok,displaced=EP.PutSpell(pocket,name,target)
    if not ok then EP.Say(EP.L("Pocket is full.")); return false end
    dragged=nil
    if ClearCursor then ClearCursor() end
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
                dragged=name
            end
            if EP.DragChanged then EP.DragChanged() end
            return result
        end
    end
    -- Cancel stale spell identity when the cursor is cleared or used elsewhere.
    for _,name in ipairs({"ClearCursor","PickupAction","PickupMacro","PickupItem","PickupContainerItem","PickupPetAction","PlaceAction"}) do
        local previous=getglobal(name)
        if type(previous)=="function" then
            _G[name]=function(a,b,c)
                dragged=nil
                local result=previous(a,b,c)
                return result
            end
        end
    end
end
function EP.InitializeActions()
    loadMacroUI()
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
    EP.RefreshActionIcons()
end

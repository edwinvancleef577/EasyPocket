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
                ((not kind or kind=="macro") and GetActionText and GetActionText(slot)==name) then return pocket.id end
        end
    end
end
function EP.ShowPocketTooltip(tooltip,id)
    local pocket=EP.GetPocket(id)
    tooltip:SetText((pocket and pocket.name) or "EasyPocket",1,0.82,0)
    tooltip:AddLine(EP.L("Click: open / close pocket"),1,1,1)
    tooltip:AddLine(EP.L("Drag spells or equipment into the pocket."),0.8,0.8,0.8)
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
        -- Suppress the extra hover square only while this button contains a pocket.
        -- Restore the bar's own texture when the slot is reused for another action.
        if b.GetHighlightTexture and b.SetHighlightTexture then
            if pocketId then
                if not b.epPocketHighlight then
                    local region=b:GetHighlightTexture()
                    b.epPocketHighlight={texture=region and region:GetTexture()}
                end
                b:SetHighlightTexture("")
            elseif b.epPocketHighlight then
                b:SetHighlightTexture(b.epPocketHighlight.texture or "")
                b.epPocketHighlight=nil
            end
        end
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
local function cursorInfo()
    if not GetCursorInfo then return nil end
    local ok,kind,a,b,id=pcall(GetCursorInfo)
    if ok then return kind,a,b,id end
end
local function cursorSummary()
    local kind,a,b,id=cursorInfo()
    return "cursor="..tostring(kind).." a="..tostring(a).." b="..tostring(b).." id="..tostring(id)..
        " spell="..tostring(CursorHasSpell and CursorHasSpell()).." item="..tostring(CursorHasItem and CursorHasItem())
end
function EP.DraggedEntry()
    local kind,a,b,id=cursorInfo()
    if kind=="item" or (CursorHasItem and CursorHasItem()) then
        if type(dragged)=="table" and dragged.kind=="item" then return dragged end
        if kind=="item" then return EP.ItemData(a) end
        return nil
    end
    if kind=="spell" then
        local entry,reason=EP.CaptureSpell(a,b,id)
        if entry then dragged=entry; return entry end
        EP.TraceDrag("Cursor spell rejected: "..tostring(reason))
        return nil
    end
    if kind then dragged=nil; return nil end
    if CursorHasSpell and not CursorHasSpell() then dragged=nil; return nil end
    if type(dragged)=="string" or (type(dragged)=="table" and dragged.kind=="spell") then return dragged end
    return nil
end
function EP.DraggedSpell()
    local entry=EP.DraggedEntry()
    return type(entry)=="string" and entry or nil
end
-- PickupSpell and PickupMacro own the native cursor; never draw a second icon.
function EP.ReceiveSpell(id,target)
    local pocket=EP.GetPocket(id)
    if not pocket or not EP.CanEdit() then
        EP.TraceDrag("Drop rejected: pocket missing or edits blocked"); return false
    end
    EP.TraceDrag("Drop pocket="..tostring(id).." cell="..tostring(target).." "..cursorSummary())
    local name=EP.DraggedEntry()
    if not name then
        EP.TraceDrag("Drop rejected: no supported spell or equipment identity")
        EP.Say(EP.L("Drop not recognized. Details: Debug."))
        return false
    end
    if type(name)=="table" and name.kind=="item" and not ClearCursor then EP.TraceDrag("Drop rejected: ClearCursor unavailable"); return false end
    local ok,displaced=EP.PutSpell(pocket,name,target)
    if not ok then EP.TraceDrag("Drop rejected: "..tostring(displaced)); EP.Say(EP.L("Pocket is full.")); return false end
    dragged=nil
    if ClearCursor then ClearCursor() end
    -- Like an action bar: an occupied destination puts its previous spell on the cursor.
    if displaced then
        if not EP.PickupEntry(displaced) then
            -- Keep the destination intact if its old shortcut cannot be picked up.
            pocket.spells[target]=displaced
            EP.PickupEntry(name)
            EP.TraceDrag("Drop rolled back: destination unavailable")
            EP.Say(type(displaced)=="table" and displaced.kind=="item" and EP.L("Item not carried.") or EP.SpellUnavailable(displaced))
            return false
        end
    end
    EP.TraceDrag("Drop accepted: "..(type(name)=="table" and name.kind or "spell")..
        " id="..tostring(type(name)=="table" and (name.spellId or name.itemId) or nil))
    if EP.ContentsChanged then EP.ContentsChanged(pocket.id) end
    return true
end
function EP.StartSpellDrag(id,index)
    local p=EP.GetPocket(id)
    if not p or not EP.CanEdit() or not p.spells[index] then return false end
    if (CursorHasItem and CursorHasItem()) or (CursorHasSpell and CursorHasSpell()) then return false end
    local entry=p.spells[index]
    if not EP.PickupEntry(entry) then
        EP.TraceDrag("Pickup rejected: saved entry unavailable")
        EP.Say(type(entry)=="table" and entry.kind=="item" and EP.L("Item not carried.") or EP.SpellUnavailable(entry)); return false
    end
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
            local result=previous(slot,book)
            local kind,cursorSlot,cursorBook,cursorId=cursorInfo()
            local entry,reason
            if kind=="spell" then entry,reason=EP.CaptureSpell(cursorSlot,cursorBook,cursorId)
            elseif not kind and (not CursorHasSpell or CursorHasSpell()) then entry,reason=EP.CaptureSpell(slot,book)
            else reason="native pickup did not produce a spell cursor" end
            dragged=entry
            EP.TraceDrag("PickupSpell slot="..tostring(slot).." book="..tostring(book).." "..cursorSummary()..
                " result="..(entry and "recognized" or tostring(reason)))
            if EP.DragChanged then EP.DragChanged() end
            return result
        end
    end
    -- Cancel stale spell identity when the cursor is cleared or used elsewhere.
    for _,name in ipairs({"ClearCursor","PickupAction","PickupMacro","PickupItem","PickupContainerItem","PickupInventoryItem","PickupPetAction","PlaceAction","UseContainerItem","UseInventoryItem","AutoEquipCursorItem"}) do
        local previous=getglobal(name)
        local hookName=name
        if type(previous)=="function" then
            _G[name]=function(a,b,c)
                local item
                if hookName=="PickupContainerItem" and GetContainerItemLink then
                    local link=GetContainerItemLink(a,b)
                    if link then item=EP.ItemData(link) end
                elseif hookName=="PickupInventoryItem" and GetInventoryItemLink then
                    local link=GetInventoryItemLink("player",a)
                    if link then item=EP.ItemData(link) end
                elseif hookName=="PickupItem" then item=EP.ItemData(a) end
                dragged=nil
                local result=previous(a,b,c)
                if item and CursorHasItem and CursorHasItem() then dragged=item end
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

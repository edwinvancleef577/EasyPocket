-- Equipment shortcuts store item IDs, never bag slots or the physical item.
local EP=EasyPocket
function EP.ItemId(value)
    if type(value)=="number" then return value end
    if type(value)~="string" then return nil end
    local _,_,id=string.find(value,"item:(%d+)")
    return tonumber(id)
end
function EP.ItemData(value)
    if not GetItemInfo or (type(value)~="number" and type(value)~="string") then return nil end
    local name,link,quality,level,a,b,c,d,e,f=GetItemInfo(EP.ItemId(value) or value)
    if not name then return nil end
    -- Vanilla puts equip location in field 8; compatibility layers may use field 9.
    local equip,icon
    if type(d)=="string" and string.find(d,"^INVTYPE_") then equip,icon=d,e
    elseif type(e)=="string" and string.find(e,"^INVTYPE_") then equip,icon=e,f end
    if not equip or equip=="INVTYPE_BAG" or equip=="INVTYPE_QUIVER" then return nil end
    local id=EP.ItemId(link) or EP.ItemId(value)
    if not id then return nil end
    return {kind="item",itemId=id,name=name,icon=type(icon)=="string" and icon or nil}
end
function EP.FindItem(entry,bagsFirst)
    local function bags()
        if not GetContainerNumSlots or not GetContainerItemLink then return end
        for bag=0,4 do
            for slot=1,GetContainerNumSlots(bag) or 0 do
                if EP.ItemId(GetContainerItemLink(bag,slot))==entry.itemId then return "bag",bag,slot end
            end
        end
    end
    local function equipment()
        if not GetInventoryItemLink then return end
        for slot=1,19 do
            if EP.ItemId(GetInventoryItemLink("player",slot))==entry.itemId then return "equipped",slot end
        end
    end
    local kind,a,b
    if bagsFirst then kind,a,b=bags() else kind,a,b=equipment() end
    if kind then return kind,a,b end
    if bagsFirst then return equipment() else return bags() end
end
function EP.ItemTexture(entry)
    local info=EP.ItemData(entry.itemId)
    return (info and info.icon) or entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
end
function EP.ShowItemTooltip(tooltip,entry)
    local kind,a,b=EP.FindItem(entry)
    if kind=="bag" and tooltip.SetBagItem then tooltip:SetBagItem(a,b)
    elseif kind=="equipped" and tooltip.SetInventoryItem then tooltip:SetInventoryItem("player",a)
    else tooltip:SetText(entry.name or ("Item "..entry.itemId)) end
    tooltip:AddLine(EP.L("Click: equip item"),1,1,1)
    if not kind then tooltip:AddLine(EP.L("Item not carried."),1,.3,.3) end
end
function EP.PickupEntry(entry)
    if type(entry)=="string" then
        local slot=EP.GetSpellSlot(entry)
        if not slot or not PickupSpell then return false end
        PickupSpell(slot,BOOKTYPE_SPELL or "spell")
        return EP.DraggedSpell()==entry
    end
    local kind,a,b=EP.FindItem(entry,true)
    if kind=="bag" and PickupContainerItem then PickupContainerItem(a,b)
    elseif kind=="equipped" and PickupInventoryItem then PickupInventoryItem(a)
    else return false end
    local current=EP.DraggedEntry()
    return type(current)=="table" and current.itemId==entry.itemId
end
function EP.EquipEntry(entry)
    if not EP.CanEdit() then return false end
    if (CursorHasItem and CursorHasItem()) or (CursorHasSpell and CursorHasSpell()) or
        (CursorHasMacro and CursorHasMacro()) then EP.Say(EP.L("Clear the cursor first.")); return false end
    local kind,bag,slot=EP.FindItem(entry)
    if kind=="equipped" then return true end
    if not kind then EP.Say(EP.L("Item not carried.")); return false end
    if not EP.ItemData(entry.itemId) or not PickupContainerItem or not AutoEquipCursorItem or not ClearCursor then
        EP.Say(EP.L("Item cannot be equipped.")); return false
    end
    -- This equipment-only path cannot sell the item when a merchant is open.
    if not EP.PickupEntry(entry) then
        ClearCursor(); EP.Say(EP.L("Item cannot be equipped.")); return false
    end
    local ok,err=pcall(AutoEquipCursorItem)
    -- Return any unaccepted item (or replaced equipment) through the native cursor.
    ClearCursor()
    if not ok then error(err) end
    local result=EP.FindItem(entry)
    if result~="equipped" then EP.Say(EP.L("Item cannot be equipped.")); return false end
    return true
end

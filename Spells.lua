-- Names are presentation, not a requirement for identifying custom player spells.
local EP=EasyPocket
local BOOK=BOOKTYPE_SPELL or "spell"
local byName,byId={},{}
local sessionBindings=setmetatable({},{__mode="k"})
local function safe(fn,a,b)
    if type(fn)~="function" then return nil end
    local ok,x,y,z=pcall(fn,a,b)
    if ok then return x,y,z end
end
local function validId(id)
    return type(id)=="number" and id>0 and id<2147483648 and id==math.floor(id)
end
function EP.ReadSpell(slot)
    if not validId(slot) then return nil end
    local name,rank=GetSpellName(slot,BOOK)
    local icon=safe(GetSpellTexture,slot,BOOK)
    local link,resolved=safe(GetSpellLink,slot,BOOK)
    local id=validId(resolved) and resolved or nil
    if type(link)=="string" then
        local _,_,number=string.find(link,"spell:(%d+)")
        id=tonumber(number) or id
    end
    if type(name)~="string" or not string.find(name,"%S") then name=nil end
    if not name and not icon and not id then return nil end
    return {slot=slot,name=name,rank=rank,icon=icon,spellId=id,passive=safe(IsSpellPassive,slot,BOOK)}
end
function EP.ScanSpells()
    byName,byId={},{}
    sessionBindings=setmetatable({},{__mode="k"})
    local limit=0
    if GetNumSpellTabs and GetSpellTabInfo then
        for tab=1,GetNumSpellTabs() or 0 do
            local _,_,offset,count=GetSpellTabInfo(tab)
            if type(offset)=="number" and type(count)=="number" then limit=math.max(limit,offset+count) end
        end
    end
    -- A missing label is not the end of the book. With no tab API, tolerate gaps.
    local bounded=limit>0
    if not bounded then limit=2048 end
    local empty=0
    for slot=1,math.min(limit,2048) do
        local info=EP.ReadSpell(slot)
        if info then
            empty=0
            if not info.passive then
                if info.name then byName[info.name]=info end
                if info.spellId then byId[info.spellId]=info end
            end
        else
            empty=empty+1
            if not bounded and empty>=8 then break end
        end
    end
end
function EP.ResolveSpell(entry)
    if type(entry)=="string" then return byName[entry] end
    if type(entry)~="table" or entry.kind~="spell" then return nil end
    if entry.spellId then
        local info=byId[entry.spellId]
        if info then return info end
        local slot=safe(FindSpellBookSlotByID,entry.spellId)
        if validId(slot) then
            local resolved=EP.ReadSpell(slot)
            if not resolved then resolved={slot=slot,spellId=entry.spellId} end
            if not resolved.passive and (not resolved.spellId or resolved.spellId==entry.spellId) then
                resolved.spellId=entry.spellId; byId[entry.spellId]=resolved; return resolved
            end
        end
        -- A cursor may reveal an ID even when the link API is absent.
        local binding=sessionBindings[entry]
        if binding then return binding end
        return nil
    end
    local binding=sessionBindings[entry]
    if binding then
        local current=EP.ReadSpell(binding.slot)
        if current and not current.passive and current.name==binding.name and current.icon==binding.icon then return binding end
    end
end
function EP.GetSpellSlot(entry)
    local info=EP.ResolveSpell(entry)
    return info and info.slot
end
function EP.CopySpellBinding(source,destination)
    sessionBindings[destination]=sessionBindings[source]
end
function EP.CaptureSpell(slot,book,cursorId)
    if book and book~=BOOK then return nil,"not a player spellbook entry" end
    local info=EP.ReadSpell(slot)
    if not info and validId(slot) and validId(cursorId) then
        info={slot=slot,spellId=cursorId,passive=safe(IsSpellPassive,slot,BOOK)}
    end
    if not info then return nil,"no spell metadata at source slot" end
    if info.passive then return nil,"passive spell" end
    if validId(cursorId) then
        if info.spellId and info.spellId~=cursorId then return nil,"cursor/source spell ID mismatch" end
        info.spellId=cursorId
    end
    if info.name and not info.spellId then
        if not byName[info.name] or byName[info.name].slot<slot then byName[info.name]=info end
        return info.name
    end
    if not info.spellId and not info.icon then return nil,"missing name, ID and icon" end
    local entry={kind="spell",spellId=info.spellId,name=info.name,icon=info.icon}
    if info.spellId then byId[info.spellId]=info end
    sessionBindings[entry]=info
    return entry
end
function EP.SpellLabel(entry)
    local info=EP.ResolveSpell(entry)
    if info and info.name then return info.name end
    if type(entry)=="string" then return entry end
    return entry.name or (entry.spellId and ("Spell #"..entry.spellId)) or EP.L("Unnamed spell")
end
function EP.SpellUnavailable(entry)
    if type(entry)=="table" and entry.kind=="spell" and not entry.spellId then
        return EP.L("Drag this spell again after reload or spellbook changes.")
    end
    return EP.L("Spell not in spellbook.")
end

-- Persistent cell coordinates: always five columns in storage, independent of visible width.
EasyPocket=EasyPocket or {}
local EP=EasyPocket
EP.MAX_SPELLS=25
EP.BAG_ICON="Interface\\Icons\\INV_Misc_Bag_08"
EP.MACRO_BODY="/script EasyPocket.Toggle()"
function EP.CellIndex(column,row) return (row-1)*5+column end
local function dimension(value)
    value=tonumber(value)
    if not value or value~=value then return 2 end
    return math.max(2,math.min(5,math.floor(value)))
end
local function validPosition(pos)
    return type(pos)=="table" and type(pos.x)=="number" and type(pos.y)=="number"
        and pos.x==pos.x and pos.y==pos.y and math.abs(pos.x)<100000 and math.abs(pos.y)<100000
end
local function oldGrid(count)
    local x,y=2,2
    while count>=x*y and x*y<25 do if x==y then x=x+1 else y=y+1 end end
    return x,y
end
local function normalizePocket(p,old)
    if type(p.name)~="string" or p.name=="" then p.name=EP.L("My spells") end
    if type(p.iconTexture)~="string" or p.iconTexture=="" then p.iconTexture=nil end
    if p.positionMode~="FIXED" and p.positionMode~="RELATIVE" then p.positionMode="FREE" end
    if not validPosition(p.position) then p.position=nil end
    if not validPosition(p.relative) then p.relative=nil end
    if p.design~="CLASSIC" and p.design~="PFUI" then p.design="CURRENT" end
    p.direction=nil
    local spells=type(p.spells)=="table" and p.spells or {}
    local result={}
    if old then
        local list,seen={},{}
        for i=1,25 do
            local v=spells[i]; if type(v)=="table" then v=v.name end
            if type(v)=="string" and v~="" and not seen[v] then table.insert(list,v); seen[v]=true
            elseif type(v)=="number" then p.retailSpells=spells end
        end
        p.width,p.height=oldGrid(table.getn(list))
        for i,v in ipairs(list) do result[EP.CellIndex(math.mod(i-1,p.width)+1,math.floor((i-1)/p.width)+1)]=v end
    else
        p.width,p.height=dimension(p.width),dimension(p.height)
        for i=1,25 do
            local v=spells[i]
            if type(v)=="string" and v~="" then
                result[i]=v
                -- Recover malformed dimensions without dropping saved cells.
                p.width=math.max(p.width,math.mod(i-1,5)+1)
                p.height=math.max(p.height,math.floor((i-1)/5)+1)
            end
        end
    end
    p.spells=result
    return p
end
function EP.Normalize(saved)
    local db=type(saved)=="table" and saved or {}
    local old=db.version~=5
    if type(db.pockets)~="table" then db={pockets={db},nextId=2,legacyId=1}; db.pockets[1].id=1; old=true end
    local nextId=tonumber(db.nextId) or 1
    if nextId~=nextId or nextId<1 or nextId>1000000 then nextId=1 end
    nextId=math.floor(nextId)
    -- Reserve every valid ID before repairing duplicates.
    for _,p in ipairs(db.pockets) do
        if type(p)=="table" and type(p.id)=="number" and p.id>=1 and p.id<1000000 then nextId=math.max(nextId,math.floor(p.id)+1) end
    end
    local pockets,seen={},{}
    for _,p in ipairs(db.pockets) do
        if type(p)=="table" then
            local id=tonumber(p.id)
            if not id or id~=id or id<1 or id>=1000000 or id~=math.floor(id) or seen[id] then id=nextId; nextId=nextId+1 end
            p.id=id; seen[id]=true
            table.insert(pockets,normalizePocket(p,old))
        end
    end
    db.pockets=pockets; db.nextId=nextId; db.version=5
    db.language=db.language or "auto"
    return db
end
function EP.GetPocket(id)
    if not EP.db then return nil end
    id=tonumber(id) or EP.selectedId or EP.db.legacyId
    for _,p in ipairs(EP.db.pockets) do if p.id==id then return p end end
end
function EP.MacroBody(id) return "/script EasyPocket.Toggle("..id..")" end
function EP.IsCellVisible(p,index)
    return type(index)=="number" and index>=1 and index<=25 and index==math.floor(index)
        and math.mod(index-1,5)<p.width and math.floor((index-1)/5)<p.height
end
function EP.CountSpells(p)
    local count=0; for i=1,25 do if p.spells[i] then count=count+1 end end; return count
end
function EP.PutSpell(p,name,target)
    if type(name)~="string" or name=="" then return false,"invalid" end
    if not target then
        for row=1,p.height do
            for column=1,p.width do
                local index=EP.CellIndex(column,row)
                if not p.spells[index] then target=index; break end
            end
            if target then break end
        end
    end
    if not target or not EP.IsCellVisible(p,target) then return false,"full" end
    local displaced=p.spells[target]
    p.spells[target]=name
    return true,displaced
end
function EP.ResizePocket(p,width,height)
    width,height=dimension(width),dimension(height)
    for i=1,25 do
        if p.spells[i] and (math.mod(i-1,5)>=width or math.floor((i-1)/5)>=height) then return false end
    end
    p.width,p.height=width,height
    return true
end

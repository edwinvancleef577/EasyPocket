-- Deliberately models legacy global this/event/arg1 callbacks only.
-- Unknown frame methods fail. No C_Spell, SetSize, SecureHandlers or C_Timer.
for _,frame in ipairs(Frames or {}) do
 if frame.name and _G[frame.name]==frame then _G[frame.name]=nil end
end
Frames,Macros,Messages,Actions={}, {}, {}, {}
Combat,Cursor,LastCast,Shift=false,nil,nil,false
Clock,EditCalls=100,0
GetActionInfo=nil
MACRO_ICON_FILENAMES,MacroFrame_LoadUI,EnumerateFrames=nil,nil,nil
SplitMacroBanks,FilenameMacroAPI,ReentrantMacroEvents=false,false,false
NativeCursorTexture=nil
BagItems,Equipped,ItemDB={},{},{}
ItemDB[6256]={name="Fishing Pole",icon="pole-icon",equip="INVTYPE_2HWEAPON",slot=16}
ItemDB[7005]={name="Skinning Knife",icon="knife-icon",equip="INVTYPE_WEAPON",slot=16}
ItemDB[6948]={name="Hearthstone",icon="stone-icon",equip=""}
ItemPickupLocked,EquipFailure,EquipCalls=false,false,0
GetCursorInfo,GetSpellLink,FindSpellBookSlotByID,GetNumSpellTabs,GetSpellTabInfo=nil,nil,nil,nil,nil
MAX_ACCOUNT_MACROS,MAX_CHARACTER_MACROS=nil,nil
SlashCmdList,UISpecialFrames={},{}
BOOKTYPE_SPELL="spell"
MAX_MACROS=18
Spells={
 {name="Fireball",rank="Rank 1"}, {name="Fireball",rank="Rank 2"},
 {name="Teleport"}, {name="Armor",passive=true}, {name="Cooking"},
}
local methods={}
function methods:SetWidth(v) self.width=v end
function methods:SetHeight(v) self.height=v end
function methods:GetWidth() return self.width or 160 end
function methods:GetHeight() return self.height or 160 end
function methods:GetFrameLevel() return self.level or (self.parent and self.parent:GetFrameLevel()+1) or 1 end
function methods:SetFrameLevel(v) self.level=v end
function methods:SetFrameStrata(v) self.strata=v end
function methods:GetFrameStrata() return self.strata or (self.parent and self.parent:GetFrameStrata()) or "MEDIUM" end
function methods:GetChildren()
 local children={}
 for _,f in ipairs(Frames) do if f.parent==self and f.kind~="Texture" and f.kind~="FontString" then table.insert(children,f) end end
 return unpack(children)
end
function methods:SetScale(v) self.scale=v end
function methods:GetCenter() return self.cx or 500,self.cy or 500 end
function methods:GetEffectiveScale() return (self.scale or 1)*(self.parent and self.parent:GetEffectiveScale() or 1) end
function methods:SetPoint(a,b,c,d,e)
 assert(type(a)=="string" and type(b)=="table" and type(c)=="string"
  and type(d)=="number" and type(e)=="number",
  "Usage: SetPoint(point, relativeFrame, relativePoint, offsetX, offsetY)")
 self.point={a,b,c,d,e}
end
function methods:ClearAllPoints() self.point=nil end
function methods:GetParent() return self.parent end
function methods:GetName() return self.name end
function methods:SetText(v)
 self.text=tostring(v)
 if self.scripts.OnTextChanged then Trigger(self,"OnTextChanged") end
end
function methods:GetText() return self.text or "" end
function methods:SetTexture(v,g,b,a) self.texture=v; if g then self.color={v,g,b,a} end end
function methods:SetBackdrop(v) self.backdrop=v end
function methods:SetBackdropColor(r,g,b,a) self.bg={r,g,b,a} end
function methods:SetBackdropBorderColor(r,g,b,a) self.border={r,g,b,a} end
function methods:SetNormalTexture(v)
 if not self.normal then self.normal=CreateFrame("Texture",nil,self) end
 self.normal:SetTexture(v)
end
function methods:GetNormalTexture() return self.normal end
function methods:SetPushedTexture(v) self.pushed=v end
function methods:SetHighlightTexture(v)
 self.highlight=v
 if not self.highlightRegion then self.highlightRegion=CreateFrame("Texture",nil,self) end
 self.highlightRegion:SetTexture(v)
end
function methods:GetHighlightTexture() return self.highlightRegion end
function methods:GetTexture() return self.texture end
function methods:SetVertexColor(r,g,b,a) self.vertex={r,g,b,a} end
function methods:SetBagItem(bag,slot) self.tooltipItem=GetContainerItemLink(bag,slot) end
function methods:SetInventoryItem(unit,slot) self.tooltipItem=GetInventoryItemLink(unit,slot) end
function methods:SetAction(slot) self.action=slot; self:SetText("Original action "..slot); return 1 end
function methods:CreateTexture() return CreateFrame("Texture",nil,self) end
function methods:CreateFontString() return CreateFrame("FontString",nil,self) end
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:RegisterEvent(k) self.events[k]=true end
function methods:Show() local changed=not self.shown; self.shown=true; if changed then Trigger(self,"OnShow") end end
function methods:Hide() local changed=self.shown; self.shown=false; if changed then Trigger(self,"OnHide") end end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function methods:StartMoving() self.moving=true end
function methods:StopMovingOrSizing() self.moving=nil end
function methods:AddMessage(v) table.insert(Messages,v) end
local noops={"SetClampedToScreen","EnableMouse","SetAllPoints","SetTexCoord","SetJustifyH",
 "RegisterForClicks","RegisterForDrag","SetMovable",
 "SetAutoFocus","SetMaxLetters","ClearFocus","SetOwner","SetSpell","AddLine",
 "SetMultiLine","SetFontObject","SetScrollChild","EnableMouseWheel","SetBlendMode","SetTextInsets"}
for _,key in ipairs(noops) do methods[key]=function() end end
function CreateFrame(kind,name,parent,template)
 local frame=setmetatable({kind=kind,name=name,parent=parent,template=template,shown=true,scripts={},events={}},{__index=methods})
 table.insert(Frames,frame)
 if name then _G[name]=frame end
 return frame
end
UIParent=CreateFrame("Frame","UIParent"); UIParent:SetWidth(1920); UIParent:SetHeight(1080)
Minimap=CreateFrame("Frame","Minimap",UIParent)
GameTooltip=CreateFrame("Frame","GameTooltip")
DEFAULT_CHAT_FRAME=CreateFrame("Frame")
function getglobal(name) return _G[name] end
function GetLocale() return "deDE" end
function GetBuildInfo() return "1.18.1","7272" end
function GetCursorPosition() return 600,500 end
function GetTime() return Clock end
function IsShiftKeyDown() return Shift end
function UnitAffectingCombat() return Combat end
function GetSpellName(slot,book)
 assert(book=="spell")
 if Spells[slot] then return Spells[slot].name,Spells[slot].rank end
end
function GetSpellTexture(slot) if Spells[slot] then return Spells[slot].icon or "icon"..slot end end
function IsSpellPassive(slot) return Spells[slot] and Spells[slot].passive end
function GetSpellCooldown() return 1,2,1 end
function CooldownFrame_SetTimer(frame,start,duration,enabled) frame.cooldown={start,duration,enabled} end
function CastSpell(slot,book) LastCast={slot,book} end
function GetNumMacros()
 if not SplitMacroBanks then return table.getn(Macros) end
 local account,character=0,0
 for index in pairs(Macros) do
  if index<=18 then account=account+1 else character=character+1 end
 end
 return account,character
end
function GetMacroInfo(index)
 if Macros[index] then
  local m=Macros[index]
  local texture=m[2]
  if type(texture)=="number" then texture=GetMacroIconInfo(texture)
  elseif FilenameMacroAPI then
   for i=1,GetNumMacroIcons() do
    local path=GetMacroIconInfo(i)
    local _,_,file=string.find(path,"([^\\]+)$")
    if string.upper(file)==texture then texture=path; break end
   end
  end
  return m[1],texture,m[3]
 end
end
function GetNumMacroIcons() return 4 end
function GetMacroIconInfo(index)
 if index==2 then return "Interface\\Icons\\INV_Misc_Bag_08" end
 if index==3 then return "Interface\\Icons\\Spell_Fire_Fireball02" end
 if index==4 then return "Interface\\Icons\\Spell_Arcane_TeleportStormWind" end
 return "Interface\\Icons\\INV_Misc_QuestionMark"
end
local function checkMacroIcon(icon)
 if FilenameMacroAPI then
  assert(type(icon)=="string" and not string.find(icon,"\\",1,true),"filename macro API requires a bare icon filename")
 else assert(type(icon)=="number") end
end
function CreateMacro(name,icon,body,localFlag,perCharacter)
 assert(not Combat); checkMacroIcon(icon); assert(localFlag==1)
 if SplitMacroBanks then
  assert(perCharacter==1,"new pockets must use character macros")
  local _,count=GetNumMacros()
  Macros[19+count]={name,icon,body}
 else table.insert(Macros,{name,icon,body}) end
end
function EditMacro(index,name,icon,body,localFlag)
 assert(not Combat)
 if icon then checkMacroIcon(icon) end
 local m=assert(Macros[index])
 m[1],m[2],m[3]=name or m[1],icon or m[2],body or m[3]
 EditCalls=EditCalls+1
 if ReentrantMacroEvents then Event("UPDATE_MACROS") end
end
function PickupMacro(index)
 assert(not Combat and Macros[index]); Cursor={"macro",index}
 local _,texture=GetMacroInfo(index); NativeCursorTexture=texture
end
function PickupSpell(slot,book)
 Cursor={"spell",slot,book}; NativeCursorTexture=GetSpellTexture(slot)
 return "original pickup result"
end
function ClearCursor()
 if Cursor and Cursor[1]=="item" and Cursor.origin then
  local o=Cursor.origin
  if o.kind=="bag" then BagItems[o.bag][o.slot]=Cursor[2]
  else Equipped[o.slot]=Cursor[2] end
 end
 Cursor=nil; NativeCursorTexture=nil
end
function PickupAction(slot)
 Cursor={"action",slot}; NativeCursorTexture=GetActionTexture(slot)
end
function PickupItem(item) Cursor={"item",item} end
local function itemLink(id)
 if id then return "|Hitem:"..id..":0:0:0|h["..ItemDB[id].name.."]|h" end
end
function GetItemInfo(value)
 local id=type(value)=="number" and value
 if type(value)=="string" then
  local _,_,parsed=string.find(value,"item:(%d+)"); id=tonumber(parsed)
 end
 local data=ItemDB[id]
 if data then return data.name,itemLink(id),1,1,"Weapon","Fishing",1,data.equip,data.icon end
end
function GetContainerNumSlots(bag) return 4 end
function GetContainerItemLink(bag,slot) return itemLink(BagItems[bag] and BagItems[bag][slot]) end
function GetInventoryItemLink(unit,slot) return itemLink(Equipped[slot]) end
function PickupContainerItem(bag,slot)
 if ItemPickupLocked then return end
 local id=BagItems[bag] and BagItems[bag][slot]
 if not id then return end
 assert(not Cursor,"test expects empty native cursor before item pickup")
 BagItems[bag][slot]=nil
 Cursor={"item",id}; Cursor.origin={kind="bag",bag=bag,slot=slot}
 NativeCursorTexture=ItemDB[id].icon
end
function PickupInventoryItem(slot)
 if ItemPickupLocked or not Equipped[slot] then return end
 assert(not Cursor)
 local id=Equipped[slot]; Equipped[slot]=nil
 Cursor={"item",id}; Cursor.origin={kind="equipped",slot=slot}
 NativeCursorTexture=ItemDB[id].icon
end
function AutoEquipCursorItem()
 EquipCalls=EquipCalls+1
 if EquipFailure then return end
 assert(Cursor and Cursor[1]=="item" and Cursor.origin.kind=="bag")
 local id,o=Cursor[2],Cursor.origin
 local slot=ItemDB[id].slot
 local old=Equipped[slot]; Equipped[slot]=id
 BagItems[o.bag][o.slot]=old
 Cursor=nil; NativeCursorTexture=nil
end
function PickupPetAction(slot) Cursor={"pet",slot} end
function CursorHasMacro() return Cursor and Cursor[1]=="macro" end
function PlaceAction(slot)
 if Cursor and Cursor[1]=="macro" then Actions[slot]=Macros[Cursor[2]][1] end
 Cursor=nil; NativeCursorTexture=nil
end
function CursorHasItem() return Cursor and Cursor[1]=="item" end
function CursorHasSpell() return Cursor and Cursor[1]=="spell" end
function GetActionText(slot) return Actions[slot] end
function GetActionTexture(slot) return "original"..slot end
function ActionButton_GetPagedID(b) return b.action end
function Trigger(frame,script,argument)
 local oldThis,oldArg=this,arg1
 this,arg1=frame,argument
 local ok,err=pcall(function() if frame.scripts[script] then frame.scripts[script]() end end)
 this,arg1=oldThis,oldArg
 assert(ok,err)
end
function Click(frame,mouse) Trigger(frame,"OnClick",mouse or "LeftButton") end
function Event(name,argument)
 local oldEvent=event
 event=name
 for _,frame in ipairs(Frames) do
  if frame.events[name] then Trigger(frame,"OnEvent",argument) end
 end
 event=oldEvent
end

function DeleteMacro(index)
 assert(not Combat)
 if SplitMacroBanks then
  local last=index<=18 and 18 or 36
  for i=index,last-1 do Macros[i]=Macros[i+1] end
  Macros[last]=nil
 else table.remove(Macros,index) end
end

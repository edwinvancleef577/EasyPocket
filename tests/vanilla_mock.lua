-- Deliberately models legacy global this/event/arg1 callbacks only.
-- Unknown frame methods fail. No C_Spell, SetSize, SecureHandlers or C_Timer.
Frames,Macros,Messages,Actions={}, {}, {}, {}
Combat,Cursor,LastCast,Shift=false,nil,nil,false
Clock,EditCalls=100,0
GetActionInfo=nil
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
function methods:SetTexture(v) self.texture=v end
function methods:SetBackdrop(v) self.backdrop=v end
function methods:SetBackdropColor(r,g,b,a) self.bg={r,g,b,a} end
function methods:SetBackdropBorderColor(r,g,b,a) self.border={r,g,b,a} end
function methods:SetNormalTexture(v)
 if not self.normal then self.normal=CreateFrame("Texture",nil,self) end
 self.normal:SetTexture(v)
end
function methods:GetNormalTexture() return self.normal end
function methods:SetPushedTexture(v) self.pushed=v end
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
local noops={"SetClampedToScreen","EnableMouse","SetAllPoints","SetTexCoord","SetHighlightTexture","SetJustifyH",
 "RegisterForClicks","RegisterForDrag","SetMovable",
 "SetAutoFocus","SetMaxLetters","ClearFocus","SetOwner","SetSpell","AddLine",
 "SetMultiLine","SetFontObject","SetScrollChild","EnableMouseWheel","SetVertexColor","SetBlendMode","SetTextInsets"}
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
function GetSpellTexture(slot) return "icon"..slot end
function IsSpellPassive(slot) return Spells[slot].passive end
function GetSpellCooldown() return 1,2,1 end
function CooldownFrame_SetTimer(frame,start,duration,enabled) frame.cooldown={start,duration,enabled} end
function CastSpell(slot,book) LastCast={slot,book} end
function GetNumMacros() return table.getn(Macros) end
function GetMacroInfo(index)
 if Macros[index] then
  local m=Macros[index]
  return m[1],type(m[2])=="number" and GetMacroIconInfo(m[2]) or m[2],m[3]
 end
end
function GetNumMacroIcons() return 4 end
function GetMacroIconInfo(index)
 if index==2 then return "Interface\\Icons\\INV_Misc_Bag_08" end
 if index==3 then return "Interface\\Icons\\Spell_Fire_Fireball02" end
 if index==4 then return "Interface\\Icons\\Spell_Arcane_TeleportStormWind" end
 return "Interface\\Icons\\INV_Misc_QuestionMark"
end
function CreateMacro(name,icon,body,localFlag)
 assert(not Combat); assert(type(icon)=="number"); assert(localFlag==1)
 table.insert(Macros,{name,icon,body}) -- legacy API need not return an index
end
function EditMacro(index,name,icon,body,localFlag)
 assert(not Combat)
 local m=assert(Macros[index])
 m[1],m[2],m[3]=name or m[1],icon or m[2],body or m[3]
 EditCalls=EditCalls+1
end
function PickupMacro(index) assert(not Combat); Cursor={"macro",index} end
function PickupSpell(slot,book) Cursor={"spell",slot,book}; return "original pickup result" end
function ClearCursor() Cursor=nil end
function PickupAction(slot) Cursor={"action",slot} end
function PickupItem(item) Cursor={"item",item} end
function PickupContainerItem(bag,slot) Cursor={"item",bag,slot} end
function PickupPetAction(slot) Cursor={"pet",slot} end
function CursorHasMacro() return Cursor and Cursor[1]=="macro" end
function PlaceAction(slot) Cursor=nil end
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
 table.remove(Macros,index)
end

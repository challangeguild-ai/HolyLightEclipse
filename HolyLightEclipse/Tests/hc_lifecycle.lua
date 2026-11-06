-- Minimal Lua 5.1 fixture: co-op down is not a completed run; panel collapse doesn't reflow.
-- Fixture only, not loaded by the game TOC.
local env=_G;
getglobal=function(k) return env[k] end
math.huge=nil
local methods={};
local function obj(kind,name,parent)
    local f=setmetatable({kind=kind,name=name,parent=parent,shown=true}, {__index=methods});
    if name then env[name]=f end
    return f
end
for _,name in ipairs({"SetFont","SetJustifyH","EnableMouse","SetFrameStrata","SetAllPoints",
        "ClearAllPoints","RegisterForDrag","SetMovable","SetClampedToScreen"}) do
    methods[name]=function() end
end
function methods:SetPoint(...) self.point={...} end
function methods:CreateTexture() return obj("Texture") end
function methods:CreateFontString() return obj("FontString") end
function methods:SetTexture(t) self.texture=t end
function methods:SetWidth(w) self.width=w end
function methods:SetHeight(h) self.height=h end
function methods:GetWidth() return self.width or 200 end
function methods:GetHeight() return self.height or 120 end
function methods:SetVertexColor(...) self.color={...} end
function methods:SetTextColor(...) self.color={...} end
function methods:SetText(t) self.text=t end
function methods:SetAlpha(a) self.alpha=a end
function methods:SetScale(a) self.scale=a end
function methods:SetScript(name,fn) self.scripts=self.scripts or {};self.scripts[name]=fn end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function CreateFrame(kind,name,parent) return obj(kind,name,parent) end
UIParent=obj("Frame","UIParent")
HLE_DB={enabled=true,showTimeline=true,showMeter=true,scale=0.85,collapsed={}}
UnitExists=function() return true end
local dead=true
UnitIsDeadOrGhost=function() return dead end
UnitHealth=function() return dead and 0 or 100 end
UnitHealthMax=function() return 100 end
UnitName=function(u) return u=="target" and "Boss One" or "Hero" end
AZS_ZONE={zone="aq",zname="AQ",heroic=3,affixes="explosive",hero="Hero",run="r123",len=900}
AZS_RUN={hp=0,hpm=100,t=515,kills=20,gold=200,en=5}
AZS_SPELLS={}
AZS_TARGET={kind="none"}
AZS_UNITS_UPDATED=45
AZS_SCHEDULE_UPDATED=38
AZS_ZONE_UPDATED=37
AZS_SCHEDULE={{index=1,at=600,name="Boss One",state="due"}}
local phase="dead"
local down=1
AZS_GetPhase=function() return phase end
AZS_GetRevive=function() return {down=down} end
AZS_GetRunTime=function() return 511 end
AZS_GetBosses=function() return {{id=12,name="Boss One",hp=45,hpm=90}} end
AZS_GetUpcomingBosses=function() return {{name="Boss One",left=89}} end
AZS_GetMeter=function() return {},0,0 end
AZS_GetStoredLevels=function() return 0 end
local r=assert(loadfile("Core.lua")); r()
assert(loadfile("Collapse.lua"))()
assert(loadfile("Timeline.lua"))()
assert(loadfile("View.lua"))()
local s=HLE.Read()
assert(s.active and s.coopDown and s.playerDead,"Co-op fallen hero lost active run")
assert(s.time==515,"Latest server clock was discarded")
assert(s.heroic==3 and s.affixes=="explosive")
assert(table.getn(s.bosses)==1 and s.bosses[1].id==12,"Live boss lost after co-op death")
local function Text(p,size,x,y,w,color)
    local v=obj("FontString");v:SetWidth(w);return v
end
local function Texture(p,path,x,y,w,h,layer)
    local v=obj("Texture");v:SetTexture(path);return v
end
HLE.BuildTimeline(Text,Texture)
local height=HLE.UpdateTimeline(s)
assert(height>0 and HLE.timeline:IsShown() and HLE.timelineNodes[1]:IsShown(),
    "Timeline went away while waiting for revive")
local meter=CreateFrame("Frame",nil,UIParent);meter.key="meter";meter:SetWidth(280);meter:SetHeight(250)
meter:SetPoint("RIGHT",UIParent,"RIGHT",-35,-24)
local point=meter.point
HLE.BuildCollapsePanels({meter})
HLE.ToggleCollapse("meter")
assert(HLE_DB.collapsed.meter==true and not meter:IsShown(),"Meter didn't collapse")
HLE.UpdateCollapsedPanels(s)
assert(meter.point==point and meter.width==280 and meter.height==250,
    "Collapsed panel position or dimensions were altered")
HLE.ToggleCollapse("meter")
assert(meter:IsShown() and not HLE_DB.collapsed.meter and meter.point==point,
    "Expanded panel was moved")
-- No co-op revive means the dead phase really ends the live HUD.
down=0;phase="dead"
local finished=HLE.Read()
assert(not finished.active and table.getn(finished.bosses)==0,
    "Ended solo run leaked old boss data")
HLE.UpdateTimeline(finished)
assert(not HLE.timeline:IsShown(),"Old timeline shown after actual run end")
-- Targeting must use client API, not claim direct selection by spawn ID.
dead=false; HLE.lifeDead=false
AZS_TARGET.id=12
local selected
TargetByName=function(name,exact) selected=name;assert(exact==true) end
assert(HLE.SelectBoss({id=12,name="Boss One"}) and selected=="Boss One")
TargetByName=nil
assert(not HLE.SelectBoss({id=12,name="Boss One"}),"Unsupported boss targeting not handled")
print("Co-op down HUD, HC state, timeline, in-place collapse, target checks passed")

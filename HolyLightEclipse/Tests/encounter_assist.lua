-- Lua 5.1 fixture: genuine encounter signal gating and alert precedence.
local env=_G; getglobal=function(k) return env[k]; end;
local methods={};
local function obj(kind,name)
    local f=setmetatable({kind=kind,name=name,shown=true},{__index=methods});
    if name then env[name]=f; end
    return f;
end
for _,k in ipairs({"SetPoint","SetJustifyH","SetFont","SetFrameStrata","EnableMouse","SetAllPoints"}) do
    methods[k]=function() end
end
function methods:CreateTexture() return obj("Texture") end
function methods:CreateFontString() return obj("FontString") end
function methods:SetTexture() end
function methods:SetHeight(h) self.height=h end
function methods:SetWidth(w) self.width=w end
function methods:SetText(v) self.text=v end
function methods:SetTextColor(...) self.color={...} end
function methods:SetVertexColor(...) self.color={...} end
function methods:SetAlpha(v) self.alpha=v end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function CreateFrame(kind,name,parent) return obj(kind,name) end
UIParent=obj("Frame","UIParent")
local now=0;GetTime=function() return now end
local sounds=0;PlaySound=function() sounds=sounds+1 end
AZS_ZONE={run="r1",affixes="sanguine,explosive"}
AZS_BANNER={}
local upcoming={}
AZS_GetUpcomingBosses=function() return upcoming end
HLE_DB={enabled=true,threatAlerts=true,threatSound=true,bossAlerts=true,language="en"}
assert(loadfile("Core.lua"))()
assert(loadfile("Localization.lua"))()
assert(loadfile("BossAlerts.lua"))()
assert(loadfile("EncounterAssist.lua"))()
HLE.BuildBossAlerts()
local s={active=true,phase="playing",playerDead=false,coopDown=false,bosses={}}
now=10
HLE.UpdateEncounterAssist(s)
assert(not HLE.bossWarning:IsShown(),"Affix alone created a fabricated alert")
upcoming={{index=1,name="Boss A",at=100,left=25}}
HLE.UpdateEncounterAssist(s)
assert(not HLE.bossWarning:IsShown(),"Distant boss timer generated premature alert")
upcoming={{index=1,name="Boss A",at=100,left=7}}
HLE.UpdateEncounterAssist(s)
assert(HLE.bossWarning:IsShown() and HLE.bossWarning.title.text=="BOSS ARRIVING SOON",
  "Verified upcoming boss did not generate useful warning")
assert(sounds==1)
now=14
HLE.UpdateBossAlerts(s);HLE.UpdateEncounterAssist(s)
assert(sounds==1,"A single upcoming boss created repeated sounds")
-- Enrage must come from the actual boss flag, not inferred from HP alone.
upcoming={}
s.bosses={{id=1,name="Boss A",hp=20,hpm=100,enraged=false}}
now=20;HLE.UpdateEncounterAssist(s)
assert(sounds==1,"Low boss HP fabricated enrage")
s.bosses[1].enraged=true
HLE.UpdateEncounterAssist(s)
assert(HLE.bossWarning.title.text=="BOSS ENRAGED" and sounds==2,
 "Server-confirmed enrage not reported")
now=25;HLE.UpdateBossAlerts(s);HLE.UpdateEncounterAssist(s)
assert(sounds==2,"Enrage for same boss spammed")
-- A high priority HP warning must not be overwritten by a less urgent boss.
HLE.ShowThreatNotice("DANGER - LOW HEALTH","HP 10%",2.5,3)
s.bosses={{id=2,name="Boss B",hp=25,hpm=100,enraged=true}}
now=26;HLE.UpdateEncounterAssist(s)
assert(HLE.bossWarning.title.text=="DANGER - LOW HEALTH",
 "The encounter info displaced a critical survival warning")
now=30;HLE.UpdateBossAlerts(s);HLE.UpdateEncounterAssist(s)
assert(HLE.bossWarning.title.text=="BOSS ENRAGED" and sounds==3,
 "Enrage was lost after more urgent HP warning")
-- No alerts when down, no fake flags, no cross-run stale encounter.
s.playerDead=true;now=40;s.bosses={{id=3,name="Boss C",hp=10,hpm=100,enraged=true}}
HLE.UpdateEncounterAssist(s);assert(sounds==3)
s.playerDead=false;s.bosses={};upcoming={{index=2,name="Boss C",at=88,left=nil}}
HLE.ResetEncounterAssist();now=50;HLE.UpdateEncounterAssist(s)
assert(sounds==3,"Upcoming boss with no authoritative timer caused fake warning")
print("Verified boss schedule/enrage, no invented affix cast, priority and anti-spam passed")

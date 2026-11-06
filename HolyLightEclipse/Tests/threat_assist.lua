-- Evidence-only danger cues. Standalone Lua 5.1 fixture; NOT listed in the TOC.
local env=_G;
getglobal=function(k) return env[k]; end
local methods={};
local function obj(kind,name)
    local f=setmetatable({kind=kind,name=name,shown=true}, {__index=methods});
    if name then env[name]=f end;return f;
end
for _,n in ipairs({"SetPoint","SetFont","SetJustifyH","EnableMouse","SetFrameStrata"}) do
    methods[n]=function() end;
end
function methods:CreateTexture() return obj("Texture"); end
function methods:CreateFontString() return obj("FontString"); end
function methods:SetTexture(t) self.texture=t; end
function methods:SetWidth(w) self.width=w; end
function methods:SetHeight(h) self.height=h; end
function methods:SetVertexColor(...) self.color={...}; end
function methods:SetTextColor(...) self.textColor={...}; end
function methods:SetText(t) self.text=t; end
function methods:SetAlpha(a) self.alpha=a; end
function methods:Show() self.shown=true; end
function methods:Hide() self.shown=false; end
function methods:IsShown() return self.shown; end
function CreateFrame(kind,name,parent) return obj(kind,name); end
UIParent=obj("Frame","UIParent");
local clock=10;GetTime=function() return clock end
local sounds=0;
PlaySound=function() sounds=sounds+1; end
AZS_ZONE={run="runA",affixes="explosive,sanguine"};
AZS_BANNER={id=1,kind="achievement"};
HLE_DB={enabled=true,bossAlerts=true,threatAlerts=true};
assert(loadfile("Core.lua"))();
assert(loadfile("BossAlerts.lua"))();
assert(loadfile("ThreatAssist.lua"))();
HLE.BuildBossAlerts();
local s={active=true,phase="playing",playerDead=false,coopDown=false,player={hp=100,hpm=100}};
HLE.UpdateThreatAssist(s);
assert(not HLE.bossWarning:IsShown() and sounds==0,"An affix alone produced a false alert");
clock=11;s.player.hp=80;HLE.UpdateThreatAssist(s);
clock=12;s.player.hp=55;HLE.UpdateThreatAssist(s);
clock=13;s.player.hp=35;HLE.UpdateThreatAssist(s);
assert(not HLE.bossWarning:IsShown(),"Healthy gradual HP losses caused a warning");
clock=14;s.player.hp=27;HLE.UpdateThreatAssist(s);
assert(HLE.bossWarning:IsShown() and HLE.bossWarning.title.text=="DANGER - LOW HEALTH");
assert(sounds==1,"Low HP should cause one distinct sound");
HLE.BossBannerNotice({id=2,kind="boss",name="Boss Two"});
assert(HLE.bossWarning.title.text=="DANGER - LOW HEALTH","Boss notice displaced a current threat");
clock=14.5;s.player.hp=26;HLE.UpdateThreatAssist(s);
assert(sounds==1,"Danger spammed on consecutive updates");
clock=17;HLE.UpdateBossAlerts(s);
assert(HLE.bossWarning:IsShown() and HLE.bossWarning.title.text=="BOSS INCOMING",
    "Deferred genuine boss arrival was lost after urgent HP warning");
assert(HLE.bossWarning.name.text=="Boss Two");
HLE.BossBannerNotice({id=3,kind="finalboss",name="Boss Three"});
assert(HLE.bossWarning:IsShown() and HLE.bossWarning.title.text=="FINAL BOSS");
clock=23;s.player.hp=100;HLE.UpdateThreatAssist(s);
clock=24;s.player.hp=60;HLE.UpdateThreatAssist(s);
assert(HLE.bossWarning.title.text=="HEAVY HIT RECEIVED","Reactive large-hit event was missed");
assert(HLE.bossWarning.name.text=="40 DAMAGE TAKEN - CHECK HP");
assert(sounds==2,"Large hit produced multiple alerts");
clock=25;HLE.UpdateThreatAssist(s);
assert(sounds==2,"Repeated identical HP produced another alert");
s.phase="paused";s.player.hp=20;clock=30;HLE.UpdateThreatAssist(s);
assert(sounds==2,"Paused scene generated a real-time warning");
s.phase="playing";clock=31;HLE.UpdateThreatAssist(s);
assert(sounds==2,"Resume treated an old hit as new");
clock=36;s.player.hp=80;HLE.UpdateThreatAssist(s);
clock=40;s.player.hp=20;HLE.UpdateThreatAssist(s);
assert(sounds==3 and HLE.bossWarning.title.text=="DANGER - LOW HEALTH");
s.playerDead=true;clock=41;HLE.UpdateThreatAssist(s);
assert(not HLE.bossWarning:IsShown(),"Downed player retained an active danger alert");
-- The entire run boundary clears the baseline, even when the next run starts low.
s.playerDead=false;AZS_ZONE.run="runB";clock=50;s.player.hp=19;
HLE.UpdateThreatAssist(s);assert(sounds==3 and not HLE.bossWarning:IsShown());
clock=51;s.player.hp=60;HLE.UpdateThreatAssist(s);
clock=60;s.player.hp=24;HLE.UpdateThreatAssist(s);
assert(sounds==4);
HLE_DB.threatAlerts=false;HLE.UpdateThreatAssist(s);
assert(not HLE.bossWarning:IsShown(),"Disabling threat alerts didn't dismiss the overlay");
-- Danger alerts and boss alerts share one center frame; disabling boss warnings
-- must not suppress the independent verified danger cue.
HLE_DB.threatAlerts=true;HLE_DB.bossAlerts=false;
clock=70;s.player.hp=100;HLE.UpdateThreatAssist(s);
clock=71;s.player.hp=20;HLE.UpdateThreatAssist(s);
HLE.UpdateBossAlerts(s);
assert(HLE.bossWarning:IsShown() and HLE.bossWarning.title.text=="DANGER - LOW HEALTH",
    "Boss-alert setting unexpectedly suppressed independent danger warnings");
-- End-user settings must drive the same verified HP alerts, without sound spam.
HLE_DB.threatLowPct=40;HLE_DB.threatCooldown=6;HLE_DB.threatSound=false;
local beforeMuted=sounds;
AZS_ZONE.run="runC";s.player.hp=100;clock=80;HLE.UpdateThreatAssist(s);
clock=81;s.player.hp=39;HLE.UpdateThreatAssist(s);
assert(HLE.bossWarning:IsShown() and HLE.bossWarning.title.text=="DANGER - LOW HEALTH",
    "Custom low-HP threshold is not connected to alerts")
assert(sounds==beforeMuted,"Muting danger sound did not work")
print("HC danger warnings: actual HP only, user threshold/sound, no spam and reset passed");

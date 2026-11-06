-- Non-game Lua 5.1 regression for left rescue, names, quiet banners, red boss title.
-- This test is NOT loaded by the addon TOC.
local env=_G;
getglobal=function(k) return env[k]; end
local methods={};
local function obj(kind,name)
    local f=setmetatable({kind=kind,shown=true,name=name}, {__index=methods});
    if name then env[name]=f end; return f;
end
local noop=function() end;
for _,key in ipairs({"SetFont","SetJustifyH","EnableMouse","SetFrameStrata","SetAllPoints","ClearAllPoints"}) do methods[key]=noop; end
function methods:SetPoint(...) self.point={...}; end
function methods:CreateTexture() return obj("Texture"); end
function methods:CreateFontString() return obj("FontString"); end
function methods:SetTexture(t) self.texture=t; end
function methods:SetWidth(w) self.width=w; end
function methods:SetHeight(h) self.height=h; end
function methods:SetVertexColor(r,g,b,a) self.color={r,g,b,a}; end
function methods:SetTextColor(r,g,b,a) self.color={r,g,b,a}; end
function methods:SetText(t) assert(type(t)=="string"); self.text=t; end
function methods:SetAlpha(a) self.alpha=a; end
function methods:Show() self.shown=true; end
function methods:Hide() self.shown=false; end
function methods:IsShown() return self.shown; end
function methods:GetWidth() return self.width or 200; end
function methods:GetHeight() return self.height or 100; end
function CreateFrame(kind,name,parent) return obj(kind,name); end
UIParent=obj("Frame","UIParent");
local now=0;
GetTime=function() return now; end
HLE_DB={enabled=true,replaceNative=true,quietBanners=true,rescueArrow=true,bossAlerts=true,nativeBackup={}};
assert(loadfile("Core.lua"))();
assert(loadfile("PartyRescue.lua"))();
assert(loadfile("BossAlerts.lua"))();
assert(loadfile("Native.lua"))();
local down={
    {id="p1",name="First",positionAvailable=false},
    {id="p2",name="Second",positionAvailable=false},
    {id="p3",name="Third",positionAvailable=false},
    {id="p4",name="Fourth",positionAvailable=false}
};
local centers=0;
UIErrorsFrame={AddMessage=function() centers=centers+1 end};
DEFAULT_CHAT_FRAME={AddMessage=function() end};
AZS_GetDownedPartyMembers=function() return down end
HLE.BuildRescue();
assert(HLE.rescueGuide.point[1]=="LEFT","Rescue panel is not left anchored");
HLE.UpdateRescue({active=true,playerDead=false});
assert(HLE.rescueGuide:IsShown() and HLE.rescueGuide.height==154);
for i=1,4 do
    local fs=HLE.rescueGuide.names[i];
    assert(fs:IsShown() and fs.text==down[i].name,"Downed name missing");
    assert(fs.color[1]==1 and fs.color[2]<0.4,"Downed name is not red");
end
-- Transition to a new downed player after a revive. The addon must not
-- add another center-screen warning of its own.
now=now+1; down={};
HLE.UpdateRescue({active=true,playerDead=false});
assert(not HLE.rescueGuide:IsShown(),"Rescue guide remains visible after revival");
now=now+1; down={{id="p5",name="Fifth",positionAvailable=false}};
HLE.UpdateRescue({active=true,playerDead=false});
assert(HLE.rescueGuide.names[1].text=="Fifth" and HLE.rescueGuide.names[1]:IsShown());
assert(not HLE.rescueGuide.names[2]:IsShown(),"Stale second name remains");
assert(centers==0,"Rescue added a center-screen notice");
HLE.BuildBossAlerts();
assert(HLE.bossWarning.title.color[1]==1 and HLE.bossWarning.title.color[2]<0.4,"Boss title not red");
assert(HLE.bossWarning.name.color[1]==1 and HLE.bossWarning.name.color[2]<0.5,"Boss name not red");
local hud={banners=true};
AZS_IsHudShown=function(part) return hud[part]~=false end;
AZS_SetHudShown=function(part,shown) hud[part]=shown end;
local state={active=true,hasAPI=true,phase="playing",player={}};
HLE.TakeOver(state);
assert(hud.banners==false,"Native banner spam not suppressed");
HLE_DB.quietBanners=false; HLE.TakeOver(state);
assert(hud.banners==true,"Native banners did not restore after preference off");
HLE_DB.quietBanners=true; HLE.TakeOver(state);
assert(hud.banners==false);
HLE_DB.enabled=false; HLE.TakeOver(state);
assert(hud.banners==true,"Native banners did not restore when addon disabled");
print("Rescue layout, red names, red boss and quiet banner restoration passed");

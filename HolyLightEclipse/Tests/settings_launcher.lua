-- Tests beginner settings, localization, minimap launcher and profile persistence.
-- Lua 5.1 only, never loaded by addon TOC.
local env=_G; getglobal=function(k) return env[k] end
local methods={};
local function obj(kind,name,parent)
    local f=setmetatable({kind=kind,name=name,parent=parent,shown=true,x=0,y=0}, {__index=methods});
    if name then env[name]=f end;return f;
end
for _,n in ipairs({"SetJustifyH","EnableMouse","SetFrameStrata","SetMovable","RegisterForDrag",
        "ClearAllPoints","SetAutoFocus","SetMaxLetters","SetFocus","ClearFocus",
        "SetClampedToScreen"}) do methods[n]=function() end end
function methods:SetPoint(...) self.point={...} end
function methods:CreateTexture() return obj("Texture") end
function methods:CreateFontString() return obj("FontString") end
function methods:SetTexture(x) self.texture=x end
function methods:SetWidth(x) self.width=x end
function methods:SetHeight(x) self.height=x end
function methods:GetWidth() return self.width or 200 end
function methods:GetHeight() return self.height or 100 end
function methods:GetCenter() return self.x,self.y end
function methods:GetEffectiveScale() return self.scale or 1 end
function methods:SetScale(v) self.scale=v end
function methods:SetFont(path,size,flags) self.font=path;self.fontSize=size;return true end
function methods:SetAllPoints() end
function methods:SetVertexColor(...) self.color={...} end
function methods:SetTextColor(...) self.textColor={...} end
function methods:SetText(v) self.text=v end
function methods:GetText() return self.text end
function methods:SetScript(k,v) self.scripts=self.scripts or {};self.scripts[k]=v end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:StartMoving() self.moving=true end
function methods:StopMovingOrSizing() self.moving=false end
function CreateFrame(kind,name,parent,template) return obj(kind,name,parent) end
UIParent=obj("Frame","UIParent");UIParent.x=600;UIParent.y=400
Minimap=obj("Frame","Minimap",UIParent);Minimap.x=1100;Minimap.y=650
local hleScaleCalls=0
HLE_DB={enabled=true,scale=0.85,showMeter=true,showGear=true,
    showParty=true,showTimeline=true,showLauncher=true,threatAlerts=true,
    bossAlerts=true,threatSound=true,threatLowPct=30,threatCooldown=8,
    nameplates=true,replaceNative=true,profiles={},profileNames={}}
assert(loadfile("Core.lua"))()
assert(loadfile("Localization.lua"))()
assert(loadfile("Extras.lua"))()
assert(loadfile("SettingsUI.lua"))()
assert(loadfile("MinimapLauncher.lua"))()
assert(HLE.Language()=="en" and HLE.L("appearance")=="Appearance",
    "English default was not retained")
assert(HLE.SetLanguage("hu") and HLE.L("appearance")=="Megjelenés",
    "Hungarian locale failed")
assert(HLE.SetLanguage("de") and HLE.L("profiles")=="Profile","German locale failed")
assert(HLE.SetLanguage("zhCN") and HLE.L("appearance")=="外观",
    "Simplified Chinese locale failed")
assert(not HLE.SetLanguage("xx") and HLE.Language()=="zhCN",
    "Invalid locale changed setting")
assert(HLE.SetLanguage("en"))
HLE.ApplyScaleKeepingPositions=function(value)
    hleScaleCalls=hleScaleCalls+1;HLE_DB.scale=value;
end
HLE.ApplyLayout=function() end
HLE.ResetMeterCache=function() end
HLE.BuildSettingsUI()
assert(HLE.settings and not HLE.settings:IsShown(),"Settings should be closed initially")
assert(HLE.settings:GetHeight()==420,"Advanced options should not cover screen initially")
HLE.ToggleSettings();assert(HLE.settings:IsShown(),"Settings did not open")
arg1="LeftButton"
HLE.advancedButton.scripts.OnMouseUp()
assert(HLE.settings:GetHeight()==600,"Advanced options didn't expand")
HLE.advancedButton.scripts.OnMouseUp()
assert(HLE.settings:GetHeight()==420,"Advanced options didn't collapse")
HLE.langButtons[2].scripts.OnMouseUp()
assert(HLE.Language()=="hu" and HLE_DB.language=="hu","Language button didn't switch to Hungarian")
HLE.langButtons[1].scripts.OnMouseUp()
assert(HLE.Language()=="en","English fallback button failed")
HLE.ToggleSettings();assert(not HLE.settings:IsShown(),"Settings did not close")
assert(HLE.settingsEnabled,"HUD recovery control missing")
assert(HLE.ChangeHudScale(1) and HLE_DB.scale==1 and hleScaleCalls==1)
assert(not HLE.ChangeHudScale(2),"Invalid scale accepted")
assert(HLE.settingsStatus,"Profile status missing")
HLE_DB.meter={x=190,y=80}
HLE.Profile("save",1)
assert(HLE_DB.profiles[1] and HLE_DB.profiles[1].meter.x==190,"Profile lost panel coordinates")
HLE_DB.meter={x=900,y=80}
HLE.Profile("load",1)
assert(HLE_DB.meter.x==190,"Saved panel location did not restore")
-- Reset needs two deliberate clicks and must not touch persistent character data.
HLE_DB.journal={{key="ring:123",name="Verified ring"}};
arg1="LeftButton"
HLE.profileReset.scripts.OnMouseUp()
assert(HLE_DB.meter.x==190 and HLE.settingsResetArmed==true,
    "Single reset click destroyed saved positions")
HLE.profileReset.scripts.OnMouseUp()
assert(HLE_DB.meter==nil and HLE.settingsResetArmed==false,
    "Confirmed layout reset did not clear positions")
assert(HLE_DB.journal[1].key=="ring:123","Layout reset erased saved character journal")
HLE.BuildMinimapLauncher()
assert(HLE.launcher and HLE.launcher:IsShown(),"Minimap launcher was not created")
assert(HLE.launcher.point and HLE.launcher.point[2]==Minimap,
    "Launcher was not anchored to minimap")
arg1="LeftButton";this=HLE.launcher
HLE.launcher.scripts.OnMouseUp()
assert(HLE.settings:IsShown(),"Launcher click didn't open settings")
HLE.launcher.scripts.OnMouseUp()
assert(not HLE.settings:IsShown(),"Launcher second click didn't close settings")
HLE_DB.showLauncher=false;HLE.UpdateMinimapLauncher();
assert(not HLE.launcher:IsShown(),"Hidden launcher ignored user setting")
HLE_DB.showLauncher=true;HLE.UpdateMinimapLauncher()
assert(HLE.launcher:IsShown(),"Hidden launcher could not be recovered")
local shift=false;IsShiftKeyDown=function() return shift end
this=HLE.launcher;shift=true
HLE.launcher.scripts.OnDragStart()
assert(HLE.launcher.moving==true,"Shift-drag failed")
HLE.launcher.x=1050;HLE.launcher.y=670
HLE.launcher.scripts.OnDragStop()
assert(HLE_DB.launcherPosition and HLE_DB.launcherPosition.x==-50,
    "Dragged icon location wasn't saved")
assert(HLE_DB.launcherPosition.y==20)
HLE.ResetLauncherPosition()
assert(HLE_DB.launcherPosition==nil,"Launcher reset failed")
print("Settings launcher: EN/HU/DE/ZH, profile, scale, click, visibility and drag passed")

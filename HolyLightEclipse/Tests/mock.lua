-- Standalone test fixture, NOT loaded by the addon TOC.
local env = _G;
math.huge = nil; -- Reproduce the actual client failure from the user's screenshot.
getglobal = function(k) return env[k]; end
local methods = {};
local function obj(kind)
    local f=setmetatable({kind=kind, shown=true, scripts={}}, {__index=methods});
    if kind=="Texture" then f.GetTexture=function(self) return self.texture; end; end
    if kind=="FontString" then f.GetText=function(self) return self.text; end; end
    return f;
end
local noop = function() end;
local names = {"SetFont", "SetPoint", "ClearAllPoints", "SetJustifyH", "SetTextColor", "SetTexture", "SetVertexColor", "SetStatusBarTexture", "SetStatusBarColor", "SetMinMaxValues", "SetFrameStrata", "SetMovable", "RegisterForDrag", "SetClampedToScreen", "StartMoving", "StopMovingOrSizing", "RegisterEvent"};
for _, name in ipairs(names) do methods[name] = noop; end
function methods:SetPoint(point,relative,relativePoint,x,y) self.point={point,relative,relativePoint,x,y}; end
function methods:ClearAllPoints() self.point=nil; end
function methods:SetParent(parent) self.parent=parent; end
function methods:GetParent() return self.parent; end
function methods:GetWidth() return self.width or 36; end
function methods:GetHeight() return self.height or 36; end
function methods:GetNumPoints() return self.point and 1 or 0; end
function methods:GetPoint() if self.point then return unpack(self.point); end end
function methods:SetFrameLevel(level) self.level=level; end
function methods:GetFrameLevel() return self.level or 1; end
function methods:SetFrameStrata(strata) self.strata=strata; end
function methods:GetFrameStrata() return self.strata or "MEDIUM"; end
function methods:SetTexture(v) self.texture=v; end
function methods:SetVertexColor(r,g,b,a) self.color={r,g,b,a}; end
function methods:SetStatusBarColor(r,g,b,a) self.barColor={r,g,b,a}; end
function methods:SetMinMaxValues(low,high) self.low,self.high=low,high; end
function methods:GetMinMaxValues() return self.low,self.high; end
function methods:GetValue() return self.value; end
function methods:SetWidth(v) assert(type(v)=="number"); self.width=v; end
function methods:SetHeight(v) assert(type(v)=="number"); self.height=v; end
function methods:SetText(v) assert(type(v)=="string"); self.text=v; end
function methods:SetValue(v) assert(type(v)=="number" and v>=0 and v<=1); self.value=v; end
function methods:SetScale(v) self.scale=v; end
function methods:GetEffectiveScale() return self.scale or 1; end
function methods:GetCenter() return 500, 400; end
function methods:EnableMouse(v) self.mouse=v; end
function methods:SetAlpha(v) self.alpha=v; end
function methods:GetAlpha() return self.alpha or 1; end
function methods:IsShown() return self.shown; end
function methods:SetScript(k,v) self.scripts[k]=v; end
function methods:Show() self.shown=true; end
function methods:Hide() self.shown=false; end
function methods:CreateTexture() return obj("Texture"); end
function methods:CreateFontString() return obj("FontString"); end
function CreateFrame(kind, name, parent)
    assert(kind=="Frame" or kind=="StatusBar");
    local f=obj(kind); f.parent=parent; if name then env[name]=f; end return f;
end
UIParent=obj("Frame");
PlayerFrame=obj("Frame"); TargetFrame=obj("Frame"); MainMenuBar=obj("Frame");
DEFAULT_CHAT_FRAME={messages={}, AddMessage=function(self,s) table.insert(self.messages,s); end};
UnitExists=function(u) return u=="player"; end;
UnitName=function() return "Paladin"; end;
UnitHealth=function() return 90; end;
UnitHealthMax=function() return 100; end;
UnitMana=function() return 20; end;
UnitManaMax=function() return 50; end;
UnitPowerType=function() return 0; end;
UnitXP=function() return 2; end;
UnitXPMax=function() return 10; end;
UnitLevel=function() return 1; end;
-- Remove modern global access in addon execution; getglobal retains the captured env.
_G=nil;

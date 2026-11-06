-- Standalone Lua 5.1 compatibility smoke test; not loaded by the addon TOC.
local env=_G;
getglobal=function(k) return env[k]; end
local methods={};
local function obj(kind,name,parent)
    local f=setmetatable({kind=kind,shown=true,parent=parent,name=name,children={}}, {__index=methods});
    if parent then table.insert(parent.children,f); end
    if name then env[name]=f; end
    return f;
end
local noop=function() end;
for _,n in ipairs({'SetPoint','ClearAllPoints','SetFont','SetJustifyH','EnableMouse','SetFrameStrata'}) do methods[n]=noop; end
function methods:CreateTexture() return obj('Texture',nil,self); end
function methods:CreateFontString() return obj('FontString',nil,self); end
function methods:SetTexture(texture) self.texture=texture; end
function methods:SetWidth(w) self.width=w; end
function methods:SetHeight(h) self.height=h; end
function methods:GetWidth() return self.width or 40; end
function methods:GetHeight() return self.height or 40; end
function methods:GetName() return self.name; end
function methods:GetID() return self.id; end
function methods:SetVertexColor(r,g,b,a) self.color={r,g,b,a}; end
function methods:SetText(text) assert(type(text)=='string'); self.text=text; end
function methods:GetText() return self.text; end
function methods:SetTextColor(r,g,b) self.color={r,g,b}; end
function methods:SetAlpha(alpha) self.alpha=alpha; end
function methods:SetScript(name,fn) self.scripts=self.scripts or {}; self.scripts[name]=fn; end
function methods:Show() self.shown=true; end
function methods:Hide() self.shown=false; end
function methods:IsShown() return self.shown; end
function CreateFrame(kind,name,parent) return obj(kind,name,parent); end
UIParent=obj('Frame','UIParent');
local clock=0;
GetTime=function() return clock end
HLE_DB={enabled=true,skinBags=true,bossAlerts=true,showEndSummary=true};
assert(loadfile('Core.lua'))();
assert(loadfile('BagSkin.lua'))();
assert(loadfile('BossAlerts.lua'))();
assert(loadfile('EndSummary.lua'))();
local container=CreateFrame('Frame','ContainerFrame1',UIParent);container:SetWidth(210);container:SetHeight(310);container.id=0;
local item=CreateFrame('Button','ContainerFrame1Item1',container); item:SetWidth(36); item:SetHeight(36);
GetContainerItemLink=function(bag,slot) if bag==0 and slot==1 then return 'item:123' end end
GetItemInfo=function() return 'Ring',nil,4 end
HLE.UpdateBagSkin(0.5);
assert(table.getn(container.children)>3 and table.getn(item.children)==4,'Bag chrome/quality edges missing');
assert(item.scripts==nil,'Inventory should not take item click scripts');
HLE_DB.skinBags=false;HLE.UpdateBagSkin(0.5);
for _,child in ipairs(item.children) do assert(child.shown==false,'Bag border not removed'); end
local handler,unregistered;
AZS_RegisterBannerHandler=function(fn) handler=fn end
AZS_UnregisterBannerHandler=function(fn) unregistered=fn end
AZS_BANNER={id=1,kind='achievement'};
HLE.BuildBossAlerts();HLE.UpdateBossAlerts({active=true,playerDead=false});
assert(type(handler)=='function','Banner handler not registered');
handler({id=2,kind='achievement',name='No'});assert(not HLE.bossWarning:IsShown());
handler({id=3,kind='boss',name='Kurinnaxx'});
assert(HLE.bossWarning:IsShown() and HLE.bossWarning.name.text=='Kurinnaxx');
clock=3;HLE.UpdateBossAlerts({active=true,playerDead=false});assert(not HLE.bossWarning:IsShown());
HLE_DB.bossAlerts=false;HLE.UpdateBossAlerts({active=true});assert(unregistered==handler);
HLE_DB.bossAlerts=true;
HLE.BuildEndSummary();
AZS_ZONE={run='first'};
AZS_GetRunSummary=function() return {result='defeat',hero='Mage',cname='Mage',zname='Elwynn Forest',
    t=120,lvl=8,kills=100,elites=5,guardians=2,bosses=1,dmg=20000,taken=3000,gold=600,chests=3,magnets=2} end
HLE.UpdateEndSummary({phase='playing'});assert(not HLE.endSummary:IsShown());
HLE.UpdateEndSummary({phase='dead'});assert(HLE.endSummary:IsShown());
assert(HLE.endSummary.stats[8].text=='167','Summary average DPS incorrect');
HLE.ToggleEndSummary();assert(not HLE.endSummary:IsShown());
HLE.UpdateEndSummary({phase='dead'});assert(not HLE.endSummary:IsShown(),'Closed summary resurfaced');
HLE.ToggleEndSummary();assert(HLE.endSummary:IsShown());
HLE.ResetEndSummary();assert(not HLE.endSummary:IsShown());
print('Bag, boss banner and run-summary regression fixture passed')

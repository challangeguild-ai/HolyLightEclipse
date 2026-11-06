-- Lua 5.1 fallback regression: Game banners are still quiet without HUD getter.
local env=_G;getglobal=function(k) return env[k]; end
HLE_DB={enabled=true,replaceNative=true,quietBanners=true,bossAlerts=false,nativeBackup={}}
assert(loadfile("Core.lua"))()
assert(loadfile("Native.lua"))()
local cvars={hudBanners="1"}
GetCVar=function(k) return cvars[k] end
SetCVar=function(k,v) cvars[k]=v end
GetTime=function() return 123 end
AZS_BANNERS={}
AZS_BANNER={}
local state={active=true,hasAPI=true,phase="playing",player={}}
HLE.TakeOver(state)
assert(cvars.hudBanners=="0","CVar fallback didn't quiet native banner channel")
assert(HLE_DB.nativeBackup.banners==true,"Original preference not backed up")
HLE_DB.bossAlerts=true;HLE.TakeOver(state)
assert(cvars.hudBanners=="0","Turning on own boss warning restored game spam")
HLE_DB.bossAlerts=false;HLE.TakeOver(state)
assert(cvars.hudBanners=="0","Turning off own boss warning restored game spam")
HLE_DB.quietBanners=false;HLE.TakeOver(state)
assert(cvars.hudBanners=="1","Turning off quiet banners didn't restore native channel")
HLE_DB.quietBanners=true;HLE.TakeOver(state)
assert(cvars.hudBanners=="0")
-- Quiet banners remains independent even in native HUD mode.
HLE_DB.replaceNative=false;HLE.TakeOver(state)
assert(cvars.hudBanners=="0","Native HUD mode restored unwanted banner spam")
HLE_DB.quietBanners=false;HLE.TakeOver(state)
assert(cvars.hudBanners=="1","Native HUD mode failed to restore banner preference")
HLE_DB.replaceNative=true;HLE_DB.quietBanners=true;HLE.TakeOver(state)
assert(cvars.hudBanners=="0")
HLE_DB.enabled=false;HLE.TakeOver(state)
assert(cvars.hudBanners=="1","Disabling addon didn't restore original user preference")
print("Game banner CVar fallback, independent native HUD settings and restoration passed")

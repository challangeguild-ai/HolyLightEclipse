-- Minimal read-only meter contract regression. Run with: lua5.1 Tests/meter_scope.lua
-- Test fixture only; this is never loaded by the addon TOC.
local core=assert(loadfile('Core.lua')); core()
local tracking=assert(loadfile('Tracking.lua')); tracking()
getglobal=function(k) return _G[k] end
local time=1
GetTime=function() return time end
GetNumPartyMembers=function() return 2 end
AZS_ZONE={run='example',zone='test'}
HLE_DB={meterMode='run',meterScope='self'}
local sample={active=true,phase='playing',time=42,damage=100,dps=10,meter={{name='Legacy Spell',dmg=100}},enemies=5}
local calls=0
AZS_GetMeterCapabilities=function() return {apiVersion=1} end
AZS_GetMeterContext=function() return {runId='run_1'} end
AZS_GetMeterSnapshot=function(q)
    calls=calls+1
    assert(q.apiVersion==1 and q.runId=='run_1' and q.windowSeconds==0)
    assert(q.groupBy==(q.scope=='self' and 'source' or 'owner'))
    assert(q.period==(HLE_DB.meterMode=='boss' and 'encounter' or 'run'))
    assert(q.metric==(HLE_DB.meterMode=='heal' and 'healing' or 'damage'))
    if q.metric=='healing' then assert(q.healingPerspective=='performed')
    else assert(q.healingPerspective==nil) end
    local amount=q.scope=='party' and 250 or 75
    return {apiVersion=1,status='ready',complete=true,
        context={runId='run_1'},rows={
            {ownerId='a1',sourceKey='src',displayAmount=amount,displayRate={value=13.5},share=1}
        },totals={displayAmount=amount,displayRate={value=13.5}},
        actors={a1={name='Mage'}},sources={src={name='Fireball'}}}
end
for _,scope in ipairs({'self','party'}) do
    for _,mode in ipairs({'run','boss','heal'}) do
        HLE_DB.meterScope=scope;HLE_DB.meterMode=mode;time=time+1
        local result=HLE.ReadMeter(sample)
        assert(result.scope==scope and result.mode==mode and result.source=='snapshot')
        assert(result.total==(scope=='party' and 250 or 75))
        assert(result.lines[1].name==(scope=='party' and 'Mage' or 'Fireball'))
        assert(result.rate==13.5 and not result.unavailable)
        local before=calls; local cached=HLE.ReadMeter(sample)
        assert(cached==result and calls==before)
    end
end
AZS_GetMeterCapabilities=nil;AZS_GetMeterContext=nil;AZS_GetMeterSnapshot=nil
AZS_GetPartyMeter=function() return {{name='Warrior',dmg=98}},98,9.8 end
HLE_DB.meterScope='party';HLE_DB.meterMode='run';HLE.ResetMeterCache()
local legacy=HLE.ReadMeter(sample)
assert(legacy.source=='legacy' and legacy.lines[1].name=='Warrior' and legacy.rate==9.8)
HLE_DB.meterMode='boss';HLE.ResetMeterCache()
assert(HLE.ReadMeter(sample).unavailable==true)
HLE_DB.meterScope='self';HLE_DB.meterMode='run';HLE.ResetMeterCache()
assert(HLE.ReadMeter(sample).lines[1].name=='Legacy Spell')
AZS_GetBossMeter=function() return {{name='Blessed',dmg=50}},50,12 end
HLE_DB.meterMode='boss';HLE.ResetMeterCache()
assert(HLE.ReadMeter(sample).lines[1].name=='Blessed')
AZS_GetHealing=function() return {{name='Holy Light',dmg=18}},18,2 end
HLE_DB.meterMode='heal';HLE.ResetMeterCache()
assert(HLE.ReadMeter(sample).healing and HLE.ReadMeter(sample).total==18)
print('SELF/PARTY x RUN/BOSS/HEAL meter fixture passed')

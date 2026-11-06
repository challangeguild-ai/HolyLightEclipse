-- Conservative HC danger cues for Azeroth Survivors / WoW 1.12.
-- Only the local hero's VERIFIED HP transitions are announced.
-- No boss cast or affix is called "incoming" without an actual pre-hit API.
local H=HLE;
local lastRun,lastHP,lastMax,lastArea,lastAlert,armed=nil,nil,nil,nil,nil,false;
local function Reset()
    lastRun,lastHP,lastMax,lastArea,lastAlert,armed=nil,nil,nil,nil,nil,false;
    if H.HideThreatNotice then H.HideThreatNotice(); end
end
function H.ResetThreatAssist() Reset(); end
function H.UpdateThreatAssist(s)
    if type(s)~="table" or not HLE_DB or not HLE_DB.enabled or
        HLE_DB.threatAlerts==false or H.suspended or not s.active or
        s.playerDead or s.coopDown then
        Reset(); return;
    end

    local z=H.Table(AZS_ZONE);
    -- The same run id is the only safe boundary for a damage series.
    local id=type(z.run)=="string" and z.run or nil;
    if not id or id=="" then Reset(); return; end
    if id~=lastRun then Reset(); lastRun=id; end

    local player=H.Table(s.player);
    local hp,max=H.Pair(player.hp,player.hpm);
    if not hp or not max or hp<=0 then lastHP=nil; lastMax=nil; armed=false; return; end
    local now=H.Number(H.Call("GetTime"));
    if not now then lastHP=hp; lastMax=max; return; end

    -- AZS_TAKEN is cumulative verified damage, not a forecast of a cast.
    -- An increase in the "area" row proves a ground-effect hit reached the hero.
    local area=nil;
    local taken=H.Table(AZS_TAKEN);
    for i=1,table.getn(taken) do
        local row=H.Table(taken[i]);
        if row.source=="area" and H.Number(row.dmg) and row.dmg>=0 then area=row.dmg; break; end
    end
    local areaHit=nil;
    if area then
        if lastArea and area>lastArea and s.phase=="playing" then areaHit=area-lastArea; end
        lastArea=area;
    end
    local fraction=math.max(0,math.min(1,hp/max));
    if not lastHP or not lastMax or max~=lastMax then
        -- A level-up or equipment change can alter maximum HP without a hit.
        -- Rebaseline instead of interpreting this as incoming damage.
        lastHP,lastMax=hp,max; armed=fraction>=0.45; return;
    end
    if fraction>=0.45 then armed=true; end

    -- Paused and card-choosing scenes have no immediate combat exposure.
    if s.phase~="playing" then
        lastHP,lastMax=hp,max; return;
    end

    local previous=math.max(0,math.min(1,lastHP/lastMax));
    local fell=hp<lastHP and lastHP-hp or 0;
    local threshold=(H.Number(HLE_DB.threatLowPct) or 30)/100;
    local enteredLow=armed and previous>threshold and fraction<=threshold;
    local largeHit=fell>=0.35*max and fraction>0.30;
    lastHP,lastMax=hp,max;

    if enteredLow then armed=false; end
    if not enteredLow and not areaHit and not largeHit then return; end
    if lastAlert and now-lastAlert<(H.Number(HLE_DB.threatCooldown) or 8) then return; end

    local title,detail;
    if enteredLow then
        title=H.L and H.L("low_health") or "DANGER - LOW HEALTH";
        detail="HP "..H.Short(math.floor(fraction*100+0.5)).."% - "..(H.L and H.L("recover") or "RECOVER");
    elseif areaHit then
        -- Reactive cue: a verified area hit occurred. It is not a cast prediction.
        title=H.L and H.L("area_warning") or "MOVE OUT OF THE AREA";
        detail=H.Short(areaHit).." - "..(H.L and H.L("area_detail") or "AREA DAMAGE RECEIVED");
    else
        -- This hit has ALREADY happened; never misrepresent it as an incoming cast.
        title=H.L and H.L("confirmed_hit") or "HEAVY HIT RECEIVED";
        detail=H.Short(fell).." "..(H.L and H.L("damage_taken") or "DAMAGE TAKEN - CHECK HP");
    end
    if H.ShowThreatNotice and H.ShowThreatNotice(title,detail,2.5) then
        lastAlert=now;
        if HLE_DB.threatSound~=false and type(PlaySound)=="function" then pcall(PlaySound,"RaidWarning"); end
    end
end

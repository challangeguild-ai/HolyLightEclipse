-- Conservative HC danger cues for Azeroth Survivors / WoW 1.12.
-- Only the local hero's VERIFIED HP transitions are announced.
-- No boss cast or affix is called "incoming" without an actual pre-hit API.
local H=HLE;
local lastRun,lastHP,lastMax,lastAlert,armed=nil,nil,nil,nil,false;
local function Reset()
    lastRun,lastHP,lastMax,lastAlert,armed=nil,nil,nil,nil,false;
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
    local enteredLow=armed and previous>0.30 and fraction<=0.30;
    local largeHit=fell>=0.35*max and fraction>0.30;
    lastHP,lastMax=hp,max;

    if enteredLow then armed=false; end
    if not enteredLow and not largeHit then return; end
    if lastAlert and now-lastAlert<8 then return; end

    local title,detail;
    if enteredLow then
        title="DANGER - LOW HEALTH";
        detail="HP "..H.Short(math.floor(fraction*100+0.5)).."% - RECOVER";
    else
        -- This hit has ALREADY happened; never misrepresent it as an incoming cast.
        title="HEAVY HIT RECEIVED";
        detail=H.Short(fell).." DAMAGE TAKEN - CHECK HP";
    end
    if H.ShowThreatNotice and H.ShowThreatNotice(title,detail,2.5) then
        lastAlert=now;
        if type(PlaySound)=="function" then pcall(PlaySound,"RaidWarning"); end
    end
end

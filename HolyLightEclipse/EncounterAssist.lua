-- Genuine encounter cues. No fictional spell casts, target prediction or
-- guessed affix explosions: only server-published boss schedule and live enrage.
local H=HLE;
local runId,seenEnrage,seenSoon=nil,{},{};
local lastNotice=nil;
function H.ResetEncounterAssist()
    runId=nil;seenEnrage={};seenSoon={};lastNotice=nil;
end
local function Sound()
    if HLE_DB.threatSound~=false and type(PlaySound)=="function" then
        pcall(PlaySound,"RaidWarning");
    end
end
local function Notice(title,detail,priority)
    local now=H.Number(H.Call("GetTime"));
    if not now or (lastNotice and now-lastNotice<4) then return false; end
    if H.ShowThreatNotice and H.ShowThreatNotice(title,detail,2.2,priority or 1) then
        lastNotice=now;Sound();return true;
    end
    return false;
end
function H.UpdateEncounterAssist(s)
    if type(s)~="table" or not HLE_DB or not HLE_DB.enabled or
        HLE_DB.threatAlerts==false or H.suspended or not s.active or
        s.phase~="playing" or s.playerDead or s.coopDown then
        return;
    end
    local z=H.Table(AZS_ZONE);
    local id=type(z.run)=="string" and z.run or nil;
    if not id or id=="" then return; end
    if runId~=id then
        runId=id;seenEnrage={};seenSoon={};lastNotice=nil;
    end
    -- A boss truly entering enraged state is a meaningful change in threat.
    -- Use stable numeric spawn ID when the server publishes it.
    local bosses=H.Table(s.bosses);
    for i=1,table.getn(bosses) do
        local b=H.Table(bosses[i]);
        local bid=H.Number(b.id);
        if bid and H.Number(b.hp) and H.Number(b.hpm) and b.hp>0 and b.hpm>0 then
            if b.enraged==true or b.enraged==1 then
                if seenEnrage[bid]~=true then
                    local name=H.Text(b.name,"Boss");
                    local title=H.L and H.L("boss_enrage_warning") or "BOSS ENRAGED";
                    local detail=name.." - "..(H.L and H.L("enrage_detail") or "FASTER ATTACKS");
                    if Notice(title,detail,2) then
                        seenEnrage[bid]=true;return;
                    end
                end
            else
                seenEnrage[bid]=false;
            end
        end
    end
    -- The game's direct upcoming-boss list includes authoritative remaining
    -- seconds and an index. Without these, do not predict an arrival.
    local upcoming=H.Table(H.Call("AZS_GetUpcomingBosses"));
    for i=1,table.getn(upcoming) do
        local b=H.Table(upcoming[i]);
        local index=H.Number(b.index);
        local at=H.Number(b.at);
        local left=H.Number(b.left);
        if index and at and left and left>0 and left<=8 then
            local key=tostring(index)..":"..tostring(at);
            if seenSoon[key]~=true then
                local title=H.L and H.L("boss_soon_warning") or "BOSS ARRIVING SOON";
                local name=H.Text(b.name,"Boss");
                local detail=name.." - "..H.Short(math.ceil(left)).."s";
                if Notice(title,detail,1) then
                    seenSoon[key]=true;return;
                end
            end
        end
    end
end

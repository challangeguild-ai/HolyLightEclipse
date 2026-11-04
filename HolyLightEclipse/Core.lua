-- Lua 5.0 subset: no _G, #, vararg forwarding or modern WoW APIs.
HLE = { errors = {}, version = "0.8.3", maxSkills = 32 };
local H = HLE;
function H.Number(v)
    -- math.huge is absent in the user's client. Finite numbers subtract to zero;
    -- infinities subtract to NaN, which does not equal zero.
    if type(v) ~= "number" or v ~= v or v - v ~= 0 then return nil; end
    return v;
end
function H.Table(v) if type(v) == "table" then return v; end return {}; end
function H.Call(name, a, b)
    local fn = getglobal(name);
    if type(fn) ~= "function" then return nil; end
    local ok, x, y, z;
    -- Some client bindings reject surplus nil arguments.
    if b~=nil then ok,x,y,z=pcall(fn,a,b);
    elseif a~=nil then ok,x,y,z=pcall(fn,a);
    else ok,x,y,z=pcall(fn); end
    if not ok then H.errors[name] = tostring(x); return nil; end
    return x, y, z;
end
function H.Text(v, fallback)
    if type(v) == "string" and v ~= "" then return v; end
    return fallback or "--";
end
function H.Short(v)
    v = H.Number(v);
    if not v then return "--"; end
    if math.abs(v) >= 1000000 then return string.format("%.1fM", v / 1000000); end
    if math.abs(v) >= 10000 then return string.format("%.1fk", v / 1000); end
    return string.format("%.0f", v);
end
function H.Clock(v)
    v = H.Number(v);
    if not v or v < 0 then return "--:--"; end
    v = math.floor(v);
    return string.format("%d:%02d", math.floor(v / 60), math.mod(v, 60));
end
function H.Pair(value, maximum)
    value, maximum = H.Number(value), H.Number(maximum);
    if not value or not maximum or maximum <= 0 then return nil, nil; end
    return math.max(0, value), maximum;
end
function H.Exists(unit)
    if type(UnitExists) ~= "function" then return nil; end
    local value = H.Call("UnitExists", unit);
    return value == true or value == 1;
end
function H.IsPlayerDead()
    local names={"UnitIsDeadOrGhost","UnitIsDead","UnitIsGhost"};
    for i=1,3 do local v=H.Call(names[i],"player"); if v==true or v==1 then return true; end end
    return false;
end
function H.ResetEncounters(reason)
    H.encounterWaiting=true; H.encounterStamp=H.Number(AZS_UNITS_UPDATED); H.encounterReason=reason;
    H.encounterStarted=H.Number(H.Call("GetTime"));
    if H.ClearBossVisuals then H.ClearBossVisuals(); end
end
function H.PlayerDied(explicit)
    if H.ResetTracking then H.ResetTracking(); end
    H.lifeDead=true; H.deathExplicit=explicit==true or H.deathExplicit;
    if explicit then H.deathObserved=false; end
    H.ResetEncounters("death");
end
function H.PlayerAlive()
    if H.ResetTracking then H.ResetTracking(); end
    H.lifeDead=false; H.deathExplicit=false; H.deathObserved=false; H.ResetEncounters("revive");
end
function H.EncounterUnitsUpdated()
    local stamp=H.Number(AZS_UNITS_UPDATED);
    if not H.lifeDead and not H.IsPlayerDead() and
        (not stamp or not H.encounterStarted or stamp>=H.encounterStarted) then H.encounterWaiting=false; end
    H.encounterStamp=H.Number(AZS_UNITS_UPDATED);
end
function H.EncountersAllowed(s)
    if not s.active or s.playerDead or H.lifeDead then return false; end
    local stamp=H.Number(AZS_UNITS_UPDATED);
    if H.encounterWaiting and stamp and stamp~=H.encounterStamp and
        (not H.encounterStarted or stamp>=H.encounterStarted) then H.encounterWaiting=false; H.encounterStamp=stamp; end
    return not H.encounterWaiting;
end
local function NativeUnit(unit)
    local u = {};
    if H.Exists(unit) ~= true then return u; end
    u.name = H.Call("UnitName", unit);
    u.level = H.Number(H.Call("UnitLevel", unit));
    u.hp, u.hpm = H.Pair(H.Call("UnitHealth", unit), H.Call("UnitHealthMax", unit));
    u.power, u.powerMax = H.Pair(H.Call("UnitMana", unit), H.Call("UnitManaMax", unit));
    u.powerType = H.Call("UnitPowerType", unit);
    return u;
end
function H.Read()
    local s = { player = NativeUnit("player"), target = {}, spells = {}, bosses = {}, guardians = {} };
    s.phase = H.Call("AZS_GetPhase");
    s.active = s.phase == "playing" or s.phase == "paused" or s.phase == "choosing";
    s.hasAPI = type(AZS_GetPhase) == "function";
    s.level = H.Number(H.Call("UnitLevel", "player"));
    if s.phase == "ready" then
        s.xp, s.xpn = H.Pair(H.Call("UnitXP", "player"), H.Call("UnitXPMax", "player"));
    end
    if not s.hasAPI then
        s.target = NativeUnit("target");
        s.xp, s.xpn = H.Pair(H.Call("UnitXP", "player"), H.Call("UnitXPMax", "player"));
        s.level = H.Call("UnitLevel", "player");
        return s;
    end
    -- AZS tables can contain the previous run outside these three phases.
    if s.phase=="dead" then
        s.playerDead=true; if not H.lifeDead then H.PlayerDied(); end; H.deathObserved=true;
    elseif s.phase=="ready" and H.lifeDead then H.PlayerAlive(); end
    if not s.active then return s; end
    local r, z = H.Table(AZS_RUN), H.Table(AZS_ZONE);
    s.player.name = H.Text(z.hero, H.Text(s.player.name));
    local hp, hpm = H.Pair(r.hp, r.hpm);
    if hp then s.player.hp, s.player.hpm = hp, hpm; end
    s.playerDead=H.IsPlayerDead() or (s.player.hp~=nil and s.player.hp<=0);
    if s.playerDead then
        if not H.lifeDead then H.PlayerDied(); end; H.deathObserved=true;
    elseif H.lifeDead and (not H.deathExplicit or H.deathObserved) then H.PlayerAlive(); end
    s.playerDead=s.playerDead or H.lifeDead;
    s.shield = H.Number(r.sh);
    s.xp, s.xpn = H.Pair(r.xp, r.xpn);
    s.level = H.Number(r.lvl);
    s.time = H.Call("AZS_GetRunTime");
    s.zone = H.Text(z.zname, "AZEROTH SURVIVORS");
    s.kills, s.gold, s.enemies = H.Number(r.kills), H.Number(r.gold), H.Number(r.en);
    s.elites, s.lives = H.Number(r.el), H.Number(r.lives);
    s.cache = H.Number(r.chest);
    local lines, total, dps = H.Call("AZS_GetMeter");
    s.damage, s.dps = H.Number(total) or H.Number(r.dealt), H.Number(dps);
    s.meter = H.Table(lines);
    s.stored = H.Number(H.Call("AZS_GetStoredLevels")) or H.Number(r.sl);
    s.spells = H.Table(AZS_SPELLS);
    if H.EncountersAllowed(s) then
        s.bosses = H.Table(H.Call("AZS_GetBosses"));
        s.guardians = H.Table(H.Call("AZS_GetGuardians"));
    end
    local upcoming = H.Table(H.Call("AZS_GetUpcomingBosses"));
    local nextBoss = H.Table(upcoming[1]);
    s.nextName, s.nextLeft = H.Text(nextBoss.name, H.Text(r.nbn, "Next boss")), H.Number(nextBoss.left) or H.Number(r.nb);
    local t = H.Table(AZS_TARGET);
    if s.playerDead then return s; end
    local exists = H.Exists("target");
    local liveName = exists and H.Call("UnitName", "target") or nil;
    local valid = {normal=true, elite=true, boss=true, final=true, guardian=true, player=true, other=true};
    if exists == false then return s; end
    if valid[t.kind] and type(t.name) == "string" and t.name ~= "" and (not liveName or liveName == t.name) then
        s.target.name, s.target.kind = t.name, t.kind;
        s.target.hp, s.target.hpm = H.Pair(t.hp, t.hpm);
    elseif exists == true then
        s.target = NativeUnit("target");
        s.target.kind = H.Call("AZS_UnitKind", "target");
    end
    if exists==true then s.target.level=H.Number(H.Call("UnitLevel","target")); end
    return s;
end

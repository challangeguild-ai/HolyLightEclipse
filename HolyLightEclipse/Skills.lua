local H = HLE;
local samples, nativeSamples = {}, {};
local lastRun;
-- Display metadata only. These keys never grant membership or cooldowns.
-- Paths cross-checked against KeijinUI's published ability metadata.
local knownIcons={consecration="Spell_Holy_InnerFire",exorcism="Spell_Holy_Excorcism_02",
    hammer_of_wrath="Ability_ThunderClap",holy_wrath="Spell_Holy_Excorcism",
    holy_shield="Spell_Holy_BlessingOfProtection",redemption="Spell_Holy_Resurrection",
    perception="Spell_Nature_Sleep",holy_shock="Spell_Holy_SearingLight",
    judgement="Spell_Holy_RighteousFury",hammer_of_justice="Spell_Holy_SealOfMight",
    holy_light="Spell_Holy_HolyBolt",divine_shield="Spell_Holy_DivineIntervention"};
function H.IconPath(value)
    if type(value)~="string" or value=="" then return nil; end
    value=string.gsub(value,"/","\\");
    if string.find(string.lower(value),"inv_misc_questionmark",1,true) then return nil; end
    if not string.find(value,"\\",1,true) then value="Interface\\Icons\\"..value; end
    return value;
end
function H.ResetSkills() samples, nativeSamples, lastRun = {}, {}, nil; end
local function Name(key)
    return string.gsub(H.Text(key, "Skill"), "_", " ");
end
local book;
local function Normalize(text)
    return string.gsub(string.lower(H.Text(text,"")),"[%s_%-]","");
end
function H.ResetSpellBook() book=nil; end
local function BookEntry(key)
    if not book then
        book={};
        if type(GetSpellName)=="function" and type(GetSpellTexture)=="function" then
            local tabs=H.Number(H.Call("GetNumSpellTabs"));
            if tabs and type(GetSpellTabInfo)=="function" then
                for tab=1,math.min(12,tabs) do
                    local ok,title,texture,offset,count=pcall(GetSpellTabInfo,tab);
                    if ok and H.Number(offset) and H.Number(count) then
                        for index=offset+1,math.min(offset+count,600) do
                            local name=H.Call("GetSpellName",index,BOOKTYPE_SPELL or "spell");
                            local icon=H.Call("GetSpellTexture",index,BOOKTYPE_SPELL or "spell");
                            if type(name)=="string" and type(icon)=="string" then book[Normalize(name)]={name=name,icon=icon,book=index}; end
                        end
                    end
                end
            end
        end
    end
    return book[Normalize(key)];
end
-- Fallback countdown advances on the RUN clock, never the wall clock.
-- Every new AZSSPELLS update re-anchors to server values, including resets.
local function LegacySkills(s)
    -- The native bar is already populated before movement starts the run.
    -- Do not suppress its icons in ready phase, and never read stale AZS tables there.
    if not s.active and s.phase ~= "ready" and s.hasAPI ~= false then H.ResetSkills(); return {}; end
    local run = H.Number(s.time);
    if run and lastRun and run < lastRun then H.ResetSkills(); end
    lastRun = run;
    local result, native = {}, false;
    local now = H.Number(H.Call("GetTime"));
    for slot = 1, 7 do
        local nativeSlot = slot == 7 and 12 or slot;
        local buttonName = "ActionButton" .. nativeSlot;
        local button = getglobal(buttonName);
        local actionSlot = nativeSlot;
        if button and type(ActionButton_GetPagedID) == "function" then
            actionSlot = H.Number(H.Call("ActionButton_GetPagedID", button)) or nativeSlot;
        end
        local icon;
        if not s.skipNative then icon = H.Call("GetActionTexture", actionSlot); end
        if not s.skipNative and not s.blockWidgetCache and (type(icon) ~= "string" or icon == "") then
            local texture = getglobal(buttonName .. "Icon");
            if texture and type(texture.GetTexture) == "function" then
                local ok, path = pcall(texture.GetTexture, texture);
                if ok and type(path) == "string" then icon = path; end
            end
        end
        if type(icon) == "string" and icon ~= "" then
            native = true;
            local start, duration, enabled = H.Call("GetActionCooldown", actionSlot);
            start, duration = H.Number(start), H.Number(duration);
            local old = nativeSamples[slot];
            local cd;
            if start and duration and now then
                if enabled == 0 or start <= 0 or duration <= 0 then cd = 0;
                elseif s.phase ~= "playing" and old and old.start == start and old.duration == duration and old.icon == icon then cd = old.cd;
                else cd = math.max(0, math.min(duration, duration - (now - start))); end
            end
            nativeSamples[slot] = {start=start, duration=duration, cd=cd, icon=icon};
            result[slot] = {icon=icon, name=H.Text(H.Call("GetActionText", actionSlot), ""), cd=cd, cdmax=duration, slot=actionSlot, buttonName=buttonName, source="native"};
        end
    end
    -- Native slots provide the actual icon/order/CD, avoiding spellbook ID guesses.
    if native then return result; end
    if not s.active then H.ResetSkills(); return result; end
    local stamp = H.Number(AZS_SPELLS_UPDATED);
    for i = 1, math.min(H.maxSkills, table.getn(s.spells)) do
        local spell = H.Table(s.spells[i]);
        local cd, maximum = H.Number(spell.cd), H.Number(spell.cdmax);
        local key = H.Text(spell.key, tostring(i));
        local old = samples[key];
        if not old or old.stamp ~= stamp or old.cd ~= cd or old.rank ~= spell.rank or old.maximum ~= maximum or old.serial ~= H.spellSerial then
            old = {stamp=stamp, cd=cd, rank=spell.rank, maximum=maximum, time=run, serial=H.spellSerial};
            samples[key] = old;
        end
        if cd and run and old.time then cd = math.max(0, cd - math.max(0, run - old.time)); end
        local entry=BookEntry(spell.key);
        result[i] = {name=entry and entry.name or Name(spell.key), icon=H.IconPath(entry and entry.icon or knownIcons[spell.key]),
            book=entry and entry.book, cd=cd, cdmax=maximum, rank=spell.rank, source="AZS"};
    end
    return result;
end

-- AZS decides membership. Native textures never decide which spells are learned.
local snapshot, observedStamp;
local pendingCapture;
local metadata,metadataRun,metadataAt,metadataTick;
local phase, runTime, zone;
local worldPending = true;
local function ZoneKey()
    local z = H.Table(AZS_ZONE);
    return H.Text(z.zone, "") .. ":" .. H.Text(z.hero, "");
end
function H.StartSkillRun(reason, state)
    H.liveLoadout=nil;
    H.ResetSkills(); H.ResetSpellBook(); snapshot = nil; observedStamp = H.Number(AZS_SPELLS_UPDATED);
    pendingCapture=nil; metadata=nil; metadataRun=nil; metadataAt=nil; metadataTick=0;
    phase = state and state.phase or H.Call("AZS_GetPhase");
    runTime = state and H.Number(state.time) or nil; zone = ZoneKey();
    H.skillWaiting = true; H.skillReason = reason;
    if H.ClearSkillVisuals then H.ClearSkillVisuals(); end
end
local function SyncRun(s)
    local key = ZoneKey(); local t = H.Number(H.Table(AZS_RUN).t) or H.Number(s.time);
    if not phase and s.phase == "ready" then H.StartSkillRun("initial-ready", s);
    elseif phase and s.phase == "ready" and phase ~= "ready" then H.StartSkillRun("ready", s);
    elseif zone and key ~= zone then H.StartSkillRun("zone", s);
    elseif t and runTime and t < runTime-3 and phase ~= "ready" then H.StartSkillRun("clock-reset", s); end
    phase, runTime, zone = s.phase, t, key;
end
local function Capture()
    -- AZSSPELLS can announce newly learned abilities without SPELLS_CHANGED.
    H.ResetSpellBook();
    local source = H.Table(AZS_SPELLS); snapshot = {};
    -- Native Lua 5.0 tables may retain an old table.getn size after direct writes.
    -- Read the bounded indexed feed, rather than trusting that cached size.
    for i = 1, 64 do
        local entry = H.Table(source[i]);
        if type(entry.key) == "string" and entry.key ~= "" then
            table.insert(snapshot, {key=entry.key, spell=entry.spell, rank=entry.rank, cd=entry.cd, cdmax=entry.cdmax});
        end
    end
    observedStamp = H.Number(AZS_SPELLS_UPDATED); H.skillWaiting = false;
end
function H.SpellsUpdated()
    local s = {phase=H.Call("AZS_GetPhase"), time=H.Call("AZS_GetRunTime")};
    SyncRun(s); H.spellSerial = (H.spellSerial or 0) + 1;
    if s.phase == "ready" or s.phase == "playing" or s.phase == "paused" or s.phase == "choosing" then pendingCapture=true; end
end
function H.LeaveSkillWorld()
    H.StartSkillRun("world-leave"); worldPending = true;
end
function H.EnterSkillWorld()
    if not worldPending then H.StartSkillRun("world-enter"); else H.ResetSkills(); end
    worldPending = false;
end
local function ContextMatches(context,s)
    if type(context)~="table" or type(context.phase)~="string" or not H.Number(context.asOfRunSeconds) then return false; end
    if s.phase=="ready" then if context.phase~="ready" then return false; end
    elseif context.phase~="playing" and context.phase~="paused" and context.phase~="choosing" then return false; end
    local clock=H.Number(H.Table(AZS_RUN).t) or H.Number(s.time);
    return not clock or math.abs(clock-context.asOfRunSeconds)<=3;
end
local function CurrentLoadout(s,fallback,candidates)
    if type(AZS_GetMeterContext)~="function" or type(AZS_GetMeterLoadout)~="function" then return nil; end
    local ok,context=pcall(AZS_GetMeterContext);
    if not ok or type(context)~="table" or type(context.runId)~="string" or not ContextMatches(context,s) then return nil; end
    if metadataRun~=context.runId then metadata=nil; metadataAt=nil; metadataRun=context.runId; end
    local now=H.Number(H.Call("GetTime")); metadataTick=(metadataTick or 0)+1;
    if not metadata or (now and (not metadataAt or now-metadataAt>=0.2)) or (not now and math.mod(metadataTick,4)==0) then
        local success,loadout=pcall(AZS_GetMeterLoadout,{apiVersion=1,runId=context.runId});
        if success and type(loadout)=="table" and loadout.complete==true and
            type(loadout.context)=="table" and loadout.context.runId==context.runId and ContextMatches(loadout.context,s) and type(loadout.abilities)=="table" then
            metadata=loadout; metadataAt=now;
        elseif not metadata then return nil; end
    end
    if not metadata then return nil; end
    local byKey={}; for i=1,table.getn(fallback) do if fallback[i] then byKey[fallback[i].key or (snapshot and snapshot[i] and snapshot[i].key)]=fallback[i]; end end
    local result,seen={},{}; local sources=H.Table(metadata.sources);
    for i=1,64 do
        local ability=metadata.abilities[i];
        if type(ability)=="table" and (ability.learned==true or ability.selected==true) and not seen[ability.sourceKey] then
            local descriptor=H.Table(sources[ability.sourceKey]);
            local key=H.Text(descriptor.abilityKey,ability.sourceKey);
            if type(ability.sourceKey)=="string" then
                seen[ability.sourceKey]=true;
                local timing=byKey[key] or {}; local icon=H.Table(descriptor.icon);
                local slot=H.Number(ability.slotId); local native;
                if slot and slot>=1 and slot<=6 then native=candidates[slot]; elseif slot==12 then native=candidates[7]; end
                local path=icon.status=="ready" and H.IconPath(icon.path) or nil;
                local bookEntry=BookEntry(key);
                path=path or (bookEntry and H.IconPath(bookEntry.icon)) or H.IconPath(knownIcons[key]);
                local entry={key=key,name=H.Text(descriptor.name,Name(key)),rank=ability.rank,passive=ability.passive==true,
                    icon=path,cd=timing.cd,cdmax=timing.cdmax,source="loadout"};
                if native and (not path or string.lower(native.icon)==string.lower(path)) then
                    entry.icon=native.icon; entry.cd=native.cd; entry.cdmax=native.cdmax;
                    entry.slot=native.slot; entry.buttonName=native.buttonName;
                end
                table.insert(result,entry);
            end
        end
    end
    H.liveLoadout=metadata;
    return result;
end
function H.Skills(s)
    H.liveLoadout=nil;
    if s.hasAPI ~= true then return LegacySkills(s); end
    SyncRun(s);
    H.ownsSkillBar = s.active or s.phase == "ready";
    if not H.ownsSkillBar then return {}; end
    local stamp = H.Number(AZS_SPELLS_UPDATED);
    if pendingCapture or (stamp and stamp ~= observedStamp) then Capture(); pendingCapture=nil; end
    local candidates = LegacySkills({active=true, phase=s.phase, time=s.time, spells={}, blockWidgetCache=true});
    local fallback = LegacySkills({active=true, phase=s.phase, time=s.time, spells=snapshot or {}, skipNative=true});
    local loadout=CurrentLoadout(s,fallback,candidates);
    if loadout then H.skillWaiting=false; H.skillSource="loadout"; return loadout; end
    if not snapshot then H.skillWaiting = true; return {}; end
    H.skillSource="AZSSPELLS";
    local result = {}; local count = math.min(H.maxSkills, table.getn(snapshot));
    for i = 1, count do
        -- The API list puts the racial last; the native game keeps it in slot 12.
        local native;
        if i==table.getn(snapshot) and count>1 and candidates[7] then native=candidates[7];
        elseif i<=6 then native=candidates[i]; end
        local alternative=fallback[i];
        if native and alternative and alternative.icon and
            string.lower(string.gsub(native.icon,"/","\\"))~=string.lower(string.gsub(alternative.icon,"/","\\")) then native=nil; end
        local entry = native or alternative;
        if entry then entry.key = snapshot[i].key; entry.name = alternative and alternative.name or Name(snapshot[i].key); result[i] = entry; end
    end
    return result;
end

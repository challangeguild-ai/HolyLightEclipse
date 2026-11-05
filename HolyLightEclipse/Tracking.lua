local H=HLE;
local MEDIA="Interface\\AddOns\\HolyLightEclipse\\Media\\";
local feeds={};
local lastPhase,lastTime,lastZone;
local function Read(name)
    local fn=getglobal(name); if type(fn)~="function" then return nil; end
    local ok,a,b,c=pcall(fn);
    if ok then return a,b,c; end
    H.errors[name]=tostring(a); return nil;
end
-- Source/party views share a single meter and use the official v1 ledger when ready.
-- The vanilla name-based meters remain usable on older Survivors clients.
local meterCache;
function H.ResetMeterCache() meterCache=nil; end
local function LegacyMeter(s,scope,mode)
    local result={scope=scope,mode=mode,lines={},healing=mode=="heal",source="legacy"};
    if scope=="party" then
        if mode~="run" then
            result.unavailable=true; result.reason="Detailed party meter unavailable";
            return result;
        end
        local lines,total,rate=Read("AZS_GetPartyMeter");
        if type(lines)~="table" then
            result.unavailable=true; result.reason="Party meter API unavailable";
        else
            result.lines=lines; result.total=H.Number(total); result.rate=H.Number(rate);
            if table.getn(lines)==0 and (H.Number(H.Call("GetNumPartyMembers")) or 0)<1 then
                result.unavailable=true; result.reason="No co-op party";
            end
        end
    elseif mode=="run" then
        result.lines=H.Table(s.meter); result.total=H.Number(s.damage); result.rate=H.Number(s.dps);
    else
        local getter=mode=="heal" and "AZS_GetHealing" or "AZS_GetBossMeter";
        local lines,total,rate=Read(getter);
        result.lines=H.Table(lines); result.total=H.Number(total); result.rate=H.Number(rate);
        if type(lines)~="table" then result.unavailable=true; result.reason="Meter API unavailable"; end
    end
    return result;
end
local function SnapshotMeter(scope,mode)
    if type(AZS_GetMeterCapabilities)~="function" or type(AZS_GetMeterContext)~="function" or
        type(AZS_GetMeterSnapshot)~="function" then return nil; end
    local caps=H.Table(H.Call("AZS_GetMeterCapabilities"));
    if caps.apiVersion~=1 then return nil; end
    local context,ctxError=H.Call("AZS_GetMeterContext");
    if type(context)~="table" or type(context.runId)~="string" or context.runId=="" then
        return nil, H.Table(ctxError).code or "NOT_READY";
    end
    local query={apiVersion=1,runId=context.runId,
        metric=mode=="heal" and "healing" or "damage",
        scope=scope,period=mode=="boss" and "encounter" or "run",
        groupBy=scope=="party" and "owner" or "source",windowSeconds=0};
    if mode=="heal" then query.healingPerspective="performed"; end
    local snapshot,err=H.Call("AZS_GetMeterSnapshot",query);
    if type(snapshot)~="table" then return nil,H.Table(err).code or "NOT_READY"; end
    if snapshot.apiVersion~=1 or snapshot.complete~=true or
        (snapshot.status~="ready" and snapshot.status~="ready_empty") or
        type(snapshot.context)~="table" or snapshot.context.runId~=context.runId or
        type(snapshot.rows)~="table" or type(snapshot.totals)~="table" then
        return nil,"NOT_READY";
    end
    local lines={};
    local actors=H.Table(snapshot.actors); local sources=H.Table(snapshot.sources);
    for i=1,math.min(128,table.getn(snapshot.rows)) do
        local row=H.Table(snapshot.rows[i]);
        local amount=H.Number(row.displayAmount);
        if amount and amount>=0 then
            local descriptor=scope=="party" and H.Table(actors[row.ownerId]) or H.Table(sources[row.sourceKey]);
            local name=H.Text(descriptor.name,scope=="party" and ("Player "..i) or ("Source "..i));
            local rate=H.Number(H.Table(row.displayRate).value);
            table.insert(lines,{name=name,dmg=amount,dps=rate,share=H.Number(row.share)});
        end
    end
    local totals=H.Table(snapshot.totals);
    return {scope=scope,mode=mode,source="snapshot",lines=lines,
        total=H.Number(totals.displayAmount),rate=H.Number(H.Table(totals.displayRate).value),
        healing=mode=="heal"};
end
function H.ReadMeter(s)
    local mode=HLE_DB.meterMode or "run";
    local scope=HLE_DB.meterScope=="party" and "party" or "self";
    local title=scope=="party" and (mode=="heal" and "PARTY HEALING" or (mode=="boss" and "PARTY BOSS" or "PARTY DAMAGE"))
        or (mode=="heal" and "HEALING" or (mode=="boss" and "BOSS" or "DAMAGE"));
    if not s.active then H.ResetMeterCache(); return {scope=scope,mode=mode,title=title,lines={},healing=mode=="heal"}; end
    local now=H.Number(H.Call("GetTime"));
    local epoch=H.Table(AZS_ZONE); local fingerprint=scope..":"..mode..":"..tostring(epoch.run)..":"..tostring(epoch.zone);
    if meterCache and meterCache.key==fingerprint and now and meterCache.at and now>=meterCache.at and
        now-meterCache.at<0.25 and (not H.Number(s.time) or not meterCache.runTime or s.time>=meterCache.runTime-1) then
        return meterCache.result;
    end
    local result,err=SnapshotMeter(scope,mode);
    if not result then
        result=LegacyMeter(s,scope,mode);
        if scope=="party" and mode~="run" then
            result.reason=(err=="NO_PARTY" and "No co-op party") or
                (err=="NO_ENCOUNTER" and "No boss fight yet") or
                (err=="NOT_READY" and "Waiting for party data") or result.reason;
        elseif scope=="party" and mode=="run" and err=="NO_PARTY" then
            result.unavailable=true; result.reason="No co-op party"; result.lines={}; result.total=nil; result.rate=nil;
        end
    end
    result.title=title;
    meterCache={key=fingerprint,at=now,runTime=H.Number(s.time),result=result};
    return result;
end
local function HideTooltip(card)
    if H.effectHover==card and GameTooltip then GameTooltip:Hide(); H.effectHover=nil; end
end
local function Clear(cards)
    if not cards then return; end
    for i=1,table.getn(cards) do cards[i]:Hide(); cards[i].info=nil; HideTooltip(cards[i]); end
end
function H.ResetTracking()
    feeds={};
    local prefixes={"PETS","TIMERS"};
    for i=1,2 do local key=prefixes[i]; feeds[key]={stamp=H.Number(getglobal("AZS_"..key.."_UPDATED")),fresh=false}; end
    Clear(H.effectCards); Clear(H.targetAuraCards);
    if H.bossAuraCards then for i=1,3 do Clear(H.bossAuraCards[i]); end end
end
function H.ClearBossTracking()
    if H.bossAuraCards then for i=1,3 do Clear(H.bossAuraCards[i]); end end
end
function H.TrackingEvent(prefix)
    if prefix=="AZSPETS" then feeds.PETS=feeds.PETS or {}; feeds.PETS.pending=true;
    elseif prefix=="AZSTIMERS" then feeds.TIMERS=feeds.TIMERS or {}; feeds.TIMERS.pending=true; end
end
local function Fresh(key)
    local f=feeds[key] or {}; feeds[key]=f;
    local stamp=H.Number(getglobal("AZS_"..key.."_UPDATED"));
    if f.pending or (stamp and stamp~=f.stamp) then f.fresh=true; f.pending=nil; f.stamp=stamp; end
    return f.fresh;
end
local function Card(parent,Text,Texture,size)
    local c=CreateFrame("Frame",nil,parent); c:SetWidth(size); c:SetHeight(size); c:EnableMouse(true);
    c.icon=Texture(c,MEDIA.."White.tga",3,-3,size-6,size-6,"ARTWORK");
    Texture(c,MEDIA.."Skill04.tga",0,0,size,size,"OVERLAY");
    c.time=Text(c,10,0,-size+15,size,{1,0.96,0.84}); c.time:SetJustifyH("CENTER");
    c.count=Text(c,9,size-18,-2,16,{1,0.85,0.4});
    c:SetScript("OnEnter",function()
        if this.info and GameTooltip and GameTooltip.SetText then
            H.effectHover=this; GameTooltip:SetOwner(this,"ANCHOR_TOP");
            local v=this.info; local detail=v.permanent and "Permanent" or (H.Number(v.remaining) and (H.Clock(v.remaining).." remaining") or "Timing unavailable");
            if v.unitIndex then
                local fn=v.harmful and GameTooltip.SetUnitDebuff or GameTooltip.SetUnitBuff;
                if type(fn)=="function" then fn(GameTooltip,"target",v.unitIndex); GameTooltip:Show(); return; end
            end
            if v.buffIndex and GameTooltip.SetPlayerBuff then GameTooltip:SetPlayerBuff(v.buffIndex); GameTooltip:Show(); return; end
            if v.kind=="summon" then detail="Next summon: "..(H.Number(v.remaining) and H.Clock(v.remaining) or "--"); end
            GameTooltip:SetText(H.Text(v.name).."\n"..detail); GameTooltip:Show();
        end
    end);
    c:SetScript("OnLeave",function() HideTooltip(this); end);
    c:Hide(); return c;
end
function H.BuildTracking(Text,Texture,Panel)
    H.targetAuraCards={};
    for i=1,24 do
        H.targetAuraCards[i]=Card(H.targetRoot,Text,Texture,30);
        H.targetAuraCards[i]:SetPoint("TOPLEFT",H.targetRoot,"TOPLEFT",14+math.mod(i-1,7)*32,38+math.floor((i-1)/7)*32);
    end
    H.bossAuraCards={};
    for i=1,3 do
        H.bossAuraCards[i]={};
        for j=1,12 do H.bossAuraCards[i][j]=Card(H.bossBars[i],Text,Texture,28); end
    end
    H.effects=CreateFrame("Frame","HLEEffects",H.playerRoot);
    H.effects:SetWidth(230); H.effects:SetHeight(32);
    H.effects:SetPoint("BOTTOMLEFT",H.playerRoot,"TOPLEFT",82,8);
    H.effectsTitle=Text(H.effects,10,0,0,276,{0.95,0.74,0.35}); H.effectsTitle:SetText("BUFFS / SUMMONS"); H.effectsTitle:Hide();
    H.effectCards={};
    for i=1,24 do H.effectCards[i]=Card(H.effects,Text,Texture,30); end
    H.meterScopeTabs={};
    for i=1,2 do
        local scope=i==1 and "self" or "party";
        local tab=CreateFrame("Frame",nil,H.meter); tab:SetWidth(75); tab:SetHeight(18); tab:EnableMouse(true);
        tab.label=Text(tab,10,0,0,75,{0.95,0.74,0.35}); tab.label:SetJustifyH("CENTER");
        tab.label:SetText(scope=="self" and "SELF" or "PARTY"); tab.scope=scope;
        tab:SetScript("OnMouseUp",function()
            if arg1~="LeftButton" then return; end
            HLE_DB.meterScope=this.scope; H.meterPage=0; H.ResetMeterCache(); H.Render(H.Read());
        end);
        H.meterScopeTabs[i]=tab;
    end
    H.meterTabs={};
    local modes={"run","boss","heal"}; local labels={"RUN","BOSS","HEAL"};
    for i=1,3 do
        local tab=CreateFrame("Frame",nil,H.meter); tab:SetWidth(64); tab:SetHeight(17);
        tab:SetPoint("TOPLEFT",H.meter,"TOPLEFT",13+(i-1)*67,-135); tab:EnableMouse(true);
        tab.label=Text(tab,9,0,0,64,{0.95,0.74,0.35}); tab.label:SetText(labels[i]); tab.mode=modes[i];
        tab:SetScript("OnMouseUp",function() if arg1=="LeftButton" then
            HLE_DB.meterMode=this.mode; H.meterPage=0; H.ResetMeterCache(); H.Render(H.Read()); end end);
        H.meterTabs[i]=tab;
    end
    H.ResetTracking();
end
local function Paint(c,v)
    local path=H.IconPath(v.icon);
    if not path then c:Hide(); c.info=nil; HideTooltip(c); return false; end
    c.info=v; c.icon:SetTexture(path); c.icon:SetVertexColor(1,1,1,1);
    local left=H.Number(v.remaining);
    c.time:SetText(v.permanent and "" or (left and (left>0 and H.Clock(left) or "READY") or "?"));
    local count=H.Number(v.stacks) or H.Number(v.count);
    c.count:SetText(count and count>1 and H.Short(count) or ""); c:Show(); return true;
end
function H.RenderTargetAuras(s)
    local list={};
    if s.active and not s.playerDead and not H.lifeDead and H.Exists("target")==true then
        local names={"UnitBuff","UnitDebuff"};
        for kind=1,2 do
            local fn=getglobal(names[kind]);
            if type(fn)=="function" then
                for i=1,16 do
                    local ok,path,count=pcall(fn,"target",i);
                    if ok and H.IconPath(path) then table.insert(list,{icon=path,stacks=count,name=kind==1 and "Buff" or "Debuff",unitIndex=i,harmful=kind==2}); end
                end
            end
        end
    end
    for i=1,24 do
        local c=H.targetAuraCards[i];
        if list[i] then Paint(c,list[i]); c.time:SetText("");
        else c:Hide(); c.info=nil; HideTooltip(c); end
    end
end
function H.RenderBossAuras(index,b,s)
    local cards=H.bossAuraCards[index]; local list={};
    if b and s.active and not s.playerDead and not H.lifeDead and b.id~=nil and type(AZS_GetDebuffs)=="function" then
        local ok,data=pcall(AZS_GetDebuffs,b.id); if ok then list=H.Table(data); else H.errors.Debuffs=tostring(data); end
    end
    local shown=0;
    for i=1,12 do
        local v=list[i];
        if type(v)=="table" and (v.permanent==true or not H.Number(v.remaining) or v.remaining>0) and Paint(cards[i],v) then
            cards[i]:ClearAllPoints(); cards[i]:SetPoint("TOPLEFT",H.bossBars[index],"TOPLEFT",shown*31,-20); shown=shown+1;
        else cards[i]:Hide(); cards[i].info=nil; HideTooltip(cards[i]); end
    end
    return shown>0 and 31 or 0;
end
function H.UpdateTracking(s)
    local zone=H.Text(H.Table(AZS_ZONE).zone,""); local time=H.Number(H.Table(AZS_RUN).t) or H.Number(s.time);
    if (s.phase=="ready" and lastPhase~="ready") or (lastZone and zone~=lastZone) or
        (time and lastTime and time<lastTime-3) then H.ResetTracking(); end
    lastPhase,lastTime,lastZone=s.phase,time,zone;
    for i=1,2 do
        local tab=H.meterScopeTabs[i];
        if tab.scope==(HLE_DB.meterScope or "self") then tab.label:SetTextColor(1,0.94,0.7);
        else tab.label:SetTextColor(0.55,0.45,0.65); end
    end
    for i=1,3 do
        local tab=H.meterTabs[i];
        if tab.mode==(HLE_DB.meterMode or "run") then tab.label:SetTextColor(1,0.94,0.7); else tab.label:SetTextColor(0.55,0.45,0.65); end
    end
    if not HLE_DB.enabled or HLE_DB.showEffects==false or not s.active or s.playerDead or H.lifeDead or H.suspended then
        Clear(H.effectCards); H.effects:Hide(); return;
    end
    local list={};
    -- Buff timing and textures come from the native buff index, never a spell ID treated as a book slot.
    if type(GetPlayerBuff)=="function" and type(GetPlayerBuffTexture)=="function" then
        for filter=1,2 do
        for i=0,31 do
            local ok,index=pcall(GetPlayerBuff,i,filter==1 and "HELPFUL" or "HARMFUL");
            if ok and H.Number(index) and index>=0 then
                local texture=H.Call("GetPlayerBuffTexture",index);
                local left=H.Number(H.Call("GetPlayerBuffTimeLeft",index));
                if H.IconPath(texture) then table.insert(list,{icon=texture,name=filter==1 and "Buff" or "Debuff",buffIndex=index,remaining=left,stacks=H.Call("GetPlayerBuffApplications",index)}); end
            end
        end
        end
    end
    local keys={"TIMERS","PETS"}; local getters={"AZS_GetTimers","AZS_GetSummons"};
    for kind=1,2 do
        if Fresh(keys[kind]) then
            local data=H.Table(Read(getters[kind]));
            for i=1,64 do
                local v=data[i];
                if type(v)=="table" and H.IconPath(v.icon) and
                    (v.permanent==true or not H.Number(v.remaining) or v.remaining>=0) then
                    table.insert(list,{name=v.name,icon=v.icon,remaining=v.remaining,permanent=v.permanent,
                        kind=kind==1 and v.kind or "lifetime",count=v.count});
                end
            end
        end
    end
    local count=math.min(24,table.getn(list));
    for i=1,24 do
        local c=H.effectCards[i];
        if i<=count then
            Paint(c,list[i]); c:ClearAllPoints(); c:SetPoint("BOTTOMLEFT",H.effects,"BOTTOMLEFT",math.mod(i-1,7)*32,math.floor((i-1)/7)*32);
        else c:Hide(); c.info=nil; HideTooltip(c); end
    end
    H.effects:SetHeight(math.max(32,math.ceil(count/7)*32));
    if count>0 or H.unlocked then H.effects:Show(); else H.effects:Hide(); end
end

-- Optional native event renderer. No combat-log guessing, health-delta healing or name matching.
local H=HLE;
local cursor,registered,ownsDamage,priorDamage,lastState;
local labels={};
local healTotal,healTime,healRun,healZone,healBorn;
local function ClearLabels()
    for i=1,table.getn(labels) do labels[i].holder:Hide(); labels[i].born=nil; end
end
local function RestoreDamage()
    if ownsDamage then
        if H.Call("GetCVar","CombatDamage")=="0" and priorDamage~=nil then H.Call("SetCVar","CombatDamage",priorDamage); end
        ownsDamage=false; priorDamage=nil; HLE_DB.damageCvarBackup=nil;
    end
end
function H.StopCombatText()
    if registered then H.Call("AZS_UnregisterCombatTextFrameHandler",H.CombatTextFrame); registered=false; end
    RestoreDamage();
    if HLE_DB.damageCvarBackup~=nil then
        if H.Call("GetCVar","CombatDamage")=="0" then H.Call("SetCVar","CombatDamage",HLE_DB.damageCvarBackup); end
        HLE_DB.damageCvarBackup=nil;
    end
    ClearLabels(); cursor=nil; healTotal,healTime,healRun,healZone,healBorn=nil,nil,nil,nil,nil;
    if H.healText then H.healText:Hide(); end
end
local function Font(text,size)
    local ok,result=pcall(text.SetFont,text,"Fonts\\ARIALN.TTF",size,"OUTLINE");
    if not ok or result==false then text:SetFont("Fonts\\FRIZQT__.TTF",size,"OUTLINE"); end
end
local function Add(event,now)
    local born=H.Number(event.presentedAt); local amount=H.Number(event.amount);
    if event.kind~="damage" or not amount or amount<=0 or type(event.anchorId)~="string" or not born or now-born>1.1 or born>now+0.1 then return; end
    local slot;
    for i=1,128 do
        if not labels[i] then
            local holder=CreateFrame("Frame",nil,WorldFrame); holder:SetWidth(130); holder:SetHeight(36); holder:EnableMouse(false);
            local text=holder:CreateFontString(nil,"OVERLAY"); text:SetPoint("CENTER",holder,"CENTER",0,0); text:SetWidth(130); text:SetHeight(36);
            text:SetJustifyH("CENTER"); labels[i]={holder=holder,text=text};
        end
        if not labels[i].born or now-labels[i].born>1.1 then slot=labels[i]; break; end
    end
    if not slot then return; end
    slot.anchor=event.anchorId; slot.born=born; slot.id=event.eventId;
    Font(slot.text,event.critical and 22 or 16); slot.text:SetText(H.Short(amount)..(event.critical and "!" or ""));
    slot.text:SetTextColor(1,event.critical and 0.72 or 0.9,0.30);
    slot.lane=math.mod(table.getn(labels),5)-2; slot.holder:Hide();
end
local function DrawFrame()
    if not registered or not ownsDamage or not lastState or lastState.phase~="playing" or H.suspended or not HLE_DB.enabled then ClearLabels(); return; end
    if H.Call("GetCVar","CombatDamage")~="0" then HLE_DB.customDamage=false; H.StopCombatText(); return; end
    local batch,err=H.Call("AZS_GetCombatTextEvents",cursor,256);
    if not batch and type(err)=="table" and err.code=="STREAM_CHANGED" then ClearLabels(); cursor=nil; batch=H.Call("AZS_GetCombatTextEvents"); end
    if type(batch)~="table" then H.StopCombatText(); return; end
    cursor=batch.cursor;
    local now=H.Number(batch.clockSeconds); if not now then ClearLabels(); return; end
    local events=H.Table(batch.events);
    for i=1,math.min(256,table.getn(events)) do Add(H.Table(events[i]),now); end
    local ids,active={},{};
    for i=1,table.getn(labels) do local v=labels[i];
        if v.born and now-v.born<=1.1 then table.insert(ids,v.anchor); table.insert(active,v);
        else v.holder:Hide(); v.born=nil; end
    end
    if table.getn(ids)==0 then return; end
    local projection=H.Table(H.Call("AZS_ProjectCombatTextAnchors",ids,"follow")); local entries=H.Table(projection.entries);
    for i=1,table.getn(active) do local v=active[i]; local point=H.Table(entries[i]);
        if point.anchorId==v.anchor and point.state=="onScreen" and H.Number(point.x) and H.Number(point.y) then
            local age=now-v.born; v.holder:ClearAllPoints();
            v.holder:SetPoint("CENTER",WorldFrame,"BOTTOMLEFT",point.x+v.lane*13,point.y+22+age*32);
            v.holder:SetAlpha(math.max(0,math.min(1,(1.1-age)*3))); v.holder:Show();
        else v.holder:Hide(); end
    end
end
function H.CombatTextFrame()
    local ok,err=pcall(DrawFrame);
    if not ok then H.errors.CombatText=tostring(err); HLE_DB.customDamage=false; H.StopCombatText(); end
end
function H.UpdateCombatText(s)
    lastState=s;
    if not HLE_DB.enabled or H.suspended or not s.active or s.playerDead or H.lifeDead then H.StopCombatText(); return; end
    local capabilities=H.Table(H.Call("AZS_GetCombatTextCapabilities"));
    local supported=capabilities.apiVersion==1 and capabilities.frameHandler==true and WorldFrame and
        type(AZS_RegisterCombatTextFrameHandler)=="function" and type(AZS_UnregisterCombatTextFrameHandler)=="function" and
        type(AZS_GetCombatTextEvents)=="function" and type(AZS_ProjectCombatTextAnchors)=="function" and type(SetCVar)=="function";
    if HLE_DB.customDamage and supported then
        if not registered then
            local batch=H.Call("AZS_GetCombatTextEvents");
            if type(batch)=="table" and batch.cursor then
                cursor=batch.cursor;
                local ok=pcall(AZS_RegisterCombatTextFrameHandler,H.CombatTextFrame);
                if ok then
                    local original=H.Call("GetCVar","CombatDamage");
                    if type(original)=="string" then
                        priorDamage=HLE_DB.damageCvarBackup or original; HLE_DB.damageCvarBackup=priorDamage;
                        H.Call("SetCVar","CombatDamage","0"); ownsDamage=H.Call("GetCVar","CombatDamage")=="0";
                    end
                    registered=true;
                    if not ownsDamage then H.StopCombatText(); end
                end
            end
        end
    elseif registered or ownsDamage then
        H.StopCombatText();
    end
    H.combatTextAvailable=supported and true or false;
    if not supported and HLE_DB.damageCvarBackup~=nil then
        if H.Call("GetCVar","CombatDamage")=="0" then H.Call("SetCVar","CombatDamage",HLE_DB.damageCvarBackup); end
        HLE_DB.damageCvarBackup=nil;
    end
    if not HLE_DB.incomingHealing then if H.healText then H.healText:Hide(); end; healTotal=nil; return; end
    local _,total=H.Call("AZS_GetHealing"); total=H.Number(total);
    local now=H.Number(H.Call("GetTime")); local run=H.Number(s.time);
    local zone=H.Table(AZS_ZONE).zone;
    if total and now and run then
        local fresh=healTotal and healTime and run>=healTime and zone==healZone and H.Table(AZS_ZONE).run==healRun;
        if fresh and total>healTotal and s.phase=="playing" then
            if not H.healText then
                local f=CreateFrame("Frame",nil,UIParent); f:SetWidth(240); f:SetHeight(40); f:SetPoint("CENTER",UIParent,"CENTER",-120,-65); f:EnableMouse(false);
                f.text=f:CreateFontString(nil,"OVERLAY"); f.text:SetPoint("CENTER",f,"CENTER",0,0); f.text:SetWidth(240); f.text:SetHeight(36); Font(f.text,22);
                f.text:SetTextColor(0.35,1,0.45); H.healText=f;
            end
            H.healText.text:SetText("+"..H.Short(total-healTotal).." HEAL"); H.healText:Show(); healBorn=now;
        end
        healTotal,healTime,healZone,healRun=total,run,zone,H.Table(AZS_ZONE).run;
        if H.healText and (s.phase~="playing" or not healBorn or now-healBorn>1.3) then H.healText:Hide(); end
    else
        healTotal=nil; if H.healText then H.healText:Hide(); end
    end
end

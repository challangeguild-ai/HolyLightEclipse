local H=HLE;
local MEDIA="Interface\\AddOns\\HolyLightEclipse\\Media\\";
local waiting,stamp,pending=true,nil,false;
function H.ResetTimeline()
    if H.HideBossLoot then H.HideBossLoot(); end
    waiting=true; stamp=H.Number(AZS_SCHEDULE_UPDATED); pending=false;
    if H.timeline then H.timeline:Hide(); end
end
function H.TimelineUpdated() pending=true; end
function H.BuildTimeline(Text,Texture)
    H.timeline=CreateFrame("Frame","HLEBossTimeline",H.top); H.timeline:SetWidth(744); H.timeline:SetHeight(78);
    H.timeline:SetPoint("TOPLEFT",H.top,"TOPLEFT",0,-90); H.timelineNodes={};
    H.timelineLines={};
    for i=1,5 do
        local line=Texture(H.timeline,MEDIA.."White.tga",22,-13-(i-1)*78,700,1,"BACKGROUND");
        line:SetVertexColor(0.75,0.52,0.22,0.6); H.timelineLines[i]=line;
    end
    for i=1,30 do
        local node=CreateFrame("Frame",nil,H.timeline); node:SetWidth(120); node:SetHeight(76);
        node.icon=Texture(node,MEDIA.."TimelineSwords.tga",46,0,28,28,"ARTWORK");
        node.name=Text(node,11,2,-29,116,{1,0.94,0.82}); node.name:SetHeight(28); node.name:SetJustifyH("CENTER");
        node.time=Text(node,10,2,-58,116,{0.8,0.68,0.95}); node.time:SetJustifyH("CENTER");
        node:EnableMouse(true);
        node:SetScript("OnEnter",function()
            local ok,err=pcall(H.ShowBossLoot,this); if not ok then H.errors.BossLoot=tostring(err); H.HideBossLoot(); end
        end);
        node:SetScript("OnLeave",function() H.LeaveBossLoot(); end);
        H.timelineNodes[i]=node;
    end
    H.ResetTimeline();
end
function H.UpdateTimeline(s)
    if not HLE_DB.enabled or not HLE_DB.showTimeline or H.suspended or (not s.active and s.phase~="ready") then H.timeline:Hide(); return 0; end
    local current=H.Number(AZS_SCHEDULE_UPDATED);
    if pending or (current and current~=stamp) then waiting=false; stamp=current; pending=false; end
    -- On initial world entry the schedule may have arrived before the addon.
    -- Accept that publication when it belongs to the current zone's epoch.
    local zoneStamp=H.Number(AZS_ZONE_UPDATED);
    if waiting and current and zoneStamp and current>=zoneStamp then waiting=false; end
    local list={}; local source=H.Table(AZS_SCHEDULE);
    for i=1,64 do if not waiting then
        local v=source[i];
        if type(v)=="table" and type(v.name)=="string" and H.Number(v.at) and (v.state=="dead" or v.state=="due" or v.state=="up") then
            table.insert(list,{name=v.name,at=v.at,state=v.state,index=v.index or i});
        end
    end end
    local z=H.Table(AZS_ZONE); local length=H.Number(z.len); local key;
    if type(z.zone)=="string" and length and length>0 then key=z.zone..":"..length..":"..H.Text(z.zname,""); end
    HLE_DB.schedulePlans=H.Table(HLE_DB.schedulePlans);
    if table.getn(list)>0 and key and s.active then
        local plan={}; for i=1,table.getn(list) do local b=list[i]; plan[i]={index=b.index,name=b.name,at=b.at}; end
        HLE_DB.schedulePlans[key]=plan;
    elseif table.getn(list)==0 and key then
        local plan=H.Table(HLE_DB.schedulePlans[key]);
        for i=1,30 do local b=plan[i]; if type(b)=="table" and type(b.name)=="string" and H.Number(b.at) then table.insert(list,{index=b.index or i,name=b.name,at=b.at,state="due",planned=true}); end end
    end
    if s.phase=="ready" then for i=1,table.getn(list) do list[i].planned=true; list[i].state="due"; end end
    H.timelineSource=waiting and "planned/waiting" or "current";
    table.sort(list,function(a,b) if a.at==b.at then return tostring(a.index)<tostring(b.index); end; return a.at<b.at; end);
    local count=math.min(30,table.getn(list)); local nextIndex;
    for i=1,5 do
        local cols=math.min(6,math.max(0,count-(i-1)*6)); local line=H.timelineLines[i];
        if cols>1 then
            line:SetWidth((cols-1)*124); line:ClearAllPoints(); line:SetPoint("TOPLEFT",H.timeline,"TOPLEFT",(744-cols*124)/2+60,-13-(i-1)*78); line:Show();
        else line:Hide(); end
    end
    for i=1,count do if list[i].state=="due" then nextIndex=i; break; end end
    for i=1,30 do
        local node=H.timelineNodes[i]; local boss=list[i];
        if boss and i<=count then
            local row=math.floor((i-1)/6); local cols=math.min(6,count-row*6);
            node:ClearAllPoints(); node:SetPoint("TOPLEFT",H.timeline,"TOPLEFT",(744-cols*124)/2+math.mod(i-1,6)*124,-row*78);
            node.bossLootName=boss.name; node.name:SetText(boss.name); node.icon:SetTexture(MEDIA..(boss.state=="dead" and "TimelineSkull.tga" or "TimelineSwords.tga"));
            local now=H.Number(s.time) or H.Number(H.Call("AZS_GetRunTime")) or 0;
            local left=math.max(0,boss.at-now); local label;
            -- The pre-run publication may contain the client's default schedule.
            -- Keep the roster, but never advertise those times as this run's timings.
            if s.phase=="ready" then label="--:--";
            elseif boss.planned then label=now>=boss.at and "STATE ?" or ("PLAN "..H.Clock(math.ceil(left)));
            elseif boss.state=="dead" then label="DEFEATED";
            elseif boss.state=="up" then label="ACTIVE";
            else label=(i==nextIndex and "NEXT " or "IN ")..H.Clock(math.ceil(left)); end
            node.time:SetText(label);
            if boss.state=="dead" then node.icon:SetVertexColor(0.65,0.65,0.7,1); node.name:SetTextColor(0.65,0.62,0.7);
            elseif boss.state=="up" then node.icon:SetVertexColor(1,0.55,0.3,1); node.name:SetTextColor(1,0.65,0.32);
            elseif i==nextIndex then node.icon:SetVertexColor(1,0.85,0.55,1); node.name:SetTextColor(1,0.94,0.65);
            else node.icon:SetVertexColor(0.75,0.6,0.95,1); node.name:SetTextColor(0.8,0.7,0.9); end
            node:Show();
        else node.bossLootName=nil; node:Hide(); node.name:SetText(""); node.time:SetText(""); end
    end
    local height=math.ceil(count/6)*78; H.timeline:SetHeight(math.max(1,height));
    if count>0 then H.timeline:Show(); else H.timeline:Hide(); end
    return count>0 and height or 0;
end

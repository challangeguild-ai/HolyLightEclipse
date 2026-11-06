local H=HLE;
local WHITE="Interface\\AddOns\\HolyLightEclipse\\Media\\White.tga";
local cards,queue={},{};
local clock,serial,tick=0,0,0;
local deliveries={}; local fallbackUntil=0;
local intakeConfirmed=false;
local lastMarkLine,lastMarkAt=nil,nil;
local function Plain(text)
    text=string.gsub(text,"|c%x%x%x%x%x%x%x%x",""); return string.gsub(text,"|r","");
end
local function Trim(text)
    local trimmed=string.gsub(text,"^%s*(.-)%s*$","%1"); return trimmed;
end
-- Only a native, observed reward message supplies a Marks total; never guess it.
local function ParseMarks(text)
    if type(text)~="string" then return nil,nil; end
    local plain=Trim(Plain(text));
    local _,_,gain,total=string.find(plain,"^You earn ([%d%.]+) marks? %(([%d%.]+) in all%)%.$");
    if not gain then return nil,nil; end
    return tonumber(gain),tonumber(total);
end
local function Boolean(v)
    if v==true or v==1 or v=="1" then return true; end
    if v==false or v==0 or v=="0" then return false; end
end
function H.ParseLoot(text)
    if type(text)~="string" then return nil,false; end
    local prefixes={"You receive loot:"};
    local formats={LOOT_ITEM_SELF,LOOT_ITEM_SELF_MULTIPLE};
    for i=1,2 do
        local fmt=formats[i];
        if type(fmt)=="string" then
            local at=string.find(fmt,"%",1,true);
            if at and at>5 then table.insert(prefixes,Trim(string.sub(fmt,1,at-1))); end
        end
    end
    local plain=Plain(text); local body;
    for i=1,table.getn(prefixes) do
        local prefix=prefixes[i];
        if string.sub(plain,1,string.len(prefix))==prefix then body=Trim(string.sub(plain,string.len(prefix)+1)); break; end
    end
    if not body then return nil,false; end
    local first,last,reference,label=string.find(body,"|H(item:[^|]+)|h(.-)|h");
    local name,detail;
    if first then name=string.gsub(label,"^%[(.*)%]$","%1"); detail=Trim(string.sub(body,last+1));
    else local a,b,n,tail=string.find(body,"^%[([^%]]+)%](.*)$"); if a then name=n; detail=Trim(tail); end end
    if not name or name=="" then return nil,true; end
    detail=string.gsub(detail or "","^|r",""); detail=Trim(detail);
    if detail=="." then detail=""; end
    local _,_,hex=string.find(text,"|c(%x%x%x%x%x%x%x%x)|Hitem:");
    if not hex then _,_,hex=string.find(text,"|c(%x%x%x%x%x%x%x%x)%["); end
    local color;
    if hex then color={tonumber(string.sub(hex,3,4),16)/255,tonumber(string.sub(hex,5,6),16)/255,tonumber(string.sub(hex,7,8),16)/255}; end
    return {name=name,reference=reference,detail=detail,color=color},true;
end
local function Resolve(entry)
    if not entry.reference or type(GetItemInfo)~="function" then return; end
    local ok,name,link,quality,level,kind,subtype,stack,equip,texture=pcall(GetItemInfo,entry.reference);
    if not ok then H.errors.LootMetadata=tostring(name); return; end
    if type(texture)=="string" and texture~="" then entry.icon=texture; end
    if not entry.color and H.Number(quality) then
        local r,g,b=H.Call("GetItemQualityColor",quality);
        if H.Number(r) and H.Number(g) and H.Number(b) then entry.color={r,g,b}; end
    end
end
function H.RestoreLoot()
    local prior=HLE_DB and HLE_DB.lootBackup;
    if prior~=nil and type(AZS_SetHudShown)=="function" then
        local current=Boolean(H.Call("AZS_IsHudShown","loot"));
        if current==false then
            local ok=pcall(AZS_SetHudShown,"loot",prior);
            if not ok or Boolean(H.Call("AZS_IsHudShown","loot"))~=prior then return; end
        end
    end
    if HLE_DB then HLE_DB.lootBackup=nil; end
end
function H.ClearLoot()
    queue={}; deliveries={}; fallbackUntil=0; intakeConfirmed=false;
    for i=1,table.getn(cards) do cards[i].entry=nil; cards[i]:Hide(); end
    H.RestoreLoot();
    if H.loot then H.loot:Hide(); end
end
function H.LootEvent(eventName,text)
    if not HLE_DB or not HLE_DB.enabled or H.suspended then return false; end
    if eventName=="CHAT_MSG_SYSTEM" then
        local gained,total=ParseMarks(text);
        if H.Number(gained) and gained>0 and H.Number(total) and total>=0 then
            H.marksBalance=total;
            local now=H.Number(H.Call("GetTime"));
            local duplicate=text==lastMarkLine and now and lastMarkAt and now-lastMarkAt<1;
            if HLE_DB.showLoot and not duplicate then
                serial=serial+1;
                if table.getn(queue)>=32 then table.remove(queue,1); end
                table.insert(queue,{serial=serial,marks=true,name="+"..tostring(gained).." Marks",
                    detail="TOTAL "..tostring(total).." Marks"});
            end
            lastMarkLine=text;lastMarkAt=now;return true;
        end
    end
    local entry,recognized=H.ParseLoot(text);
    if not entry then
        if recognized then fallbackUntil=clock+8; intakeConfirmed=false; H.RestoreLoot(); end
        return false;
    end
    if H.ObserveBossLoot then
        local ok,err=pcall(H.ObserveBossLoot,entry,"self loot"); if not ok then H.errors.BossLoot=tostring(err); end
    end
    if not HLE_DB.showLoot then return false; end
    local seen=deliveries[text] or {}; deliveries[text]=seen;
    seen[eventName]=(seen[eventName] or 0)+1;
    local other=eventName=="CHAT_MSG_LOOT" and "CHAT_MSG_SYSTEM" or "CHAT_MSG_LOOT";
    if seen[eventName]<=(seen[other] or 0) then return false; end
    serial=serial+1; entry.serial=serial;
    intakeConfirmed=true;
    if table.getn(queue)>=32 then table.remove(queue,1); end
    table.insert(queue,entry); return true;
end
local function Text(parent,size,x,y,width)
    local t=parent:CreateFontString(nil,"OVERLAY"); t:SetFont("Fonts\\FRIZQT__.TTF",size,"OUTLINE");
    t:SetWidth(width); t:SetHeight(size+5); t:SetJustifyH("LEFT");
    t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y); return t;
end
function H.BuildLoot(parent)
    for i=1,3 do
        local c=CreateFrame("Frame",nil,parent); c:SetWidth(300); c:SetHeight(68); c:EnableMouse(true);
        c:SetPoint("BOTTOMLEFT",parent,"BOTTOMLEFT",0,(i-1)*74);
        local bg=c:CreateTexture(nil,"BACKGROUND"); bg:SetTexture(WHITE); bg:SetWidth(300); bg:SetHeight(68);
        bg:SetPoint("TOPLEFT",c,"TOPLEFT",0,0); bg:SetVertexColor(0.045,0.025,0.07,0.93);
        for edge=1,4 do
            local t=c:CreateTexture(nil,"BORDER"); t:SetTexture(WHITE); t:SetVertexColor(0.84,0.65,0.33,1);
            t:SetWidth(edge<=2 and 300 or 1); t:SetHeight(edge<=2 and 1 or 68);
            local anchor=({"TOP","BOTTOM","LEFT","RIGHT"})[edge]; t:SetPoint(anchor,c,anchor,0,0);
        end
        c.icon=c:CreateTexture(nil,"ARTWORK"); c.icon:SetWidth(40); c.icon:SetHeight(40); c.icon:SetPoint("TOPLEFT",c,"TOPLEFT",9,-14);
        c.heading=Text(c,11,58,-7,230); c.heading:SetText("LOOT RECEIVED"); c.heading:SetTextColor(0.95,0.77,0.44);
        c.name=Text(c,13,58,-23,230); c.name:SetHeight(28);
        c.detail=Text(c,10,58,-52,230); c.detail:SetTextColor(0.78,0.69,0.87);
        c:SetScript("OnEnter",function()
            if not this.entry or not GameTooltip then return; end
            local frame=this;
            local ok,err=pcall(function()
                GameTooltip:SetOwner(frame,"ANCHOR_LEFT");
                if frame.entry.reference and GameTooltip.SetHyperlink then GameTooltip:SetHyperlink(frame.entry.reference);
                elseif GameTooltip.SetText then GameTooltip:SetText(frame.entry.name); end
                GameTooltip:Show();
            end);
            if not ok then H.errors.LootTooltip=tostring(err); end
        end);
        c:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide(); end end);
        c:Hide(); cards[i]=c;
    end
    H.lootGuide=Text(parent,10,12,-90,276); H.lootGuide:SetText("LOOT - drag this area to move");
    H.lootGuide:SetTextColor(0.94,0.78,0.45); H.lootGuide:Hide();
    H.lootReady=true;
end
local function Paint(c)
    local entry=c.entry; local hasIcon=type(entry.icon)=="string";
    if hasIcon then c.icon:SetTexture(entry.icon); c.icon:Show(); else c.icon:Hide(); end
    local x=hasIcon and 58 or 12; local width=hasIcon and 230 or 276;
    c.heading:ClearAllPoints(); c.heading:SetPoint("TOPLEFT",c,"TOPLEFT",x,-7); c.heading:SetWidth(width);
    c.name:ClearAllPoints(); c.name:SetPoint("TOPLEFT",c,"TOPLEFT",x,-23); c.name:SetWidth(width);
    c.detail:ClearAllPoints(); c.detail:SetPoint("TOPLEFT",c,"TOPLEFT",x,-52); c.detail:SetWidth(width);
    c.heading:SetText(entry.marks and "MARKS EARNED" or "LOOT RECEIVED");
    c.name:SetText(entry.name); c.name:SetTextColor(unpack(entry.color or {1,0.94,0.80})); c.detail:SetText(entry.detail or "");
end
function H.UpdateLoot(delta)
    if not HLE_DB.enabled or not HLE_DB.showLoot or H.suspended or not H.lootReady then H.ClearLoot(); return; end
    clock=clock+delta; tick=tick+1; deliveries={};
    for i=1,3 do
        local c=cards[i];
        if c.entry and clock-c.born>=6 then c.entry=nil; c:Hide(); end
        if not c.entry and table.getn(queue)>0 then
            c.entry=table.remove(queue,1); c.born=clock; c.retry=clock;
            Resolve(c.entry); Paint(c); c:Show();
        end
        if c.entry then
            local age=clock-c.born;
            if age<2 and clock>=c.retry then Resolve(c.entry); Paint(c); c.retry=clock+0.2; end
            c:SetAlpha(math.min(1,age/0.15,math.max(0,6-age)));
        end
    end
    local visible={}; for i=1,3 do if cards[i].entry then table.insert(visible,cards[i]); end end
    table.sort(visible,function(a,b) return a.entry.serial<b.entry.serial; end);
    for i=1,table.getn(visible) do visible[i]:ClearAllPoints(); visible[i]:SetPoint("BOTTOMLEFT",H.loot,"BOTTOMLEFT",0,(i-1)*74); end
    if table.getn(visible)>0 or H.unlocked then H.loot:Show(); else H.loot:Hide(); end
    if H.unlocked and table.getn(visible)==0 then H.lootGuide:Show(); else H.lootGuide:Hide(); end
    if not intakeConfirmed or clock<fallbackUntil or type(AZS_SetHudShown)~="function" then H.RestoreLoot(); return; end
    local shown=Boolean(H.Call("AZS_IsHudShown","loot"));
    if shown~=nil then
        if HLE_DB.lootBackup==nil then HLE_DB.lootBackup=shown; end
        if shown then H.Call("AZS_SetHudShown","loot",false); end
    end
end
H.lootCards=cards;

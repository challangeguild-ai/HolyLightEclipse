local H = HLE;
local GOLD, VIOLET = {0.95,0.74,0.35}, {0.63,0.39,0.93};
local WHITE = "Interface\\AddOns\\HolyLightEclipse\\Media\\White.tga";
local MEDIA = "Interface\\AddOns\\HolyLightEclipse\\Media\\";
local panels, elapsed, ready = {}, 0, false;
local function Text(p,size,x,y,w,color)
    local f=p:CreateFontString(nil,"OVERLAY"); f:SetFont("Fonts\\FRIZQT__.TTF",size,"OUTLINE");
    f:SetPoint("TOPLEFT",p,"TOPLEFT",x,y); f:SetWidth(w); f:SetHeight(size+5); f:SetJustifyH("LEFT");
    f:SetTextColor(unpack(color or GOLD)); return f;
end
local function Texture(p,path,x,y,w,h,layer)
    local t=p:CreateTexture(nil,layer or "BACKGROUND"); t:SetTexture(path); t:SetWidth(w); t:SetHeight(h);
    t:SetPoint("TOPLEFT",p,"TOPLEFT",x,y); return t;
end
local function Back(p,w,h)
    local t=Texture(p,WHITE,0,0,w,h); t:SetVertexColor(0.035,0.025,0.06,0.84);
    local edge=Texture(p,WHITE,0,0,w,1,"BORDER"); edge:SetVertexColor(unpack(GOLD)); return t;
end
local function Bar(p,x,y,w,h,color)
    local f=CreateFrame("StatusBar",nil,p); f:SetWidth(w); f:SetHeight(h); f:SetPoint("TOPLEFT",p,"TOPLEFT",x,y);
    f:SetStatusBarTexture(WHITE); f:SetStatusBarColor(unpack(color)); f:SetMinMaxValues(0,1); f:SetValue(0);
    local bg=Texture(f,WHITE,0,0,w,h); bg:SetVertexColor(0.08,0.06,0.13,0.9);
    f.background=bg;
    f.label=Text(f,10,5,-1,w-10,{1,0.96,0.88}); return f;
end
local function SetBar(bar,v,m,prefix)
    v,m=H.Pair(v,m); bar:SetValue(v and math.min(1,v/m) or 0);
    bar.label:SetText((prefix or "")..(v and (H.Short(v).." / "..H.Short(m)) or "--"));
end
local function Position(f)
    local p=H.Table(HLE_DB[f.key]); f:ClearAllPoints(); f:SetScale(HLE_DB.scale);
    if H.Number(p.x) and H.Number(p.y) then f:SetPoint("CENTER",UIParent,"CENTER",p.x,p.y);
    else f:SetPoint(f.anchor,UIParent,f.anchor,f.xoffset or 0,f.offset); end
end
function H.SavePanelPosition(f)
    local x,y=f:GetCenter(); local ux,uy=UIParent:GetCenter();
    local ratio=UIParent:GetEffectiveScale()/f:GetEffectiveScale();
    HLE_DB[f.key]={x=x-ux*ratio,y=y-uy*ratio}; Position(f);
end
local function Panel(name,key,w,h,anchor,offset,xoffset)
    local f=CreateFrame("Frame",name,UIParent); f:SetWidth(w); f:SetHeight(h); f:SetFrameStrata("MEDIUM");
    f.key,f.anchor,f.offset,f.xoffset=key,anchor,offset,xoffset;
    f:SetMovable(true); f:EnableMouse(key=="meter"); f:RegisterForDrag("LeftButton");
    if f.SetClampedToScreen then f:SetClampedToScreen(true); end
    f:SetScript("OnDragStart",function() if H.unlocked or this.key=="meter" then this:StartMoving(); end end);
    f:SetScript("OnDragStop",function()
        this:StopMovingOrSizing(); local x,y=this:GetCenter(); local ux,uy=UIParent:GetCenter();
        local ratio=UIParent:GetEffectiveScale()/this:GetEffectiveScale();
        HLE_DB[this.key]={x=x-ux*ratio,y=y-uy*ratio}; Position(this);
    end);
    table.insert(panels,f); Position(f); return f;
end
local chatFrame,chatWidth,chatOwnedWidth;
function H.RestoreChat()
    if chatFrame and chatWidth and chatFrame:GetWidth()==chatOwnedWidth then chatFrame:SetWidth(chatWidth); end
    chatFrame,chatWidth,chatOwnedWidth=nil,nil,nil;
end
function H.UpdateChat()
    if not HLE_DB.enabled or H.suspended then H.RestoreChat(); return; end
    local frame=ChatFrame1 or DEFAULT_CHAT_FRAME;
    if not frame or type(frame.GetWidth)~="function" or type(frame.SetWidth)~="function" then return; end
    if chatFrame~=frame then H.RestoreChat(); chatFrame=frame; chatWidth=frame:GetWidth(); end
    local width=360;
    if H.playerRoot.GetLeft and frame.GetLeft then
        local left,playerLeft=H.Number(frame:GetLeft()),H.Number(H.playerRoot:GetLeft());
        local ownScale=H.Number(H.playerRoot:GetEffectiveScale()); local chatScale=H.Number(frame:GetEffectiveScale());
        if left and playerLeft and ownScale and chatScale and chatScale>0 then
            local available=playerLeft*ownScale/chatScale-left-16;
            if available>0 then width=math.min(width,math.max(80,available)); end
        end
    end
    chatOwnedWidth=width;
    if frame:GetWidth()~=width then frame:SetWidth(width); end
end
function H.SetTopHeight(height)
    H.top:SetHeight(height); H.topBackground:SetHeight(height);
    for i=3,4 do H.topEdges[i]:SetHeight(height); end
end
local function Build()
    H.main=Panel("HLEMain","main",760,202,"BOTTOM",24);
    H.playerRoot=CreateFrame("Frame",nil,H.main);
    H.playerRoot:SetWidth(326); H.playerRoot:SetHeight(82); H.playerRoot:SetPoint("TOPLEFT",H.main,"TOPLEFT",14,0);
    Texture(H.playerRoot,MEDIA.."UnitPanel04.tga",0,0,326,82);
    H.crest=Texture(H.main,MEDIA.."MainCrest.tga",354,-15,52,52,"ARTWORK");
    H.targetRoot=CreateFrame("Frame",nil,H.main);
    H.targetRoot:SetWidth(326); H.targetRoot:SetHeight(82); H.targetRoot:SetPoint("TOPLEFT",H.main,"TOPLEFT",420,0);
    Texture(H.targetRoot,MEDIA.."TargetPanel091.tga",0,0,326,82);
    H.playerPortrait=Texture(H.playerRoot,WHITE,15,-17,48,48,"ARTWORK");
    H.targetPortrait=Texture(H.targetRoot,WHITE,263,-17,48,48,"ARTWORK");
    Texture(H.playerRoot,MEDIA.."Portrait04.tga",4,-6,70,70,"OVERLAY");
    Texture(H.targetRoot,MEDIA.."Portrait04.tga",252,-6,70,70,"OVERLAY");
    H.name=Text(H.playerRoot,12,82,-9,230,{1,0.95,0.82}); H.hp=Bar(H.playerRoot,82,-30,230,24,{0.22,0.63,0.28});
    H.hp.label:SetFont("Fonts\\FRIZQT__.TTF",12,"OUTLINE"); H.hp.label:SetHeight(24); H.hp.label:SetJustifyH("CENTER");
    H.power=Bar(H.playerRoot,94,-61,218,11,{0.12,0.36,0.82});
    H.power.label:SetFont("Fonts\\FRIZQT__.TTF",9,"OUTLINE");
    H.shield=Text(H.playerRoot,9,82,-80,230,{0.55,0.82,1});
    H.targetName=Text(H.targetRoot,12,14,-9,230,{0.95,0.86,1}); H.targetHP=Bar(H.targetRoot,14,-30,230,24,{0.69,0.13,0.24});
    H.targetHP.label:SetFont("Fonts\\FRIZQT__.TTF",12,"OUTLINE"); H.targetHP.label:SetHeight(24); H.targetHP.label:SetJustifyH("CENTER");
    H.targetPower=Bar(H.targetRoot,14,-61,218,11,{0.12,0.36,0.82});
    H.targetPower.label:SetFont("Fonts\\FRIZQT__.TTF",9,"OUTLINE"); H.targetPower.background:SetVertexColor(0,0,0,0);
    H.targetKind=Text(H.targetRoot,9,14,-77,218,VIOLET); H.skills={};
    H.hp.background:SetVertexColor(0,0,0,0); H.power.background:SetVertexColor(0,0,0,0);
    H.targetHP.background:SetVertexColor(0,0,0,0);
    for i=1,H.maxSkills do
        local c=CreateFrame("Frame",nil,H.main); c:SetWidth(64); c:SetHeight(64);
        c:SetPoint("TOPLEFT",H.main,"TOPLEFT",0,-104);
        local overlay=CreateFrame("Frame",nil,c); overlay:SetWidth(64); overlay:SetHeight(64);
        c.overlay=overlay;
        overlay:SetPoint("TOPLEFT",c,"TOPLEFT",0,0);
        -- Always draw our verified icon above the reparented native button.
        -- Some client builds keep that button's icon hidden even when shown.
        c.icon=Texture(overlay,WHITE,5,-5,54,54,"BACKGROUND");
        c.shade=Texture(overlay,WHITE,5,-5,54,54,"ARTWORK"); c.shade:SetVertexColor(0.025,0.01,0.05,0.70);
        Texture(overlay,MEDIA.."Skill04.tga",0,0,64,64,"OVERLAY");
        c.name=Text(overlay,8,6,-6,52,{0.95,0.87,0.69}); c.name:SetHeight(22);
        c.cd=Text(overlay,18,5,-23,54,{1,0.95,0.83}); c.cd:SetJustifyH("CENTER");
        c.readyText=Text(overlay,9,5,-5,54,{1,0.89,0.38});
        c.readyText:SetJustifyH("CENTER"); c.readyText:SetText("READY"); c.readyText:Hide();
        c.progress=Bar(overlay,6,-57,52,2,VIOLET); c.progress.label:Hide(); c:EnableMouse(true);
        c:SetScript("OnEnter",function()
            if this.nativeSlot and GameTooltip and GameTooltip.SetAction then
                GameTooltip:SetOwner(this,"ANCHOR_TOP"); GameTooltip:SetAction(this.nativeSlot); GameTooltip:Show();
            elseif this.info and GameTooltip and GameTooltip.SetText then
                GameTooltip:SetOwner(this,"ANCHOR_TOP");
                if this.info.book and GameTooltip.SetSpell then GameTooltip:SetSpell(this.info.book,BOOKTYPE_SPELL or "spell");
                else GameTooltip:SetText(H.Text(this.info.name)); end
                GameTooltip:Show();
            end
        end);
        c:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide(); end end); H.skills[i]=c;
    end
    H.xp=Bar(H.main,190,-181,380,3,VIOLET); H.xp.label:Hide(); H.xp.background:Hide();
    H.xpText=Text(H.main,9,130,-188,500,{0.78,0.68,0.9}); H.xpText:SetJustifyH("CENTER");
    H.top=Panel("HLEEncounter","top",744,90,"TOP",-14);
    H.topBackground=Texture(H.top,MEDIA.."White.tga",0,0,744,90);
    H.topBackground:SetVertexColor(0.045,0.025,0.07,0.94); H.topEdges={};
    for i=1,4 do
        local edge=Texture(H.top,MEDIA.."White.tga",0,0,i<=2 and 744 or 1,i<=2 and 1 or 90,"BORDER");
        edge:ClearAllPoints(); local anchor=({"TOP","BOTTOM","LEFT","RIGHT"})[i]; edge:SetPoint(anchor,H.top,anchor,0,0); edge:SetVertexColor(0.95,0.74,0.35,1); H.topEdges[i]=edge;
    end
    H.topCorners={};
    for i=1,4 do
        local t=Texture(H.top,MEDIA.."PanelCorner092.tga",0,0,16,16,"OVERLAY");
        t:ClearAllPoints(); local anchor=({"TOPLEFT","TOPRIGHT","BOTTOMLEFT","BOTTOMRIGHT"})[i]; t:SetPoint("CENTER",H.top,anchor,0,0); H.topCorners[i]=t;
    end
    H.topCrest=Texture(H.top,MEDIA.."TimeBadge093.tga",294,-6,156,72,"ARTWORK");
    H.clock=Text(H.top,28,294,-20,156,{1,0.94,0.81}); H.clock:SetHeight(40);
    pcall(H.clock.SetFont,H.clock,"Fonts\\ARIALN.TTF",28,"OUTLINE"); H.clock:SetJustifyH("CENTER");
    H.zone=Text(H.top,13,24,-7,254); H.zone:SetHeight(20);
    H.killStats=Text(H.top,12,184,-29,98,{0.95,0.91,0.84}); H.killStats:SetHeight(24); H.killStats:SetJustifyH("RIGHT");
    H.stats=Text(H.top,12,464,-29,256,{0.95,0.91,0.84}); H.stats:SetHeight(24);
    H.statsHover=CreateFrame("Frame",nil,H.top); H.statsHover:SetWidth(256); H.statsHover:SetHeight(24);
    H.statsHover:SetPoint("TOPLEFT",H.top,"TOPLEFT",464,-29); H.statsHover:EnableMouse(true);
    H.statsHover:SetScript("OnEnter",function()
        if GameTooltip and H.fullStats then GameTooltip:SetOwner(this,"ANCHOR_BOTTOM"); GameTooltip:SetText(H.fullStats); GameTooltip:Show(); end
    end);
    H.statsHover:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide(); end end);
    H.nextBoss=Text(H.top,10,464,-56,256,VIOLET); H.nextBoss:SetHeight(35);
    H.bossPanel=CreateFrame("Frame",nil,H.top); H.bossPanel:SetWidth(560); H.bossPanel:SetHeight(72);
    H.bossBars={};
    for i=1,3 do H.bossBars[i]=Bar(H.bossPanel,0,-(i-1)*24,560,20,VIOLET); end
    H.meter=Panel("HLEMeter","meter",280,240,"RIGHT",-35,-24);
    H.meterArt=Texture(H.meter,MEDIA.."MeterFrame.tga",0,0,280,240);
    H.meterTitle=Text(H.meter,12,13,-12,254); H.meterRows={};
    for i=1,16 do H.meterRows[i]=Bar(H.meter,12,-36-(i-1)*20,254,16,VIOLET); end
    H.meterStats=Text(H.meter,11,13,-119,254,{0.91,0.84,0.98});
    H.meterHint=Text(H.meter,9,13,-137,254,{0.8,0.7,0.9});
    H.meterControls={};
    local labels={"-","+","<",">"};
    for i=1,4 do
        local c=CreateFrame("Frame",nil,H.meter); c:SetWidth(22); c:SetHeight(20); c:EnableMouse(true); c.action=i;
        c.label=Text(c,14,0,0,22); c.label:SetText(labels[i]); c.label:SetJustifyH("CENTER");
        c:SetScript("OnMouseUp",function()
            if arg1~="LeftButton" then return; end
            if this.action<=2 then HLE_DB.meterRows=math.max(4,math.min(16,(HLE_DB.meterRows or 8)+(this.action==1 and -1 or 1)));
            else H.meterPage=math.max(0,(H.meterPage or 0)+(this.action==3 and -1 or 1)); end
            H.Render(H.Read());
        end); H.meterControls[i]=c;
    end
    H.BuildTracking(Text,Texture,Panel);
    H.gear=Panel("HLEEquipment","gear",240,136,"LEFT",-35,24); H.BuildEquipment(H.gear);
    H.BuildExtras(Text,Texture,Panel);
    H.BuildGroupMap(Text,Texture,Bar,Panel); H.BuildRescue(); H.BuildBossLoot(Text,Texture); H.BuildTimeline(Text,Texture);
    H.loot=Panel("HLELoot","loot",300,216,"TOP",-295,0); H.BuildLoot(H.loot);
    H.BuildBossAlerts(); H.BuildEndSummary();
end
function H.ClearSkillVisuals()
    if H.ReleaseActionButtons then H.ReleaseActionButtons(); end
    if H.skills then
        for i=1,H.maxSkills do
            local c=H.skills[i]; c:Hide(); c.nativeSlot=nil; c.cd:SetText(""); c.name:SetText("");
            c.layoutOrder,c.layoutCount=nil,nil;
            c.readyUntil=nil; c.lastCooldown=nil; c.lastAbility=nil; c.readyText:Hide();
        end
    end
    H.hasSkills=false; H.lastSkillCount=nil;
end
function H.ClearBossVisuals()
    if H.ClearBossTracking then H.ClearBossTracking(); end
    if H.bossBars then
        for i=1,3 do H.bossBars[i]:Hide(); H.bossBars[i].label:SetText(""); end
    end
    if H.top then H.SetTopHeight(90); end
end
function H.Render(s)
    local targetVisible = type(s.target.name)=="string" and s.target.name~="" and H.Exists("target")~=false;
    H.crest:Show();
    if targetVisible then H.targetRoot:Show(); else H.targetRoot:Hide(); end
    if type(SetPortraitTexture)=="function" then
        if H.Exists("player") then pcall(SetPortraitTexture,H.playerPortrait,"player"); end
        if targetVisible and H.Exists("target") then pcall(SetPortraitTexture,H.targetPortrait,"target"); H.targetPortrait:Show(); else H.targetPortrait:Hide(); end
    else H.playerPortrait:Hide(); H.targetPortrait:Hide(); end
    H.name:SetText(H.Text(s.player.name,"PLAYER").."  /  Lv "..H.Short(s.level)); SetBar(H.hp,s.player.hp,s.player.hpm,"HP  ");
    local labels={[0]="MANA",[1]="RAGE",[2]="FOCUS",[3]="ENERGY"};
    SetBar(H.power,s.player.power,s.player.powerMax,(labels[s.player.powerType] or "POWER").."  ");
    H.shield:SetText(s.shield and s.shield>0 and ("ABSORB  +"..H.Short(s.shield)) or "");
    H.targetName:SetText(H.Text(s.target.name,"")..(s.target.level and ("  /  Lv "..(s.target.level<0 and "??" or H.Short(s.target.level))) or "")); SetBar(H.targetHP,s.target.hp,s.target.hpm);
    H.targetKind:SetText(H.Text(s.target.kind,""));
    local tp,tm=H.Pair(s.target.power,s.target.powerMax);
    if targetVisible and tp then
        SetBar(H.targetPower,tp,tm,(labels[s.target.powerType] or "POWER").."  ");
        local pc=({[0]={0.12,0.36,0.82},[1]={0.78,0.16,0.18},[2]={0.8,0.5,0.14},[3]={0.95,0.78,0.16}})[s.target.powerType] or {0.5,0.3,0.8};
        H.targetPower:SetStatusBarColor(unpack(pc)); H.targetPower:Show();
    else H.targetPower:Hide(); end
    if targetVisible then H.targetHP:Show(); else H.targetHP:Hide(); end
    H.RenderTargetAuras(s);
    SetBar(H.xp,s.xp,s.xpn); H.xpText:SetText("XP "..H.Short(s.xp).."/"..H.Short(s.xpn));
    local skills=H.Skills(s); H.hasSkills=false;
    local count=0;
    for i=1,H.maxSkills do if skills[i] then count=count+1; end end
    local columns=math.min(7,count); local rows=math.max(1,math.ceil(count/7));
    local width=columns>0 and (columns*64+(columns-1)*10) or 0;
    local order=0;
    if H.lastSkillCount~=count then
        H.xp:SetWidth(math.max(230,width)); H.xp:ClearAllPoints();
        H.xp:SetPoint("TOPLEFT",H.main,"TOPLEFT",(760-math.max(230,width))/2,-181-(rows-1)*74);
        H.xpText:ClearAllPoints(); H.xpText:SetPoint("TOPLEFT",H.main,"TOPLEFT",130,-188-(rows-1)*74);
        H.main:SetHeight(202+(rows-1)*74);
        H.lastSkillCount=count;
    end
    for i=1,H.maxSkills do
        local c,spell=H.skills[i],skills[i];
        if spell then
            if c.layoutOrder~=order or c.layoutCount~=count then
                local row=math.floor(order/7); local inRow=math.min(7,count-row*7);
                local rowWidth=inRow*64+(inRow-1)*10;
                c:ClearAllPoints(); c:SetPoint("TOPLEFT",H.main,"TOPLEFT",(760-rowWidth)/2+math.mod(order,7)*74,-104-row*74);
                c.layoutOrder,c.layoutCount=order,count;
            end
            order=order+1;
            H.hasSkills=true; c:Show(); c.nativeSlot=spell.slot; c.info=spell; c.icon:SetTexture(H.IconPath(spell.icon) or WHITE);
            local bound=false;
            if spell.buttonName and s.hasAPI and HLE_DB.replaceNative then
                local ok,value=pcall(H.BindActionButton,spell.buttonName,c);
                bound=ok and value==true;
                if not ok then H.errors.ActionSkin=tostring(value); end
                if not bound then H.ReleaseActionCard(c); end
            else H.ReleaseActionCard(c); end
            c.icon:Show();
            if spell.icon then c.icon:SetVertexColor(1,1,1,1); else c.icon:SetVertexColor(0.16,0.08,0.24,1); end
            local cd,maximum=H.Number(spell.cd),H.Number(spell.cdmax);
            local identity=H.Text(spell.key,H.Text(spell.name,tostring(i)));
            if c.lastAbility~=identity then c.readyUntil=nil; c.lastCooldown=nil; c.lastAbility=identity; end
            local now=H.Number(H.Call("GetTime"));
            if HLE_DB.skillAlerts and not spell.passive and now and
                c.lastCooldown and c.lastCooldown>0.05 and cd and cd<=0.05 then
                c.readyUntil=now+1.25;
            end
            if cd then c.lastCooldown=cd; else c.lastCooldown=nil; end
            if HLE_DB.skillAlerts and now and c.readyUntil and now<c.readyUntil then c.readyText:Show();
            else c.readyText:Hide(); end
            c.name:SetText(spell.icon and "" or H.Text(spell.name,""));
            c.cd:SetText(spell.passive and "" or (cd and (cd>0.05 and (cd<10 and string.format("%.1f",cd) or string.format("%.0f",math.ceil(cd))) or "") or "?"));
            local fraction=cd and maximum and maximum>0 and math.max(0,math.min(1,cd/maximum)) or 0;
            c.progress:SetValue(1-fraction);
            if fraction>0 then c.shade:SetHeight(math.max(1,54*fraction)); c.shade:Show(); else c.shade:Hide(); end
        else
            H.ReleaseActionCard(c); c:Hide(); c.nativeSlot=nil; c.info=nil;
            c.name:SetText(""); c.cd:SetText(""); c.progress:SetValue(0); c.shade:Hide();
            c.lastCooldown=nil; c.lastAbility=nil; c.readyUntil=nil; c.readyText:Hide();
        end
    end
    local runTime=H.Number(s.time);
    H.clock:SetText(s.phase=="ready" and "READY" or (runTime and runTime>=0 and string.format("%02d:%02d",math.floor(runTime/60),math.mod(math.floor(runTime),60)) or "--:--"));
    H.zone:SetText(H.Text(s.zone,s.phase=="ready" and "Move to begin" or ""));
    H.killStats:SetText(s.active and ("KILLS "..H.MoneyShort(s.kills)) or "");
    H.stats:SetText(s.active and ("GOLD "..H.MoneyShort(s.gold).."   CACHE "..H.MoneyShort(s.cache)) or "");
    local function Full(v) return H.Number(v) and string.format("%.0f",v) or "--"; end
    H.fullStats=s.active and ("KILLS "..Full(s.kills).."\nGOLD "..Full(s.gold).."\nCACHE "..Full(s.cache)) or nil;
    local nextText="";
    -- Upcoming bosses are shown only in the integrated timeline.
    H.nextBoss:SetText(nextText..(s.stored and s.stored>0 and ("   +"..H.Short(s.stored).." levels: /hle levels") or ""));
    local encounters={};
    if s.active and ((not s.playerDead and not H.lifeDead) or s.coopDown) then
        for i=1,table.getn(s.bosses) do
            local b=H.Table(s.bosses[i]);
            if H.Number(b.hp) and b.hp>0 and H.Number(b.hpm) and b.hpm>0 then table.insert(encounters,b); end
        end
    end
    local timelineHeight=H.UpdateTimeline(s); H.timelineHeight=timelineHeight;
    H.SetTopHeight(90+timelineHeight);
    H.bossPanel:ClearAllPoints(); H.bossPanel:SetPoint("TOP",H.top,"BOTTOM",0,-10);
    for i=1,3 do
        local bar,b=H.bossBars[i],encounters[i];
        if b then bar:Show(); SetBar(bar,b.hp,b.hpm,H.Text(b.name).."  "); else bar:Hide(); end
    end
    H.ClearBossTracking();
    if table.getn(encounters)>0 then H.bossPanel:Show(); else H.bossPanel:Hide(); end
    if table.getn(encounters)>3 then H.nextBoss:SetText("+"..(table.getn(encounters)-3).." active bosses"); end
    local meter=H.ReadMeter(s);
    H.meterTitle:SetText(meter.title.."   "..H.Short(meter.rate)..(meter.healing and " HPS" or " DPS"));
    local summary=(meter.healing and "HEAL " or "DMG ")..H.Short(meter.total);
    if meter.scope~="party" then summary=summary.."   EN "..H.Short(s.enemies); end
    H.meterStats:SetText(s.active and (meter.unavailable and "DATA UNAVAILABLE" or summary) or "");
    local lines=H.Table(meter.lines); local first=H.Number(H.Table(lines[1]).dmg);
    local rows=HLE_DB.meterRows or 8; local w=HLE_DB.meterWidth or 280; local height=132+rows*20;
    H.meter:SetWidth(w); H.meter:SetHeight(height); H.meterArt:SetWidth(w); H.meterArt:SetHeight(height);
    H.meterTitle:SetWidth(w-26); H.meterStats:SetWidth(w-26);
    H.meterStats:ClearAllPoints(); H.meterStats:SetPoint("TOPLEFT",H.meter,"TOPLEFT",13,-40-rows*20);
    H.meterHint:ClearAllPoints(); H.meterHint:SetPoint("TOPLEFT",H.meter,"TOPLEFT",13,-height+17);
    local pages=math.max(1,math.ceil(table.getn(lines)/rows)); H.meterPage=math.min(pages-1,H.meterPage or 0);
    H.meterHint:SetText(pages>1 and ("PAGE "..(H.meterPage+1).."/"..pages) or "");
    for i=1,2 do local tab=H.meterScopeTabs[i]; tab:ClearAllPoints(); tab:SetPoint("TOPLEFT",H.meter,"TOPLEFT",13+(i-1)*78,-height+68); end
    for i=1,3 do local tab=H.meterTabs[i]; tab:ClearAllPoints(); tab:SetPoint("TOPLEFT",H.meter,"TOPLEFT",13+(i-1)*67,-height+42); end
    for i=1,4 do local c=H.meterControls[i]; c:ClearAllPoints(); c:SetPoint("TOPLEFT",H.meter,"TOPLEFT",w-96+(i-1)*22,-height+21); end
    for i=1,16 do
        local bar=H.meterRows[i]; local line=H.Table(lines[H.meterPage*rows+i]); local dmg=H.Number(line.dmg);
        if i<=rows then
            bar:Show(); bar:SetWidth(w-26); bar.background:SetWidth(w-26); bar.label:SetWidth(w-36);
            bar:SetValue(dmg and first and first>0 and math.max(0,math.min(1,dmg/first)) or 0);
            local name=H.Text(line.name,i==1 and (meter.unavailable and H.Text(meter.reason,"API unavailable") or "No data yet") or "");
            bar.label:SetText(name..(dmg and ("  "..H.Short(dmg)) or ""));
        else bar:Hide(); end
    end
    local combatOK,combatError=pcall(H.UpdateCombatText,s);
    if not combatOK then H.errors.CombatText=tostring(combatError); HLE_DB.customDamage=false; HLE_DB.incomingHealing=false; H.StopCombatText(); end
    local partyOK,partyError=pcall(H.UpdateParty,s);
    if not partyOK then HLE_DB.showParty=false; H.RestoreParty(); H.errors.Party=tostring(partyError); end
    local rescueOK,rescueError=pcall(H.UpdateRescue,s);
    if not rescueOK then HLE_DB.rescueArrow=false; H.ResetRescue(); H.errors.Rescue=tostring(rescueError); end
    local mapOK,mapError=pcall(H.UpdateMinimap);
    if not mapOK then HLE_DB.skinMinimap=false; H.RestoreMinimap(); H.errors.Minimap=tostring(mapError); end
    local bossLootOK,bossLootError=pcall(H.UpdateBossLoot,s,0.05);
    if not bossLootOK then H.errors.BossLoot=tostring(bossLootError); H.HideBossLoot(); end
    H.UpdateChat(); H.UpdateTracking(s); H.UpdateLegacyBuffs(s);
    H.UpdateExtras(s,0.05);
    local alertOK,alertError=pcall(H.UpdateBossAlerts,s);
    if not alertOK then HLE_DB.bossAlerts=false; H.StopBossAlerts(); H.errors.BossAlerts=tostring(alertError); end
    local summaryOK,summaryError=pcall(H.UpdateEndSummary,s);
    if not summaryOK then HLE_DB.showEndSummary=false; H.ResetEndSummary(); H.errors.EndSummary=tostring(summaryError); end
end
local function Print(msg) if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(msg); end end
local function Visibility()
    for i=1,table.getn(panels) do
        local key=panels[i].key;
        if HLE_DB.enabled and (key~="meter" or HLE_DB.showMeter) and (key~="gear" or HLE_DB.showGear) and (key~="loot" or HLE_DB.showLoot) and (key~="navigation" or HLE_DB.showNavigation) and (key~="jewelry" or HLE_DB.showJournal) and (key~="effects" or HLE_DB.showEffects) and (key~="party" or HLE_DB.showParty) then panels[i]:Show(); else panels[i]:Hide(); end
    end
    if not HLE_DB.showGear or not HLE_DB.enabled then H.ClearEquipment(); end
    if not HLE_DB.showLoot or not HLE_DB.enabled then H.ClearLoot(); end
    if not HLE_DB.enabled then H.HideBossLoot(); H.RestoreChat(); H.StopCombatText(); H.RestoreNative(); H.RestoreNameplates(); H.ResetTracking(); H.effects:Hide(); H.ClearExtras(); H.RestoreParty(); H.ResetRescue(); H.RestoreMinimap(); H.RestoreLegacyBuffs(); H.ClearBagSkin(); H.StopBossAlerts(); H.ResetEndSummary(); end
end
function H.ApplyLayout()
    for i=1,table.getn(panels) do Position(panels[i]); end
    Visibility(); H.UpdateTracking(H.Read()); H.UpdateExtras(H.Read(),1);
end
local function Command(msg)
    msg=string.lower(msg or "");
    if msg=="off" then HLE_DB.enabled=false; Visibility();
    elseif msg=="on" then HLE_DB.enabled=true; Visibility(); H.Render(H.Read());
    elseif msg=="native" then
        HLE_DB.replaceNative=not HLE_DB.replaceNative;
        if not HLE_DB.replaceNative then H.RestoreNative(); end
        Print(HLE_DB.replaceNative and "Native HUD replacement enabled." or "Native HUD restored, including equipment controls.");
    elseif msg=="meter" then HLE_DB.showMeter=not HLE_DB.showMeter; Visibility();
    elseif string.find(msg,"^meter rows %d+$") then HLE_DB.meterRows=math.max(4,math.min(16,tonumber(string.sub(msg,12)) or 8)); H.Render(H.Read());
    elseif string.find(msg,"^meter width %d+$") then HLE_DB.meterWidth=math.max(230,math.min(480,tonumber(string.sub(msg,13)) or 280)); H.Render(H.Read());
    elseif msg=="damage" then HLE_DB.customDamage=not HLE_DB.customDamage; H.UpdateCombatText(H.Read());
    elseif msg=="healing" then HLE_DB.incomingHealing=not HLE_DB.incomingHealing; H.UpdateCombatText(H.Read());
    elseif msg=="meter run" or msg=="meter boss" or msg=="meter heal" then
        HLE_DB.meterMode=string.sub(msg,7); H.meterPage=0; H.ResetMeterCache(); H.Render(H.Read());
    elseif msg=="meter self" or msg=="meter party" then
        HLE_DB.meterScope=string.sub(msg,7); H.meterPage=0; H.ResetMeterCache(); H.Render(H.Read());
    elseif msg=="effects" then HLE_DB.showEffects=not HLE_DB.showEffects; H.UpdateTracking(H.Read());
    elseif msg=="party" then HLE_DB.showParty=not HLE_DB.showParty; H.UpdateParty(H.Read());
    elseif msg=="bag" then
        HLE_DB.skinBags=not HLE_DB.skinBags;
        if not HLE_DB.skinBags then H.ClearBagSkin(); else H.UpdateBagSkin(1); end
    elseif msg=="skills" then
        HLE_DB.skillAlerts=not HLE_DB.skillAlerts; H.Render(H.Read());
    elseif msg=="bossalerts" then
        HLE_DB.bossAlerts=not HLE_DB.bossAlerts;
        if not HLE_DB.bossAlerts then H.StopBossAlerts(); end
        H.TakeOver(H.Read());
    elseif msg=="banners" then
        HLE_DB.quietBanners=not HLE_DB.quietBanners;
        H.TakeOver(H.Read());
        Print(HLE_DB.quietBanners and "Quiet native banners: ON. Boss warning remains visible." or "Native banners restored.");
    elseif msg=="summary" then
        HLE_DB.showEndSummary=not HLE_DB.showEndSummary;
        if not HLE_DB.showEndSummary then H.ResetEndSummary();
        else H.UpdateEndSummary(H.Read()); end
    elseif msg=="summary show" then H.ToggleEndSummary();
    elseif msg=="rescue" then
        HLE_DB.rescueArrow=not HLE_DB.rescueArrow;
        if HLE_DB.rescueArrow then H.UpdateRescue(H.Read()); else H.ResetRescue(); end
    elseif msg=="timeline" then HLE_DB.showTimeline=not HLE_DB.showTimeline; H.Render(H.Read());
    elseif msg=="minimap" then HLE_DB.skinMinimap=not HLE_DB.skinMinimap; H.UpdateMinimap();
    elseif msg=="navigation" then HLE_DB.showNavigation=not HLE_DB.showNavigation; H.UpdateExtras(H.Read(),1);
    elseif msg=="journal" then HLE_DB.showJournal=not HLE_DB.showJournal; H.UpdateExtras(H.Read(),1);
    elseif msg=="settings" or msg=="" then H.RefreshSettings(); if H.settings:IsShown() then H.settings:Hide(); else H.settings:Show(); end
    elseif string.find(msg,"^profile save [123]$") then H.Profile("save",tonumber(string.sub(msg,-1)));
    elseif string.find(msg,"^profile load [123]$") then H.Profile("load",tonumber(string.sub(msg,-1)));
    elseif msg=="gear" then HLE_DB.showGear=not HLE_DB.showGear; Visibility();
    elseif msg=="loot" then HLE_DB.showLoot=not HLE_DB.showLoot; Visibility();
    elseif msg=="loot clear" then H.ClearLoot();
    elseif msg=="plates" then
        HLE_DB.nameplates=not HLE_DB.nameplates;
        if not HLE_DB.nameplates then H.RestoreNameplates(); end
        Print(HLE_DB.nameplates and "Custom nameplates enabled." or "Native nameplate appearance restored.");
    elseif string.sub(msg,1,7)=="plates " then
        local n=tonumber(string.sub(msg,8));
        if n and n>=0.6 and n<=1.8 then HLE_DB.plateScale=n; else Print("Nameplate scale: 0.6 to 1.8"); end
    elseif msg=="unlock" or msg=="lock" then
        H.unlocked=msg=="unlock";
        for i=1,table.getn(panels) do panels[i]:EnableMouse(H.unlocked or panels[i].key=="meter"); end
        Print(H.unlocked and "Drag panels. /hle lock when done." or "Layout locked. Damage meter remains draggable.");
    elseif msg=="reset" then
        HLE_DB.main,HLE_DB.top,HLE_DB.meter,HLE_DB.scale=nil,nil,nil,0.85;
        HLE_DB.gear=nil;
        HLE_DB.loot=nil; HLE_DB.effects=nil; HLE_DB.navigation=nil; HLE_DB.jewelry=nil; HLE_DB.party=nil;
        for i=1,table.getn(panels) do Position(panels[i]); end
    elseif string.sub(msg,1,6)=="scale " then
        local n=tonumber(string.sub(msg,7));
        if n and n>=0.6 and n<=1.4 then
            HLE_DB.scale=n; HLE_DB.main,HLE_DB.top,HLE_DB.meter=nil,nil,nil;
            HLE_DB.gear=nil;
            HLE_DB.loot=nil; HLE_DB.effects=nil; HLE_DB.navigation=nil; HLE_DB.jewelry=nil; HLE_DB.party=nil;
            for i=1,table.getn(panels) do Position(panels[i]); end
        else Print("Scale: 0.6 to 1.4"); end
    elseif msg=="levels" then
        local s=H.Read(); if s.active and s.stored and s.stored>0 then H.Call("AZS_OpenStoredLevels"); end
    elseif msg=="status" then
        Print("v"..H.version.."; phase="..H.Text(H.Call("AZS_GetPhase"),"unavailable"));
        Print("Native prompt matches: "..H.Short(H.promptMatches).."; scanned frames: "..H.Short(H.promptScanned));
        Print("Skill snapshot: "..(H.skillWaiting and "waiting" or "current").."; boundary="..H.Text(H.skillReason,"initial"));
        Print("Skill source: "..H.Text(H.skillSource).."; encounters: "..(H.encounterWaiting and "waiting" or "current"));
        Print("Nameplates: "..H.Short(table.getn(H.plateRecords)).."; inventory API: "..type(GetInventoryItemTexture));
        local names={"AZS_GetPhase","AZS_GetMeter","AZS_SetHudShown","GetActionTexture","GetActionCooldown"};
        for i=1,table.getn(names) do Print(names[i]..": "..type(getglobal(names[i]))); end
        for name,err in pairs(H.errors) do Print(name..": "..err); end
    else Print("/hle bag | banners | bossalerts | skills | summary | summary show | rescue | damage | healing | meter self | meter party | meter rows 10 | meter width 320 | on | off | native | meter | meter run | meter boss | meter heal | effects | gear | loot | loot clear | plates | plates 1.2 | unlock | lock | reset | scale 0.8 | levels | status"); end
end
local function Initialize()
    if ready then return; end
    HLE_DB=H.Table(HLE_DB);
    if HLE_DB.layoutVersion~=4 then
        HLE_DB.main=nil; HLE_DB.layoutVersion=4;
    end
    if HLE_DB.enabled==nil then HLE_DB.enabled=true; end
    if HLE_DB.replaceNative==nil then HLE_DB.replaceNative=true; end
    if HLE_DB.showMeter==nil then HLE_DB.showMeter=true; end
    if HLE_DB.showGear==nil then HLE_DB.showGear=true; end
    if HLE_DB.showLoot==nil then HLE_DB.showLoot=true; end
    if HLE_DB.showParty==nil then HLE_DB.showParty=true; end
    if HLE_DB.rescueArrow==nil then HLE_DB.rescueArrow=true; end
    if HLE_DB.skinBags==nil then HLE_DB.skinBags=true; end
    if HLE_DB.bossAlerts==nil then HLE_DB.bossAlerts=true; end
    if HLE_DB.quietBanners==nil then HLE_DB.quietBanners=true; end
    if HLE_DB.showEndSummary==nil then HLE_DB.showEndSummary=true; end
    if HLE_DB.skillAlerts==nil then HLE_DB.skillAlerts=true; end
    if HLE_DB.showTimeline==nil then HLE_DB.showTimeline=true; end
    if HLE_DB.skinMinimap==nil then HLE_DB.skinMinimap=true; end
    if HLE_DB.showEffects==nil then HLE_DB.showEffects=true; end
    if HLE_DB.showNavigation==nil then HLE_DB.showNavigation=true; end
    if HLE_DB.showJournal==nil then HLE_DB.showJournal=false; end
    if HLE_DB.meterMode~="boss" and HLE_DB.meterMode~="heal" then HLE_DB.meterMode="run"; end
    if HLE_DB.meterScope~="party" then HLE_DB.meterScope="self"; end
    if HLE_DB.nameplates==nil then HLE_DB.nameplates=true; end
    local plateScale=H.Number(HLE_DB.plateScale); HLE_DB.plateScale=plateScale and math.max(0.6,math.min(1.8,plateScale)) or 1;
    local n=H.Number(HLE_DB.scale); HLE_DB.scale=n and math.max(0.6,math.min(1.4,n)) or 0.85;
    if HLE_DB.noticeLayout~=1 then HLE_DB.loot=nil; HLE_DB.navigation=nil; HLE_DB.noticeLayout=1; end
    HLE_DB.meterRows=math.max(4,math.min(16,math.floor(H.Number(HLE_DB.meterRows) or 8)));
    HLE_DB.meterWidth=math.max(230,math.min(480,H.Number(HLE_DB.meterWidth) or 280));
    if HLE_DB.customDamage==nil then HLE_DB.customDamage=true; end
    if HLE_DB.incomingHealing==nil then HLE_DB.incomingHealing=true; end
    Build(); ready=true; SlashCmdList=SlashCmdList or {};
    SLASH_HOLYLIGHTECLIPSE1="/hle"; SlashCmdList.HOLYLIGHTECLIPSE=Command;
    Visibility(); H.Render(H.Read());
end
function HLE_OnLoad(frame)
    frame:RegisterEvent("ADDON_LOADED"); frame:RegisterEvent("PLAYER_LOGIN"); frame:RegisterEvent("PLAYER_ENTERING_WORLD");
    frame:RegisterEvent("PLAYER_LOGOUT"); frame:RegisterEvent("PLAYER_LEAVING_WORLD"); frame:RegisterEvent("CHAT_MSG_ADDON");
    frame:RegisterEvent("PLAYER_TARGET_CHANGED");
    frame:RegisterEvent("PLAYER_DEAD"); frame:RegisterEvent("PLAYER_ALIVE"); frame:RegisterEvent("PLAYER_UNGHOST");
    frame:RegisterEvent("SPELLS_CHANGED"); frame:RegisterEvent("CHAT_MSG_LOOT"); frame:RegisterEvent("CHAT_MSG_SYSTEM");
end
function HLE_OnEvent(evt,name)
    if evt=="CHAT_MSG_LOOT" or evt=="CHAT_MSG_SYSTEM" then
        if HLE_DB and HLE_DB.enabled then H.LootEvent(evt,name); end
    elseif evt=="SPELLS_CHANGED" then H.ResetSpellBook();
    elseif evt=="PLAYER_DEAD" then H.PlayerDied(true); HLE_OnUpdate(0.05);
    elseif evt=="PLAYER_ALIVE" or evt=="PLAYER_UNGHOST" then H.PlayerAlive();
    elseif evt=="PLAYER_TARGET_CHANGED" then
        HLE_OnUpdate(0.05);
    elseif evt=="PLAYER_LOGOUT" or evt=="PLAYER_LEAVING_WORLD" then
        H.RestoreChat(); H.StopCombatText();
        H.RestoreNameplates(); H.ClearEquipment();
        H.ClearLoot(); H.ResetEncounters("world-leave"); H.ResetTracking(); H.ClearExtras(); H.RestoreParty(); H.ResetRescue(); H.RestoreMinimap(); H.RestoreLegacyBuffs(); H.ClearBagSkin(); H.StopBossAlerts(); H.ResetEndSummary(); H.ResetTimeline(); if H.effects then H.effects:Hide(); end
        H.LeaveSkillWorld();
        if ready then H.RestoreNative(); H.suspended=true; end
    elseif evt=="CHAT_MSG_ADDON" then
        H.TrackingEvent(name);
        if name=="AZSZONE" then H.StartSkillRun("AZSZONE"); H.lifeDead=false; H.deathExplicit=false; H.ResetEncounters("AZSZONE"); H.ClearLoot(); H.ResetTracking(); H.ResetMeterCache(); H.ResetTimeline(); H.ResetRescue(); H.ResetBossAlerts(); H.ResetEndSummary();
        elseif name=="AZSBOSSES" then H.TimelineUpdated();
        elseif name=="AZSSPELLS" then H.SpellsUpdated();
        elseif name=="AZSUNITS" then H.EncounterUnitsUpdated(); end
    elseif evt=="ADDON_LOADED" and name=="HolyLightEclipse" or evt=="PLAYER_LOGIN" or evt=="PLAYER_ENTERING_WORLD" then
        if evt=="PLAYER_ENTERING_WORLD" then H.suspended=false; H.EnterSkillWorld(); H.lifeDead=false; H.deathExplicit=false; H.ResetEncounters("world-enter"); H.ResetMeterCache(); H.ResetTimeline(); H.ResetRescue(); H.StopBossAlerts(); H.ResetEndSummary(); end
        Initialize();
    end
end
function HLE_OnUpdate(delta)
    if not ready or not HLE_DB.enabled or H.suspended then return; end
    elapsed=elapsed+(H.Number(delta) or 0); if elapsed<0.05 then return; end
    local tick=elapsed; elapsed=0;
    local ok,err=pcall(function()
        local s=H.Read(); H.Render(s); H.TakeOver(s);
        if HLE_DB.nameplates then
            local success,message=pcall(H.UpdateNameplates,tick,s);
            if not success then
                HLE_DB.nameplates=false; pcall(H.RestoreNameplates); H.errors.Nameplates=tostring(message);
                Print("Nameplates paused: "..tostring(message));
            end
        end
        if HLE_DB.showGear then
            local success,message=pcall(H.UpdateEquipment,tick,s);
            if not success then
                HLE_DB.showGear=false; pcall(H.ClearEquipment); H.gear:Hide(); H.errors.Equipment=tostring(message);
                Print("Equipment panel paused: "..tostring(message));
            end
        end
        local bagOK,bagError=pcall(H.UpdateBagSkin,tick);
        if not bagOK then HLE_DB.skinBags=false; H.ClearBagSkin(); H.errors.BagSkin=tostring(bagError); end
        if HLE_DB.showLoot then
            local success,message=pcall(H.UpdateLoot,tick);
            if not success then
                HLE_DB.showLoot=false; pcall(H.ClearLoot); H.errors.Loot=tostring(message);
                Print("Loot notices paused: "..tostring(message));
            end
        end
    end);
    if not ok then
        HLE_DB.enabled=false; Visibility(); Print("HUD stopped: "..tostring(err)..". Native HUD restored. /hle on to retry.");
    end
end

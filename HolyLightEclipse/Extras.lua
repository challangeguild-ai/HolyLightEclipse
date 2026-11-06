local H=HLE;
local MEDIA="Interface\\AddOns\\HolyLightEclipse\\Media\\";
local age=0;
local eliteEpoch,eliteHeld=nil,{};
local function Read(name)
    local fn=getglobal(name); if type(fn)~="function" then return nil; end
    local ok,value=pcall(fn); if ok then return value; end
    H.errors[name]=tostring(value); return nil;
end
local function SameSpace(p,v)
    return type(p.runId)=="string" and type(p.spaceId)=="string" and H.Number(p.mapId) and
        p.runId==v.runId and p.mapId==v.mapId and p.spaceId==v.spaceId and
        H.Number(p.x) and H.Number(p.y) and H.Number(v.x) and H.Number(v.y);
end
function H.Direction(p,v)
    if not SameSpace(p,v) then return nil; end
    local dx,dy=v.x-p.x,v.y-p.y; local distance=math.sqrt(dx*dx+dy*dy);
    if distance<3 then return "HERE",distance; end
    local facing=H.Number(p.facing); if not facing then return "",distance; end
    local front=dx*math.cos(facing)+dy*math.sin(facing);
    local left=-dx*math.sin(facing)+dy*math.cos(facing);
    if math.abs(front)>=math.abs(left) then return front>=0 and "^ AHEAD" or "v BEHIND",distance; end
    return left>0 and "< LEFT" or "> RIGHT",distance;
end
local function Nearest(p,list)
    local best,bestDistance,bestDirection;
    for i=1,256 do
        local v=list[i];
        if type(v)=="table" then
            local direction,distance=H.Direction(p,v);
            if distance and (not bestDistance or distance<bestDistance) then best,bestDistance,bestDirection=v,distance,direction; end
        end
    end
    return best,bestDistance,bestDirection;
end
local function NavText(p,list,label)
    local v,distance,direction=Nearest(p,list);
    if not v then return label..": --"; end
    local wait=H.Number(v.left);
    return label..": "..direction.."  "..H.Short(distance).." yd"..
        (v.state=="empty" and (wait and wait>=0 and ("  return "..H.Clock(wait)) or "  empty") or "");
end
local function Observe(key,name,icon,category,reference)
    if type(key)~="string" or key=="" or type(name)~="string" or name=="" then return; end
    HLE_DB.journal=H.Table(HLE_DB.journal);
    local journal=HLE_DB.journal;
    for i=1,table.getn(journal) do if journal[i].key==key then
        journal[i].name=name; journal[i].icon=H.IconPath(icon) or journal[i].icon; return;
    end end
    table.insert(journal,{key=key,name=name,icon=H.IconPath(icon),category=H.Text(category,"Item"),reference=reference});
    if table.getn(journal)>200 then table.remove(journal,1); end
end
local function CurrentJewelry(s)
    local result={}; local seen={};
    if not s.active then return result; end
    local loadout=H.liveLoadout;
    if loadout then
        local context=Read("AZS_GetMeterContext");
        if type(context)~="table" or context.runId~=H.Table(loadout.context).runId or
            not H.Number(context.asOfRunSeconds) or not H.Number(s.time) or math.abs(context.asOfRunSeconds-s.time)>3 then loadout=nil; end
    end
    if s.active and type(loadout)=="table" then
        local sources=H.Table(loadout.sources); local items=H.Table(loadout.runJewelry);
        for i=1,64 do
            local v=items[i];
            if type(v)=="table" and type(v.sourceKey)=="string" then
                local descriptor=H.Table(sources[v.sourceKey]); local icon=H.Table(descriptor.icon);
                if type(descriptor.name)=="string" then
                    local row={key=v.sourceKey,name=descriptor.name,icon=icon.status=="ready" and H.IconPath(icon.path) or nil,category=v.category};
                    table.insert(result,row); seen[row.key]=true; Observe(row.key,row.name,row.icon,row.category);
                end
            end
        end
    end
    -- Older clients expose only normal inventory. Keep it separate from the loadout.
    local ids={11,12,2,13,14};
    for i=1,5 do
        local link=H.Call("GetInventoryItemLink","player",ids[i]);
        if type(link)=="string" and link~="" and not seen[link] then
            local _,_,name=string.find(link,"|h%[(.-)%]|h");
            if name then
                local row={key=link,name=name,icon=H.IconPath(H.Call("GetInventoryItemTexture","player",ids[i])),category="Equipped",reference=link};
                if not loadout then table.insert(result,row); end
                Observe(link,name,row.icon,row.category,link);
            end
        end
    end
    return result;
end
local function Click(parent,Text,Texture,x,y,w,label,action)
    local f=CreateFrame("Frame",nil,parent); f:SetWidth(w); f:SetHeight(23); f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y); f:EnableMouse(true);
    local bg=Texture(f,MEDIA.."White.tga",0,0,w,23,"BACKGROUND"); bg:SetVertexColor(0.18,0.10,0.25,0.95);
    f.label=Text(f,10,5,-4,w-10,{0.95,0.81,0.52}); f.label:SetText(label);
    f:SetScript("OnMouseUp",function() if arg1=="LeftButton" then action(); end end); return f;
end
function H.BuildExtras(Text,Texture,Panel)
    H.navigation=CreateFrame("Frame","HLENavigation",UIParent);
    H.navigation:SetWidth(240); H.navigation:SetHeight(80); H.navigation:SetFrameStrata("MEDIUM");
    H.navigation:SetPoint("BOTTOMLEFT",H.gear,"TOPLEFT",0,12);
    H.eliteBackground=Texture(H.navigation,MEDIA.."White.tga",0,0,240,80);
    H.eliteBackground:SetVertexColor(0.045,0.025,0.065,0.93);
    local edge=Texture(H.navigation,MEDIA.."White.tga",0,0,240,1,"BORDER"); edge:SetVertexColor(0.95,0.74,0.35,1);
    H.navigationText=Text(H.navigation,13,12,-9,216,{0.95,0.81,0.52}); H.navigationText:SetText("ELITES / GUARDIANS");
    H.eliteRows={};
    for i=1,6 do
        local row={}; row.name=Text(H.navigation,13,12,-32-(i-1)*48,216,{1,0.94,0.82});
        row.name:SetHeight(30);
        row.skull=Texture(H.navigation,MEDIA.."TimelineSkull.tga",204,-56-(i-1)*48,20,20,"ARTWORK"); row.skull:Hide();
        row.hp=CreateFrame("StatusBar",nil,H.navigation); row.hp:SetWidth(216); row.hp:SetHeight(17);
        row.hp:SetPoint("TOPLEFT",H.navigation,"TOPLEFT",12,-57-(i-1)*48); row.hp:SetStatusBarTexture(MEDIA.."White.tga");
        row.hp:SetStatusBarColor(0.66,0.26,0.78); row.hp:SetMinMaxValues(0,1);
        row.hpLabel=Text(row.hp,11,4,0,208,{1,0.96,0.86}); row.hp:Hide();
        row.status=Text(H.navigation,12,12,-59-(i-1)*48,216,{0.76,0.65,0.95}); H.eliteRows[i]=row;
    end
    H.elitePrev=Click(H.navigation,Text,Texture,12,-325,100,"< PAGE",function() H.elitePage=math.max(0,(H.elitePage or 0)-1); H.UpdateExtras(H.Read(),1); end);
    H.eliteNext=Click(H.navigation,Text,Texture,128,-325,100,"PAGE >",function() H.elitePage=(H.elitePage or 0)+1; H.UpdateExtras(H.Read(),1); end);
    H.jewelry=Panel("HLEJewelryJournal","jewelry",260,270,"TOPLEFT",-180,300);
    local bg=Texture(H.jewelry,MEDIA.."White.tga",0,0,260,270); bg:SetVertexColor(0.045,0.025,0.065,0.93);
    H.journalTitle=Text(H.jewelry,12,10,-10,240,{0.95,0.74,0.35}); H.journalTitle:SetText("RUN JEWELRY");
    H.journalRows={};
    for i=1,8 do
        local row=CreateFrame("Frame",nil,H.jewelry); row:SetWidth(240); row:SetHeight(24); row:SetPoint("TOPLEFT",H.jewelry,"TOPLEFT",10,-32-(i-1)*25); row:EnableMouse(true);
        row.icon=Texture(row,MEDIA.."White.tga",0,0,22,22,"ARTWORK");
        row.label=Text(row,10,28,-3,212,{1,0.94,0.82});
        row:SetScript("OnEnter",function()
            if this.info and GameTooltip then
                GameTooltip:SetOwner(this,"ANCHOR_RIGHT");
                if this.info.reference and GameTooltip.SetHyperlink then GameTooltip:SetHyperlink(this.info.reference);
                else GameTooltip:SetText(H.Text(this.info.name).."\n"..H.Text(this.info.category,"Observed item").."\nPer-item stats unavailable in this API"); end
                GameTooltip:Show(); H.journalHover=this;
            end
        end);
        row:SetScript("OnLeave",function() if H.journalHover==this and GameTooltip then GameTooltip:Hide(); H.journalHover=nil; end end);
        H.journalRows[i]=row;
    end
    Click(H.jewelry,Text,Texture,10,-239,72,"RUN/SEEN",function() H.journalHistory=not H.journalHistory; H.journalPage=0; H.UpdateExtras(H.Read(),1); end);
    Click(H.jewelry,Text,Texture,87,-239,72,"< PAGE",function() H.journalPage=math.max(0,(H.journalPage or 0)-1); H.UpdateExtras(H.Read(),1); end);
    Click(H.jewelry,Text,Texture,164,-239,86,"PAGE >",function() H.journalPage=(H.journalPage or 0)+1; H.UpdateExtras(H.Read(),1); end);
    H.settings=CreateFrame("Frame","HLESettings",UIParent); H.settings:SetWidth(340); H.settings:SetHeight(620); H.settings:SetFrameStrata("DIALOG");
    H.settings:SetPoint("CENTER",UIParent,"CENTER",0,0); H.settings:SetMovable(true); H.settings:EnableMouse(true); H.settings:RegisterForDrag("LeftButton");
    H.settings:SetScript("OnDragStart",function() this:StartMoving(); end); H.settings:SetScript("OnDragStop",function() this:StopMovingOrSizing(); end);
    local sbg=Texture(H.settings,MEDIA.."White.tga",0,0,340,620); sbg:SetVertexColor(0.045,0.025,0.065,0.98);
    Text(H.settings,15,15,-12,300,{0.95,0.74,0.35}):SetText("HUD SETTINGS");
    H.settingButtons={};
    local controls={{"showMeter","Damage meter","meter"},{"showGear","Equipment","gear"},{"showLoot","Loot notices","loot"},
        {"nameplates","Nameplates","plates"},{"showEffects","Buffs / timers","effects"},{"showNavigation","Elite / guardian list","navigation"},{"showJournal","Jewelry / diary","journal"},{"showParty","Party frames","party"},{"showTimeline","Boss timeline","timeline"},{"skinMinimap","Minimap skin","minimap"},{"rescueArrow","Rescue guidance","rescue"},{"skinBags","Inventory skin","bag"},{"bossAlerts","Boss warning","bossalerts"},{"showEndSummary","Run summary","summary"},{"skillAlerts","Skill ready cues","skills"},{"quietBanners","Quiet center notices","banners"}};
    for i=1,table.getn(controls) do
        local spec=controls[i]; local command=spec[3];
        local button=Click(H.settings,Text,Texture,15,-40-(i-1)*27,310,spec[2],function() SlashCmdList.HOLYLIGHTECLIPSE(command); H.RefreshSettings(); end);
        button.key,button.title=spec[1],spec[2]; H.settingButtons[i]=button;
    end
    Click(H.settings,Text,Texture,15,-482,95,"MOVE / LOCK",function() SlashCmdList.HOLYLIGHTECLIPSE(H.unlocked and "lock" or "unlock"); end);
    Click(H.settings,Text,Texture,120,-482,95,"SCALE -",function() HLE_DB.scale=math.max(0.6,HLE_DB.scale-0.05); H.ApplyLayout(); end);
    Click(H.settings,Text,Texture,225,-482,100,"SCALE +",function() HLE_DB.scale=math.min(1.4,HLE_DB.scale+0.05); H.ApplyLayout(); end);
    for i=1,3 do local slot=i;
        Click(H.settings,Text,Texture,15+(i-1)*105,-515,100,"SAVE "..i,function() H.Profile("save",slot); end);
        Click(H.settings,Text,Texture,15+(i-1)*105,-542,100,"LOAD "..i,function() H.Profile("load",slot); end);
    end
    H.settingsStatus=Text(H.settings,9,15,-577,220,{0.8,0.7,0.9}); H.settingsStatus:SetText("Profiles store layout and settings only.");
    Click(H.settings,Text,Texture,245,-582,80,"CLOSE",function() H.settings:Hide(); end);
    H.settings:Hide();
end
function H.RefreshSettings()
    for i=1,table.getn(H.settingButtons) do local b=H.settingButtons[i]; b.label:SetText((HLE_DB[b.key] and "[ON] " or "[OFF] ")..b.title); end
end
local preferenceKeys={"scale","plateScale","showMeter","showGear","showLoot","nameplates","showEffects","showNavigation","showJournal","replaceNative","meterMode","meterScope","showParty","showTimeline","skinMinimap","rescueArrow","skinBags","bossAlerts","showEndSummary","skillAlerts","quietBanners"};
local positions={"main","top","meter","gear","loot","effects","navigation","jewelry","party"};
function H.Profile(mode,index)
    if index~=1 and index~=2 and index~=3 then return false; end
    HLE_DB.profiles=H.Table(HLE_DB.profiles);
    if mode=="save" then
        local p={}; for i=1,table.getn(preferenceKeys) do local key=preferenceKeys[i]; p[key]=HLE_DB[key]; end
        for i=1,table.getn(positions) do local key=positions[i]; local v=H.Table(HLE_DB[key]); if H.Number(v.x) and H.Number(v.y) then p[key]={x=v.x,y=v.y}; end end
        p.collapsed={};
        for key,v in pairs(H.Table(HLE_DB.collapsed)) do if type(v)=="boolean" then p.collapsed[key]=v; end end
        HLE_DB.profiles[index]=p; H.settingsStatus:SetText("Saved profile "..index); return true;
    elseif mode=="load" and type(HLE_DB.profiles[index])=="table" then
        local p=HLE_DB.profiles[index];
        for i=1,table.getn(preferenceKeys) do local key=preferenceKeys[i]; local v=p[key];
            if type(v)=="boolean" and key~="scale" and key~="plateScale" and key~="meterMode" then HLE_DB[key]=v;
            elseif key=="scale" and H.Number(v) then HLE_DB.scale=math.max(0.6,math.min(1.4,v));
            elseif key=="plateScale" and H.Number(v) then HLE_DB.plateScale=math.max(0.6,math.min(1.8,v));
            elseif key=="meterMode" and (v=="run" or v=="boss" or v=="heal") then HLE_DB[key]=v;
            elseif key=="meterScope" and (v=="self" or v=="party") then HLE_DB[key]=v; end
        end
        for i=1,table.getn(positions) do local key=positions[i]; local v=H.Table(p[key]); HLE_DB[key]=nil;
            if H.Number(v.x) and H.Number(v.y) then HLE_DB[key]={x=v.x,y=v.y}; end
        end
        if type(p.collapsed)=="table" then
            HLE_DB.collapsed={}; for key,v in pairs(p.collapsed) do
                if type(v)=="boolean" then HLE_DB.collapsed[key]=v; end
            end
        end
        if not HLE_DB.nameplates then H.RestoreNameplates(); end
        if not HLE_DB.replaceNative then H.RestoreNative(); end
        H.meterPage=0; H.ResetMeterCache(); H.ApplyLayout(); H.RefreshSettings(); H.settingsStatus:SetText("Loaded profile "..index); return true;
    end
    H.settingsStatus:SetText("Profile "..index.." is empty"); return false;
end
function H.ClearExtras()
    if H.navigation then H.navigation:Hide(); H.navigationText:SetText(""); end
    if H.jewelry then H.jewelry:Hide(); end
    if H.journalHover and GameTooltip then GameTooltip:Hide(); end; H.journalHover=nil;
end
function H.UpdateEliteWindow(s)
    if not HLE_DB.showNavigation or not s.active or H.suspended or not HLE_DB.enabled then H.navigation:Hide(); return; end
    local p=Read("AZS_GetPlayerPosition"); local data=H.Table(Read("AZS_GetLairs")); local list={};
    for i=1,256 do
        local v=data[i];
        if type(v)=="table" and type(v.name)=="string" and v.name~="" and type(p)=="table" and
            type(p.runId)=="string" and type(p.spaceId)=="string" and H.Number(p.mapId) and
            v.runId==p.runId and v.spaceId==p.spaceId and v.mapId==p.mapId then table.insert(list,v); end
    end
    local epoch=type(p)=="table" and (H.Text(p.runId,"")..":"..H.Text(p.spaceId,"")) or "";
    if epoch~=eliteEpoch then eliteEpoch=epoch; eliteHeld={}; end
    local count=table.getn(list); local pages=math.max(1,math.ceil(count/6));
    H.elitePage=math.min(pages-1,H.elitePage or 0);
    H.navigationText:SetText("ELITES / GUARDIANS"..(pages>1 and (" "..(H.elitePage+1).."/"..pages) or ""));
    for i=1,6 do
        local row=H.eliteRows[i]; local v=list[H.elitePage*6+i];
        row.hp:Hide(); row.skull:Hide();
        if v then
            row.name:SetText(v.name); row.name:Show(); row.status:Show();
            local status="State unavailable"; local color={0.76,0.65,0.95};
            if v.state=="asleep" then status="Available"; color={0.5,0.9,0.5};
            elseif v.state=="awake" then status="Fighting"; color={1,0.64,0.3};
            elseif v.state=="empty" then
                local left=H.Number(v.left); local stamp=H.Number(AZS_LAIRS_UPDATED); local now=H.Number(H.Call("GetTime"));
                if stamp and now and now-stamp>5 then status="Respawn: waiting for update";
                elseif left and left>=0 then status=left>0 and ("Respawn: "..H.Clock(math.ceil(left))) or "Respawn due";
                else status="Respawn: unavailable"; end
            end
            local lairKey=tostring(v.index or (H.elitePage*6+i));
            if v.state=="empty" and eliteHeld[lairKey] then row.skull:Show(); end
            if v.state=="asleep" or v.state=="awake" then eliteHeld[lairKey]=true; end
            if v.state=="asleep" or v.state=="awake" then
                local guardian;
                for j=1,table.getn(s.guardians) do local g=H.Table(s.guardians[j]); if H.Number(v.id) and v.id>0 and g.id==v.id then guardian=g; break; end end
                local hp,maximum=H.Pair(guardian and guardian.hp,guardian and guardian.hpm);
                if hp and hp>0 and not s.playerDead and not H.lifeDead then
                    row.hp:SetValue(math.min(1,hp/maximum)); row.hpLabel:SetText(H.Short(hp).." / "..H.Short(maximum));
                    row.hp:Show(); row.status:Hide();
                end
            end
            row.status:SetText(status); row.status:SetTextColor(unpack(color));
        else row.name:Hide(); row.status:Hide(); row.name:SetText(""); row.status:SetText(""); end
    end
    if count==0 then H.eliteRows[1].name:SetText("Waiting for current map data"); H.eliteRows[1].name:Show(); end
    local height=32+math.max(1,math.min(6,count))*48+(pages>1 and 32 or 0);
    H.navigation:SetHeight(height); H.eliteBackground:SetHeight(height); H.navigation:SetScale(HLE_DB.scale);
    if pages>1 then H.elitePrev:Show(); H.eliteNext:Show(); else H.elitePrev:Hide(); H.eliteNext:Hide(); end
    H.navigation:Show();
end
function H.UpdateExtras(s,delta)
    age=age+(delta or 0.05); if age<0.25 then return; end; age=0;
    if not HLE_DB.enabled or H.suspended then H.ClearExtras(); return; end
    H.UpdateEliteWindow(s);
    local current=CurrentJewelry(s);
    if not HLE_DB.showJournal then H.jewelry:Hide(); return; end
    local data=H.journalHistory and H.Table(HLE_DB.journal) or current;
    local pages=math.max(1,math.ceil(table.getn(data)/8)); H.journalPage=math.min(pages-1,H.journalPage or 0);
    H.journalTitle:SetText((H.journalHistory and "OBSERVED JEWELRY" or "RUN JEWELRY").."  "..(H.journalPage+1).."/"..pages);
    for i=1,8 do
        local row=H.journalRows[i]; local v=data[H.journalPage*8+i]; row.info=v;
        if v then
            local path=H.IconPath(v.icon); if path then row.icon:SetTexture(path); row.icon:Show(); else row.icon:Hide(); end
            local name=H.Text(v.name); row.label:SetText(string.len(name)>29 and string.sub(name,1,26).."..." or name); row:Show();
        else row:Hide(); end
        if H.journalHover==row and GameTooltip then GameTooltip:Hide(); H.journalHover=nil; end
    end
    if table.getn(data)==0 then H.journalRows[1].label:SetText(H.journalHistory and "No observed jewelry yet" or "No current item data"); H.journalRows[1].icon:Hide(); H.journalRows[1]:Show(); end
    H.jewelry:Show();
end

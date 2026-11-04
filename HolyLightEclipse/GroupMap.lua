local H=HLE;
local MEDIA="Interface\\AddOns\\HolyLightEclipse\\Media\\";
local stockParty,mapArt,buffArt={},{},{};
local mapText;
local function True(v) return v==true or v==1; end
local function Restore(list)
    for object,data in pairs(list) do
        if object.SetAlpha and data.alpha~=nil then object:SetAlpha(data.alpha); end
        if data.shown~=nil then if data.shown then object:Show(); else object:Hide(); end end
    end
end
function H.RestoreParty()
    Restore(stockParty); stockParty={};
    if H.party then H.party:Hide(); end
end
function H.RestoreMinimap()
    Restore(mapArt); mapArt={};
    if H.mapRim then H.mapRim:Hide(); end
    if HLE_DB and HLE_DB.mapClockBackup~=nil and type(AZS_SetHudShown)=="function" then
        local ok=pcall(AZS_SetHudShown,"localClock",HLE_DB.mapClockBackup);
        if ok then HLE_DB.mapClockBackup=nil; end
    end
end
function H.RestoreLegacyBuffs() Restore(buffArt); buffArt={}; end
function H.UpdateLegacyBuffs(s)
    if not HLE_DB.enabled or not HLE_DB.showEffects or H.suspended or
        type(GetPlayerBuff)~="function" or type(GetPlayerBuffTexture)~="function" then H.RestoreLegacyBuffs(); return; end
    local f=BuffFrame;
    if f and f.GetAlpha and f.SetAlpha then
        if not buffArt[f] then buffArt[f]={alpha=f:GetAlpha(),shown=f.IsShown and f:IsShown()}; end
        f:SetAlpha(0); f:Hide();
    end
end
function H.BuildGroupMap(Text,Texture,Bar,Panel)
    mapText=Text;
    H.party=Panel("HLEParty","party",300,112,"BOTTOMRIGHT",145,-24); H.partyCards={};
    for i=1,4 do
        local c=CreateFrame("Frame",nil,H.party); c:SetWidth(146); c:SetHeight(50); c:EnableMouse(true);
        local bg=Texture(c,MEDIA.."White.tga",0,0,146,50); bg:SetVertexColor(0,0,0,0);
        local edge=Texture(c,MEDIA.."White.tga",0,0,146,1,"BORDER"); edge:SetVertexColor(0.95,0.74,0.35,1);
        c.portrait=Texture(c,MEDIA.."White.tga",5,-12,28,28,"ARTWORK");
        Texture(c,MEDIA.."Portrait04.tga",0,-7,38,38,"OVERLAY");
        c.name=Text(c,10,39,-3,102,{1,0.94,0.82});
        c.hp=Bar(c,39,-20,101,13,{0.25,0.65,0.38}); c.hp.label:SetFont("Fonts\\FRIZQT__.TTF",9,"OUTLINE");
        c.power=Bar(c,39,-36,101,4,{0.18,0.36,0.85}); c.power.label:Hide();
        c:RegisterForDrag("LeftButton");
        c:SetScript("OnDragStart",function()
            if H.unlocked then this.dragged=true; H.party:StartMoving(); end
        end);
        c:SetScript("OnDragStop",function()
            if this.dragged then H.party:StopMovingOrSizing(); H.SavePanelPosition(H.party); this.dragged=false; this.skipClick=true; end
        end);
        c:SetScript("OnMouseUp",function()
            if this.skipClick then this.skipClick=nil; return; end
            if arg1=="LeftButton" and this.unit then H.Call("TargetUnit",this.unit); end
        end);
        c:SetScript("OnEnter",function()
            if this.unit and GameTooltip and GameTooltip.SetUnit then
                GameTooltip:SetOwner(this,"ANCHOR_TOP"); pcall(GameTooltip.SetUnit,GameTooltip,this.unit); GameTooltip:Show();
            end
        end);
        c:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide(); end end);
        H.partyCards[i]=c;
    end
end
function H.UpdateParty(s)
    if not HLE_DB.enabled or not HLE_DB.showParty or not HLE_DB.replaceNative or H.suspended or not s.active then H.RestoreParty(); return; end
    local count=H.Number(H.Call("GetNumPartyMembers")); local members={};
    -- These are the four peer tokens exposed by the vanilla party-unit API,
    -- not an assertion about the game's maximum co-op lobby size.
    if count and count>0 then
        for i=1,math.min(4,math.floor(count)) do
            local unit="party"..i; if H.Exists(unit)==true then table.insert(members,{unit=unit,index=i}); end
        end
    end
    local shown=table.getn(members); local replaced={};
    local revive=H.Table(H.Call("AZS_GetRevive"));
    for i=1,4 do
        local c=H.partyCards[i]; local member=members[i];
        if member then
            local unit=member.unit; local name=H.Text(H.Call("UnitName",unit),"Teammate");
            local hp,max=H.Pair(H.Call("UnitHealth",unit),H.Call("UnitHealthMax",unit));
            local level=H.Number(H.Call("UnitLevel",unit));
            local offline=H.Call("UnitIsConnected",unit); offline=offline==false or offline==0;
            local dead=True(H.Call("UnitIsDeadOrGhost",unit)) or (hp and hp<=0) or revive.reviving==name;
            c.unit=unit; c.name:SetText(name..(level and level>=0 and (" / "..H.Short(level)) or ""));
            c.hp:SetValue(hp and math.min(1,hp/max) or 0);
            local label=hp and (H.Short(hp).."/"..H.Short(max)) or "HP --";
            if offline then label="OFFLINE";
            elseif dead then label="DOWN";
                local share=H.Number(revive.rshare); if revive.reviving==name and share then label="REVIVE "..H.Short(math.max(0,math.min(1,share))*100).."%"; end
            end
            c.hp.label:SetText(label); c.hp:SetStatusBarColor(dead and 0.7 or 0.25,dead and 0.2 or 0.65,0.38);
            local power,pmax=H.Pair(H.Call("UnitMana",unit),H.Call("UnitManaMax",unit)); c.power:SetValue(power and math.min(1,power/pmax) or 0);
            if type(SetPortraitTexture)=="function" then pcall(SetPortraitTexture,c.portrait,unit); c.portrait:Show(); else c.portrait:Hide(); end
            c:ClearAllPoints(); c:SetPoint("TOPLEFT",H.party,"TOPLEFT",math.mod(i-1,2)*154,-math.floor((i-1)/2)*56); c:Show();
            if hp and HLE_DB.replaceNative then
                local stock=getglobal("PartyMemberFrame"..member.index);
                if stock then
                    if not stockParty[stock] then stockParty[stock]={alpha=stock.GetAlpha and stock:GetAlpha(),shown=stock.IsShown and stock:IsShown()}; end
                    replaced[stock]=true; stock:SetAlpha(0); stock:Hide();
                end
            end
        else c:Hide(); c.unit=nil; end
    end
    for f,data in pairs(stockParty) do if not replaced[f] then Restore({[f]=data}); stockParty[f]=nil; end end
    H.party:SetWidth(shown==1 and 146 or 300); H.party:SetHeight(math.ceil(shown/2)*56);
    if shown>0 then H.party:Show(); else H.RestoreParty(); end
end
function H.UpdateMinimap()
    if not HLE_DB.enabled or not HLE_DB.skinMinimap or H.suspended then H.RestoreMinimap(); return; end
    local map=Minimap;
    if not map or type(map.GetWidth)~="function" or type(map.GetHeight)~="function" then H.RestoreMinimap(); return; end
    if map.IsShown and not map:IsShown() then H.RestoreMinimap(); return; end
    if not H.mapRim then
        local f=CreateFrame("Frame","HLEMinimapRim",map); f:EnableMouse(false);
        f:SetPoint("CENTER",map,"CENTER",0,0);
        if f.SetFrameLevel and map.GetFrameLevel then f:SetFrameLevel(map:GetFrameLevel()+2); end
        local t=f:CreateTexture(nil,"OVERLAY"); t:SetTexture(MEDIA.."MinimapRim.tga"); t:SetPoint("CENTER",f,"CENTER",0,0);
        H.mapRim,H.mapRimTexture=f,t;
        H.mapZone=mapText(f,11,0,0,120,{0.96,0.79,0.44}); H.mapZone:ClearAllPoints(); H.mapZone:SetPoint("TOP",map,"TOP",-8,-8); H.mapZone:SetHeight(28); H.mapZone:SetJustifyH("CENTER");
        H.mapClock=mapText(f,11,0,0,160,{0.88,0.76,0.96}); H.mapClock:ClearAllPoints(); H.mapClock:SetPoint("TOP",map,"BOTTOM",0,-13); H.mapClock:SetJustifyH("CENTER");
        local actions={"+","-","x"}; H.mapButtons={};
        for i=1,3 do
            local button=CreateFrame("Frame",nil,f); button:SetWidth(20); button:SetHeight(20); button:EnableMouse(true);
            local bg=button:CreateTexture(nil,"BACKGROUND"); bg:SetTexture(MEDIA.."White.tga"); bg:SetWidth(20); bg:SetHeight(20); bg:SetPoint("TOPLEFT",button,"TOPLEFT",0,0); bg:SetVertexColor(0.08,0.035,0.13,0.95);
            local rim=button:CreateTexture(nil,"OVERLAY"); rim:SetTexture(MEDIA.."Skill04.tga"); rim:SetWidth(20); rim:SetHeight(20); rim:SetPoint("TOPLEFT",button,"TOPLEFT",0,0);
            local label=mapText(button,14,0,-1,20,{0.95,0.74,0.35}); label:SetText(actions[i]); label:SetJustifyH("CENTER");
            button.action=i;
            if i==3 then button:SetPoint("TOPRIGHT",map,"TOPRIGHT",-4,-4);
            else button:SetPoint("BOTTOMRIGHT",map,"BOTTOMRIGHT",i==1 and -4 or -28,4); end
            button:SetScript("OnMouseUp",function()
                if arg1~="LeftButton" then return; end
                local native=getglobal(this.action==1 and "MinimapZoomIn" or (this.action==2 and "MinimapZoomOut" or "MinimapToggleButton"));
                if native and type(native.Click)=="function" then pcall(native.Click,native); return; end
                if this.action==3 then map:Hide();
                elseif type(map.GetZoom)=="function" and type(map.SetZoom)=="function" then
                    local z=map:GetZoom(); local levels=map.GetZoomLevels and map:GetZoomLevels() or 6;
                    if H.Number(z) and H.Number(levels) then map:SetZoom(math.max(0,math.min(levels-1,z+(this.action==1 and 1 or -1)))); end
                end
            end);
            H.mapButtons[i]=button;
        end
    end
    local w,h=H.Number(map:GetWidth()),H.Number(map:GetHeight());
    if not w or not h or w<=0 or h<=0 then H.RestoreMinimap(); return; end
    H.mapRim:SetWidth(w*1.2); H.mapRim:SetHeight(h*1.2); H.mapRimTexture:SetWidth(w*1.2); H.mapRimTexture:SetHeight(h*1.2); H.mapZone:SetWidth(math.max(60,w-38));
    local names={"MinimapBorder","MinimapBorderTop","MinimapBackdrop","GameTimeFrame","MinimapZoomIn","MinimapZoomOut","MinimapToggleButton","MinimapZoneTextButton","MiniMapTrackingBorder","MiniMapMailBorder","MiniMapBattlefieldBorder"};
    for i=1,table.getn(names) do
        local art=getglobal(names[i]);
        if art and art.SetAlpha and art.GetAlpha then
            local parent=map; local ancestor=false;
            for depth=1,16 do if not parent then break; end; if parent==art then ancestor=true; break; end; parent=parent.GetParent and parent:GetParent() or nil; end
            if not ancestor then
                if not mapArt[art] then mapArt[art]={alpha=art:GetAlpha(),shown=art.IsShown and art:IsShown()}; end
                art:SetAlpha(0); if art.Hide then art:Hide(); end
            end
        end
    end
    -- Some clients keep border textures on the map or its parent, without a global name.
    local surfaces={map,map.GetParent and map:GetParent(),MinimapBackdrop};
    for i=1,3 do
        local surface=surfaces[i];
        if surface and type(surface.GetRegions)=="function" then
            local ok,regions=pcall(function() return {surface:GetRegions()}; end);
            if ok then for j=1,table.getn(regions) do
                local region=regions[j]; local path=region.GetTexture and region:GetTexture();
                if type(path)=="string" then
                    path=string.lower(path);
                    if string.find(path,"minimap",1,true) and (string.find(path,"border",1,true) or string.find(path,"zoom",1,true)) and region.GetAlpha and region.SetAlpha then
                        if not mapArt[region] then mapArt[region]={alpha=region:GetAlpha()}; end; region:SetAlpha(0);
                    end
                end
            end end
        end
    end
    local zone=H.Call("GetMinimapZoneText") or H.Call("GetRealZoneText"); H.mapZone:SetText(H.Text(zone,""));
    local clock=H.Table(H.Call("AZS_GetLocalTime")); H.mapClock:SetText(H.Text(clock.text,""));
    if type(clock.text)=="string" and type(AZS_SetHudShown)=="function" and type(AZS_IsHudShown)=="function" then
        local shown=H.Call("AZS_IsHudShown","localClock");
        if shown==true or shown==1 or shown==false or shown==0 then
            if HLE_DB.mapClockBackup==nil then HLE_DB.mapClockBackup=shown==true or shown==1; end
            H.Call("AZS_SetHudShown","localClock",false);
        end
    end
    H.mapRim:Show();
end

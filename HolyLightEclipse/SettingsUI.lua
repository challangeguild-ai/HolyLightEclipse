-- Beginner-first settings window: three categories + closed-by-default advanced section.
-- All controls operate on the existing HLE_DB and /hle command handlers.
-- No extra configuration is required after installing the addon.
local H=HLE;
local WHITE="Interface\\AddOns\\HolyLightEclipse\\Media\\White.tga";
local pages={"appearance","alerts","profiles"};
local controls,labels,tabs,groups={}, {}, {}, {};
local activePage,advanced="appearance",false;
local skin={};
local langCodes={"en","hu","de","zhCN"};
local langNames={"English","Magyar","Deutsch","简体中文"};
local UI_FONT="Fonts\\FRIZQT__.TTF";
local function Paint(t,r,g,b,a)
    t:SetTexture(WHITE);t:SetVertexColor(r,g,b,a or 1);return t;
end
local function Text(parent,size,x,y,w,key,color)
    local t=parent:CreateFontString(nil,"OVERLAY");
    t:SetFont(UI_FONT,size,"OUTLINE");
    t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);
    t:SetWidth(w);t:SetHeight(size+9);t:SetJustifyH("LEFT");
    t:SetTextColor(unpack(color or {0.95,0.82,0.59}));
    if key then labels[table.getn(labels)+1]={font=t,key=key,size=size}; t:SetText(H.L(key)); end
    return t;
end
local function Click(parent,x,y,w,h,action)
    local f=CreateFrame("Frame",nil,parent);f:SetWidth(w);f:SetHeight(h);
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);f:EnableMouse(true);
    f:SetScript("OnMouseUp",function()
        if arg1=="LeftButton" then action(); end
    end);
    return f;
end
local function Button(parent,x,y,w,h,key,fn)
    local f=Click(parent,x,y,w,h,fn);
    local bg=Paint(f:CreateTexture(nil,"BACKGROUND"),0.14,0.075,0.20,0.95);
    bg:SetAllPoints(f); f.bg=bg;
    local line=Paint(f:CreateTexture(nil,"BORDER"),0.78,0.56,0.28,1);
    line:SetWidth(w);line:SetHeight(1);line:SetPoint("TOP",f,"TOP",0,0);
    f.label=Text(f,11,5,-math.floor((h-15)/2),w-10,key);
    f.label:SetJustifyH("CENTER");f.key=key;
    return f;
end
local function Invoke(command)
    if SlashCmdList and type(SlashCmdList.HOLYLIGHTECLIPSE)=="function" then
        SlashCmdList.HOLYLIGHTECLIPSE(command);
    end
    if H.RefreshSettings then H.RefreshSettings(); end
end
local function PageToggle(page,advancedFlag,x,y,w,key,dbkey,command)
    local parent=groups[page] and groups[page][advancedFlag and "extra" or "basic"];
    local frame=Click(parent,x,y,w,25,function() Invoke(command); end);
    local small=Paint(frame:CreateTexture(nil,"BACKGROUND"),0.07,0.04,0.11,0.92);
    small:SetAllPoints(frame);frame.back=small;
    frame.value=Text(frame,11,0,-3,36,nil,{0.97,0.81,0.43});
    frame.name=Text(frame,11,39,-3,w-43,key,{0.93,0.87,0.96});
    controls[table.getn(controls)+1]={frame=frame,dbkey=dbkey,size=11};
    return frame;
end
local function PageText(page,advancedFlag,x,y,w,key,size)
    return Text(groups[page][advancedFlag and "extra" or "basic"],size or 12,x,y,w,key);
end
local function ActiveButton(b,active)
    if active then b.bg:SetVertexColor(0.36,0.20,0.43,0.98);
    else b.bg:SetVertexColor(0.14,0.075,0.20,0.95); end
end
local function SetPage(v)
    activePage=v; H.settingsResetArmed=false;
    H.RefreshSettings();
end
local function SetAdvanced(v)
    advanced=v==true;
    H.settings:SetHeight(advanced and 600 or 420);
    skin.background:SetHeight(advanced and 600 or 420);
    H.RefreshSettings();
end
function H.ToggleSettings()
    if not H.settings then return; end
    if H.settings:IsShown() then H.settingsResetArmed=false; H.settings:Hide();
    else H.RefreshSettings(); H.settings:Show(); end
end
function H.ChangeHudScale(value)
    local next=H.Number(value);
    if not next or next<0.6 or next>1.4 or not HLE_DB then return false; end
    if H.ApplyScaleKeepingPositions then H.ApplyScaleKeepingPositions(next);
    else HLE_DB.scale=next; if H.ApplyLayout then H.ApplyLayout(); end end
    if H.RefreshSettings then H.RefreshSettings(); end
    return true;
end
local function AdjustThreat(step)
    HLE_DB.threatLowPct=math.max(20,math.min(40,(H.Number(HLE_DB.threatLowPct) or 30)+step));
    if H.ResetThreatAssist then H.ResetThreatAssist(); end
    H.RefreshSettings();
end
local function AdjustCooldown(step)
    HLE_DB.threatCooldown=math.max(6,math.min(16,(H.Number(HLE_DB.threatCooldown) or 8)+step));
    H.RefreshSettings();
end
local function ResetLayout()
    if not H.settingsResetArmed then
        H.settingsResetArmed=true;
        H.settingsStatus:SetText(H.L("reset_question"));
        H.RefreshSettings();return;
    end
    H.settingsResetArmed=false;
    HLE_DB.scale=0.85;
    for _,key in ipairs({"main","top","meter","gear","loot","effects","navigation","jewelry","party"}) do
        HLE_DB[key]=nil;
    end
    if H.ApplyLayout then H.ApplyLayout(); end
    H.settingsStatus:SetText(H.L("reset_done"));H.RefreshSettings();
end
local function ProfileTitle(slot)
    local names=H.Table(HLE_DB.profileNames);
    local name=names[slot];
    if type(name)=="string" and name~="" then return name; end
    return H.L("profile_name").." "..slot;
end
local function BuildProfiles()
    local p=groups.profiles.basic;
    PageText("profiles",false,10,-5,395,"profile_intro",12);
    H.profileRows={};
    for i=1,3 do
        local slot=i;local y=-48-(i-1)*54;
        local f=CreateFrame("Frame",nil,p);f:SetWidth(425);f:SetHeight(44);f:SetPoint("TOPLEFT",p,"TOPLEFT",10,y);
        local name=Text(f,12,2,-5,175,nil,{0.93,0.86,0.99});
        local save=Button(f,177,-5,74,30,"save",function() H.Profile("save",slot);H.RefreshSettings(); end);
        local load=Button(f,256,-5,74,30,"load",function() H.Profile("load",slot);H.RefreshSettings(); end);
        local rename=Button(f,335,-5,82,30,"rename",function()
            local edit=H.profileRename;
            if not edit then return; end
            edit.slot=slot;edit:SetText(ProfileTitle(slot));
            edit:Show();edit:SetFocus();
        end);
        H.profileRows[i]={name=name,save=save,load=load,rename=rename};
    end
    local edit=CreateFrame("EditBox",nil,p,"InputBoxTemplate");
    edit:SetWidth(240);edit:SetHeight(24);
    edit:SetPoint("TOPLEFT",p,"TOPLEFT",18,-236);
    edit:SetAutoFocus(false);
    edit:SetMaxLetters(24);edit:Hide();
    edit:SetScript("OnEnterPressed",function()
        local v=this:GetText();if type(v)=="string" then
            v=string.gsub(v,"^%s+","");v=string.gsub(v,"%s+$","");
            if v~="" then
                HLE_DB.profileNames=H.Table(HLE_DB.profileNames);
                HLE_DB.profileNames[this.slot]=v;
            end
        end
        this:ClearFocus();this:Hide();H.RefreshSettings();
    end);
    edit:SetScript("OnEscapePressed",function() this:ClearFocus();this:Hide();end);
    H.profileRename=edit;
    H.profileReset=Button(p,10,-272,234,31,"reset",ResetLayout);
    H.profileMove=Button(p,255,-272,166,31,"unlock",function()
        Invoke(H.unlocked and "lock" or "unlock");
    end);
    PageText("profiles",true,9,-10,413,"reset_explain",11);
    PageText("profiles",true,9,-44,413,"scale_help",11);
    PageText("profiles",true,9,-81,413,"collapse",11);
end
function H.BuildSettingsUI()
    if H.settings then return; end
    local f=CreateFrame("Frame","HLESettings",UIParent);
    f:SetWidth(470);f:SetHeight(420);f:SetFrameStrata("DIALOG");
    f:SetPoint("CENTER",UIParent,"CENTER",0,0);
    f:SetMovable(true);f:EnableMouse(true);f:RegisterForDrag("LeftButton");
    f:SetScript("OnDragStart",function() this:StartMoving(); end);
    f:SetScript("OnDragStop",function() this:StopMovingOrSizing(); end);
    H.settings=f;
    skin.background=Paint(f:CreateTexture(nil,"BACKGROUND"),0.045,0.026,0.07,0.98);
    skin.background:SetPoint("TOPLEFT",f,"TOPLEFT",0,0);
    skin.background:SetWidth(470);skin.background:SetHeight(420);
    local edge=Paint(f:CreateTexture(nil,"BORDER"),0.96,0.74,0.35,1);
    edge:SetWidth(470);edge:SetHeight(2);edge:SetPoint("TOP",f,"TOP",0,0);
    Text(f,15,15,-14,365,nil,{0.96,0.78,0.43}):SetText("HOLY LIGHT × ECLIPSE");
    local close=Button(f,427,-10,30,29,nil,function()f:Hide();end);
    close.label:SetText("X");
    local enabled=Button(f,334,-11,85,27,nil,function()
        Invoke(HLE_DB.enabled and "off" or "on");
    end);
    H.settingsEnabled=enabled;
    for i=1,3 do
        local page=pages[i];
        tabs[page]=Button(f,14+(i-1)*149,-57,142,30,page,function() SetPage(page); end);
    end
    for i=1,3 do
        local page=pages[i];
        local container=CreateFrame("Frame",nil,f);
        container:SetWidth(440);container:SetHeight(277);
        container:SetPoint("TOPLEFT",f,"TOPLEFT",14,-99);
        groups[page]={container=container};
        local basic=CreateFrame("Frame",nil,container);basic:SetWidth(438);basic:SetHeight(277);
        basic:SetPoint("TOPLEFT",container,"TOPLEFT",0,0);
        groups[page].basic=basic;
        local extra=CreateFrame("Frame",nil,f);extra:SetWidth(440);extra:SetHeight(155);
        extra:SetPoint("TOPLEFT",f,"TOPLEFT",14,-411);
        groups[page].extra=extra;
        local bg=Paint(extra:CreateTexture(nil,"BACKGROUND"),0.09,0.052,0.13,0.88);
        bg:SetAllPoints(extra);
    end
    -- APPEARANCE / the only default choices most users need.
    PageText("appearance",false,8,-5,390,"basics",12);
    PageToggle("appearance",false,8,-34,200,"meter","showMeter","meter");
    PageToggle("appearance",false,224,-34,200,"equipment","showGear","gear");
    PageToggle("appearance",false,8,-66,200,"party","showParty","party");
    PageToggle("appearance",false,224,-66,200,"timeline","showTimeline","timeline");
    PageText("appearance",false,8,-111,195,"size",12);
    H.sizeButtons={};
    for i=1,3 do
        local size=({0.75,0.85,1})[i];
        H.sizeButtons[i]=Button(groups.appearance.basic,8+(i-1)*144,-142,138,31,
            ({"compact","standard","large"})[i],function() H.ChangeHudScale(size);end);
        H.sizeButtons[i].scale=size;
    end
    PageText("appearance",false,8,-196,390,"language",12);
    H.langButtons={};
    for i=1,4 do
        local lang=langCodes[i];
        H.langButtons[i]=Button(groups.appearance.basic,8+(i-1)*108,-225,103,32,nil,
            function() H.SetLanguage(lang); end);
        H.langButtons[i].label:SetText(langNames[i]);
        H.langButtons[i].lang=lang;
    end
    PageToggle("appearance",true,8,-12,200,"loot","showLoot","loot");
    PageToggle("appearance",true,224,-12,200,"effects","showEffects","effects");
    PageToggle("appearance",true,8,-43,200,"navigation","showNavigation","navigation");
    PageToggle("appearance",true,224,-43,200,"jewelry","showJournal","journal");
    PageToggle("appearance",true,8,-74,200,"minimap","skinMinimap","minimap");
    PageToggle("appearance",true,224,-74,200,"bags","skinBags","bag");
    PageToggle("appearance",true,8,-105,200,"launcher","showLauncher","launcher");
    PageToggle("appearance",true,224,-105,200,"nameplates","nameplates","plates");
    -- ALERTS / only verified actions, never fictional boss mechanic predictions.
    PageText("alerts",false,8,-5,415,"warning_title",12);
    PageToggle("alerts",false,8,-36,415,"danger","threatAlerts","threats");
    PageToggle("alerts",false,8,-68,415,"boss","bossAlerts","bossalerts");
    PageToggle("alerts",false,8,-100,415,"rescue","rescueArrow","rescue");
    PageToggle("alerts",false,8,-132,415,"threat_sound","threatSound","threatsound");
    PageText("alerts",false,8,-176,250,"lowhp",12);
    H.thresholdDown=Button(groups.alerts.basic,265,-174,39,31,nil,function() AdjustThreat(-5);end);
    H.thresholdDown.label:SetText("-");
    H.thresholdValue=Text(groups.alerts.basic,12,311,-179,53,nil);
    H.thresholdUp=Button(groups.alerts.basic,371,-174,39,31,nil,function() AdjustThreat(5);end);
    H.thresholdUp.label:SetText("+");
    PageText("alerts",true,9,-10,240,"seconds",12);
    H.cooldownDown=Button(groups.alerts.extra,257,-6,39,31,nil,function() AdjustCooldown(-2);end);
    H.cooldownDown.label:SetText("-");
    H.cooldownValue=Text(groups.alerts.extra,12,304,-11,57,nil);
    H.cooldownUp=Button(groups.alerts.extra,376,-6,39,31,nil,function() AdjustCooldown(2);end);
    H.cooldownUp.label:SetText("+");
    PageToggle("alerts",true,8,-47,200,"quiet","quietBanners","banners");
    PageToggle("alerts",true,224,-47,200,"skill","skillAlerts","skills");
    PageToggle("alerts",true,8,-78,200,"summary","showEndSummary","summary");
    PageToggle("alerts",true,224,-78,200,"damage","customDamage","damage");
    PageToggle("alerts",true,8,-109,200,"healing","incomingHealing","healing");
    BuildProfiles();
    H.advancedButton=Button(f,15,-379,435,30,"advanced",function()SetAdvanced(not advanced);end);
    H.settingsStatus=Text(f,10,15,0,432,nil,{0.74,0.63,0.86});
    H.settingsStatus:ClearAllPoints();
    H.settingsStatus:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",15,13);
    H.settingsStatus:SetText(H.L("status"));
    f:Hide(); H.RefreshSettings();
end
function H.RefreshSettings()
    if not H.settings then return; end
    for page,tab in pairs(tabs) do
        tab.label:SetText(H.L(page)); H.LocalizedFont(tab.label,11);
        ActiveButton(tab,page==activePage);
    end
    for page,group in pairs(groups) do
        if page==activePage then group.container:Show();
        else group.container:Hide();end
        if page==activePage and advanced then group.extra:Show();
        else group.extra:Hide();end
    end
    for i=1,table.getn(labels) do
        local v=labels[i];v.font:SetText(H.L(v.key));H.LocalizedFont(v.font,v.size);
    end
    for i=1,table.getn(controls) do
        local v=controls[i];
        local yes=HLE_DB[v.dbkey]~=false;
        v.frame.value:SetText(yes and "[x]" or "[ ]");
        v.frame.value:SetTextColor(yes and 0.96 or 0.48,yes and 0.82 or 0.46,yes and 0.49 or 0.55);
    end
    H.advancedButton.label:SetText((advanced and "[-]  " or "[+]  ")..H.L("advanced"));
    H.LocalizedFont(H.advancedButton.label,11);
    for i=1,3 do ActiveButton(H.sizeButtons[i],math.abs((HLE_DB.scale or 0.85)-H.sizeButtons[i].scale)<0.01);end
    for i=1,4 do
        ActiveButton(H.langButtons[i],H.Language()==H.langButtons[i].lang);
        if i==4 and H.langButtons[i].label.SetFont then
            -- Ensure the language's own name is readable even in an English UI.
            local ok,worked=pcall(H.langButtons[i].label.SetFont,H.langButtons[i].label,
                "Fonts\\ARKai_T.TTF",11,"OUTLINE");
            if not ok or (worked~=true and worked~=1) then H.langButtons[i].label:SetText("Chinese"); end
        else H.LocalizedFont(H.langButtons[i].label,11); end
    end
    H.thresholdValue:SetText((H.Number(HLE_DB.threatLowPct) or 30).."%");
    H.cooldownValue:SetText((H.Number(HLE_DB.threatCooldown) or 8).."s");
    for i=1,3 do
        local r=H.profileRows[i];r.name:SetText(ProfileTitle(i));
        r.save.label:SetText(H.L("save"));r.load.label:SetText(H.L("load"));
        r.rename.label:SetText(H.L("rename"));
        H.LocalizedFont(r.name,12);
        H.LocalizedFont(r.save.label,11);H.LocalizedFont(r.load.label,11);
    end
    H.profileReset.label:SetText(H.settingsResetArmed and H.L("reset_question") or H.L("reset"));
    H.profileMove.label:SetText(H.unlocked and H.L("lock") or H.L("unlock"));
    H.settingsEnabled.label:SetText(HLE_DB.enabled and "HUD: ON" or "HUD: OFF");
end

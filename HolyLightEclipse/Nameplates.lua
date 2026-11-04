local H=HLE;
local WHITE="Interface\\AddOns\\HolyLightEclipse\\Media\\White.tga";
local records,byFrame={},{};
local age,scanAge=0,0;
local visibility;
local function Alpha(region)
    if region and region.GetAlpha then return region:GetAlpha(); end return 1;
end
local function Restore(record)
    record.overlay:Hide(); record.health:SetAlpha(record.alpha);
    for i=1,table.getn(record.regions) do
        local saved=record.regions[i]; saved.region:SetAlpha(saved.alpha);
    end
    record.owned=false;
end
function H.RestoreNameplates()
    for i=1,table.getn(records) do if records[i].owned then Restore(records[i]); end end
    if visibility then
        if visibility.shown then H.Call("ShowNameplates"); NAMEPLATES_ON=1;
        else H.Call("HideNameplates"); NAMEPLATES_ON=nil; end
        visibility=nil;
    end
end
local function Skin(plate)
    if byFrame[plate] or type(plate.GetRegions)~="function" or type(plate.GetChildren)~="function" then return; end
    local regions={plate:GetRegions()}; local border,name,level;
    for i=1,table.getn(regions) do
        local r=regions[i];
        if r.GetTexture then
            local path=r:GetTexture();
            if type(path)=="string" and string.lower(string.gsub(path,"/","\\"))=="interface\\tooltips\\nameplate-border" then border=r; end
        elseif r.GetText then if not name then name=r; elseif not level then level=r; end end
    end
    if not border or not name then return; end
    local children={plate:GetChildren()}; local health;
    for i=1,table.getn(children) do
        local c=children[i]; if c.GetMinMaxValues and c.GetValue and c.SetAlpha then health=c; break; end
    end
    if not health then return; end
    local overlay=CreateFrame("Frame",nil,plate); overlay:SetWidth(140); overlay:SetHeight(32);
    overlay:SetPoint("CENTER",plate,"CENTER",0,0); overlay:EnableMouse(false);
    local bar=CreateFrame("StatusBar",nil,overlay); bar:SetWidth(132); bar:SetHeight(12);
    bar:SetPoint("BOTTOM",overlay,"BOTTOM",0,1); bar:SetStatusBarTexture(WHITE); bar:SetMinMaxValues(0,1);
    local bg=bar:CreateTexture(nil,"BACKGROUND"); bg:SetTexture(WHITE); bg:SetWidth(136); bg:SetHeight(16);
    bg:SetPoint("CENTER",bar,"CENTER",0,0); bg:SetVertexColor(0.045,0.025,0.065,0.9);
    local edges={};
    for i=1,4 do
        local edge=bar:CreateTexture(nil,"BORDER"); edge:SetTexture(WHITE);
        edge:SetWidth(i<=2 and 136 or 1); edge:SetHeight(i<=2 and 1 or 14);
        local anchor=({"TOP","BOTTOM","LEFT","RIGHT"})[i];
        edge:SetPoint(anchor,bg,anchor,0,0); edges[i]=edge;
    end
    local title=overlay:CreateFontString(nil,"OVERLAY"); title:SetFont("Fonts\\FRIZQT__.TTF",10,"OUTLINE");
    title:SetWidth(156); title:SetHeight(15); title:SetPoint("BOTTOM",bar,"TOP",0,3);
    local levelText=bar:CreateFontString(nil,"OVERLAY"); levelText:SetFont("Fonts\\FRIZQT__.TTF",11,"OUTLINE");
    levelText:SetWidth(44); levelText:SetHeight(14); levelText:SetPoint("LEFT",bar,"LEFT",3,0); levelText:SetJustifyH("LEFT");
    levelText:SetTextColor(1,0.84,0.48);
    local value=bar:CreateFontString(nil,"OVERLAY"); value:SetFont("Fonts\\FRIZQT__.TTF",9,"OUTLINE");
    value:SetWidth(126); value:SetHeight(12); value:SetPoint("CENTER",bar,"CENTER",0,0); value:SetJustifyH("RIGHT");
    local saved={};
    for i=1,table.getn(regions) do
        local r=regions[i]; if r.SetAlpha then table.insert(saved,{region=r,alpha=Alpha(r)}); end
    end
    local record={plate=plate,health=health,name=name,level=level,alpha=Alpha(health),regions=saved,
        overlay=overlay,bar=bar,title=title,value=value,levelText=levelText,edges=edges};
    byFrame[plate]=record; table.insert(records,record);
end
local function Draw(record,s)
    if not record.plate:IsShown() then record.overlay:Hide(); return; end
    local low,high=record.health:GetMinMaxValues(); local value=H.Number(record.health:GetValue());
    low,high=H.Number(low),H.Number(high);
    local name=record.name:GetText();
    if not low or not high or high<=low or not value or type(name)~="string" or name=="" then
        if record.owned then Restore(record); end; return;
    end
    if not record.owned then
        record.alpha=Alpha(record.health);
        for i=1,table.getn(record.regions) do record.regions[i].alpha=Alpha(record.regions[i].region); end
    end
    record.health:SetAlpha(0);
    for i=1,table.getn(record.regions) do record.regions[i].region:SetAlpha(0); end
    record.owned=true;
    local target=H.Exists("target")==true and H.Call("UnitName","target")==name and Alpha(record.plate)>=0.99;
    local kind;
    if target then kind=H.Call("AZS_UnitKind","target"); end
    if not kind and s.active then
        for i=1,table.getn(s.bosses) do if H.Table(s.bosses[i]).name==name then kind="boss"; break; end end
    end
    local color={0.72,0.16,0.27};
    if kind=="boss" or kind=="final" then color={0.63,0.29,0.82};
    elseif kind=="guardian" then color={0.15,0.62,0.72};
    elseif kind=="elite" then color={0.84,0.46,0.12}; end
    record.bar:SetStatusBarColor(unpack(color));
    local edge=target and {0.80,0.57,1} or {0.80,0.64,0.35};
    for i=1,4 do record.edges[i]:SetVertexColor(unpack(edge)); end
    local nativeLevel=record.level and record.level:GetText();
    local levelLabel="";
    if type(nativeLevel)=="string" then
        nativeLevel=string.gsub(string.gsub(nativeLevel,"|c%x%x%x%x%x%x%x%x",""),"|r","");
        local number=tonumber(nativeLevel);
        if number and number>=0 then levelLabel="Lv "..H.Short(number);
        elseif string.find(nativeLevel,"??",1,true) then levelLabel="??"; end
    end
    record.levelText:SetText(levelLabel);
    record.title:SetText(name); record.title:SetTextColor(1,0.93,0.80);
    local fraction=math.max(0,math.min(1,(value-low)/(high-low)));
    record.bar:SetValue(fraction); record.value:SetText(string.format("%.0f%%",fraction*100));
    record.value:SetTextColor(1,0.97,0.91); record.overlay:SetScale(HLE_DB.plateScale or 1);
    record.overlay:Show();
end
function H.UpdateNameplates(delta,s)
    if not HLE_DB.enabled or not HLE_DB.nameplates or H.suspended then H.RestoreNameplates(); return; end
    if not WorldFrame or type(WorldFrame.GetChildren)~="function" then return; end
    if not visibility and type(ShowNameplates)=="function" and type(HideNameplates)=="function" then
        visibility={shown=NAMEPLATES_ON==1 or NAMEPLATES_ON==true}; H.Call("ShowNameplates"); NAMEPLATES_ON=1;
    end
    age=age+delta; scanAge=scanAge+delta; if age<0.05 then return; end age=0;
    if scanAge>=0.25 then
        scanAge=0;
        local children={WorldFrame:GetChildren()};
        for i=1,table.getn(children) do Skin(children[i]); end
    end
    for i=1,table.getn(records) do Draw(records[i],s); end
end
-- Exposed for diagnostics and deterministic mocks; no native frame scripts are replaced.
H.plateRecords=records;

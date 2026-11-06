-- Compact, dismissible run-summary overlay; reads the game's native AZS_END
-- snapshot only after an actual terminal phase. No speculative counters.
local H=HLE;
local WHITE="Interface\\AddOns\\HolyLightEclipse\\Media\\White.tga";
local currentKey,closedKey,hasData=nil,nil,false;
local function Text(parent,size,x,y,width,color)
    local label=parent:CreateFontString(nil,"OVERLAY");
    label:SetFont("Fonts\\FRIZQT__.TTF",size,"OUTLINE");
    label:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y); label:SetWidth(width); label:SetHeight(size+6);
    label:SetTextColor(unpack(color or {1,0.92,0.80})); return label;
end
function H.BuildEndSummary()
    local f=CreateFrame("Frame","HLERunSummary",UIParent); f:SetWidth(386); f:SetHeight(312);
    f:SetPoint("RIGHT",UIParent,"RIGHT",-20,0); f:SetFrameStrata("DIALOG"); f:EnableMouse(true);
    local bg=f:CreateTexture(nil,"BACKGROUND"); bg:SetTexture(WHITE);
    bg:SetPoint("TOPLEFT",f,"TOPLEFT",0,0); bg:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",0,0);
    bg:SetVertexColor(0.043,0.026,0.074,0.96);
    local line=f:CreateTexture(nil,"BORDER"); line:SetTexture(WHITE); line:SetWidth(386); line:SetHeight(2);
    line:SetPoint("TOP",f,"TOP",0,0); line:SetVertexColor(0.96,0.74,0.36,1);
    f.heading=Text(f,17,16,-11,310,{0.97,0.78,0.40});
    f.context=Text(f,10,16,-41,353,{0.76,0.68,0.85}); f.context:SetHeight(24);
    f.stats={};
    local captions={"SURVIVED","LEVEL","ENEMIES","ELITES","GUARDIANS","BOSSES",
        "DAMAGE","AVG DPS","DAMAGE TAKEN","GOLD","CHESTS","MAGNETS"};
    for i=1,12 do
        local col=math.floor((i-1)/6); local row=math.mod(i-1,6);
        local x=16+col*188; local y=-77-row*32;
        local label=Text(f,9,x,y,173,{0.66,0.59,0.78}); label:SetText(captions[i]);
        local value=Text(f,13,x,y-13,174,{1,0.93,0.78}); f.stats[i]=value;
    end
    f.note=Text(f,9,16,-280,348,{0.73,0.67,0.81});
    f.note:SetText("Native end-of-run statistics");
    local close=CreateFrame("Frame",nil,f); close:SetWidth(28); close:SetHeight(28);
    close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-7,-6); close:EnableMouse(true);
    close.text=Text(close,18,5,-2,21,{0.94,0.67,0.46}); close.text:SetText("X");
    close:SetScript("OnMouseUp",function()
        if arg1=="LeftButton" then closedKey=currentKey; f:Hide(); end
    end);
    f:Hide(); H.endSummary=f;
end
function H.ResetEndSummary()
    currentKey=nil; closedKey=nil; hasData=false;
    if H.endSummary then H.endSummary:Hide(); end
end
local function Stat(value)
    local n=H.Number(value);
    return n and H.Short(n) or "--";
end
local function Paint(summary)
    local f=H.endSummary;
    local result=H.Text(summary.result,"END");
    if result=="victory" then f.heading:SetText("VICTORY SUMMARY");
    elseif result=="defeat" then f.heading:SetText("RUN DEFEAT");
    elseif result=="left" then f.heading:SetText("RUN ENDED");
    else f.heading:SetText("RUN SUMMARY"); end
    f.context:SetText(H.Text(summary.hero,"Hero").." / "..H.Text(summary.cname,H.Text(summary.class,"Class")).."  -  "..H.Text(summary.zname,H.Text(summary.zone,"Zone")));
    local time=H.Number(summary.t); local d=H.Number(summary.dmg);
    local stats={time and H.Clock(time) or "--:--",Stat(summary.lvl),Stat(summary.kills),Stat(summary.elites),
        Stat(summary.guardians),Stat(summary.bosses),Stat(summary.dmg),d and time and time>0 and Stat(d/math.max(1,time)) or "--",
        Stat(summary.taken),Stat(summary.gold),Stat(summary.chests),Stat(summary.magnets)};
    for i=1,12 do f.stats[i]:SetText(stats[i]); end
end
function H.UpdateEndSummary(s)
    if not H.endSummary then return; end
    if not HLE_DB.enabled or HLE_DB.showEndSummary==false or H.suspended then
        H.endSummary:Hide(); return;
    end
    if s.phase~="dead" and s.phase~="victory" then
        H.endSummary:Hide(); return;
    end
    local summary=H.Call("AZS_GetRunSummary");
    if type(summary)~="table" or (summary.result~="victory" and summary.result~="defeat" and summary.result~="left") then
        H.endSummary:Hide(); return;
    end
    local run=H.Table(AZS_ZONE).run;
    local signature=tostring(run)..":"..tostring(summary.result)..":"..tostring(summary.t);
    if signature~=currentKey then
        currentKey=signature; hasData=true; Paint(summary);
    end
    if currentKey~=closedKey then H.endSummary:Show(); else H.endSummary:Hide(); end
end
function H.ToggleEndSummary()
    if not H.endSummary or not hasData or not currentKey then return; end
    if H.endSummary:IsShown() then closedKey=currentKey; H.endSummary:Hide();
    else closedKey=nil; H.endSummary:Show(); end
end

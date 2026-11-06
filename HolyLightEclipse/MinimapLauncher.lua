-- Independent minimap launcher. Never modifies the game's minimap, its mask,
-- zoom handlers, frame position, or the user's existing minimap skin.
local H=HLE;
local WHITE="Interface\\AddOns\\HolyLightEclipse\\Media\\White.tga";
local function SetLauncherPosition(f)
    if not f or not Minimap then return; end
    local p=H.Table(HLE_DB and HLE_DB.launcherPosition);
    local dx=H.Number(p.x) or -97;
    local dy=H.Number(p.y) or 64;
    f:ClearAllPoints();
    f:SetPoint("CENTER",Minimap,"CENTER",dx,dy);
end
function H.BuildMinimapLauncher()
    if H.launcher or not Minimap then return; end
    local f=CreateFrame("Frame","HLEMinimapLauncher",UIParent);
    f:SetWidth(30);f:SetHeight(30);f:SetFrameStrata("HIGH");
    f:EnableMouse(true);f:SetMovable(true);f:RegisterForDrag("LeftButton");
    local shadow=f:CreateTexture(nil,"BACKGROUND");shadow:SetTexture(WHITE);
    shadow:SetAllPoints(f);shadow:SetVertexColor(0.025,0.013,0.045,0.97);
    local gold=f:CreateTexture(nil,"ARTWORK");gold:SetTexture(WHITE);
    gold:SetPoint("TOPLEFT",f,"TOPLEFT",2,-2);
    gold:SetWidth(26);gold:SetHeight(26);
    gold:SetVertexColor(0.56,0.32,0.67,0.92);
    local top=f:CreateTexture(nil,"OVERLAY");top:SetTexture(WHITE);
    top:SetPoint("TOPLEFT",f,"TOPLEFT",0,0);top:SetWidth(30);top:SetHeight(2);
    top:SetVertexColor(0.96,0.75,0.37,1);
    local bottom=f:CreateTexture(nil,"OVERLAY");bottom:SetTexture(WHITE);
    bottom:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",0,0);bottom:SetWidth(30);bottom:SetHeight(2);
    bottom:SetVertexColor(0.96,0.75,0.37,1);
    local crest=f:CreateFontString(nil,"OVERLAY");
    crest:SetFont("Fonts\\FRIZQT__.TTF",16,"OUTLINE");
    crest:SetAllPoints(f);crest:SetJustifyH("CENTER");
    crest:SetTextColor(1,0.88,0.60);crest:SetText("H");
    f:SetScript("OnEnter",function()
        if GameTooltip then
            GameTooltip:SetOwner(this,"ANCHOR_LEFT");
            GameTooltip:SetText("Holy Light × Eclipse");
            GameTooltip:AddLine(H.L("open_settings"),0.96,0.81,0.50);
            GameTooltip:AddLine(H.L("move_icon"),0.75,0.64,0.91);
            GameTooltip:Show();
        end
    end);
    f:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide(); end end);
    f:SetScript("OnDragStart",function()
        if type(IsShiftKeyDown)=="function" and IsShiftKeyDown() then
            this.hleDrag=true; this:StartMoving();
        end
    end);
    f:SetScript("OnDragStop",function()
        if not this.hleDrag then return; end
        this:StopMovingOrSizing();this.hleDrag=false;this.hleSkipClick=true;
        local x,y=this:GetCenter();
        local mx,my=Minimap:GetCenter();
        local scale=H.Number(this:GetEffectiveScale());
        local mapScale=H.Number(Minimap:GetEffectiveScale());
        if x and y and mx and my and scale and mapScale and scale>0 then
            HLE_DB.launcherPosition={
                x=math.max(-300,math.min(300,(x*scale-mx*mapScale)/scale)),
                y=math.max(-300,math.min(300,(y*scale-my*mapScale)/scale))
            };
        end
        SetLauncherPosition(this);
    end);
    f:SetScript("OnMouseUp",function()
        if arg1~="LeftButton" then return; end
        if this.hleDrag or this.hleSkipClick then this.hleSkipClick=nil;return; end
        if H.ToggleSettings then H.ToggleSettings(); end
    end);
    H.launcher=f;SetLauncherPosition(f);
    H.UpdateMinimapLauncher();
end
function H.UpdateMinimapLauncher()
    if not H.launcher then return; end
    if HLE_DB and HLE_DB.showLauncher==false then H.launcher:Hide();
    else H.launcher:Show(); end
end
function H.ResetLauncherPosition()
    if not HLE_DB then return; end
    HLE_DB.launcherPosition=nil;
    if H.launcher then SetLauncherPosition(H.launcher); end
end

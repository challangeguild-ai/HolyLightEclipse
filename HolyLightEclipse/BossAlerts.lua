-- Native banner-driven, one-shot boss warnings. This does not suppress or alter
-- non-boss banners and never infers a boss appearance from a cached schedule.
local H=HLE;
local WHITE="Interface\\AddOns\\HolyLightEclipse\\Media\\White.tga";
local registered,lastId,started,untilTime,activeKind=false,nil,false,nil,nil;
local pendingBoss,currentBoss=nil,nil;
local function Hide()
    if H.bossWarning then H.bossWarning:Hide(); end
    untilTime=nil; activeKind=nil;
end
function H.ResetBossAlerts()
    Hide(); pendingBoss=nil; currentBoss=nil;
    lastId=H.Number(H.Table(AZS_BANNER).id);
end
function H.HideThreatNotice()
    if activeKind=="threat" then Hide(); end
end
function H.BuildBossAlerts()
    local f=CreateFrame("Frame","HLEBossWarning",UIParent); f:SetWidth(330); f:SetHeight(66);
    f:SetPoint("TOP",UIParent,"TOP",0,-190); f:SetFrameStrata("HIGH"); f:EnableMouse(false);
    local bg=f:CreateTexture(nil,"BACKGROUND"); bg:SetTexture(WHITE);
    bg:SetPoint("TOPLEFT",f,"TOPLEFT",0,0); bg:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",0,0);
    bg:SetVertexColor(0.06,0.028,0.09,0.90);
    local border=f:CreateTexture(nil,"OVERLAY"); border:SetTexture(WHITE);
    border:SetWidth(330); border:SetHeight(2); border:SetPoint("TOP",f,"TOP",0,0);
    border:SetVertexColor(0.96,0.72,0.35,1);
    f.title=f:CreateFontString(nil,"OVERLAY"); f.title:SetFont("Fonts\\FRIZQT__.TTF",16,"OUTLINE");
    f.title:SetPoint("TOP",f,"TOP",0,-8); f.title:SetWidth(310); f.title:SetHeight(21);
    f.title:SetText("BOSS INCOMING"); f.title:SetJustifyH("CENTER"); f.title:SetTextColor(1,0.18,0.22);
    f.name=f:CreateFontString(nil,"OVERLAY"); f.name:SetFont("Fonts\\FRIZQT__.TTF",12,"OUTLINE");
    f.name:SetPoint("TOP",f,"TOP",0,-34); f.name:SetWidth(310); f.name:SetHeight(22);
    f.name:SetJustifyH("CENTER"); f.name:SetTextColor(1,0.35,0.38);
    f:Hide(); H.bossWarning=f;
end
local function RenderBoss(banner)
    if not H.bossWarning or not HLE_DB or HLE_DB.bossAlerts==false then return; end
    local now=H.Number(H.Call("GetTime"));
    activeKind="boss"; currentBoss=banner;
    H.bossWarning.title:SetText(banner.kind=="finalboss" and
        (H.L and H.L("final_boss") or "FINAL BOSS") or
        (H.L and H.L("incoming_boss") or "BOSS INCOMING"));
    H.bossWarning.name:SetText(H.Text(banner.name,H.Text(banner.text,"Encounter")));
    if H.LocalizedFont then H.LocalizedFont(H.bossWarning.title,16); H.LocalizedFont(H.bossWarning.name,12); end
    untilTime=now and now+2.4 or nil;
    H.bossWarning:SetAlpha(1); H.bossWarning:Show();
end
-- Reuse the boss warning's CENTER location rather than stacking alert overlays.
-- Threats take priority until their short duration ends.
function H.ShowThreatNotice(title,detail,duration)
    if not HLE_DB or not HLE_DB.enabled or HLE_DB.threatAlerts==false or
        H.suspended or not H.bossWarning then return false; end
    local now=H.Number(H.Call("GetTime"));
    if not now then return false; end
    if activeKind=="boss" and untilTime and now<untilTime and currentBoss then
        pendingBoss=currentBoss;
    end
    H.bossWarning.title:SetText(H.Text(title,"DANGER"));
    if H.LocalizedFont then H.LocalizedFont(H.bossWarning.title,16); H.LocalizedFont(H.bossWarning.name,12); end
    H.bossWarning.name:SetText(H.Text(detail,""));
    activeKind="threat"; untilTime=now+(H.Number(duration) or 2.5);
    H.bossWarning:SetAlpha(1); H.bossWarning:Show();
    return true;
end
function H.BossBannerNotice(banner)
    if type(banner)~="table" or (banner.kind~="boss" and banner.kind~="finalboss") then return; end
    if not HLE_DB or not HLE_DB.enabled or not HLE_DB.bossAlerts or H.suspended then return; end
    if H.Number(banner.id) then
        if lastId and banner.id<=lastId then return; end
        lastId=banner.id;
    end
    if not H.bossWarning then return; end
    local now=H.Number(H.Call("GetTime"));
    if activeKind=="threat" and now and untilTime and now<untilTime then
        pendingBoss=banner; return;
    end
    pendingBoss=nil; RenderBoss(banner);
end
function H.StartBossAlerts()
    if registered then return; end
    lastId=H.Number(H.Table(AZS_BANNER).id);
    if type(AZS_RegisterBannerHandler)=="function" then
        local ok=pcall(AZS_RegisterBannerHandler,H.BossBannerNotice);
        registered=ok;
    end
    started=true;
end
function H.StopBossAlerts()
    if registered and type(AZS_UnregisterBannerHandler)=="function" then
        pcall(AZS_UnregisterBannerHandler,H.BossBannerNotice);
    end
    registered=false; started=false; H.ResetBossAlerts();
end
function H.UpdateBossAlerts(s)
    if not H.bossWarning then return; end
    if not HLE_DB.enabled or H.suspended or not s.active or
        (s.playerDead and not s.coopDown) then
        H.StopBossAlerts(); return;
    end
    if HLE_DB.bossAlerts==false then
        if registered and type(AZS_UnregisterBannerHandler)=="function" then
            pcall(AZS_UnregisterBannerHandler,H.BossBannerNotice);
        end
        registered=false; started=false; pendingBoss=nil;
    else
        if not started then H.StartBossAlerts(); end
        if not registered then
            local banner=H.Table(AZS_BANNER); local id=H.Number(banner.id);
            if id and (not lastId or id>lastId) then H.BossBannerNotice(banner); end
        end
    end
    if H.bossWarning:IsShown() then
        local now=H.Number(H.Call("GetTime"));
        if not now or not untilTime or now>=untilTime then Hide();
        elseif untilTime-now<0.4 then H.bossWarning:SetAlpha((untilTime-now)/0.4);
        else H.bossWarning:SetAlpha(1); end
    end
    if HLE_DB.bossAlerts~=false and not H.bossWarning:IsShown() and pendingBoss then
        -- A genuine boss arrival may have occurred during a higher-priority
        -- low-HP warning. Display it afterwards, never on top of the danger.
        local boss=pendingBoss; pendingBoss=nil; RenderBoss(boss);
    end
end

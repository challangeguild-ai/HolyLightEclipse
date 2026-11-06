local H = HLE;
local frames = {};
local noticeHooks = {};
local promptRegions = {};
local scanCursor, scanDelay = nil, 0;
H.promptMatches, H.promptScanned = 0, 0;
local parts = {"clock", "tally", "bosses", "build", "meter", "banners"};
local function IsBeginNotice(text)
    if type(text) ~= "string" then return false; end
    text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "");
    text = string.gsub(text, "|r", "");
    text = string.lower(text);
    text = string.gsub(text, "^%s+", "");
    text = string.gsub(text, "[%s%.!]+$", "");
    return text == "move to begin";
end
local function ScanBeginNotice()
    if type(EnumerateFrames) ~= "function" then return; end
    if scanDelay > 0 then scanDelay = scanDelay - 1; return; end
    for i = 1, 200 do
        local ok, frame = pcall(EnumerateFrames, scanCursor);
        if not ok or not frame then scanCursor = nil; scanDelay = 10; return; end
        if frame == scanCursor then scanCursor = nil; scanDelay = 10; return; end
        scanCursor = frame; H.promptScanned = H.promptScanned + 1;
        local owned, parent = false, frame;
        for j = 1, 12 do
            if not parent then break; end
            if parent == H.main or parent == H.top or parent == H.meter then owned = true; break; end
            local name;
            if type(parent.GetName) == "function" then
                local success, value = pcall(parent.GetName, parent); if success then name = value; end
            end
            if type(name) == "string" and string.find(name, "^ChatFrame") then owned = true; break; end
            if type(parent.GetParent) ~= "function" then break; end
            local success, value = pcall(parent.GetParent, parent);
            if not success or value == parent then break; end
            parent = value;
        end
        if not owned and type(frame.GetRegions) == "function" then
            local success, regions = pcall(function() return {frame:GetRegions()}; end);
            if success then
                for j = 1, table.getn(regions) do
                    local region = regions[j];
                    if region ~= H.zone and region and type(region.GetText) == "function" and type(region.SetText) == "function" then
                        local read, text = pcall(region.GetText, region);
                        if read and IsBeginNotice(text) then
                            local data = promptRegions[region];
                            if not data then
                                local original = region.SetText;
                                data = {original=original};
                                local entry = data;
                                data.wrapper = function(self, value)
                                    if HLE_DB.enabled and HLE_DB.replaceNative and IsBeginNotice(value) then
                                        entry.suppressed = value; return original(self, "");
                                    end
                                    entry.suppressed = nil; return original(self, value);
                                end;
                                local installed = pcall(function() region.SetText = data.wrapper; end);
                                if installed then promptRegions[region] = data; H.promptMatches = H.promptMatches + 1; end
                            end
                            data.suppressed = text; pcall(data.original, region, "");
                        end
                    end
                end
            end
        end
    end
end
local function SuppressBeginNotice()
    local names = {"RaidBossEmoteFrame", "RaidWarningFrame", "UIErrorsFrame"};
    for i = 1, table.getn(names) do
        local name = names[i]; local frame = getglobal(name);
        if frame and type(frame.AddMessage) == "function" and not noticeHooks[name] then
            local original = frame.AddMessage;
            local wrapper = function(self, text, r, g, b, a, hold)
                if HLE_DB.enabled and HLE_DB.replaceNative and IsBeginNotice(text) then return; end
                return original(self, text, r, g, b, a, hold);
            end;
            noticeHooks[name] = {frame=frame, original=original, wrapper=wrapper};
            frame.AddMessage = wrapper;
        end
        -- Also remove a matching FontString delivered before addon initialization.
        if frame and type(frame.GetRegions) == "function" then
            local regions = {frame:GetRegions()};
            for j = 1, table.getn(regions) do
                local region = regions[j];
                if region and type(region.GetText) == "function" and type(region.SetText) == "function" then
                    if IsBeginNotice(region:GetText()) then region:SetText(""); end
                end
            end
        end
    end
end
local function Boolean(v)
    if v == true or v == 1 or v == "1" then return true; end
    if v == false or v == 0 or v == "0" then return false; end
    return nil;
end
function H.RestoreNative(keepBosses)
    if H.ReleaseActionButtons then H.ReleaseActionButtons(); end
    for region, data in pairs(promptRegions) do
        if region.SetText == data.wrapper then
            region.SetText = data.original;
            local ok, text = pcall(region.GetText, region);
            if ok and text == "" and data.suppressed then pcall(data.original, region, data.suppressed); end
        end
    end
    promptRegions = {}; scanCursor = nil; scanDelay = 0;
    for name, data in pairs(noticeHooks) do
        if data.frame.AddMessage == data.wrapper then data.frame.AddMessage = data.original; end
    end
    noticeHooks = {};
    local backup = H.Table(HLE_DB.nativeBackup);
    for part, shown in pairs(backup) do
        if type(AZS_SetHudShown) == "function" and not (keepBosses and part=="bosses") then
            local ok = pcall(AZS_SetHudShown, part, shown);
            if ok then backup[part] = nil; end
        end
    end
    HLE_DB.nativeBackup = backup;
    for name, data in pairs(frames) do
        local f = getglobal(name);
        if f then
            if data.alpha and f.SetAlpha then f:SetAlpha(data.alpha); end
            if data.shown then f:Show(); end
        end
    end
    frames = {};
end
function H.TakeOver(s)
    local preparing = s.phase == "ready";
    if not HLE_DB.enabled or not HLE_DB.replaceNative or not s.hasAPI then H.RestoreNative(); return; end
    if not s.active and not preparing then
        -- Keep ownership across death/end screens: restoring the native boss HUD
        -- here can redisplay its retained encounter from the previous life/run.
        H.RestoreNative(true);
        local current=Boolean(H.Call("AZS_IsHudShown","bosses"));
        if current~=nil and type(AZS_SetHudShown)=="function" then
            if HLE_DB.nativeBackup.bosses==nil then HLE_DB.nativeBackup.bosses=current; end
            if current then H.Call("AZS_SetHudShown","bosses",false); end
        end
        return;
    end
    SuppressBeginNotice();
    if preparing then ScanBeginNotice(); end
    HLE_DB.nativeBackup = H.Table(HLE_DB.nativeBackup);
    local wanted = {clock=s.time ~= nil or preparing, tally=preparing or (s.kills ~= nil and s.gold ~= nil and s.cache ~= nil),
        bosses=type(AZS_GetBosses) == "function", build=H.hasSkills == true or H.ownsSkillBar == true, meter=type(AZS_GetMeter) == "function" and (s.dps ~= nil or preparing),
        banners=HLE_DB.quietBanners~=false and HLE_DB.bossAlerts~=false};
    for i = 1, table.getn(parts) do
        local part = parts[i];
        if wanted[part] and type(AZS_IsHudShown) == "function" and type(AZS_SetHudShown) == "function" then
            if HLE_DB.nativeBackup[part] == nil then HLE_DB.nativeBackup[part] = Boolean(H.Call("AZS_IsHudShown", part)); end
            if HLE_DB.nativeBackup[part] ~= nil and Boolean(H.Call("AZS_IsHudShown", part)) ~= false then
                H.Call("AZS_SetHudShown", part, false);
            end
        elseif HLE_DB.nativeBackup[part] ~= nil and type(AZS_SetHudShown) == "function" then
            H.Call("AZS_SetHudShown", part, HLE_DB.nativeBackup[part]); HLE_DB.nativeBackup[part] = nil;
        end
    end
    local wantedFrames = {PlayerFrame=s.player.hp ~= nil, TargetFrame=true, MainMenuBar=H.hasSkills == true or H.ownsSkillBar == true};
    for name, hide in pairs(wantedFrames) do
        local f = getglobal(name);
        if f and hide then
            if not frames[name] then
                frames[name] = {shown=f.IsShown and f:IsShown(), alpha=f.GetAlpha and f:GetAlpha()};
            end
            -- Alpha also suppresses native OnShow refreshes without replacing scripts.
            if f.SetAlpha then f:SetAlpha(0); end
            f:Hide();
        elseif f and frames[name] then
            local data = frames[name];
            if data.alpha and f.SetAlpha then f:SetAlpha(data.alpha); end
            if data.shown then f:Show(); end
            frames[name] = nil;
        end
    end
end

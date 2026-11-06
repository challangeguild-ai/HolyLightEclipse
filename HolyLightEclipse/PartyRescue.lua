-- Co-op rescue guidance. Uses native downed-ally positions only; never invents
-- a corpse location from a unit's map dot or its last known position.
-- Written for the 1.12 / Lua 5.0 subset used by Azeroth Survivors.
local H = HLE;
local seen, sampled, lastCheck = {}, false, nil;
local GOLD = "Interface\\AddOns\\HolyLightEclipse\\Media\\White.tga";

local function Flag(value) return value == true or value == 1; end

local function Hidden()
    if H.rescueGuide then H.rescueGuide:Hide(); end
end

function H.ResetRescue()
    seen, sampled, lastCheck = {}, false, nil;
    Hidden();
end

function H.BuildRescue()
    local frame = CreateFrame("Frame", "HLERescueGuide", UIParent);
    frame:SetWidth(274); frame:SetHeight(97);
    -- Keep rescue information on the left, clear of native center-screen banners.
    -- Center-left with an upward offset avoids the existing equipment panel.
    frame:SetPoint("LEFT", UIParent, "LEFT", 22, 185);
    frame:SetFrameStrata("HIGH"); frame:EnableMouse(false);

    local bg = frame:CreateTexture(nil, "BACKGROUND");
    bg:SetTexture(GOLD); bg:SetAllPoints(frame);
    bg:SetVertexColor(0.035, 0.022, 0.065, 0.93);

    local trim = frame:CreateTexture(nil, "BORDER");
    trim:SetTexture(GOLD); trim:SetWidth(274); trim:SetHeight(2);
    trim:SetPoint("TOP", frame, "TOP", 0, 0);
    trim:SetVertexColor(0.98, 0.73, 0.33, 1);

    local title = frame:CreateFontString(nil, "OVERLAY");
    title:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE");
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -9);
    title:SetWidth(250); title:SetHeight(20);
    title:SetTextColor(0.99, 0.80, 0.44);
    title:SetText("ALLIES DOWN");
    frame.title = title;

    frame.names = {};
    for i=1,4 do
        local name=frame:CreateFontString(nil, "OVERLAY");
        name:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE");
        name:SetPoint("TOPLEFT", frame, "TOPLEFT", 13, -34-(i-1)*19);
        name:SetWidth(248); name:SetHeight(18);
        name:SetJustifyH("LEFT"); name:SetTextColor(1, 0.25, 0.28);
        name:Hide(); frame.names[i]=name;
    end

    local arrow = frame:CreateFontString(nil, "OVERLAY");
    arrow:SetFont("Fonts\\FRIZQT__.TTF", 25, "OUTLINE");
    arrow:SetWidth(38); arrow:SetHeight(27);
    arrow:SetJustifyH("CENTER"); arrow:SetTextColor(1, 0.83, 0.36);
    frame.arrow = arrow;

    local detail = frame:CreateFontString(nil, "OVERLAY");
    detail:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE");
    detail:SetWidth(210); detail:SetHeight(22);
    detail:SetTextColor(1, 0.94, 0.80);
    frame.detail = detail;

    frame:Hide();
    H.rescueGuide = frame;
end
local function FallbackParty()
    local list = {};
    local count = H.Number(H.Call("GetNumPartyMembers")) or 0;
    for i = 1, math.min(4, math.max(0, math.floor(count))) do
        local unit = "party"..i;
        if H.Exists(unit) then
            local connected = H.Call("UnitIsConnected", unit);
            local hp, max = H.Pair(H.Call("UnitHealth", unit), H.Call("UnitHealthMax", unit));
            local dead = Flag(H.Call("UnitIsDeadOrGhost", unit)) or (hp and hp <= 0);
            if connected ~= false and connected ~= 0 and dead then
                table.insert(list, {id = unit, name = H.Text(H.Call("UnitName", unit), "Teammate"),
                    positionAvailable = false});
            end
        end
    end
    return list;
end

local function DownedSnapshot()
    if type(AZS_GetDownedPartyMembers) ~= "function" then return FallbackParty(); end
    local ok, list, err = pcall(AZS_GetDownedPartyMembers);
    -- A failed native snapshot is unknown, NOT proof that everyone revived.
    if not ok or type(list) ~= "table" or err ~= nil then return nil; end
    local result = {};
    for i = 1, math.min(4, table.getn(list)) do
        local ally = list[i];
        if type(ally) == "table" and type(ally.id) == "string" and ally.id ~= "" then
            table.insert(result, ally);
        end
    end
    return result;
end

local function MatchedDistance(ally, player)
    if not Flag(ally.positionAvailable) or type(player) ~= "table" or player.apiVersion ~= 1 then return nil; end
    if type(player.spaceId) ~= "string" or player.spaceId == "" or
        type(ally.spaceId) ~= "string" or ally.spaceId ~= player.spaceId or
        not H.Number(player.mapId) or ally.mapId ~= player.mapId or
        ally.runId ~= player.runId then return nil; end
    local px, py, ax, ay = H.Number(player.x), H.Number(player.y), H.Number(ally.x), H.Number(ally.y);
    if not px or not py or not ax or not ay then return nil; end
    local north, west = ax-px, ay-py;
    local squared = north*north + west*west;
    if not H.Number(squared) or squared < 0 then return nil; end
    return math.sqrt(squared), north, west;
end

local function Direction(north, west, facing)
    local forward = north*math.cos(facing) + west*math.sin(facing);
    local left = west*math.cos(facing) - north*math.sin(facing);
    local side = math.abs(left);
    -- Eight sectors without atan2, which is not guaranteed in the old client.
    if forward >= 0 then
        if side <= forward*0.41421356237 then return "↑", "AHEAD"; end
        if side >= forward*2.41421356237 then
            if left >= 0 then return "←", "LEFT"; end
            return "→", "RIGHT";
        end
        if left >= 0 then return "↖", "AHEAD LEFT"; end
        return "↗", "AHEAD RIGHT";
    end
    local behind = -forward;
    if side <= behind*0.41421356237 then return "↓", "BEHIND"; end
    if side >= behind*2.41421356237 then
        if left >= 0 then return "←", "LEFT"; end
        return "→", "RIGHT";
    end
    if left >= 0 then return "↙", "BEHIND LEFT"; end
    return "↘", "BEHIND RIGHT";
end

local function Announce(name)
    local message = "ALLY DOWN: "..name;
    if DEFAULT_CHAT_FRAME and type(DEFAULT_CHAT_FRAME.AddMessage) == "function" then
        pcall(DEFAULT_CHAT_FRAME.AddMessage, DEFAULT_CHAT_FRAME, "|cffffc453[Holy Light]|r "..message);
    end
    -- Avoid another center-screen warning: the persistent rescue panel owns this notice.
    if type(PlaySound) == "function" then pcall(PlaySound, "RaidWarning"); end
end

function H.UpdateRescue(s)
    if not H.rescueGuide then return; end
    if not HLE_DB.enabled or HLE_DB.rescueArrow == false or H.suspended or
        not s.active or s.playerDead or H.lifeDead then Hidden(); return; end

    local now = H.Number(H.Call("GetTime"));
    if now and lastCheck and now >= lastCheck and now-lastCheck < 0.15 then return; end
    lastCheck = now;
    local down = DownedSnapshot();
    if not down then Hidden(); return; end

    local nextSeen = {};
    for i = 1, table.getn(down) do
        local a = down[i];
        nextSeen[a.id] = true;
        if sampled and not seen[a.id] then Announce(H.Text(a.name, "Teammate")); end
    end
    seen, sampled = nextSeen, true;

    if table.getn(down) == 0 then Hidden(); return; end
    local player = H.Call("AZS_GetPlayerPosition");
    local target, best, bestNorth, bestWest;
    for i = 1, table.getn(down) do
        local a = down[i];
        local distance, north, west = MatchedDistance(a, player);
        if distance and (not best or distance < best) then
            target, best, bestNorth, bestWest = a, distance, north, west;
        end
    end
    target = target or down[1];

    -- Every downed ally gets their own high-contrast RED name, not a +N counter.
    local count=math.min(4,table.getn(down));
    H.rescueGuide.title:SetText(count==1 and "ALLY DOWN" or "ALLIES DOWN");
    H.rescueGuide:SetHeight(78+count*19);
    for i=1,4 do
        local label=H.rescueGuide.names[i];
        if i<=count then
            local name=H.Text(down[i].name,"Teammate");
            label:SetText(name); label:Show();
        else label:SetText(""); label:Hide(); end
    end

    local arrowTop=-42-count*19;
    H.rescueGuide.arrow:ClearAllPoints();
    H.rescueGuide.arrow:SetPoint("TOPLEFT",H.rescueGuide,"TOPLEFT",12,arrowTop);
    H.rescueGuide.detail:ClearAllPoints();
    H.rescueGuide.detail:SetPoint("TOPLEFT",H.rescueGuide,"TOPLEFT",52,arrowTop-3);
    local facing = type(player)=="table" and H.Number(player.facing) or nil;
    if best and facing then
        if best < 1 then
            H.rescueGuide.arrow:Hide();
            H.rescueGuide.detail:SetText("AT REVIVE LOCATION");
        else
            local arrow, direction = Direction(bestNorth, bestWest, facing);
            H.rescueGuide.arrow:SetText(arrow); H.rescueGuide.arrow:Show();
            H.rescueGuide.detail:SetText(H.Short(best).." yd  |  "..direction);
        end
    else
        -- No guessed directional guidance when the exact corpse location is unknown.
        H.rescueGuide.arrow:Hide();
        H.rescueGuide.detail:SetText("POSITION UNAVAILABLE");
    end
    H.rescueGuide:Show();
end

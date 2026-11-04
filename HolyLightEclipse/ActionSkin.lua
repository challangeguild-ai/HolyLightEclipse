local H = HLE;
local owned = {};
local function Restore(data)
    local b = data.button;
    b:SetParent(data.parent); b:SetWidth(data.width); b:SetHeight(data.height);
    b:ClearAllPoints();
    for i = 1, table.getn(data.points) do b:SetPoint(unpack(data.points[i])); end
    if data.level and b.SetFrameLevel then b:SetFrameLevel(data.level); end
    if data.strata and b.SetFrameStrata then b:SetFrameStrata(data.strata); end
    for i = 1, table.getn(data.art) do data.art[i].region:SetAlpha(data.art[i].alpha); end
    if data.shown then b:Show(); else b:Hide(); end
end
function H.ReleaseActionCard(card)
    for name, data in pairs(owned) do
        if data.card == card then Restore(data); owned[name] = nil; end
    end
end
function H.ReleaseActionButtons()
    for name, data in pairs(owned) do Restore(data); end
    owned = {};
end
function H.BindActionButton(name, card)
    if type(name) ~= "string" or not HLE_DB.replaceNative then return false; end
    local b = getglobal(name);
    if not b or type(b.SetParent) ~= "function" or type(b.GetParent) ~= "function" or
        type(b.GetWidth) ~= "function" or type(b.GetPoint) ~= "function" or type(b.GetNumPoints) ~= "function" then return false; end
    if not owned[name] or owned[name].card ~= card then H.ReleaseActionCard(card); end
    if not owned[name] then
        local data = {button=b, card=card, parent=b:GetParent(), width=b:GetWidth(), height=b:GetHeight(),
            points={}, art={}, shown=b:IsShown(), level=b.GetFrameLevel and b:GetFrameLevel(), strata=b.GetFrameStrata and b:GetFrameStrata()};
        for i = 1, b:GetNumPoints() do table.insert(data.points, {b:GetPoint(i)}); end
        local art, suffixes = {}, {"Border", "HotKey", "Name"};
        for i = 1, 3 do
            local region = getglobal(name..suffixes[i]); if region then table.insert(art, region); end
        end
        if b.GetNormalTexture then local region = b:GetNormalTexture(); if region then table.insert(art, region); end end
        for i = 1, table.getn(art) do
            local region = art[i];
            if region and region.GetAlpha and region.SetAlpha then
                table.insert(data.art, {region=region, alpha=region:GetAlpha()}); region:SetAlpha(0);
            end
        end
        owned[name] = data;
    elseif owned[name].card ~= card then
        H.ReleaseActionCard(card); owned[name].card = card;
    end
    if owned[name].attachedCard ~= card or b:GetParent() ~= card then
        b:SetParent(card); b:SetWidth(54); b:SetHeight(54);
        if b.SetFrameStrata and card.GetFrameStrata then b:SetFrameStrata(card:GetFrameStrata()); end
        b:ClearAllPoints(); b:SetPoint("TOPLEFT",card,"TOPLEFT",5,-5);
        if b.SetFrameLevel and card.GetFrameLevel then
            b:SetFrameLevel(card:GetFrameLevel()+1);
            if card.overlay and card.overlay.SetFrameLevel then card.overlay:SetFrameLevel(card:GetFrameLevel()+3); end
        end
        owned[name].attachedCard = card;
    end
    b:Show(); return true;
end

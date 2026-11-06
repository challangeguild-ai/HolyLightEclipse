-- Independent collapsible panel headers. Never reflow or move a HUD panel.
-- Collapsed panels hide their original frame entirely and show a small sibling
-- anchored to its existing top-left point. Their saved positions are untouched.
local H=HLE;
local WHITE="Interface\\AddOns\\HolyLightEclipse\\Media\\White.tga";
local specs={};
local titles={meter="DAMAGE METER",gear="EQUIPMENT",loot="LOOT",effects="BUFFS / TIMERS",
    navigation="NAVIGATION",jewelry="JEWELRY / JOURNAL",party="PARTY"};
local enabledKeys={meter="showMeter",gear="showGear",loot="showLoot",effects="showEffects",
    navigation="showNavigation",jewelry="showJournal",party="showParty"};
local titleKeys={meter="damage_meter",gear="equipment_caps",loot="loot_caps",
    effects="effects_caps",navigation="navigation_caps",jewelry="jewelry_caps",party="party_caps"};

function H.BuildCollapsePanels(panels)
    for i=1,table.getn(panels) do
        local frame=panels[i]; local title=titles[frame.key];
        if title then
            local header=CreateFrame("Frame",nil,UIParent);
            header:SetWidth(math.min(240,frame:GetWidth())); header:SetHeight(25);
            header:SetFrameStrata("HIGH"); header:EnableMouse(true);
            header:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0);
            local bg=header:CreateTexture(nil,"BACKGROUND");
            bg:SetTexture(WHITE); bg:SetAllPoints(header);
            bg:SetVertexColor(0.045,0.028,0.074,0.96);
            local edge=header:CreateTexture(nil,"BORDER");
            edge:SetTexture(WHITE); edge:SetWidth(math.min(240,frame:GetWidth())); edge:SetHeight(2);
            edge:SetPoint("TOP",header,"TOP",0,0); edge:SetVertexColor(0.95,0.74,0.35,1);
            local label=header:CreateFontString(nil,"OVERLAY");
            label:SetFont("Fonts\\FRIZQT__.TTF",11,"OUTLINE");
            label:SetPoint("LEFT",header,"LEFT",9,0); label:SetWidth(math.min(190,frame:GetWidth()-36));
            label:SetHeight(20); label:SetJustifyH("LEFT"); label:SetTextColor(1,0.88,0.67);
            label:SetText(title);
            local arrow=header:CreateFontString(nil,"OVERLAY");
            arrow:SetFont("Fonts\\FRIZQT__.TTF",16,"OUTLINE");
            arrow:SetPoint("RIGHT",header,"RIGHT",-9,0); arrow:SetWidth(18);
            arrow:SetHeight(20); arrow:SetTextColor(0.96,0.74,0.36); arrow:SetText("+");
            local open=CreateFrame("Frame",nil,frame);
            open:SetWidth(22); open:SetHeight(21);
            open:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-3,-3); open:EnableMouse(true);
            local down=open:CreateFontString(nil,"OVERLAY");
            down:SetFont("Fonts\\FRIZQT__.TTF",16,"OUTLINE");
            down:SetAllPoints(open); down:SetJustifyH("CENTER");
            down:SetTextColor(1,0.79,0.42); down:SetText("-");
            header:SetScript("OnMouseUp",function()
                if arg1=="LeftButton" then H.ToggleCollapse(frame.key); end
            end);
            open:SetScript("OnMouseUp",function()
                if arg1=="LeftButton" then H.ToggleCollapse(frame.key); end
            end);
            header:Hide(); specs[frame.key]={frame=frame,header=header,title=title,
                localeKey=titleKeys[frame.key],label=label};
        end
    end
end
function H.RefreshCollapseLabels()
    for _,spec in pairs(specs) do
        spec.title=H.L and H.L(spec.localeKey) or spec.title;
        spec.label:SetText(spec.title);
    end
end
function H.ToggleCollapse(key)
    if not specs[key] then return; end
    HLE_DB.collapsed=H.Table(HLE_DB.collapsed);
    HLE_DB.collapsed[key]=not (HLE_DB.collapsed[key]==true);
    local spec=specs[key];
    if not HLE_DB.collapsed[key] then spec.header:Hide(); spec.frame:Show(); end
    H.UpdateCollapsedPanels(H.Read());
end
function H.UpdateCollapsedPanels(s)
    if not HLE_DB then return; end
    HLE_DB.collapsed=H.Table(HLE_DB.collapsed);
    for key,spec in pairs(specs) do
        local f,h=spec.frame,spec.header;
        local display=HLE_DB.enabled and not H.suspended and HLE_DB[enabledKeys[key]]==true;
        if key=="party" then
            local count=H.Number(H.Call("GetNumPartyMembers")) or 0;
            display=display and s and s.active and count>0;
        end
        if HLE_DB.collapsed[key]==true then
            f:Hide();
            if display then
                h:SetScale(HLE_DB.scale or 1);
                if key=="meter" and s and s.active then
                    local meter=H.ReadMeter and H.ReadMeter(s) or {};
                    local rate=H.Number(meter.rate) or H.Number(s.dps);
                    local unit=meter.healing and "HPS" or "DPS";
                    spec.label:SetText(unit.."  "..H.Short(rate));
                elseif key=="party" then
                    spec.label:SetText("PARTY  "..H.Short(H.Call("GetNumPartyMembers")).." MEMBERS");
                else spec.label:SetText(spec.title); end
                h:Show();
            else h:Hide(); end
        else h:Hide(); end
    end
end
function H.ClearCollapsedPanels()
    for _,spec in pairs(specs) do spec.header:Hide(); end
end

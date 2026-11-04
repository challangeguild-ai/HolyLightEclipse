local H=HLE;
local MEDIA="Interface\\AddOns\\HolyLightEclipse\\Media\\";
local slots={
    {key="Finger0Slot",label="RING 1"},{key="Finger1Slot",label="RING 2"},
    {key="NeckSlot",label="NECK"},{key="Trinket0Slot",label="TRINKET 1"},{key="Trinket1Slot",label="TRINKET 2"}
};
local widgets,age={},0;
local vanillaSlots={11,12,2,13,14};
local function Text(parent,size,x,y,width)
    local t=parent:CreateFontString(nil,"OVERLAY"); t:SetFont("Fonts\\FRIZQT__.TTF",size,"OUTLINE");
    t:SetWidth(width); t:SetHeight(size+5); t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);
    t:SetJustifyH("LEFT"); t:SetTextColor(0.94,0.81,0.57); return t;
end
local function Hover(widget)
    if not widget.equipped or not widget.slotId or not GameTooltip or not GameTooltip.SetInventoryItem then return; end
    local ok,err=pcall(function()
        GameTooltip:SetOwner(widget,"ANCHOR_TOP"); GameTooltip:SetInventoryItem("player",widget.slotId); GameTooltip:Show();
    end);
    if ok then H.equipmentHover=widget;
    else H.errors.EquipmentTooltip=tostring(err); if GameTooltip.Hide then pcall(GameTooltip.Hide,GameTooltip); end end
end
function H.BuildEquipment(parent)
    local bg=parent:CreateTexture(nil,"BACKGROUND"); bg:SetTexture(MEDIA.."White.tga");
    bg:SetWidth(240); bg:SetHeight(136); bg:SetPoint("TOPLEFT",parent,"TOPLEFT",0,0); bg:SetVertexColor(0.045,0.025,0.065,0.80);
    local line=parent:CreateTexture(nil,"BORDER"); line:SetTexture(MEDIA.."White.tga");
    line:SetWidth(240); line:SetHeight(1); line:SetPoint("TOPLEFT",parent,"TOPLEFT",0,0); line:SetVertexColor(0.85,0.66,0.33,1);
    H.equipmentTitle=Text(parent,11,12,-8,216); H.equipmentTitle:SetText("JEWELRY");
    for i=1,5 do
        local w=CreateFrame("Frame",nil,parent); w:SetWidth(36); w:SetHeight(36);
        w:SetPoint("TOPLEFT",parent,"TOPLEFT",14+(i-1)*44,-31); w:EnableMouse(true);
        w.icon=w:CreateTexture(nil,"ARTWORK"); w.icon:SetWidth(30); w.icon:SetHeight(30); w.icon:SetPoint("TOPLEFT",w,"TOPLEFT",3,-3);
        w.rim=w:CreateTexture(nil,"OVERLAY"); w.rim:SetTexture(MEDIA.."Skill04.tga"); w.rim:SetWidth(36); w.rim:SetHeight(36); w.rim:SetPoint("TOPLEFT",w,"TOPLEFT",0,0);
        w.empty=Text(w,9,5,-12,26); w.empty:SetJustifyH("CENTER");
        w.label=Text(parent,7,12+(i-1)*44,-71,42); w.label:SetText(slots[i].label); w.label:SetJustifyH("CENTER");
        w:SetScript("OnEnter",function() Hover(this); end);
        w:SetScript("OnLeave",function() if H.equipmentHover==this then H.ClearEquipmentTooltip(); end end);
        widgets[i]=w;
    end
    H.equipmentStats=Text(parent,12,12,-96,216); H.equipmentStats:SetHeight(34);
    H.equipmentStats:SetText("Hover an item for its stats");
end
function H.ClearEquipmentTooltip()
    if H.equipmentHover and GameTooltip then GameTooltip:Hide(); end
    H.equipmentHover=nil;
end
function H.ClearEquipment()
    H.ClearEquipmentTooltip();
    for i=1,table.getn(widgets) do
        local w=widgets[i]; w.icon:Hide(); w.slotId=nil; w.equipped=false; w.empty:SetText("");
    end
end
local function Percent(value,bonus)
    value=H.Number(value); if not value then return "--"; end
    return string.format(bonus and "%+.0f%%" or "%.0f%%",(value-(bonus and 1 or 0))*100);
end
function H.UpdateEquipment(delta,s)
    if not HLE_DB.enabled or not HLE_DB.showGear or H.suspended then H.ClearEquipment(); return; end
    age=age+delta; if age<0.2 then return; end; age=0;
    if H.Exists("player")~=true or type(GetInventoryItemTexture)~="function" then
        H.ClearEquipment(); H.equipmentStats:SetText("Equipment API unavailable"); return;
    end
    local used={};
    for i=1,5 do
        local w=widgets[i]; local id=H.Number(H.Call("GetInventorySlotInfo",slots[i].key)) or vanillaSlots[i];
        if id and id>0 and not used[id] then
            used[id]=true; w.slotId=id;
            local path=H.Call("GetInventoryItemTexture","player",id);
            w.equipped=type(path)=="string" and path~="";
            if w.equipped then w.icon:SetTexture(path); w.icon:Show(); w.empty:SetText("");
            else w.icon:Hide(); w.empty:SetText(i==3 and "N" or (i<=2 and "R" or "T")); end
            local quality=H.Number(H.Call("GetInventoryItemQuality","player",id));
            local colors={[0]={0.6,0.6,0.6},[1]={0.95,0.95,0.95},[2]={0.3,0.95,0.3},[3]={0.3,0.55,1},[4]={0.76,0.4,1},[5]={1,0.60,0.20}};
            w.rim:SetVertexColor(unpack(w.equipped and colors[quality] or {1,0.88,0.65}));
            if H.equipmentHover==w then if w.equipped then Hover(w); else H.ClearEquipmentTooltip(); end end
        else
            if H.equipmentHover==w then H.ClearEquipmentTooltip(); end
            w.slotId=nil; w.equipped=false; w.icon:Hide(); w.empty:SetText("--");
        end
    end
    if s.active and type(AZS_STATS)=="table" then
        H.equipmentStats:SetText("RUN TOTAL  DMG "..Percent(AZS_STATS.dmg,true).."\nCRIT "..Percent(AZS_STATS.crit).."   DR "..Percent(AZS_STATS.arm));
    else H.equipmentStats:SetText("Hover an item for its stats"); end
end
H.equipmentWidgets=widgets;

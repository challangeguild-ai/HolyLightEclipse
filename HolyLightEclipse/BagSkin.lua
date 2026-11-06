-- Non-invasive inventory chrome. Native container buttons, drag/drop, tooltips and
-- bag placement stay untouched. Uses only live ContainerFrame* objects.
local H=HLE;
local WHITE="Interface\\AddOns\\HolyLightEclipse\\Media\\White.tga";
local containers,elapsed={},0;
local GOLD={0.90,0.69,0.35};
local DIM={0.38,0.28,0.48};
local qualities={
    [0]={0.57,0.55,0.57},[1]={0.77,0.72,0.83},[2]={0.35,0.83,0.37},
    [3]={0.35,0.57,1},[4]={0.76,0.40,1},[5]={1,0.59,0.24},
};
local function HideDecorations(record)
    if record then
        for i=1,table.getn(record.all) do record.all[i]:Hide(); end
        for _,slot in pairs(record.items) do
            for j=1,table.getn(slot.edges) do slot.edges[j]:Hide(); end
        end
    end
end
function H.ClearBagSkin()
    for frame,record in pairs(containers) do HideDecorations(record); end
end
local function Decorate(frame)
    local record=containers[frame]; if record then return record; end
    record={all={},items={}}; containers[frame]=record;
    local bg=frame:CreateTexture(nil,"BACKGROUND"); bg:SetTexture(WHITE);
    bg:SetPoint("TOPLEFT",frame,"TOPLEFT",3,-3);
    bg:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-3,3);
    bg:SetVertexColor(0.07,0.037,0.11,0.78); table.insert(record.all,bg);
    for side=1,4 do
        local edge=frame:CreateTexture(nil,"OVERLAY"); edge:SetTexture(WHITE);
        edge:SetVertexColor(GOLD[1],GOLD[2],GOLD[3],0.88);
        if side<=2 then edge:SetWidth(math.max(1,frame:GetWidth()-4)); edge:SetHeight(2);
        else edge:SetWidth(2); edge:SetHeight(math.max(1,frame:GetHeight()-4)); end
        local anchor=({"TOP","BOTTOM","LEFT","RIGHT"})[side]; edge:SetPoint(anchor,frame,anchor,0,0);
        record.all[table.getn(record.all)+1]=edge;
    end
    local signature=frame:CreateFontString(nil,"OVERLAY");
    signature:SetFont("Fonts\\FRIZQT__.TTF",9,"OUTLINE");
    signature:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",11,6);
    signature:SetWidth(130); signature:SetHeight(13);
    signature:SetText("HOLY LIGHT  /  INVENTORY");
    signature:SetTextColor(0.91,0.73,0.44);
    record.all[table.getn(record.all)+1]=signature;
    return record;
end
local function SlotFrame(frame,index)
    local name=frame.GetName and frame:GetName();
    if type(name)~="string" or name=="" then return nil; end
    return getglobal(name.."Item"..index);
end
local function ItemQuality(bag,index)
    if type(GetContainerItemLink)~="function" or not bag then return nil; end
    local link=H.Call("GetContainerItemLink",bag,index);
    if type(link)~="string" or type(GetItemInfo)~="function" then return nil; end
    local ok,name,hyperlink,quality=pcall(GetItemInfo,link);
    if ok then return H.Number(quality); end
end
local function PaintSlots(record,frame,bag)
    for index=1,48 do
        local item=SlotFrame(frame,index); local owned=record.items[index];
        if item and item.IsShown and item:IsShown() then
            if not owned or owned.frame~=item then
                if owned then for j=1,table.getn(owned.edges) do owned.edges[j]:Hide(); end end
                owned={frame=item,edges={}}; record.items[index]=owned;
                for side=1,4 do
                    local edge=item:CreateTexture(nil,"OVERLAY"); edge:SetTexture(WHITE);
                    if side<=2 then edge:SetWidth(math.max(1,item:GetWidth()-2)); edge:SetHeight(1);
                    else edge:SetWidth(1); edge:SetHeight(math.max(1,item:GetHeight()-2)); end
                    local anchor=({"TOP","BOTTOM","LEFT","RIGHT"})[side]; edge:SetPoint(anchor,item,anchor,0,0);
                    owned.edges[side]=edge;
                end
            end
            local tint=qualities[ItemQuality(bag,index)] or DIM;
            for j=1,4 do owned.edges[j]:SetVertexColor(tint[1],tint[2],tint[3],0.92); owned.edges[j]:Show(); end
        elseif owned then
            for j=1,table.getn(owned.edges) do owned.edges[j]:Hide(); end
        end
    end
end
function H.UpdateBagSkin(delta)
    if not HLE_DB or not HLE_DB.enabled or HLE_DB.skinBags==false or H.suspended then
        H.ClearBagSkin(); return;
    end
    elapsed=elapsed+(H.Number(delta) or 0.05);
    if elapsed<0.45 then return; end
    elapsed=0;
    for i=1,16 do
        local frame=getglobal("ContainerFrame"..i);
        if frame and frame.IsShown and frame.GetWidth and frame.GetHeight then
            if frame:IsShown() and frame:GetWidth()>40 and frame:GetHeight()>40 then
                local record=Decorate(frame);
                for j=1,table.getn(record.all) do record.all[j]:Show(); end
                local bag=frame.GetID and H.Number(frame:GetID());
                PaintSlots(record,frame,bag);
            else HideDecorations(containers[frame]); end
        end
    end
end

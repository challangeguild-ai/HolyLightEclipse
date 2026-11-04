local H=HLE;
local MEDIA="Interface\\AddOns\\HolyLightEclipse\\Media\\";
local classes={warrior=true,paladin=true,hunter=true,rogue=true,priest=true,shaman=true,mage=true,warlock=true,druid=true};
local classIds={[1]="warrior",[2]="paladin",[3]="hunter",[4]="rogue",[5]="priest",[7]="shaman",[8]="mage",[9]="warlock",[11]="druid"};
local age,leave=0,nil;
function H.BossLootClass()
    local a,b=H.Call("UnitClass","player"); local values={b,a,H.Table(AZS_ZONE).class};
    for i=1,3 do
        local v=values[i]; if type(v)=="string" then v=string.lower(v); elseif H.Number(v) then v=classIds[v]; end
        if classes[v] then return v; end
    end
end
local function Scope()
    local class=H.BossLootClass(); local name=H.Call("UnitName","player");
    if not class or type(name)~="string" or name=="" then return nil; end
    return class..":"..name;
end
local function Store()
    local scope=Scope(); if not scope then return nil; end
    HLE_DB.bossLootOwned=H.Table(HLE_DB.bossLootOwned);
    local store=H.Table(HLE_DB.bossLootOwned[scope]); HLE_DB.bossLootOwned[scope]=store; return store;
end
function H.BossLootStatus(id)
    local store=Store(); local entry=store and H.Table(store[id]) or {};
    if entry.confirmed==true then return "COLLECTED ("..(entry.method=="equipped" and "EQUIPPED" or "SELF LOOT")..")",{0.45,1,0.55},"confirmed"; end
    if entry.manual=="owned" then return "COLLECTED (YOUR MARK)",{0.6,0.92,0.6},"manual-owned"; end
    if entry.manual=="missing" then return "MISSING (YOUR MARK)",{1,0.58,0.4},"manual-missing"; end
    return "UNKNOWN",{0.8,0.72,0.93},"unknown";
end
local function ItemId(reference)
    if type(reference)~="string" then return nil; end
    local _,_,id=string.find(reference,"item:(%d+)"); return id and tonumber(id) or nil;
end
function H.ObserveBossLoot(entry,method)
    if type(entry)~="table" or not HLE_DB or not HLE_DB.enabled then return false; end
    local class=H.BossLootClass(); if not class then return false; end
    local id=ItemId(entry.reference); local item=id and H.BossLootItems[id];
    if id then
        if not item or item.class~=class then return false; end
    elseif type(entry.name)=="string" then
        for key,v in pairs(H.BossLootItems) do
            if v.class==class and v.name==entry.name then
                if item then return false; end -- Duplicate names never establish ownership.
                id,item=key,v;
            end
        end
    end
    if not item then return false; end
    local store=Store(); if not store then return false; end
    local record=H.Table(store[id]); store[id]=record;
    record.confirmed=true; record.method=method=="equipped" and "equipped" or "self loot"; record.manual=nil;
    if type(entry.reference)=="string" then record.reference=string.sub(entry.reference,1,250); end
    return true;
end
function H.MarkBossLoot(id)
    local item=H.BossLootItems[id]; local store=Store();
    if not item or item.class~=H.BossLootClass() or not store then return; end
    local entry=H.Table(store[id]); store[id]=entry;
    if entry.confirmed==true then return; end
    if not entry.manual then entry.manual="owned";
    elseif entry.manual=="owned" then entry.manual="missing";
    else store[id]=nil; end
end
function H.HideBossLoot()
    if H.bossLootPopup then H.bossLootPopup:Hide(); end
    if H.bossLootTooltip and GameTooltip then GameTooltip:Hide(); end
    H.bossLootTooltip=nil; H.bossLootNode=nil; leave=nil;
end
function H.LeaveBossLoot() leave=0.25; end
function H.BuildBossLoot(Text,Texture)
    local f=CreateFrame("Frame","HLEBossLootPopup",UIParent); H.bossLootPopup=f;
    f:SetWidth(360); f:SetHeight(200); f:SetFrameStrata("TOOLTIP"); f:EnableMouse(true);
    if f.SetClampedToScreen then f:SetClampedToScreen(true); end
    f.bg=Texture(f,MEDIA.."White.tga",0,0,360,200); f.bg:SetVertexColor(0.045,0.025,0.07,0.98);
    for i=1,4 do
        local edge=Texture(f,MEDIA.."White.tga",0,0,i<=2 and 360 or 1,i<=2 and 1 or 200,"BORDER");
        edge:ClearAllPoints(); local anchor=({"TOP","BOTTOM","LEFT","RIGHT"})[i]; edge:SetPoint(anchor,f,anchor,0,0);
        edge:SetVertexColor(0.95,0.74,0.35,1);
        if i>2 then edge:ClearAllPoints(); edge:SetPoint("TOP"..anchor,f,"TOP"..anchor,0,0); edge:SetHeight(200); end
        if i==3 then f.edgeLeft=edge; elseif i==4 then f.edgeRight=edge; end
    end
    f.title=Text(f,13,12,-9,336); f.title:SetHeight(32);
    f.classText=Text(f,10,12,-40,336,{0.8,0.71,0.94});
    f.rows={};
    for i=1,2 do
        local row=CreateFrame("Frame",nil,f); row:SetWidth(336); row:SetHeight(54); row:SetPoint("TOPLEFT",f,"TOPLEFT",12,-61-(i-1)*56); row:EnableMouse(true);
        row.icon=Texture(row,MEDIA.."White.tga",0,-4,32,32,"ARTWORK");
        row.name=Text(row,12,42,0,294,{1,0.94,0.82}); row.name:SetHeight(28);
        row.status=Text(row,10,42,-30,294,{0.8,0.71,0.94});
        row:SetScript("OnEnter",function()
            leave=nil;
            if not this.item or not GameTooltip then return; end
            local status=H.BossLootStatus(this.item.id);
            GameTooltip:SetOwner(this,"ANCHOR_RIGHT");
            GameTooltip:SetText(this.item.name.."\n"..this.item.slot.."  "..this.item.tier.."\n"..status.."\nRight-click unknown entries: collected / missing / auto");
            GameTooltip:Show(); H.bossLootTooltip=this;
        end);
        row:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide(); end; H.bossLootTooltip=nil; H.LeaveBossLoot(); end);
        row:SetScript("OnMouseUp",function()
            if arg1=="RightButton" and this.item then H.MarkBossLoot(this.item.id); H.RefreshBossLoot(); end
        end); f.rows[i]=row;
    end
    f.notice=Text(f,9,12,-178,336,{0.77,0.69,0.88}); f.notice:SetHeight(44);
    f:SetScript("OnEnter",function() leave=nil; end); f:SetScript("OnLeave",function() H.LeaveBossLoot(); end);
    f:Hide();
end
function H.RefreshBossLoot()
    local f=H.bossLootPopup; local node=H.bossLootNode;
    if not f or not node or not node.bossLootName then H.HideBossLoot(); return; end
    local name=node.bossLootName; local class=H.BossLootClass();
    local group=H.BossLootCatalog[string.lower(name)]; local ids=group and class and group[class] or {};
    f.title:SetText(name); f.classText:SetText(class and (string.upper(class).." - POSSIBLE DROPS") or "CLASS DATA UNAVAILABLE");
    local count=math.min(2,table.getn(ids));
    for i=1,2 do
        local row=f.rows[i]; local item=H.BossLootItems[ids[i]]; row.item=item;
        if item then
            row.name:SetText(item.name); row.icon:SetTexture(H.IconPath(item.icon));
            local label,color=H.BossLootStatus(item.id); row.status:SetText(label); row.status:SetTextColor(unpack(color)); row:Show();
        else row:Hide(); end
    end
    local text="Reference: "..H.BossLootCatalogDate..". Rates vary; no guarantee.\nRight-click unknown items: collected / missing / auto.";
    if count==0 then text=class and "No verified drop reference for this boss/class.\nNo missing items are inferred." or "Waiting for native class data.\nNo items or ownership are guessed."; end
    local height=64+count*56+46; f:SetHeight(height); f.bg:SetHeight(height); f.edgeLeft:SetHeight(height); f.edgeRight:SetHeight(height);
    f.notice:ClearAllPoints(); f.notice:SetPoint("TOPLEFT",f,"TOPLEFT",12,-66-count*56); f.notice:SetText(text);
end
function H.ShowBossLoot(node)
    if not HLE_DB.enabled or H.suspended or not node or not node.bossLootName then H.HideBossLoot(); return; end
    H.bossLootNode=node; leave=nil;
    H.bossLootPopup:ClearAllPoints(); H.bossLootPopup:SetPoint("TOP",node,"BOTTOM",0,-6);
    H.bossLootPopup:SetScale(HLE_DB.scale); H.RefreshBossLoot(); H.bossLootPopup:Show();
end
function H.UpdateBossLoot(s,delta)
    if not HLE_DB.enabled or H.suspended then H.HideBossLoot(); return; end
    if leave then leave=leave-(delta or 0.05); if leave<=0 then H.HideBossLoot(); end end
    age=age+(delta or 0.05); if age<0.5 then return; end; age=0;
    if s.active or s.phase=="ready" then
        local slots={1,3,5,6,7,8,9,10,16,17,18};
        for i=1,11 do
            local link=H.Call("GetInventoryItemLink","player",slots[i]);
            if type(link)=="string" then H.ObserveBossLoot({reference=link},"equipped"); end
        end
    end
    if H.bossLootNode then
        if not H.timeline:IsShown() or not H.bossLootNode:IsShown() or not HLE_DB.showTimeline then H.HideBossLoot();
        else H.RefreshBossLoot(); end
    end
end

_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['BARRACKITEMLIST'] = _G['ADDONS']['BARRACKITEMLIST'] or {};
local acutil = require('acutil')
local g = _G['ADDONS']['BARRACKITEMLIST']
g.settingPath = '../addons/barrackitemlist/'
g.userlist  = acutil.loadJSON(g.settingPath..'userlist.json',nil) or {}
g.warehouseList = acutil.loadJSON(g.settingPath..'warehouse.json',nil) or {}
g.nodeList = {
        {"Unused" , "シルバー"}
        ,{"Weapon" , "武器"}
        ,{"SubWeapon" , "サブ武器"}
        ,{"Armor" , "アーマー"}
        ,{"Drug" , "消費アイテム"}
        ,{"Recipe" ,"レシピ"}
        ,{"Material","素材"}
        ,{"Gem","ジェム"}
        ,{"Card","カード"}
        ,{"Collection","コレクション"}
        ,{"Quest" ,"クエスト"}
        ,{"Event" ,"イベント"}
        ,{"Cube" , "キューブ"}
        ,{"Premium" ,"プレミアム"}
        ,{"warehouse","倉庫"}
    }
g.setting = acutil.loadJSON(g.settingPath..'setting.json',nil)
if not g.setting then
    g.setting = {}
    g.setting.col = 14
    g.setting.hideNode = {}
    g.setting.OpenNodeAll = false
    acutil.saveJSON(g.settingPath..'setting.json',g.setting)
end

g.itemlist = g.itemlist or {}
for k,v in pairs(g.userlist) do
    if not g.itemlist[k] then
        g.itemlist[k] = acutil.loadJSON(g.settingPath..k..'.json',nil)
    end
end


function BARRACKITEMLIST_ON_INIT(addon,frame)
    local cid = info.GetCID(session.GetMyHandle())
    g.userlist[cid] = info.GetPCName(session.GetMyHandle())
    acutil.saveJSON(g.settingPath..'userlist.json',g.userlist)
    acutil.slashCommand('/itemlist', BARRACKITEMLIST_COMMAND)
    acutil.slashCommand('/il',BARRACKITEMLIST_COMMAND)
    
    acutil.setupEvent(addon,'GAME_TO_BARRACK','BARRACKITEMLIST_SAVE_LIST')
    acutil.setupEvent(addon,'GAME_TO_LOGIN','BARRACKITEMLIST_SAVE_LIST')
    acutil.setupEvent(addon,'DO_QUIT_GAME','BARRACKITEMLIST_SAVE_LIST')
    acutil.setupEvent(addon,'WAREHOUSE_CLOSE','BARRACKITEMLIST_SAVE_WAREHOUSE')
    -- acutil.setupEvent(addon, 'SELECT_CHARBTN_LBTNUP', 'SELECT_CHARBTN_LBTNUP_EVENT')

    addon:RegisterMsg('GAME_START_3SEC','BARRACKITEMLIST_CREATE_VAR_ICONS')
    
    local droplist = tolua.cast(frame:GetChild("droplist"), "ui::CDropList");
    droplist:ClearItems()
    droplist:AddItem(1,'None')
    for k,v in pairs(g.userlist) do
        droplist:AddItem(k,"{s20}"..v.."{/}",0,'BARRACKITEMLIST_SHOW_LIST()');
    end
    tolua.cast(frame:GetChild('tab'), "ui::CTabControl"):SelectTab(0)
    frame:GetChild('saveBtn'):SetTextTooltip('現在のキャラのインベントリを保存する')
    BARRACKITEMLIST_CREATE_SETTINGMENU()
    BARRACKITEMLIST_TAB_CHANGE(frame)
    frame:ShowWindow(0)
end

-- function SELECT_CHARBTN_LBTNUP_EVENT(addonFrame, eventMsg)
--     local parent, ctrl, cid, argNum = acutil.getEventArgs(eventMsg);
--     BARRACKITEMLIST_SHOW_LIST(cid)
-- end

function BARRACKITEMLIST_TAB_CHANGE(frame, obj, argStr, argNum)
    local treeGbox = frame:GetChild('treeGbox')
    local droplist = frame:GetChild("droplist")
    local searchGbox = frame:GetChild('searchGbox')
    local settingGbox = frame:GetChild('settingGbox')
    local tabObj = tolua.cast(frame:GetChild('tab'), "ui::CTabControl");
	local tabIndex = tabObj:GetSelectItemIndex();

	if (tabIndex == 0) then
		treeGbox:ShowWindow(1)
        droplist:ShowWindow(1)
		searchGbox:ShowWindow(0)
        settingGbox:ShowWindow(0)
        BARRACKITEMLIST_SHOW_LIST()
        BARRACKITEMLIST_SAVE_SETTINGMENU()
	elseif (tabIndex == 1) then
		treeGbox:ShowWindow(0)
        droplist:ShowWindow(0)
		searchGbox:ShowWindow(1)
        settingGbox:ShowWindow(0)
        BARRACKITEMLIST_SAVE_SETTINGMENU()
        BARRACKITEMLIST_SHOW_SEARCH_ITEMS()
    else
        treeGbox:ShowWindow(0)
        droplist:ShowWindow(0)
		searchGbox:ShowWindow(0)
        settingGbox:ShowWindow(1)
	end
end

function BARRACKITEMLIST_COMMAND(command)
    BARRACKITEMLIST_CREATE_SETTINGMENU()
    ui.ToggleFrame('barrackitemlist')
end 

function BARRACKITEMLIST_SAVE_LIST()
    local list = {}
    session.BuildInvItemSortedList()
	local invItemList = session.GetInvItemSortedList();

    for i = 1, invItemList:size() - 1 do
        local invItem = invItemList:at(i);
        if invItem ~= nil then
    		local obj = GetIES(invItem:GetObject());
            list[obj.GroupName] = list[obj.GroupName] or {}
            table.insert(list[obj.GroupName],GetItemData(obj,invItem))
        end
	end
    local cid = info.GetCID(session.GetMyHandle())
    acutil.saveJSON(g.settingPath..cid..'.json',list)
    g.itemlist[cid] = list  
end

function BARRACKITEMLIST_SHOW_LIST(cid)
    local frame = ui.GetFrame('barrackitemlist')
    frame:ShowWindow(1)
    local gbox = GET_CHILD(frame,'treeGbox','ui::CGroupBox');
    local droplist = GET_CHILD(frame,'droplist', "ui::CDropList")
    if not cid then cid= droplist:GetSelItemKey() end
    for k,v in pairs(g.userlist) do
        local child = gbox:GetChild("tree"..k) 
        if child then
            child:ShowWindow(0)
        end
    end
    local list = g.itemlist[cid]
    if not list then
        list ,e = acutil.loadJSON(g.settingPath..cid..'.json',{})
        if(e) then return end
    end
    g.warehouseList[tostring(cid)] = g.warehouseList[tostring(cid)] or {}
    list.warehouse =  g.warehouseList[tostring(cid)].warehouse or {};
    local tree = gbox:CreateOrGetControl('tree','tree'..cid,25,50,545,0)
    -- if tree:GetUserValue('exist_data') ~= '1' then
        -- tree:SetUserValue('exist_data',1) 
        tolua.cast(tree,'ui::CTreeControl')
        tree:ResizeByResolutionRecursively(1)
        tree:Clear()
        tree:EnableDrawFrame(true);
        tree:SetFitToChild(true,60); 
        tree:SetFontName("white_20_ol");
        local nodeName,parentCategory
        local slot,slotset,icon
        local nodeList = g.nodeList
        for i,value in ipairs(nodeList) do
            local nodeItemList = list[value[1]]
            if nodeItemList and not g.setting.hideNode[i] then
                if value[1] == "Unused" then
                    tree:Add("シルバー : " .. acutil.addThousandsSeparator(nodeItemList[1][2]));
                else
                    tree:Add(value[2]);
                    parentCategory = tree:FindByCaption(value[2]);
                    slotset = BARRACKITEMLIST_MAKE_SLOTSET(tree,value[1])
                    tree:Add(parentCategory,slotset, 'slotset_'..value[1]);
                    for i ,v in ipairs(nodeItemList) do
                        slot = slotset:GetSlotByIndex(i - 1)
                        slot:SetText(string.format(v[2]))
                        slot:SetTextMaxWidth(1000)
                        icon = CreateIcon(slot)
                        icon:SetImage(v[3])
                        icon:SetTextTooltip(string.format("%s : %s",v[1],v[2]))
                        if (i % g.setting.col) == 0 then
                            slotset:ExpandRow()
                        end
                    end
                end
            end
        -- end
    end
    if g.setting.OpenNodeAll then
        tree:OpenNodeAll()
    end
    tree:ShowWindow(1)
    frame:ShowWindow(1)
end
function BARRACKITEMLIST_MAKE_SLOTSET(tree, name)
    local col = g.setting.col
    local slotsize = math.floor(tree:GetWidth() / (col + 1))
    local slotsetTitle = 'slotset_titile_'..name
	local newslotset = tree:CreateOrGetControl('slotset','slotset_'..name,0,0,0,0) 
	tolua.cast(newslotset, "ui::CSlotSet");
	
	newslotset:EnablePop(0)
	newslotset:EnableDrag(0)
	newslotset:EnableDrop(0)
	newslotset:SetMaxSelectionCount(999)
	newslotset:SetSlotSize(slotsize,slotsize);
	newslotset:SetColRow(col,1)
	newslotset:SetSpc(0,0)
	newslotset:SetSkinName('invenslot2')
	newslotset:EnableSelection(0)
    newslotset:ResizeByResolutionRecursively(1)
	newslotset:CreateSlots()
	return newslotset;
end

function BARRACKITEMLIST_SEARCH_ITEMS(itemlist,itemName,iswarehouse)
    local items = {}
    for cid,name in pairs(g.userlist) do
        if itemlist[cid] then
            for group,list in pairs(itemlist[cid]) do
                if group ~= 'warehouse' or iswarehouse then
                    for i ,v in ipairs(list) do
                        if string.find(v[1],itemName) then
                            items[cid] = items[cid] or {}
                            table.insert(items[cid],v)
                        end
                    end
                end
            end
        end
    end
    return items
end

function BARRACKITEMLIST_SHOW_SEARCH_ITEMS(frame, obj, argStr, argNum)
    local frame = ui.GetFrame('barrackitemlist')
    local searchGbox = frame:GetChild('searchGbox')
    local editbox = tolua.cast(searchGbox:GetChild('searchEdit'), "ui::CEditControl");
    local tree = searchGbox:CreateOrGetControl('tree','saerchTree',25,50,545,0)
    tolua.cast(tree,'ui::CTreeControl')
    tree:ResizeByResolutionRecursively(1)
    tree:Clear()
    tree:EnableDrawFrame(true);
    tree:SetFitToChild(true,60); 
    tree:SetFontName("white_20_ol");
    if editbox:GetText() == '' or not editbox:GetText() then return end
    local invItems = BARRACKITEMLIST_SEARCH_ITEMS(g.itemlist,editbox:GetText(),false)
    local warehouseItems = BARRACKITEMLIST_SEARCH_ITEMS(g.warehouseList,editbox:GetText(),true)
    tree:Add('インベントリ')
    _BARRACKITEMLIST_SEARCH_ITEMS(tree,invItems,'_i')
    tree:Add('倉庫')
    _BARRACKITEMLIST_SEARCH_ITEMS(tree,warehouseItems,'_w')
    tree:OpenNodeAll()
    tree:ShowWindow(1)
end

function _BARRACKITEMLIST_SEARCH_ITEMS(tree,items,type)
    local nodeName,parentCategory
    local slot,slotset,icon
    for k,value in pairs(items) do
        tree:Add(g.userlist[k]..type);
        parentCategory = tree:FindByCaption(g.userlist[k]..type);
        slotset = BARRACKITEMLIST_MAKE_SLOTSET(tree,k..type)
        tree:Add(parentCategory,slotset, 'slotset_'..k..type);
        for i ,v in ipairs(value) do
            slot = slotset:GetSlotByIndex(i - 1)
            slot:SetText(string.format('{s20}%s',v[2]))
            slot:SetTextAlign(30,30)
            -- slot:SetTextMaxWidth(1000)
            icon = CreateIcon(slot)
            icon:SetImage(v[3])
            icon:SetTextTooltip(string.format("%s : %s",v[1],v[2]))
            if (i % g.setting.col) == 0 then
                slotset:ExpandRow()
            end
        end
    end

end

function BARRACKITEMLIST_SAVE_WAREHOUSE()
    local frame = ui.GetFrame('warehouse')
    local slotset = frame:GetChild("gbox"):GetChild('slotset')
    tolua.cast(slotset,'ui::CSlotSet')
    local items = {}
    local slot , item
	for i = 0 , slotset:GetSlotCount() -1 do
         slot = slotset:GetSlotByIndex(i)
         item = GetItemData(GetObjBySlot(slot))
         if item then
             table.insert(items,item)
         end
    end
    local cid = tostring(info.GetCID(session.GetMyHandle()))
    g.warehouseList[cid] = {}
    g.warehouseList[cid].warehouse = items
    acutil.saveJSON(g.settingPath..'warehouse.json',g.warehouseList)
end

 function GetItemData(obj,item)
    if not obj then return end
    local itemName = dictionary.ReplaceDicIDInCompStr(obj.Name)
    local itemCount = item.count
    local iconImg = obj.Icon
    if obj.GroupName ==  'Gem' or obj.GroupName ==  'Card' then
        itemCount = 'Lv' .. GET_ITEM_LEVEL(obj)
    end
    if obj.ItemType == 'Equip' and obj.ClassType == 'Outer' then
        local tempiconname = string.sub(obj.Icon, string.len(obj.Icon) - 1 );
        if tempiconname ~= "_m" and tempiconname ~= "_f" then
            if gender == nil then
                gender = GetMyPCObject().Gender;
            end
            if gender == 1 then
                iconImg =iconImg.."_m"
            else
                iconImg = iconImg.."_f"
            end
        end
    end
    return {itemName,itemCount,iconImg}
end

 function GetObjBySlot(slot)
    local icon = slot:GetIcon()
    if not icon then return end
    local info = icon:GetInfo()
    local IESID = info:GetIESID()
    return GetObjectByGuid(IESID) ,info ,IESID
end

function BARRACKITEMLIST_CREATE_SETTINGMENU()
    local frame = ui.GetFrame('barrackitemlist')
    local settingGbox = frame:GetChild('settingGbox')
    local hideNodeGbox = settingGbox:GetChild('hideNodeGbox')

    -- create slotsize droplist
    local droplist = tolua.cast(settingGbox:GetChild("slotColDList"), "ui::CDropList");
    droplist:ClearItems()
    for i = 7, 14  do
        droplist:AddItem(i,"{s20}"..i.."{/}");
    end
    droplist:SelectItemByKey(g.setting.col)
    
    --create hide node list
    local checkbox
    for i = 1 ,#g.nodeList do
        checkbox = hideNodeGbox:CreateOrGetControl('checkbox','checkbox'..i,30,i*30,200,30)
        tolua.cast(checkbox,'ui::CCheckBox')
        checkbox:SetText('{s30}{#000000}'..g.nodeList[i][2])
        if not g.setting.hideNode[i] then 
            checkbox:SetCheck(1)
        end
    end
    checkbox = tolua.cast(settingGbox:GetChild('openNodeChbox'),'ui::CCheckBox')
    if g.setting.OpenNodeAllthen then
        checkbox:SetCheck(1)
    end
end

function BARRACKITEMLIST_SAVE_SETTINGMENU() 
    local frame = ui.GetFrame('barrackitemlist')
    local settingGbox = frame:GetChild('settingGbox')
    local hideNodeGbox = settingGbox:GetChild('hideNodeGbox')
    -- save slotsize droplist
    local droplist = tolua.cast(settingGbox:GetChild("slotColDList"), "ui::CDropList");
    g.setting.col = droplist:GetSelItemKey()
    --save hide node list
    local checkbox
    for i = 1 ,#g.nodeList do
        checkbox = tolua.cast(hideNodeGbox:GetChild('checkbox'..i),'ui::CCheckBox')
        if checkbox:IsChecked() ~= 1 then 
            g.setting.hideNode[i] = true
        else
            g.setting.hideNode[i] = false
        end
    end
    
    checkbox = tolua.cast(settingGbox:GetChild('openNodeChbox'),'ui::CCheckBox')
    if checkbox:IsChecked() == 1 then 
        g.setting.OpenNodeAll = true
    else
        g.setting.OpenNodeAll = false
    end
    acutil.saveJSON(g.settingPath..'setting.json',g.setting)
end

function BARRACKITEMLIST_CREATE_VAR_ICONS()
    local frame = ui.GetFrame("sysmenu");
	if false == VARICON_VISIBLE_STATE_CHANTED(frame, "necronomicon", "necronomicon")
	and false == VARICON_VISIBLE_STATE_CHANTED(frame, "grimoire", "grimoire")
	and false == VARICON_VISIBLE_STATE_CHANTED(frame, "guild", "guild")
	and false == VARICON_VISIBLE_STATE_CHANTED(frame, "poisonpot", "poisonpot")
	then
		return;
	end

	DESTROY_CHILD_BY_USERVALUE(frame, "IS_VAR_ICON", "YES");

    local extraBag = frame:GetChild('extraBag');
	local status = frame:GetChild("status");
	local offsetX = status:GetX() - extraBag:GetX();
	local rightMargin = extraBag:GetMargin().right + offsetX;

	rightMargin = SYSMENU_CREATE_VARICON(frame, extraBag, "guild", "guild", "sysmenu_guild", rightMargin, offsetX, "Guild");
	rightMargin = SYSMENU_CREATE_VARICON(frame, extraBag, "necronomicon", "necronomicon", "sysmenu_card", rightMargin, offsetX);
	rightMargin = SYSMENU_CREATE_VARICON(frame, extraBag, "grimoire", "grimoire", "sysmenu_neacro", rightMargin, offsetX);
	rightMargin = SYSMENU_CREATE_VARICON(frame, extraBag, "poisonpot", "poisonpot", "sysmenu_wugushi", rightMargin, offsetX);	
    if _G["EXPCARDCALCULATOR"] then
    	rightMargin = SYSMENU_CREATE_VARICON(frame, status, "expcardcalculator", "expcardcalculator", "addonmenu_expcard", rightMargin, offsetX, "Experience Card Calculator") or rightMargin
	end
    rightMargin = SYSMENU_CREATE_VARICON(frame, status, "barrackitemlist", "barrackitemlist", "sysmenu_inv", rightMargin, offsetX, "barrack item list");

    local expcardcalculatorButton = GET_CHILD(frame, "expcardcalculator", "ui::CButton");
	if expcardcalculatorButton ~= nil then
		expcardcalculatorButton:SetTextTooltip("{@st59}expcardcalculator");
	end

	local barrackitemlistButton = GET_CHILD(frame, "barrackitemlist", "ui::CButton");
	if barrackitemlistButton ~= nil then
		barrackitemlistButton:SetTextTooltip("{@st59}barrackitemlist");
	end
end
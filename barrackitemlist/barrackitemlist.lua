_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['BARRACKITEMLIST'] = _G['ADDONS']['BARRACKITEMLIST'] or {};
local acutil = require('acutil')
local g = _G['ADDONS']['BARRACKITEMLIST']
g.settingPath = '../addons/barrackitemlist/'
g.userlist  = acutil.loadJSON(g.settingPath..'userlist.json',nil)

function BARRACKITEMLIST_ON_INIT(addon,frame)
    local cid = info.GetCID(session.GetMyHandle())
    g.userlist[cid] = info.GetPCName(session.GetMyHandle())
    acutil.saveJSON(g.settingPath..'userlist.json',g.userlist)
    acutil.slashCommand('/itemlist', BARRACKITEMLIST_COMMAND)
    acutil.slashCommand('/il',BARRACKITEMLIST_COMMAND)
    
    acutil.setupEvent(addon,'GAME_TO_BARRACK',BARRACKITEMLIST_SAVE_LIST)
    acutil.setupEvent(addon, 'SELECT_CHARBTN_LBTNUP', SELECT_CHARBTN_LBTNUP_EVENT)
   
end

function SELECT_CHARBTN_LBTNUP_EVENT(addonFrame, eventMsg)
    local parent, ctrl, cid, argNum = acutil.getEventArgs(eventMsg);
    BARRACKITEMLIST_SHOW_LIST(cid)
end

function BARRACKITEMLIST_COMMAND(command)
    local t = {}
    for k,v in pairs(g.userlist) do
        table.insert(t,{k,v})
    end
    if #command > 0 then
        local cmd = table.remove(command,1)
        local cid = t[tonumber(cmd)][1]
        if cid then
            BARRACKITEMLIST_SHOW_LIST(cid)
        else
            return
        end
    else
        for i,v in ipairs(t) do
            CHAT_SYSTEM(string.format("%d : %s",i,v[2]))
        end
    end
end 

function BARRACKITEMLIST_SAVE_LIST()
    local list = {}
	local invItemList = session.GetInvItemList();

	local i = invItemList:Head();
	local slotindex = 0
	while 1 do
		if i == invItemList:InvalidIndex() then
			break;
		end

		local invItem = invItemList:Element(i);
		local obj = GetIES(invItem:GetObject());
        list[obj.GroupName] = list[obj.GroupName] or {}
        table.insert(list[obj.GroupName],{dictionary.ReplaceDicIDInCompStr(obj.Name),obj.Icon,invItem.count})
		i = invItemList:Next(i);
	end
    local cid = info.GetCID(session.GetMyHandle())
    acutil.saveJSON(g.settingPath..cid..'.json',list)    
end

function BARRACKITEMLIST_SHOW_LIST(cid)
    local frame = ui.GetFrame('barrackitemlist')
    frame:ShowWindow(0)
    local gbox = GET_CHILD(frame,'treeGbox','ui::CGroupBox');
    local tree = GET_CHILD(gbox,'inventree','ui::CTreeControl');  
    tree:RemoveAllChild() 
    local list ,e = acutil.loadJSON(g.settingPath..cid..'.json',nil)
    if(e) then return end
    local col = 13
    local slot,slotset,treegroup

    for k,value in pairs(list) do
        treegroup =  tree:Add(k,k)
        BARRACKITEMLIST_MAKE_INVEN_SLOTSET_AND_TITLE(tree, treegroup, k)
        slotset = GET_CHILD(tree,k,'ui::CSlotSet')	
        for i ,v in ipairs(value) do
            if (i % col) == 0 then
                slotset:ExpandRow()
            end
            slot = slotset:GetSlotByIndex(i)
            slot:SetImage(v[2])
        end
    end
    frame:ShowWindow(1)
end

function BARRACKITEMLIST_MAKE_INVEN_SLOTSET_AND_TITLE(tree, treegroup, name)
	local slotsettitle = 'ssettitle_'..name;
	local newSlotsname = BARRACKITEMLIST_MAKE_INVEN_SLOTSET_NAME(tree, slotsettitle,name)
	local newSlots = BARRACKITEMLIST_MAKE_INVEN_SLOTSET(tree, name)
	tree:Add(treegroup, newSlotsname, slotsettitle);
	local slotHandle = tree:Add(treegroup, newSlots, name);

	local slotNode = tree:GetNodeByTreeItem(slotHandle);
	slotNode:SetUserValue("IS_ITEM_SLOTSET", 1);
end

function BARRACKITEMLIST_MAKE_INVEN_SLOTSET(tree, name)
	
	local frame = ui.GetFrame('barrackitemlist');
	local slotsize = 40
	local colcount = 13

	local newslotset = tree:CreateOrGetControl('slotset',name,0,0,0,0) 
	tolua.cast(newslotset, "ui::CSlotSet");
	
	newslotset:EnablePop(0)
	newslotset:EnableDrag(0)
	newslotset:EnableDrop(0)
	newslotset:SetMaxSelectionCount(999)
	newslotset:SetSlotSize(slotsize,slotsize);
	newslotset:SetColRow(colcount,1)
	newslotset:SetSpc(0,0)
	newslotset:SetSkinName('invenslot')
	newslotset:EnableSelection(0)
	newslotset:CreateSlots()
	-- SLOTSET_NAMELIST[#SLOTSET_NAMELIST + 1] = name
	return newslotset;
end


function BARRACKITEMLIST_MAKE_INVEN_SLOTSET_NAME(tree, name, titletext)

	local frame = ui.GetFrame('barrackitemlist');
	local width = 300
	local height = 40
	local font = 'white_18_ol'

	local newtext = tree:CreateOrGetControl('richtext',name,0,0,width,height) 
	tolua.cast(newtext, "ui::CRichText");

	newtext:EnableResizeByText(0);
	newtext:SetFontName(font);
	newtext:SetUseOrifaceRect(true);
	newtext:SetText(titletext..'(0)');
	newtext:SetTextAlign('left','bottom');

	return newtext;
end

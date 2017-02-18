_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['BARRACKITEMLIST'] = _G['ADDONS']['BARRACKITEMLIST'] or {};
local acutil = require('acutil')
local g = _G['ADDONS']['BARRACKITEMLIST']
g.settingPath = '../addons/barrackitemlist/'
g.userlist  = acutil.loadJSON(g.settingPath..'userlist.json',nil)
g.itemlist = g.itemlist or {}

function BARRACKITEMLIST_ON_INIT(addon,frame)
    local cid = info.GetCID(session.GetMyHandle())
    g.userlist[cid] = info.GetPCName(session.GetMyHandle())
    acutil.saveJSON(g.settingPath..'userlist.json',g.userlist)
    acutil.slashCommand('/itemlist', BARRACKITEMLIST_COMMAND)
    acutil.slashCommand('/il',BARRACKITEMLIST_COMMAND)
    
    acutil.setupEvent(addon,'GAME_TO_BARRACK','BARRACKITEMLIST_SAVE_LIST')
    acutil.setupEvent(addon,'GAME_TO_LOGIN','BARRACKITEMLIST_SAVE_LIST')
    acutil.setupEvent(addon,'DO_QUIT_GAME','BARRACKITEMLIST_SAVE_LIST')
    -- acutil.setupEvent(addon, 'SELECT_CHARBTN_LBTNUP', 'SELECT_CHARBTN_LBTNUP_EVENT')
    local droplist = tolua.cast(ui.GetFrame('barrackitemlist'):GetChild("droplist"), "ui::CDropList");
    droplist:ClearItems()
    droplist:AddItem(1,'None')
    for k,v in pairs(g.userlist) do
        droplist:AddItem(k,"{s20}"..v.."{/}",0,'BARRACKITEMLIST_SHOW_LIST()');
    end
end

function SELECT_CHARBTN_LBTNUP_EVENT(addonFrame, eventMsg)
    local parent, ctrl, cid, argNum = acutil.getEventArgs(eventMsg);
    BARRACKITEMLIST_SHOW_LIST(cid)
end
function BARRACKITEMLIST_COMMAND(command)
    ui.GetFrame('barrackitemlist'):ShowWindow(1)
    -- local droplist = tolua.cast(ui.GetFrame('barrackitemlist'):GetChild("droplist"), "ui::CDropList");
    -- droplist:ClearItems()
    -- droplist:AddItem(1,'None')
    -- local t = {}
    -- for k,v in pairs(g.userlist) do
    --     table.insert(t,{k,v})
    --     droplist:AddItem(k,"{s20}"..v.."{/}",0,'BARRACKITEMLIST_SHOW_LIST()');
    -- end
    local cmd = table.remove(command,1)
    if cmd then
        local cid = t[tonumber(cmd)][1]
        if cid then
            BARRACKITEMLIST_SHOW_LIST(cid)
        end
    -- else
    --     for i,v in ipairs(t) do
    --         CHAT_SYSTEM(string.format("%d : %s",i,v[2]))
    --     end
    end
end 

function BARRACKITEMLIST_SAVE_LIST()
    local list = {}
	local invItemList = session.GetInvItemSortedList();

    for i = 1, invItemList:size() - 1 do
        local invItem = invItemList:at(i);
        if invItem ~= nil then
    		local obj = GetIES(invItem:GetObject());

            list[obj.GroupName] = list[obj.GroupName] or {}
            table.insert(list[obj.GroupName],{dictionary.ReplaceDicIDInCompStr(obj.Name),invItem.count,obj.Icon})
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
        list ,e = acutil.loadJSON(g.settingPath..cid..'.json',nil)
        if(e) then return end
    end

    local tree = gbox:CreateOrGetControl('tree','tree'..cid,25,20,545,0)
    if tree:GetUserValue('exist_data') ~= '1' then
        tree:SetUserValue('exist_data',1) 
        tolua.cast(tree,'ui::CTreeControl')
        tree:ResizeByResolutionRecursively(1)
        tree:Clear()
        tree:EnableDrawFrame(true);
        tree:SetFitToChild(true,60); 
        tree:SetFontName("white_20_ol");
        local nodeName,parentCategory
        local slot,slotset,icon
        local col,slotsize = 13,40
        for k,value in pairs(list) do
            tree:Add(k);
            parentCategory = tree:FindByCaption(k);
            slotset = BARRACKITEMLIST_MAKE_SLOTSET(tree,k,col,slotsize)
            tree:Add(parentCategory,slotset, 'slotset_'..k);
            for i ,v in ipairs(value) do
                slot = slotset:GetSlotByIndex(i - 1)
                slot:SetText('{#000000}'..v[2])
                slot:SetTextMaxWidth(1000)
                icon = CreateIcon(slot)
                icon:SetImage(v[3])
                icon:SetTextTooltip(v[1])
                if (i % col) == 0 then
                    slotset:ExpandRow()
                end
            end
        end
    end
    tree:ShowWindow(1)
    frame:ShowWindow(1)
end


function BARRACKITEMLIST_MAKE_SLOTSET(tree, name,col,slotsize)
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
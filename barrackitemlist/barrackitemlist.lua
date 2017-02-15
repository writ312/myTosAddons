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
    
    addon:RegisterMsg('GAME_TO_BARRACK','BARRACKITEMLIST_SAVE_LIST')
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
    gbox:RemoveAllChild()
    local list ,e = acutil.loadJSON(g.settingPath..cid..'.json',nil)
    if(e) then return end
    local row = 1
    local cow = 13
    for k,value in pairs(list) do
        local text = gbox:CreateOrGetControl("richtext","text"..k,30,(row-1)*40,300,40)
        text:SetText(string.format("{s25}{#000000}%s{/}",k))
            for i = 0 , #value - 1 do
            if i%cow == 0 and i ~= (#value - 1) and i ~= 0 then row = row + 1 end
            local v = value[i + 1]
            local slot = gbox:CreateOrGetControl("slot","slot"..v[1]..i,40*(i%cow + 1),row*40,40,40)
            tolua.cast(slot, 'ui::CSlot')
            slot:SetSkinName('slot')
            local icon = CreateIcon(slot);
            icon:SetImage(v[2])
        end
        row = row + 2
    end
    frame:ShowWindow(1)
end

-- function BARRACKITEMLIST_SETUP_SLOTSET(frame,name,slotsize,col)
--     local slotset = frame:CreateOrGetControl('slotset','slotset'..name,0,0,480,0)
--     slotset:EnablePop(0)
-- 	slotset:EnableDrag(0)
-- 	slotset:EnableDrop(0)
-- 	slotset:SetMaxSelectionCount(999)
-- 	slotset:SetSlotSize(slotsize,slotsize);
-- 	slotset:SetColRow(10,1)
-- 	slotset:SetSpc(0,0)
-- 	slotset:SetSkinName('invenslot')
-- 	slotset:EnableSelection(0)
-- 	slotset:CreateSlots()
--     return slotset
-- end


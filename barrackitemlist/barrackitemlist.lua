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
    acutil.setupEvent(addon, 'SELECT_CHARBTN_LBTNUP', 'SELECT_CHARBTN_LBTNUP_EVENT')
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


function BARRACKITEMLIST_SHOW_LIST(cid)
    local frame = ui.GetFrame('barrackitemlist')
    frame:ShowWindow(1)
    local gbox = GET_CHILD(frame,'treeGbox','ui::CGroupBox');
    local droplist = GET_CHILD(frame,'droplist', "ui::CDropList")
    if not cid then cid= droplist:GetSelItemKey() end
    for k,v in pairs(g.userlist) do
        local child = gbox:GetChild("textview"..k) 
        if child then
            child:ShowWindow(0)
        end
    end
    local list = g.itemlist[cid]
    if not list then
        list ,e = acutil.loadJSON(g.settingPath..cid..'.json',nil)
        if(e) then return end
    end
    local textview = gbox:CreateOrGetControl("textview","textview"..cid,30,70,540,830)
	tolua.cast(textview, "ui::CTextView");
    if  textview:GetUserValue('IS_SET') ~= '1' then
        textview:SetUserValue('IS_SET',1)
        textview:Clear()
        CHAT_SYSTEM('clear')
        for k,value in pairs(list) do
            textview:AddText(k, "red_18_b");
            for i ,v in ipairs(value) do
                textview:AddText(v[1]..' : '..v[2], "white_18_ol");
            end
        end
    
    end
    textview:ShowWindow(1)
    frame:ShowWindow(1)
end 

function BARRACKITEMLIST_SAVE_LIST()
    local list = {}
	local invItemList = session.GetInvItemSortedList();

    for i = 1, invItemList:size() - 1 do
        local invItem = invItemList:at(i);
        if invItem ~= nil then
    		local obj = GetIES(invItem:GetObject());
            list[obj.GroupName] = list[obj.GroupName] or {}
            table.insert(list[obj.GroupName],{dictionary.ReplaceDicIDInCompStr(obj.Name),invItem.count})
        end
	end
    local cid = info.GetCID(session.GetMyHandle())
    acutil.saveJSON(g.settingPath..cid..'.json',list)
    g.itemlist[cid] = list  
end
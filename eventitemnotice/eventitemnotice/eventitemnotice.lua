_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['EVENTITEMNOTICE'] = _G['ADDONS']['EVENTITEMNOTICE'] or {};
local g = _G['ADDONS']['EVENTITEMNOTICE'] 
g.itemID = 666165
g.itemAmout = 10
g.flag = false
function IS_EVENTITEM_FINISHED()
    if g.flag == true then return end
    local item = GetClassByType('Item',g.itemID)
    local invitem = session.GetInvItemByName(item.ClassName)    
    if invitem then
        if invitem.count == g.itemAmout then
            g.flag = true
            CHAT_SYSTEM(string.format("You've completed requirement the event items(%s : %d). '",item.Name,invitem.count))
        end
    end
end
function EVENTITEMNOTICE_ON_INIT(addon,frame)
    if g.name ~= GETMYPCNAME() then
        g.name = GETMYPCNAME()
        g.flag = false
    end
	addon:RegisterMsg('INV_ITEM_CHANGE_COUNT', 'IS_EVENTITEM_FINISHED');
end

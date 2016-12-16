_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['RESOURCEMANAGER'] = _G['ADDONS']['RESOURCEMANAGER'] or {};
local g = _G['ADDONS']['RESOURCEMANAGER'];

g.table = {
    {
        --flecher
        645250,
        645251,
        645252,
        645349,
        645567,
        645568
    },
    {
        -- dievdirbys
        645238,
        645239,
        645240,
        645241
    },
    {
        -- sapper
        645239,
        645240,
        645604,
        645605
    }
}
g.preset = 1;
g.isShowed = 1
g.posX = 1500;
g.posY = 200;
CHAT_SYSTEM("load Resource Manager");

function RESOURCEMANAGER_ON_INIT(addon,frame)
    local acutil = require('acutil');
     acutil.slashCommand("/rscm", RESOURCEMANAGER_COMMAND);
    local g = _G['ADDONS']['RESOURCEMANAGER'];
    g.addnon = addnon;
    g.frame = frame;
    setFrameText()
    frame:ShowWindow(g.isShowed);
end

function RESOURCEMANAGER_COMMAND(command)
    local g = _G['ADDONS']['RESOURCEMANAGER'];
    local cmd = table.remove(command, 1);
    if cmd == nil then
        RESOURCEMANAGER_TOGGLE()
        return
    end
    if (cmd == '1' or cmd == '2' or cmd == '3') then
        g.preset = tonumber(cmd);
        setFrameText()
        return
    end
    CHAT_SYSTEM('this command can use 1 or 2 or 3')
    CHAT_SYSTEM('/rscm : toggle on or off')
    CHAT_SYSTEM('/rscm number  1:flecher 2:dievdirbys 3:sapper')
end

function RESOURCEMANAGER_TOGGLE()
local g = _G['ADDONS']['RESOURCEMANAGER'];
    if g.isShowed == 1 then
        g.isShowed = 0;
        CHAT_SYSTEM('RESOURCEMANAGER IS OFF')
    else
        g.isShowed = 1;
        CHAT_SYSTEM('RESOURCEMANAGER IS ON')
    end
    g.frame:ShowWindow(g.isShowed);
end

function setFrameText()
    local g = _G['ADDONS']['RESOURCEMANAGER'];
    g.frame:SetPos(g.posX,g.posY)
    deleteFrameText(g.frame)
    local i = 1;
    items = GET_ITEM_NAME_AND_COUNT(g.table[g.preset]);
    for k,v in pairs(items) do
           local text = g.frame:CreateOrGetControl("richtext","ID_"..i,10,i*25 ,100,20)
            text:SetText(string.format("{#%s}{s20} %s : %d{/}{/}",getTextColor(v),k,v));
       i = i + 1; 
    end
end

function deleteFrameText(frame)
    local num = frame:GetChildCount()
    if num <= 1 then
        return;end
    for i = 2 ,num do
        local text = GET_CHILD(frame,"ID_"..i,"ui::CRichText")
        if text ~= nil then
            text:SetText('')
        end
    end
end

function getTextColor(count)
    local color = 'FFFFFF';
    if(count < 100) then
        color = 'FF4500'
    end
    if(count < 50) then
        color = 'FF0000'
    end
    return color
end

function GET_ITEM_NAME_AND_COUNT(table)
    local inventoryItems = session.GetInvItemList();
	local items = {}

	if inventoryItems == nil then
        return nil;end

    local index = inventoryItems:Head();
    local itemCount = session.GetInvItemList():Count();

    for i = 0, itemCount - 1 do
        local inventoryItem = inventoryItems:Element(index);
        index = inventoryItems:Next(index);
        
        if inventoryItem == nil then
            break;end
        
        local itemObj = GetIES(inventoryItem:GetObject());
        if itemObj == nil then
            break;end

        
        for i, value in ipairs(table) do
            if (itemObj.ClassID == value) then
                items[itemObj.Name] = inventoryItem.count
            end
        end        
    end
    return items;
end

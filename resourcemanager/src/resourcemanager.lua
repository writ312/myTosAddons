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
    },{
        -- rune
        645750

    }
}
g.counter = 0;
g.preset = 1;
g.isShowed = 1
g.posX = 1570
g.posY = 200

CHAT_SYSTEM("load Resource Manager");

function RESOURCEMANAGER_COUNTER()
    local g = _G['ADDONS']['RESOURCEMANAGER'];
    if g.counter < 20 then
        g.counter = g.counter + 1;
        return
    end
    g.counter = 0;
    RESOURCEMANAGER_SET_TEXT()
end

function RESOURCEMANAGER_ON_INIT(addon,frame)
    local acutil = require('acutil');
    acutil.slashCommand("/rscm", RESOURCEMANAGER_COMMAND);
    acutil.setupEvent(addon,"FPS_UPDATE","RESOURCEMANAGER_COUNTER")

    local g = _G['ADDONS']['RESOURCEMANAGER'];
    g.addnon = addnon;
    g.frame = frame;
    RESOURCEMANAGER_SET_TEXT()
    frame:ShowWindow(g.isShowed);
    g.frame:Resize(350,180)

end

function RESOURCEMANAGER_COMMAND(command)
    local g = _G['ADDONS']['RESOURCEMANAGER'];
    local cmd = table.remove(command, 1);
    if cmd == nil then
        RESOURCEMANAGER_TOGGLE()
        return
    end
    if (cmd == '1' or cmd == '2' or cmd == '3'or cmd=='4') then
        g.preset = tonumber(cmd);
        RESOURCEMANAGER_SET_TEXT()
        return
    end
    CHAT_SYSTEM('this command can use 1 or 2 or 3 or 4')
    CHAT_SYSTEM('/rscm : toggle on or off')
    CHAT_SYSTEM('/rscm number  1:Flecher 2:Dievdirbys 3:Sapper 4:RuneCaster')
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


function RESOURCEMANAGER_SET_TEXT()
    local g = _G['ADDONS']['RESOURCEMANAGER'];
    g.frame:SetPos(g.posX,g.posY)
    g.frame:RemoveAllChild()
    local i = 1;
    local items ,itemSum = GET_ITEM_NAME_AND_COUNT(g.table[g.preset]);
    if itemSum == 0 then
        return;end
    local size = 23
    for k,v in pairs(items) do
        local icon = g.frame:CreateOrGetControl("slot","icon_"..i,size,(i - 0.5)*(size+5),size,size)
        SET_SLOT_ITEM_CLS(icon,GetIES(v:GetObject()))
        local text = g.frame:CreateOrGetControl("richtext","txt_"..i,size*2,(i - 0.5)*(size+5) ,100,size)
        text:SetText(string.format("{#%s}{s%d} %s:%d{/}{/}",getTextColor(v.count),size,k,v.count));
       i = i + 1; 
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
    local sum = 0

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
                items[itemObj.Name] = inventoryItem
                sum = sum + 1
            end
        end        
    end
    return items,sum;
end
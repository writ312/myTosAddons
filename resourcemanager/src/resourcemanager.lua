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
g.preset = 1;
g.posX = 1570
g.posY = 200
g.frameName = 'resourcemanager'
g.frameVisual = 1
CHAT_SYSTEM("load Resource Manager");

function RESOURCEMANAGER_ON_INIT(addon,frame)
    local g = _G['ADDONS']['RESOURCEMANAGER'];
    g.addnon = addnon;
    g.frame = frame;
    frame:SetGravity(ui.LEFT, ui.TOP)
    frame:ShowWindow(g.frameVisual)
    local acutil = require('acutil');
    RESOURCEMANAGER_SET_ICON()
    acutil.slashCommand("/rscm", RESOURCEMANAGER_COMMAND);
    acutil.setupEvent(addon,"FPS_UPDATE","RESOURCEMANAGER_UPDATE_TXT")
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
        RESOURCEMANAGER_SET_ICON()
        return
    end
    CHAT_SYSTEM('this command can use 1 or 2 or 3 or 4')
    CHAT_SYSTEM('/rscm : toggle on or off')
    CHAT_SYSTEM('/rscm number  1:Flecher 2:Dievdirbys 3:Sapper 4:RuneCaster')
end

function RESOURCEMANAGER_TOGGLE()
    local g = _G['ADDONS']['RESOURCEMANAGER'];
    ui.ToggleFrame(g.frameName)    
    g.frameVisual = ui.IsFrameVisible(g.frameName)

    local msg = (g.frameVisual == 1) and 'ON' or 'OFF'
    CHAT_SYSTEM(g.frameName..' is '..msg)
end

function RESOURCEMANAGER_SET_ICON()
    local g = _G['ADDONS']['RESOURCEMANAGER'];
    local frame = ui.GetFrame('resourcemanager')
    frame:SetPos(g.posX,g.posY)
    frame:RemoveAllChild()
    local i = 0;
    local items = GET_ITEM_COUNT(g.table[g.preset]);
    for k,v in pairs(items) do
        if v ~= 0 then
            local item = GetClassByType('Item',k)
            local slot = frame:CreateOrGetControl("slot","slot"..i,45*i + 5,10,45,45)
            tolua.cast(slot, 'ui::CSlot')

            local icon = CreateIcon(slot);
            icon:SetImage(item.Icon)

            local text = slot:CreateOrGetControl("richtext","txt"..k,0,0,60,20)
            tolua.cast(text, 'ui::CRichText')
            text:SetText(string.format("{#%s}{s%d}%d{/}{/}",getTextColor(v),22,v));
            text:SetGravity(ui.RIGHT,ui.BOTTOM)
            i = i + 1;
        end
    end
    frame:Resize(45 * i + 10 ,60)
end
function RESOURCEMANAGER_UPDATE_TXT()
    local frame = ui.GetFrame('resourcemanager')
    local g = _G['ADDONS']['RESOURCEMANAGER'];
    local items = GET_ITEM_COUNT(g.table[g.preset]);
    for k,v in pairs(items) do
        local text = GET_CHILD_RECURSIVELY(frame, "txt"..k, "ui::CRichText");
        if text then
            text:SetText(string.format("{#%s}{s%d}%d{/}{/}",getTextColor(v),22,v));
        end
    end
end

function getTextColor(count)
    local color = (count < 100) and 'FF4500';
    color = (count < 50) and 'FF0000' or color
    return color or 'FFFFFF'
end

function GET_ITEM_COUNT(list)
       local items = {}
    for i,value in ipairs(list) do
        local item = GetClassByType('Item',value)
        item = session.GetInvItemByName(item.ClassName)    
        if item ~= nil then
            items[value] = item.count
        else 
            items[value] = 0;
        end
    end
    return items
end
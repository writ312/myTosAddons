_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['WRIT'] = _G['ADDONS']['WRIT'] or {};
_G['ADDONS']['WRIT']['MONEYDIFF'] = _G['ADDONS']['WRIT']['MONEYDIFF'] or {};
local g = _G['ADDONS']['WRIT']['MONEYDIFF'];

CHAT_SYSTEM("load money diff");

function MONEYDIFF_ON_INIT(addon,frame)
    MONEYDIFF_INIT()
end

function MONEYDIFF_INIT()
    local g = _G['ADDONS']['WRIT']['MONEYDIFF'];
    local acutil = require("acutil")

    g.money = g.money or GET_PC_MONEY()
    g.name = g.name or GETMYPCNAME()
    g.map = g.map or session.GetMapName()
    
    if not string.find(g.name,GETMYPCNAME()) then
        g.money = GET_PC_MONEY();
        g.name = GETMYPCNAME()
        g.map =  session.GetMapName()
    return;end

    if string.find(g.map ,session.GetMapName())then
    return;end

    local nowMoney = GET_PC_MONEY();
    local diff = nowMoney - g.money;
    if diff > 10000 then
        local mapName = geMapTable.GetMapProp(g.map):GetName()
        CHAT_SYSTEM(string.format("%s：%ss Get",mapName,acutil.addThousandsSeparator(diff)))
    end
    g.money = nowMoney;
    g.map = session.GetMapName()
end
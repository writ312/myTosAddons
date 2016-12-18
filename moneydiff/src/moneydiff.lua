_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['WRIT'] = _G['ADDONS']['WRIT'] or {};
_G['ADDONS']['WRIT']['MONEYDIFF'] = _G['ADDONS']['WRIT']['MONEYDIFF'] or {};
local g = _G['ADDONS']['WRIT']['MONEYDIFF'];

CHAT_SYSTEM("load money diff");

function MONEYDIFF_ON_INIT(addon,frame)
    local g = _G['ADDONS']['WRIT']['MONEYDIFF'];
    if (g.money == nil or g.money == 0) then
        g.money = GET_PC_MONEY();
    end

    local nowMoney = GET_PC_MONEY();
    local diff = nowMoney - g.money;
    if diff > 10000 then
        CHAT_SYSTEM(string.format("先程のマップでは %d silver 取得しました",diff))
    end
    g.money = nowMoney;
end
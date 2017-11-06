_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['ACCOUNTBOOK'] = _G['ADDONS']['ACCOUNTBOOK'] or {};
local g = _G['ADDONS']['ACCOUNTBOOK'];
local acutil = require('acutil');
local today = os.date("%yy%mm%dd")
local folderPath = '../addons/accountbook/'
local isFirstLoad = true

-- ログイン記録の保存
g.loginRecord ,e = acutil.loadJSON(folderPath..'loginRecord.json',nil)  
if(e) then
    table.push(g.loginRecord,today)
    acutil.saveJSON(folderPath ..'loginRecord.json',g.loginRecord)
else
    if #g.loginRecord < 3 then
        table.push(g.loginRecord,today)
    elseif g.loginRecord[3] ~= today then
        table.remove(g.loginRecord,1)
        table.push(g.loginRecord,today)
    end
end    

-- 本日と過去のデータ読み込み又は作成
g.accountBook = {}
for i,date in ipars(g.loginRecord) do
    if date then
        local tempBook,e = acutil.loadJSON(folderPath..date..'.json')
        g.accountBook[i] = tempBook or {}
        acutil.saveJSON(folderPath..date..'.json',g.accountBook[i])
    end
end

-- init処理
function ACCOUNTBOOK_ON_INIT(addon,frame)
    addon:RegisterMsg('INV_ITEM_ADD', 'ACCOUNTBOOK_UPDATE');
    addon:RegisterMsg('INV_ITEM_REMOVE', 'ACCOUNTBOOK_UPDATE');
    addon:RegisterMsg('INV_ITEM_CHANGE_COUNT', 'ACCOUNTBOOK_UPDATE');

-- mapが同じなら記録継続
    if string.find(g.map ,session.GetMapName())then
    return;end

--　一時帳簿をプッシュ 初回ならスルー
    if not isFirstLoad then
        g.accountBook[g.user] = g.accountBook[g.user] or {}
        table.push(g.accountBook[g.user],g.tempBook)
        isFirstLoad = false
    end
    g.user = GETMYPCNAME()
    g.money =  GET_PC_MONEY()
    g.map = session.GetMapName()
    g.tempBook = {}
    t.tempBook.map = g.map
end

function ACCOUNTBOOK_UPDATE(frame, msg, guid, invIndex)
-- vis == シルバー
    local obj = GetObjectByGuid(guid)
    if obj.ClassName ~= 'Vis' then
        return
    end
-- 現在のお金と差分の計算
    local money = GET_PC_MONEY();
    local diff = money - g.money;
    g.money = money;
-- 差分を一時帳簿に付ける 
    if diff <= 0 then
        g.tempBook.expenses = g.tempBook.expenses - diff 
    else
        g.tempBook.incomes = g.tempBook.incomes + diff
    end
end

local function accountBookCreateAssetGBox(frame,x,y)
local gbox = frame:CreateControl
end

function ACCOUNTBOOK_CREATE_ASSET_FRAME(frame,control,argStr,argNum)
    
end

local function ACCOUNTBOOK_CREATE_USERS_FRAME(frame,control,argStr,argNum)

end

function ACCOUNTBOOK_CREATE_FRAME()

end

function ACCOUNTBOOK_OPEN()
    ui.ToggleFrame('accountbook')
end
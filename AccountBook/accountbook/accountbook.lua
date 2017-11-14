_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['ACCOUNTBOOK'] = _G['ADDONS']['ACCOUNTBOOK'] or {};
local g = _G['ADDONS']['ACCOUNTBOOK'];
local acutil = require('acutil');
local today = os.date("%yy%mm%dd")
local folderPath = '../addons/accountbook/'
local isFirstLoad = true
local today
local todayIndex = 1
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
    todayIndex = i
    today = date
end

--jsonの構造とか
-- yymmdd.json
-- users:{
--     writ:{
--         [
--             {
--                 map:"Klaipe",
--                 expenses:10000,
--                 incomes:5000
--             }
--         ]
--     }
-- },
-- total:{
--     writ:{
--         expenses:100000,
--         incomes:500000
--     }
-- }
g.totalAsset , e = acutil.loadJSON(folderPath..'totalAsset.json')
if e then
    g.totalAsset = {}
    g.totalAsset.userMoeny = {}
    acutil.saveJSON(folderPath..'totalAsset.json')
end
-- totalAsset.json
-- {
--     deposit : 10000,
--     usersMoeny : {
--         hoge : 880
--     }
-- }

-- init処理
function ACCOUNTBOOK_ON_INIT(addon,frame)
    ACCOUNTBOOK_CREATE_FRAME(frame)
    addon:RegisterMsg('INV_ITEM_ADD', 'ACCOUNTBOOK_UPDATE');
    addon:RegisterMsg('INV_ITEM_REMOVE', 'ACCOUNTBOOK_UPDATE');
    addon:RegisterMsg('INV_ITEM_CHANGE_COUNT', 'ACCOUNTBOOK_UPDATE');
    acutil.setupEvent(addon,'ACCOUNTWAREHOUSE_CLOSE','ACCOUNTBOOK_SAVE_WAREHOUSE_MONEY')
-- mapが同じなら記録継続
    if string.find(g.map ,session.GetMapName())then
    return;end

--　一時帳簿をプッシュ 初回ならスルー
    if not isFirstLoad then
        g.accountBook[todayIndex][g.user] = g.accountBook[todayIndex][g.user] or {}
        table.push(g.accountBook[todayIndex][g.user],g.tempBook)
        isFirstLoad = false
        acutil.saveJSON(folderPath..today..'.json',g.accountBook[todayIndex])
        
    end
    --キャラが違ったら所持金を保存し、総支出と総収入の計算
    if not string.find(g.user ,GET_PC_MONEY() then
        g.totalAsset.userMoeny[g.user] = g.money
        local totalExpenses = 0
        local totalIncomes = 0
        for i , item in ipars(g.accountbook.users[g.user]) do
            totalExpenses = totalExpenses + item.expenses
            totalIncomes = totalIncomes + item.incomes
        end
        g.accountBook.total[g.user].expenses = totalExpenses
        g.accountBook.total[g.user].incomes = totalIncomes
    end
    g.user = GETMYPCNAME()
    g.money =  GET_PC_MONEY()
    g.map = session.GetMapName()
    g.tempBook = {}
    t.tempBook.map = g.map
end

--
function ACCOUNTBOOK_SAVE_WAREHOUSE_MONEY()
    local itemList = session.GetEtcItemList(IT_ACCOUNT_WAREHOUSE);
    local index = itemList:Head();
    local itemCnt = itemList:Count();
    local deposit = 0;

    while itemList:InvalidIndex() ~= index do
        local invItem = itemList:Element(index);
        local obj = GetIES(invItem:GetObject());
        if obj.ClassName == MONEY_NAME then
            g.totalAsset.deposit = deposit
            acutil.saveJSON(folderPath..'totalAsset.json')    
            return;
        end
    index = itemList:Next(index);
    end
end
function ACCOUNTBOOK_UPDATE(frame, msg, guid, invIndex)
-- vis == シルバー
    local obj = GetObjectByGuid(guid)
    if obj.ClassName ~= 'Vis' then
        return
    end
-- 現在のお金と差分の計算
    local money = session.GetInvItemByName('Vis').count;
    local diff = money - g.money;
    g.money = money;
-- 差分を一時帳簿に付ける 
    if diff <= 0 then
        g.tempBook.expenses = g.tempBook.expenses - diff 
    else
        g.tempBook.incomes = g.tempBook.incomes + diff
    end
end

local function accountBookCreateAssetGBox(frame,index,x,y)
    local width , height = 300 , 200
    local gbox = frame:CreateOrGetControl('groupbox','assetGbox'..index, 10 + (index - 1)%3*width, 10 + (index - 1)%3*height, width, height)

end

function ACCOUNTBOOK_CREATE_ASSET_FRAME(frame,control,username,index)
    local accountBook = g.accountBook[index][username]
    local 
end

local function accountbookCreateAssetItem(gbox,username,index)
    local accountBook = g.accountBook[index][username]
    for i , item in ipars(accountBook) do
        local itemGbox = gbox:CreateOrGetControl('groupbox','itemGbox'..i,10,(i-1)*100+10,180,90)
        local mapName = itemGbox:CreateOrGetControl('richtext','mapName',5,5,170,25)
        mapName:SetText(item.map) 
        
        local incomesText = itemGbox:CreateOrGetControl('richtext','incomesText',5,35,85,45)
        incomesText:SetText('INCOMES{nl}'..item.incomes)
        local expensesText = itemGbox:CreateOrGetControl('richtext','expensesText',95,40,85,45)
        expensesText:SetText('EXPENSES{nl}'..item.expenses)
    end 
end

-- フレーム右側の家計簿部分の作成
function ACCOUNTBOOK_CREATE_USER_ASSET_FRAME(frame,control,username,argNum)
    -- local accountBook = g.accountBook[todayIndex][argStr]
    local assetGbox = frame:GetChild('assetGbox')
    for i , date in ipars(g.loginRecord) do
        local gbox = assetGbox:CreateOrGetControl('groupbox',date..'Gbox',(i-1)*200+10,10,200,600)
        accountbookCreateAssetItem(gbox,username,i)
    end
end

--フレーム左側のユーザー選択メニューの作成
function ACCOUNTBOOK_CREATE_USERSLIST_FRAME(frame,gbox)
    local i = 0
    local btn = gbox:CreateOrGetControl('button','totalAssetBtn',10,30*i + 10,80,20)
    btn:SetEventScript(ui.LBTNUP,'ACCOUNTBOOK_CREATE_TOTAL_ASSET_FRAME')
    btn:SetText('Total')
    i = i  + 1
    end
    for username , v in pars(g.accountBook[todayIndex]) do
        local btn = gbox:CreateOrGetControl('button','userBtn_'..username,10,30*i + 10,80,20)
        btn:SetEventScript(ui.LBTNUP,'ACCOUNTBOOK_CREATE_USER_ASSET_FRAME')
        btn:SetEventScriptArgString(ui.LBTNUP,username)
        btn:SetText(username)
        i = i  + 1
    end
end

function ACCOUNTBOOK_CREATE_FRAME(frame)
    local usersGbox = frame:CreateOrGetControl('groupbox','usersGbox',20,20,100,600)
    ACCOUNTBOOK_CREATE_USERSLIST_FRAME(frame,usersGbox)
    local assetGbox = frame:CreateOrGetControl('groupbox','assetGbox',120,20,650,600)
    ACCOUNTBOOK_SET_ASSET_FRAME(frame,nil,g.user,0)
end

function ACCOUNTBOOK_OPEN()
    ui.ToggleFrame('accountbook')
end
_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['MARKETHISTORY'] = _G['ADDONS']['MARKETHISTORY'] or {};
local g = _G['ADDONS']['MARKETHISTORY'] 
local acutil = require('acutil')

local function CreateHistoryModeBtn(frame)
    local btn = frame:CreateOrGetControl("button","historyBtn",0,0,200,45)
    btn:SetOffset(1210,105)
    tolua.cast(btn,'ui::CButton')
    btn:SetSkinName('tab2_btn')
    btn:SetText('{@st66b18}履歴')
    btn:SetEventScript(ui.LBUTTONUP, 'MARKET_HISTORY_MODE');
end

local function SaveMarketHistroy(type,item)
    local list = g.list[type]
    if #list >  10 then
        for i = 1 , #list - 10 do
            table.remove(list,1)
        end
    end
    local now = os.date('*t')
    item.date = string.format('%2s/%2s',now.month,now.day)
    table.insert(list,item)
    g.list[type] = list
    acutil.saveJSON(g.settingsFileLoc, g.list);
end

function CREATE_HISTORY_LIST(frame,ctrl,type,argNum)
    frame = ui.GetFrame('markethistory')
   	local itemlist = GET_CHILD(frame, "itemlist", "ui::CDetailListBox");
	itemlist:RemoveAllChild();
	
	local title = GET_CHILD_RECURSIVELY(frame,"selectTitle","ui::CRichText")
	if type == "sell" then
		title:SetText('{@st43}{s24}販売履歴')
	else
		title:SetText('{@st43}{s24}購入履歴')
	end
	local list = g.list[type]
    if not list then return end
	
    local count = #list
    for i = 1 , count  do
        local marketItem = list[i];
		

		local ctrlSet = INSERT_CONTROLSET_DETAIL_LIST(itemlist, i, 0, "market_sell_item_detail");
        local pic = GET_CHILD(ctrlSet, "pic", "ui::CPicture");
		pic:SetImage(marketItem.icon);

		local name = ctrlSet:GetChild("name");
		name:SetTextByKey("value", marketItem.name);

		local itemCount = ctrlSet:GetChild("count");
		itemCount:SetTextByKey("value", marketItem.count);

		local price = ctrlSet:GetChild("silverFee");
		price:SetTextByKey("value",  acutil.addThousandsSeparator(marketItem.price));

		local totalPrice = ctrlSet:GetChild("totalPrice");
		totalPrice:SetTextByKey("value",  acutil.addThousandsSeparator(marketItem.count *  marketItem.price));
	
		ctrlSet:GetChild("btn"):ShowWindow(0)
    end

	itemlist:RealignItems();
	GBOX_AUTO_ALIGN(itemlist, 10, 0, 0, false, true);
end

function MARKET_SELLMODE_HOOK(frame)
	ui.CloseFrame("market");
	ui.CloseFrame("market_cabinet");
	ui.CloseFrame("markethistory");    
	ui.OpenFrame("market_sell");
	ui.OpenFrame("inventory");
end

function MARKET_BUYMODE_HOOK(frame)
	ui.OpenFrame("market");
	ui.CloseFrame("market_sell");
	ui.CloseFrame("market_cabinet");
	ui.CloseFrame("markethistory");    
end

function MARKET_CABINET_MODE_HOOK(frame)
	ui.CloseFrame("market");
	ui.CloseFrame("market_sell");
	ui.CloseFrame("markethistory");    
	ui.OpenFrame("market_cabinet");
end

function MARKET_HISTORY_MODE(frame)
	ui.CloseFrame("market");
	ui.CloseFrame("market_sell");
	ui.CloseFrame("market_cabinet");    
	ui.OpenFrame("markethistory");
end

function _BUY_MARKET_ITEM_HOOK(row)
	local frame = ui.GetFrame("market");

	local totalPrice = 0;
	local itemlist = GET_CHILD(frame, "itemlist", "ui::CDetailListBox");
	market.ClearBuyInfo();

	local child = itemlist:GetChildByIndex(row);
	local childCnt = child:GetChildCount();
    local buyCount , price
	for i = 0, childCnt - 1 do
		local ctrl = child:GetChildByIndex(i);
        if ctrl:GetClassName() == "numupdown" then
            local numUpDown = tolua.cast(ctrl, "ui::CNumUpDown");
            buyCount = numUpDown:GetNumber();
            if buyCount > 0 then
                local marketItem = session.market.GetItemByIndex(row-1);
                market.AddBuyInfo(marketItem:GetMarketGuid(), buyCount);
                price = marketItem.sellPrice
                totalPrice = totalPrice + buyCount * marketItem.sellPrice;
            else
                ui.SysMsg(ScpArgMsg("YouCantBuyZeroItem"));
            end
        end
	end

	if totalPrice == 0 then
		return;
	end

	local myMoney = GET_TOTAL_MONEY();
	if totalPrice > myMoney then
		ui.SysMsg(ClMsg("NotEnoughMoney"));
		return;
	end

    local pic = GET_CHILD(child, "pic", "ui::CPicture");
    local item = {}
    item.price = price
    item.count = buyCount
    item.name = child:GetChild('name'):GetTextByKey('value')
    item.icon = pic:GetImageName()
    SaveMarketHistroy('buy',item)

	market.ReqBuyItems();

end

function ON_MARKET_REGISTER_HOOK(frame, msg, argStr, argNum)
	ui.SysMsg(ClMsg("MarketItemRegisterSucceeded"));

	local groupbox = frame:GetChild("groupbox");
    local slot_item = GET_CHILD(groupbox, "slot_item", "ui::CSlot");
    local icon = slot_item:GetIcon()

	local item = {}
    item.name = frame:GetChildRecursively("itemname"):GetTextByKey("name")
    item.price = frame:GetChildRecursively("edit_price"):GetText()
    item.count = frame:GetChildRecursively("edit_count"):GetText()
    item.icon = icon:GetInfo().imageName
    SaveMarketHistroy('sell',item)
	CLEAR_SLOT_ITEM_INFO(slot_item);
	MARKET_SELL_UPDATE_SLOT_ITEM(frame);
end

function MARKETHISTORY_ON_INIT(addon,frame)
    acutil.setupHook(MARKET_SELLMODE_HOOK, "MARKET_SELLMODE");
	acutil.setupHook(MARKET_BUYMODE_HOOK, "MARKET_BUYMODE");
	acutil.setupHook(MARKET_BUYMODE_HOOK, "MARKET_BUYMODE");
	acutil.setupHook(MARKET_CABINET_MODE_HOOK, "MARKET_CABINET_MODE");
	acutil.setupHook(_BUY_MARKET_ITEM_HOOK, "_BUY_MARKET_ITEM");
	acutil.setupHook(ON_MARKET_REGISTER_HOOK, "ON_MARKET_REGISTER");
    
    local user = GETMYPCNAME()
    if g.user ~= user then
        g.settingsFileLoc = string.format('../addons/markethistory/%s.json',user)
        g.list, err = acutil.loadJSON(g.settingsFileLoc, g.settings)
		if err then
			g.list = {}
			g.list.sell = {}
			g.list.buy = {}
			acutil.saveJSON(g.settingsFileLoc, g.list);
		end
    end
   CreateHistoryModeBtn(ui.GetFrame('market')) 
   CreateHistoryModeBtn(ui.GetFrame('market_sell')) 
   CreateHistoryModeBtn(ui.GetFrame('market_cabinet')) 
   CREATE_HISTORY_LIST(frame,nil,'sell',nil)
end

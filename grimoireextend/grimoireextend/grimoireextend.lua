_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['GRIMOIREEXTEND'] = _G['ADDONS']['GRIMOIREEXTEND'] or {};
local g = _G['ADDONS']['GRIMOIREEXTEND'] 
local acutil = require('acutil');
local maxCardList = 5
g.setList ,e = acutil.loadJSON('../addons/grimoireextend/cardList.json',nil)
if(e) then
    g.setList = {}
    acutil.saveJSON('../addons/grimoireextend/cardList.json',g.setList)
end    

local function _grimoireSetCard(slotnumber,cardGUID)
    session.ResetItemList();
    session.AddItemID(cardGUID);
    local resultlist = session.GetItemIDList();
    item.DialogTransaction("SET_SORCERER_CARD", resultlist, string.format("%s %s", slotnumber, '1'));
end

local function grimoireEquipCardSet(i)
    local cardSet = g.setList[i]
    if not cardSet then return end
    if cardSet[1] then
        _grimoireSetCard('1',cardSet[1])
    end

    if cardSet[2] then
        _grimoireSetCard('2',cardSet[2])
    end
end

function GRIMOIREEXTEND_EQUIP_CARD(frame,control,argStr,index)
    grimoireEquipCardSet(index)
end

local function saveCardSet(setNum,slotNum,guid)
    if setNum and slotNum and guid then
        g.setList[setNum] =  g.setList[setNum] or {}
        g.setList[setNum][slotNum] = guid
    end
    acutil.saveJSON('../addons/grimoireextend/cardList.json',g.setList)
end
function GRIMOIREEXTEND_ON_DROP(frame,control,argStr,argNum)
    local slot = tolua.cast(slot,'ui::CSlot')
    local CardSetNum = math.floor(argNum/10)
    local slotNum = argNum % 10

	local liftIcon 			= ui.GetLiftIcon();
	local iconParentFrame 	= liftIcon:GetTopParentFrame();
	local iconInfo			= liftIcon:GetInfo();
	local invenItemInfo = session.GetInvItem(iconInfo.ext);

	if nil == invenItemInfo then
		return;
	end
	local tempobj = invenItemInfo:GetObject()
	local cardobj = GetIES(invenItemInfo:GetObject());

	if cardobj.GroupName ~= 'Card' then
		ui.SysMsg(ClMsg("PutOnlyCardItem"));
		return 
	end

	local cardItemCls = GetClassByType("Item", cardobj.ClassID);
	if nil == cardItemCls then
		ui.SysMsg(ClMsg("PutOnlyCardItem"));
		return;
	end
	local monCls = GetClassByType("Monster", cardItemCls.NumberArg1);
	if monCls == nil then
		ui.SysMsg(ClMsg("CheckCardType"));
		return;
	end

	if monCls.RaceType ~= 'Velnias' then
		ui.SysMsg(ClMsg("CheckCardType"));
		return;
	end
	local GUID = GetIESID(cardobj);
    if g.setList[CardSetNum][(slotNum == 1) and 2 or 1] == GUID then
    	ui.SysMsg(ClMsg("AlreadRegSameCard"))
        return
    end
    saveCardSet(CardSetNum,slotNum,GUID)
    GRIMOIREEXTEND_UPDATE_UI()
end

function GRIMOIREEXTEND_RELESE_SLOT(frame,control,argStr,argNum)
    local CardSetNum = math.floor(argNum/10)
    local slotNum = argNum % 10
    g.setList[CardSetNum][slotNum] = nil
    saveCardSet() 
    GRIMOIREEXTEND_UPDATE_UI()
end


function GRIMOIREEXTEND_UPDATE_UI()
    local frame = ui.GetFrame('grimoire');
    frame:Resize(750,1000)
    frame:GetChild('bg'):SetGravity(0,0)
    frame:GetChild('grimoireGbox'):SetGravity(0,0)
    frame:GetChild('pip4'):SetGravity(0,0)
    local cardSet = frame:CreateOrGetControl('groupbox','cardSetGbox',0,0,220,400)
    cardSet:SetGravity(1,0)
    cardSet:SetSkinName('pip_simple_frame')
    cardSet:SetOffset(70,50)
    cardSet:RemoveAllChild()
    local cardBox = {}
    local wid = 200
    local hei = 120
    for i = 1 , maxCardList do
        g.setList[i] = g.setList[i] or {}
        cardBox[i] = cardSet:CreateOrGetControl('groupbox','cardBox'..i, 10,(i - 1)*hei + 20,wid,hei)
        cardBox[i]:SetSkinName('test_frame_low')
        local slot1 = cardBox[i]:CreateOrGetControl('slot','slot1',10,10,65,100)        
        AUTO_CAST(slot1)
        slot1:SetSkinName('slot')
        slot1:SetEventScript(ui.DROP,'GRIMOIREEXTEND_ON_DROP')
        slot1:SetEventScriptArgNumber(ui.DROP,i * 10 + 1)
        slot1:SetEventScript(ui.RBUTTONUP,'GRIMOIREEXTEND_RELESE_SLOT')
        slot1:SetEventScriptArgNumber(ui.RBUTTONUP,i * 10 + 1)
        slot1:EnablePop(0)
        if session.GetInvItemByGuid(g.setList[i][1]) then
            CreateIcon(slot1):SetImage(GetObjectByGuid(g.setList[i][1]).TooltipImage)
        end 
    
       local slot2 = cardBox[i]:CreateOrGetControl('slot','slot2',80,10,65,100)
        AUTO_CAST(slot2)
        slot2:SetSkinName('slot')
        slot2:SetEventScript(ui.DROP,'GRIMOIREEXTEND_ON_DROP')
        slot2:SetEventScriptArgNumber(ui.DROP,i * 10 + 2)
        slot2:SetEventScript(ui.RBUTTONUP,'GRIMOIREEXTEND_RELESE_SLOT')
        slot2:SetEventScriptArgNumber(ui.RBUTTONUP,i * 10 + 2)
        slot2:EnablePop(0)
     
        if session.GetInvItemByGuid(g.setList[i][2]) then
            CreateIcon(slot2):SetImage(GetObjectByGuid(g.setList[i][2]).TooltipImage)
        end
    
        local pic = tolua.cast(cardBox[i]:CreateOrGetControl('picture','numberImg',0,0,20,20),'ui::CPicture')
        pic:SetImage(i)
        pic:SetEnableStretch(1)
    
        local btn = cardBox[i]:CreateOrGetControl('button','btn',145,15,50,90)
        btn:SetSkinName('test_cardtext_btn')
        btn:SetEventScript(ui.LBUTTONUP,'GRIMOIREEXTEND_EQUIP_CARD')
        btn:SetEventScriptArgNumber(ui.LBUTTONUP,i)
        btn:SetText('Equip')
    end
end

function GRIMOIREEXTEND_COMMAND(command)
    local number = tonumber(table.remove(command))
    if 1 <= number and maxCardList <= number then
        grimoireEquipCardSet(number)
    end
end

function GRIMOIREEXTEND_ON_INIT(addon, frame)
    acutil.slashCommand('/ge',GRIMOIREEXTEND_COMMAND)
    acutil.slashCommand('/grimoireextend',GRIMOIREEXTEND_COMMAND)
	GRIMOIREEXTEND_UPDATE_UI()
end

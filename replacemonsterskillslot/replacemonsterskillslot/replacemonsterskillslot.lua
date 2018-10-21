_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['REPLACEMONSTERSKILLSLOT'] = _G['ADDONS']['REPLACEMONSTERSKILLSLOT'] or {};
local g = _G['ADDONS']['REPLACEMONSTERSKILLSLOT']
local acutil = require('acutil')
g.setting = acutil.loadJSON('../addons/replacemonsterskillslot/setting.json') or {slotNum = 0}
acutil.saveJSON('../addons/replacemonsterskillslot/setting.json',g.setting)

local function GetHotKeySetting(idx)
	local obj = {}
	obj.idx = idx
	obj.key = config.GetHotKeyElementAttributeForConfig(idx, "Key")
	obj.useAlt = config.GetHotKeyElementAttributeForConfig(idx, "UseAlt")
	obj.useCtrl = config.GetHotKeyElementAttributeForConfig(idx, "UseCtrl")
	obj.useShift = config.GetHotKeyElementAttributeForConfig(idx, "UseShift")
	-- print(string.format("idx %d , key %s , alt %s , ctrl %s , shift %s ",obj.idx,obj.key,obj.useAlt,obj.useCtrl,obj.useShift))
	return obj
end

function SaveHotKeySetting()
	-- hoge foo あとで置換する
	g.hoge = {}
	for i = 0 , 4 do
		table.insert(g.hoge,GetHotKeySetting(i))
	end
	g.foo = {}
	for i = g.setting.slotNum , g.setting.slotNum + 4 do
		table.insert(g.foo , GetHotKeySetting(i))
	end
	acutil.saveJSON('../addons/replacemonsterskillslot/setting.json',g.setting)
end

local function swapSlotItems(srcIndex,destIndex)
	local frame= ui.GetFrame("quickslotnexpbar")
	local srcSlot = GET_CHILD_RECURSIVELY(frame, "slot"..srcIndex, "ui::CSlot")
	local destSlot = GET_CHILD_RECURSIVELY(frame, "slot"..destIndex, "ui::CSlot")
	local src = {
		index = srcIndex
	}
	local srcIcon = srcSlot:GetIcon()
	
	local dest = {
		index = destIndex
	}
	local destIcon = destSlot:GetIcon()
	if destIcon ~= nil then
		local iconInfo = destIcon:GetInfo()
		dest.category = iconInfo.category
		dest.invIndex = iconInfo.ext
		dest.type = iconInfo.type
		dest.guid = iconInfo:GetIESID()
	end
	if srcIcon ~= nil then
		SET_QUICK_SLOT(destSlot, src.category, src.type, src.guid, 1, true);
	end
	g.setting[g.user].src = src
	g.setting[g.user].dest = dest
end

function changeTransformingStatus()
	g.setting[g.user].transforming = false
	acutil.saveJSON('../addons/replacemonsterskillslot/setting.json',g.setting)
end

local function restoreQuickSlotItem()
	local dest = g.setting[g.user].dest
	local frame= ui.GetFrame("quickslotnexpbar")
	local destSlot = GET_CHILD_RECURSIVELY(frame, "slot"..dest.index, "ui::CSlot")
	SET_QUICK_SLOT(destSlot, dest.category, dest.type, dest.guid, 1, true);

	--キャラチェン対策(変更時に上記の処理が間に合わないため、フラグをOFFにさせない)
	ReserveScript('changeTransformingStatus()',5.0)
end

local function swapQuickslotPos(srcIndex,destIndex)
	local frame= ui.GetFrame("quickslotnexpbar")
	local srcSlot = GET_CHILD_RECURSIVELY(frame, "slot"..srcIndex, "ui::CSlot")
	local destSlot = GET_CHILD_RECURSIVELY(frame, "slot"..destIndex, "ui::CSlot")

	local srcSlotMargin = srcSlot:GetMargin()
	local destSlotMargin = destSlot:GetMargin()

	local src = {
		x = srcSlotMargin.left,
		y = srcSlotMargin.top
	}
	local dest = {
		x = destSlotMargin.left,
		y = destSlotMargin.top
	}
	srcSlot:SetOffset(dest.x,dest.y)
	destSlot:SetOffset(src.x,src.y)
end

--あとで処理をまとめる
local function swapHotkeySetting(obj_1,obj_2,isChangePos)
	local idx_1 = obj_1.idx
	config.SetHotKeyElementAttributeForConfig(idx_1, "Key", obj_2.key);
	config.SetHotKeyElementAttributeForConfig(idx_1, "UseAlt", obj_2.useAlt);
	config.SetHotKeyElementAttributeForConfig(idx_1, "UseCtrl", obj_2.useCtrl);
	config.SetHotKeyElementAttributeForConfig(idx_1, "UseShift", obj_2.useShift);

	local idx_2 = obj_2.idx
	config.SetHotKeyElementAttributeForConfig(idx_2, "Key", obj_1.key);
	config.SetHotKeyElementAttributeForConfig(idx_2, "UseAlt", obj_1.useAlt);
	config.SetHotKeyElementAttributeForConfig(idx_2, "UseCtrl", obj_1.useCtrl);
	config.SetHotKeyElementAttributeForConfig(idx_2, "UseShift", obj_1.useShift);
	
	config.SaveHotKey('hotkey.xml')
	local frame = ui.GetFrame('quickslotnexpbar')
	QUICKSLOTNEXPBAR_UPDATE_HOTKEYNAME(frame);
	frame:Invalidate()
	if isChangePos then
		swapQuickslotPos(idx_1 +1,idx_2 +1)
	end
end

local function restoreHotkeySetting(obj_1,obj_2,isChangePos)
	local idx_1 = obj_1.idx
	config.SetHotKeyElementAttributeForConfig(idx_1, "Key", obj_1.key);
	config.SetHotKeyElementAttributeForConfig(idx_1, "UseAlt", obj_1.useAlt);
	config.SetHotKeyElementAttributeForConfig(idx_1, "UseCtrl", obj_1.useCtrl);
	config.SetHotKeyElementAttributeForConfig(idx_1, "UseShift", obj_1.useShift);

	local idx_2 = obj_2.idx
	config.SetHotKeyElementAttributeForConfig(idx_2, "Key", obj_2.key);
	config.SetHotKeyElementAttributeForConfig(idx_2, "UseAlt", obj_2.useAlt);
	config.SetHotKeyElementAttributeForConfig(idx_2, "UseCtrl", obj_2.useCtrl);
	config.SetHotKeyElementAttributeForConfig(idx_2, "UseShift", obj_2.useShift);
	
	config.SaveHotKey('hotkey.xml')
	local frame = ui.GetFrame('quickslotnexpbar')
	QUICKSLOTNEXPBAR_UPDATE_HOTKEYNAME(frame);
	frame:Invalidate()
	if isChangePos then
		swapQuickslotPos(idx_1 +1,idx_2 +1)
	end
end

function REPLACEMONSTERSKILLSLOT_ON_INIT(addon,frame)
	g.addon = addon
	g.frame = frame
	g.user = GETMYPCNAME()
    acutil.slashCommand("/monsterskill", REPLACEMONSTERSKILLSLOT_COMMAND);
    acutil.slashCommand("/replacemonsterskillslot", REPLACEMONSTERSKILLSLOT_COMMAND);
    acutil.slashCommand("/rmss", REPLACEMONSTERSKILLSLOT_COMMAND);
	acutil.setupHook(QUICKSLOTNEXPBAR_MY_MONSTER_SKILL_HOOK,'QUICKSLOTNEXPBAR_MY_MONSTER_SKILL')
	addon:RegisterMsg("GAME_START_3SEC","REPLACEMONSTERSKILLSLOT_INIT")
end

function REPLACEMONSTERSKILLSLOT_INIT()
	local frame = ui.GetFrame('keyconfig')
	KEYCONFIG_OPEN_CATEGORY(frame,'hotkey.xml','Battle')
	g.setting[g.user] = g.setting[g.user] or {}
	if g.setting[g.user].transforming then
		restoreQuickSlotItem()
		restoreHotkeySetting(g.hoge[g.lastSlotNum],g.foo[g.lastSlotNum],false)
		g.setting[g.user].transforming = false
		acutil.saveJSON('../addons/replacemonsterskillslot/setting.json',g.setting)
	end
	frame:SetCloseScript('SaveHotKeySetting')
	SaveHotKeySetting()
end

function REPLACEMONSTERSKILLSLOT_COMMAND(cmd)
    if #cmd > 0 then
        local slotNum = tonumber(table.remove(cmd,1))
        if slotNum > 0 then
            g.setting.slotNum = slotNum - 1
            CHAT_SYSTEM(string.format("Change Monster Skill Slot to %dth Quickslot",slotNum))
            acutil.saveJSON('../addons/replacemonsterskillslot/setting.json',g.setting)
            return 
        end
	end
	CHAT_SYSTEM(string.format("Monster Skill Slot to %dth Quickslot",g.setting.slotNum))
    CHAT_SYSTEM('Replace monster skill slot{nl}/rmss <QuickSlotNumber>{nl}ex) /rmss 11{nl}↑ change postion monster skill of quickslot to QWER from ASDF')
end

function QUICKSLOTNEXPBAR_MY_MONSTER_SKILL_HOOK(isOn, monName, buffType)
	local frame= ui.GetFrame("quickslotnexpbar")
    local slotNum = g.setting.slotNum
	if isOn == 1 then
        local monCls = GetClass("Monster", monName);
		local list = GetMonsterSkillList(monCls.ClassID);
		for i = slotNum, slotNum + list:Count() - 1 do
			local sklName = list:Get(i - slotNum);
			local sklCls = GetClass("Skill", sklName);
			local slot = GET_CHILD_RECURSIVELY(frame, "slot"..i+1, "ui::CSlot");
			tolua.cast(slot, "ui::CSlot");	
			local icon = slot:GetIcon();
			if icon ~= nil then
				local iconInfo = icon:GetInfo();
				slot:SetUserValue('ICON_CATEGORY', iconInfo.category);
				slot:SetUserValue('ICON_TYPE', iconInfo.type);
			end
			CLEAR_SLOT_ITEM_INFO(slot);
			local slotString 	= 'QuickSlotExecute'..(i+1);
			local text 			= hotKeyTable.GetHotKeyString(slotString);
			slot:SetText('{s14}{#f0dcaa}{b}{ol}'..text, 'default', 'left', 'top', 2, 1);
			local type = sklCls.ClassID;
			local icon = CreateIcon(slot);
			local imageName = 'icon_' .. sklCls.Icon;
			icon:Set(imageName, "Skill", type, 0);
			icon:SetOnCoolTimeUpdateScp('ICON_UPDATE_SKILL_COOLDOWN');
			icon:SetEnableUpdateScp('MONSTER_ICON_UPDATE_SKILL_ENABLE');
			icon:SetColorTone("FFFFFFFF");
			quickslot.OnSetSkillIcon(slot, type);
			SET_QUICKSLOT_OVERHEAT(slot);

			slot:EnableDrag(0);
		end
		local lastSlot = GET_CHILD_RECURSIVELY(frame, "slot"..(list:Count() +1 ), "ui::CSlot");
		local icon = lastSlot:GetIcon();
		if icon ~= nil then
			local iconInfo = icon:GetInfo();
			lastSlot:SetUserValue('ICON_CATEGORY', iconInfo.category);
			lastSlot:SetUserValue('ICON_TYPE', iconInfo.type);

		end
		swapSlotItems(list:Count()+1,list:Count() +1 +slotNum)
		CLEAR_SLOT_ITEM_INFO(lastSlot);
		local icon = CreateIcon(lastSlot);
		local slotString 	= 'QuickSlotExecute'..(list:Count() +1 );
		local text 			= hotKeyTable.GetHotKeyString(slotString);
		lastSlot:SetText('{s14}{#f0dcaa}{b}{ol}'..text, 'default', 'left', 'top', 2, 1);
		icon:SetImage("druid_del_icon");		
		lastSlot:EnableDrag(0);
		SET_QUICKSLOT_OVERHEAT(lastSlot);
		frame:SetUserValue('SKL_MAX_CNT',list:Count() + 1)
		g.setting[g.user].transforming = true
		g.lastSlotNum = list:Count()+1
		swapHotkeySetting(g.hoge[list:Count()+1],g.foo[list:Count()+1],true)
		acutil.saveJSON('../addons/replacemonsterskillslot/setting.json',g.setting)
		return;
	end

	local sklCnt = frame:GetUserIValue('SKL_MAX_CNT');
	if g.setting[g.user].transforming then
		restoreQuickSlotItem()
	end
	restoreHotkeySetting(g.hoge[sklCnt],g.foo[sklCnt],true)
	for i = 1 + slotNum, slotNum +  sklCnt do
		local slot = GET_CHILD_RECURSIVELY(frame, "slot"..i, "ui::CSlot");
		CLEAR_SLOT_ITEM_INFO(slot);	
		local slotString 	= 'QuickSlotExecute'..i;
		local text 			= hotKeyTable.GetHotKeyString(slotString);
		slot:SetText('{s14}{#f0dcaa}{b}{ol}'..text, 'default', 'left', 'top', 2, 1);
		local cate = slot:GetUserValue('ICON_CATEGORY');
		if 'None' ~= cate then
			SET_QUICK_SLOT(slot, cate, slot:GetUserIValue('ICON_TYPE'),  "", 0, 0);
	end
		slot:SetUserValue('ICON_CATEGORY', 'None');
		slot:SetUserValue('ICON_TYPE', 0);
		SET_QUICKSLOT_OVERHEAT(slot)
	end
	frame:SetUserValue('SKL_MAX_CNT',0)
end
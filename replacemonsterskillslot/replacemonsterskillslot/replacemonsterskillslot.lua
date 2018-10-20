_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['REPLACEMONSTERSKILLSLOT'] = _G['ADDONS']['REPLACEMONSTERSKILLSLOT'] or {};
local g = _G['ADDONS']['REPLACEMONSTERSKILLSLOT']
local acutil = require('acutil')
-- g.setting = acutil.loadJSON('../addons/replacemonsterskillslot/setting.json') or {slotNum = 0}
-- acutil.saveJSON('../addons/replacemonsterskillslot/setting.json',g.setting)

function REPLACEMONSTERSKILLSLOT_ON_INIT(addon,frame)
	g.addon = addon
    g.frame = frame
    acutil.slashCommand("/monsterskill", REPLACEMONSTERSKILLSLOT_COMMAND);
    acutil.slashCommand("/replacemonsterskillslot", REPLACEMONSTERSKILLSLOT_COMMAND);
    acutil.slashCommand("/rmss", REPLACEMONSTERSKILLSLOT_COMMAND);
	acutil.setupHook(QUICKSLOTNEXPBAR_MY_MONSTER_SKILL_HOOK,'QUICKSLOTNEXPBAR_MY_MONSTER_SKILL')

	acutil.setupHook(QUICKSLOTNEXPBAR_SLOT_USE_HOOK,"QUICKSLOTNEXPBAR_SLOT_USE")
	addon:RegisterMsg("BUFF_ADD", "TRANSFORM_BUFF_CHECK")
	addon:RegisterMsg("GAME_START_3SEC","REPLACEMONSTERSKILLSLOT_INIT")
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
		local lastSlot = GET_CHILD_RECURSIVELY(frame, "slot"..(list:Count() +1 +slotNum), "ui::CSlot");
		local icon = lastSlot:GetIcon();
		if icon ~= nil then
			local iconInfo = icon:GetInfo();
			lastSlot:SetUserValue('ICON_CATEGORY', iconInfo.category);
			lastSlot:SetUserValue('ICON_TYPE', iconInfo.type);
		end

		CLEAR_SLOT_ITEM_INFO(lastSlot);
		local icon = CreateIcon(lastSlot);
		local slotString 	= 'QuickSlotExecute'..(list:Count() +1 +slotNum);
		local text 			= hotKeyTable.GetHotKeyString(slotString);
		lastSlot:SetText('{s14}{#f0dcaa}{b}{ol}'..text, 'default', 'left', 'top', 2, 1);
		icon:SetImage("druid_del_icon");		
		lastSlot:EnableDrag(0);
		SET_QUICKSLOT_OVERHEAT(lastSlot);
		frame:SetUserValue('SKL_MAX_CNT',list:Count() + 1)
		
		return;
	end

	local sklCnt = frame:GetUserIValue('SKL_MAX_CNT');
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



function GetHotKeySetting(idx)
	local obj = {}
	obj.idx = idx
	obj.key = config.GetHotKeyElementAttributeForConfig(idx, "Key")
	obj.useAlt = config.GetHotKeyElementAttributeForConfig(idx, "UseAlt")
	obj.useCtrl = config.GetHotKeyElementAttributeForConfig(idx, "UseCtrl")
	obj.useShift = config.GetHotKeyElementAttributeForConfig(idx, "UseShift")
	print(string.format("idx %d , key %s , alt %s , ctrl %s , shift %s ",obj.idx,obj.key,obj.useAlt,obj.useCtrl,obj.useShift))
	return obj
end

function setHotkeySetting(obj,idx)
	if not idx then idx = obj.idx end
	config.SetHotKeyElementAttributeForConfig(idx, "Key", obj.key);
	config.SetHotKeyElementAttributeForConfig(idx, "UseAlt", obj.useAlt);
	config.SetHotKeyElementAttributeForConfig(idx, "UseCtrl", obj.useCtrl);
	config.SetHotKeyElementAttributeForConfig(idx, "UseShift", obj.useShift);
	config.SaveHotKey('hotkey.xml');
end

function repleceHotkeySetting()
	for i = 1 , 5 do
		setHotkeySetting(g.foo[i],g.hoge[i].idx)
	end
	local quickSlotFrame = ui.GetFrame("quickslotnexpbar");
	QUICKSLOTNEXPBAR_UPDATE_HOTKEYNAME(quickSlotFrame);
	quickSlotFrame:Invalidate();
end

function restoreHoekeySetting()
	for i = 1, 5 do
		setHotkeySetting(g.hoge[i])
	end
	local quickSlotFrame = ui.GetFrame("quickslotnexpbar");
	QUICKSLOTNEXPBAR_UPDATE_HOTKEYNAME(quickSlotFrame);
	quickSlotFrame:Invalidate();
end

function REPLACEMONSTERSKILLSLOT_INIT()

	local cid = info.GetCID(session.GetMyHandle())
    local pcSession = session.GetSessionByCID(cid);
    local pcJobInfo = pcSession.pcJobInfo;
    local cnt = pcJobInfo:GetJobCount();
    local n = 1
    local tempTable = {}
    g.presetTable = {}
    for i = 0 , cnt - 1 do
        local jobID = pcJobInfo:GetJobByIndex(i);
        if jobID == -1 then
            break;
		end
		if jobID == 4005 then 
			g.isDruid = true
		end
	end

	local frame = ui.GetFrame('keyconfig')
	KEYCONFIG_OPEN_CATEGORY(frame,'hotkey.xml','Battle')
	frame:SetCloseScript('REPLACEMONSTERSKILLSLOT_INIT')
	-- hoge foo あとで置換する
	g.hoge = {}
	for i = 0 , 4 do
		table.insert(g.hoge,GetHotKeySetting(i))
	end
	g.foo = {}
	for i = g.setting.slotNum , g.setting.slotNum + 4 do
		table.insert(g.foo , GetHotKeySetting(i))
	end
end

function TRANSFORM_BUFF_CHECK(frame, msg, argStr, buffid)
	if buffid == 6012 then
		-- restoreHoekeySetting()
	end
end

function QUICKSLOTNEXPBAR_SLOT_USE_HOOK(frame, slot, argStr, argNum)
	if GetCraftState() == 1 then
		return;
	end

	if ui.CheckHoldedUI() == true then
		return;
	end

	tolua.cast(slot, "ui::CSlot");
	local icon = slot:GetIcon();
	if icon == nil then
		return;
	end

	local iconInfo = icon:GetInfo();

	if iconInfo.category == 'Skill' then    
		-- add
		print(iconInfo.type)
		if iconInfo.type == 40904 and g.isDruid then
			repleceHotkeySetting()
			ReserveScript(repleceHotkeySetting(),0.2)
		end
		ICON_USE(icon);
		return;
	end

	local invenItemInfo = session.GetInvItem(iconInfo.ext);
	if invenItemInfo == nil then
		invenItemInfo = session.GetInvItemByType(iconInfo.type);
	elseif invenItemInfo.type ~= iconInfo.type then
		return;
	end

	if invenItemInfo == nil then
		if iconInfo.category == 'Item' then
			icon:SetColorTone("FFFF0000");
			icon:SetText('0', 'quickiconfont', 'right', 'bottom', -2, 1);
		end
		return;
	end

	local itemobj = GetIES(invenItemInfo:GetObject());
	if TRY_TO_USE_WARP_ITEM(invenItemInfo, itemobj) == 1 then
		return;
	end
		
	if invenItemInfo.count == 0 then
		icon:SetColorTone("FFFF0000");
		icon:SetText(invenItemInfo.count, 'quickiconfont', 'right', 'bottom', -2, 1);
		return;
	end
		
	if true == BEING_TRADING_STATE() then
		return;
	end

	local invItemAllowReopen = ''
	if itemobj ~= nil then
		invItemAllowReopen = TryGetProp(itemobj, 'AllowReopen')
	end

	local groupName = itemobj.ItemType;
	local gachaCubeFrame = ui.GetFrame('gacha_cube')
	if groupName == 'Consume' and gachaCubeFrame ~= nil and gachaCubeFrame:IsVisible() == 1 and invItemAllowReopen == 'YES' then
		return
	end

	ICON_USE(icon);
end

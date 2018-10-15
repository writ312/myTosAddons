_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['REPLACEMONSTERSKILLSLOT'] = _G['ADDONS']['REPLACEMONSTERSKILLSLOT'] or {};
local g = _G['ADDONS']['REPLACEMONSTERSKILLSLOT']
local acutil = require('acutil')
g.setting = acutil.loadJSON('../addons/replacemonsterskillslot/setting.json') or {slotNum = 0}
acutil.saveJSON('../addons/replacemonsterskillslot/setting.json',g.setting)

function REPLACEMONSTERSKILLSLOT_ON_INIT(addon,frame)
	g.addon = addon
    g.frame = frame
    acutil.slashCommand("/monsterskill", REPLACEMONSTERSKILLSLOT_COMMAND);
    acutil.slashCommand("/replacemonsterskillslot", REPLACEMONSTERSKILLSLOT_COMMAND);
    acutil.slashCommand("/rmss", REPLACEMONSTERSKILLSLOT_COMMAND);
    acutil.setupHook(QUICKSLOTNEXPBAR_MY_MONSTER_SKILL_HOOK,'QUICKSLOTNEXPBAR_MY_MONSTER_SKILL')
end

function REPLACEMONSTERSKILLSLOT_COMMAND(cmd)
    if #cmd > 0 then
        local slotNum = tonumber(table.remove(cmd,1))
        if slotNum > 0 then
            g.setting.slotNum = slotNum - 1
            CHAT_SYSTEM(string.format("Change Monster Skill Slot to %dth quickslot",slotNum))
            acutil.saveJSON('../addons/replacemonsterskillslot/setting.json',g.setting)
            return 
        end
    end
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
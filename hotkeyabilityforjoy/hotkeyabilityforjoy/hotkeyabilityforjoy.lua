_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['HOTKEYABILITYFORJOY'] = _G['ADDONS']['HOTKEYABILITYFORJOY'] or {};
local g = _G['ADDONS']['HOTKEYABILITYFORJOY'];
local acutil = require('acutil')

g.user = nil;
g.setting = {}
g.settingPath = '../addons/hotkeyabilityforjoy/'

CHAT_SYSTEM('on load hotkey')   

function HOTKEYABILITYFORJOY_ON_INIT(addon,frame)
    g.addon = addon
    acutil.setupHook(MAKE_ABILITY_ICON_HOOK,'MAKE_ABILITY_ICON')
    acutil.setupHook(JOYSTICK_QUICKSLOT_ON_DROP_HOOK,'JOYSTICK_QUICKSLOT_ON_DROP')
    acutil.setupHook(LOAD_SESSION_CHAT_MACRO_HOOK,'LOAD_SESSION_CHAT_MACRO')

    acutil.slashCommand('/hotkey', HOTKEYABILITY_COMMAND)
    
    addon:RegisterMsg('GAME_START_3SEC','HOTKEYABILITY_SET_ICON')
    local user = GetMyName()
    if(g.user ~= user) then
        g.setting = {}
        g.user = user
    end
  
    g.setting ,e = acutil.loadJSON(g.settingPath..user..'.json',g.setting)
  
    if(e) then
        g.setting = {}
        return
    end    
end

function HOTKEYABILITY_SET_ICON()
    acutil.setupEvent(g.addon, 'JOYSTICK_QUICKSLOT_EXECUTE', 'JOYSTICK_QUICKSLOT_EXECUTE_EVENT')
    if  g.setting then
        local frame = ui.GetFrame('joystickquickslot')
        for k,v in pairs(g.setting) do
            if v[2] == 'Pose' then
                HOTKEYABILITY_SET_POSE_ICON(k,v[1])
            elseif v[2] == 'Macro' then
                local imageNum = tonumber(v[1])%10
                ui.GetFrame('joystickquickslot'):GetChildRecursively('slot'..k):GetIcon():SetImage('key'..imageNum)
            else
                HOTKEYABILITY_SET_ABIL_ICON(k,v[1])
            end         
            frame:GetChildRecursively('slot'..k):SetEventScript(ui.RBUTTONUP, 'HOTKEYABILITY_RBTN_FUNC');
        end
    end
end

function HOTKEYABILITY_COMMAND(command)
    local key = table.remove(command,1);
    
    if( key == 'd') then
        g.setting[table.remove(command,1)] = nil
        local slot = ui.GetFrame('joystickquickslot'):GetChildRecursively('slot'..k)
        slot:ClearIcon()
        CreateIcon(slot)
        acutil.saveJSON(g.settingPath..g.user..'.json',g.setting)
        return
    end
    
    if(key == 'list') then
        for k,v in pairs(g.setting) do
            if v[2] == 'Pose' then
                local cls = GetClassByType("Pose", v[1])
                CHAT_SYSTEM(string.format("%s : %s",k,cls.Name))
            elseif v[2] == 'Macro' then
                CHAT_SYSTEM(string.format('%s : Chat Macro %s',k,v[1]))
            else
                local abilID,abilName,abilClass = GetAbilityData(v[1])
                CHAT_SYSTEM(string.format("%s : %s",k,abilClass.Name))
            end
        end
        return
    end
    
    local num = tonumber(table.remove(command,1))

    local abilID = GetAbilityData(num)
	if not abilID then
        CHAT_SYSTEM('error')
        return;
    end
    g.setting[key] = {abilID}
    acutil.saveJSON(g.settingPath..g.user..'.json',g.setting)
    HOTKEYABILITY_SET_ABIL_ICON(key,abilID)
end

function HOTKEYABILITY_TOGGLE_ABILITIY(key,abilID)
    local abilID,abilName,abilClass = GetAbilityData(abilID)
    if not abilID then return end 
    local status = abilClass.ActiveState
    local icon  = ui.GetFrame('joystickquickslot'):GetChildRecursively('slot'..key):GetIcon()
    icon:SetColorTone(status == 1 and "FF222222" or "FFFFFFFF")
    
    local topFrame = ui.GetFrame('skilltree');
	topFrame:SetUserValue("CLICK_ABIL_ACTIVE_TIME",imcTime.GetAppTime()-10);
    local fn = _G['TOGGLE_ABILITY_ACTIVE']
    fn(nil, nil,abilName,abilID)

end

function HOTKEYABILITY_SET_ABIL_ICON(key,abilID)
    local abilID,abilName,abilClass = GetAbilityData(abilID)
    if not abilID then return end 
    
    local icon = ui.GetFrame('joystickquickslot'):GetChildRecursively('slot'..key):GetIcon()
    icon:SetImage(abilClass.Icon);
    local status = abilClass.ActiveState
    icon:SetColorTone(status == 1 and "FF222222" or "FFFFFFFF")

    
    -- insert tooltip
    local cid = info.GetCID(session.GetMyHandle())
    local pc = GetPCObjectByCID(cid)    
    icon:SetTooltipType('ability');
	icon:SetTooltipStrArg(abilClass.Name);
	icon:SetTooltipNumArg(abilID);
	local abilIES = GetAbilityIESObject(pc, abilName);
	icon:SetTooltipIESID(GetIESGuid(abilIES));

end

function HOTKEYABILITY_SET_POSE_ICON(k,poseID)
    local icon = ui.GetFrame('joystickquickslot'):GetChildRecursively('slot'..k):GetIcon()
    local cls = GetClassByType("Pose", poseID);
    local isPremiumTokenState = session.loginInfo.IsPremiumState(ITEM_TOKEN);
    if cls.Premium == "YES" and isPremiumTokenState == false then
        g.setting[k] = nil
        return
    end
    icon:SetImage(cls.Icon)
end

function HOTKEYABILITY_SET_MACRO_ICON(k,macroID)
end

function GetAbilityData(abilID)
    local abil = session.GetAbility(abilID);
	if not abil then
    return;end
    
    local abilClass = GetIES(abil:GetObject());
	local abilName = abilClass.ClassName;
    return abilID,abilName,abilClass;
end


function JOYSTICK_QUICKSLOT_ON_DROP_HOOK(frame, control, argStr, argNum)
	local liftIcon 				= ui.GetLiftIcon();
    local FromFrameName			= liftIcon:GetTopParentFrame():GetName();
	local slot 					= tolua.cast(control, 'ui::CSlot');
    local icon                  = slot:GetIcon()
    if(FromFrameName == 'chatmacro') then
        local poseID = liftIcon:GetUserValue('POSEID');
        local macroID =  liftIcon:GetUserValue('MacroID')
        if poseID ~='None' then
            local cls = GetClassByType("Pose", poseID);
            local isPremiumTokenState = session.loginInfo.IsPremiumState(ITEM_TOKEN);
            if cls.Premium == "YES" and isPremiumTokenState == false then return end
            icon:SetImage(cls.Icon)
            g.setting[tostring(slot:GetSlotIndex()+1)] = {poseID,'Pose'}
        elseif macroID ~= 'None'then
            icon:SetImage('key'..tonumber(macroID)%10)
            g.setting[tostring(slot:GetSlotIndex()+1)] = {macroID,'Macro'}
        end
    elseif(FromFrameName == 'skilltree' and liftIcon:GetUserValue('ABILID') ~= 'None') then
        local abilID,abilName,abilClass = GetAbilityData(liftIcon:GetUserValue('ABILID'))
        if(abilClass.AlwaysActive == 'YES') then return end
        icon:SetImage(abilClass.Icon)
        local status = abilClass.ActiveState
        icon:SetColorTone(status and "FF222222" or "FFFFFFFF")

        g.setting[tostring(slot:GetSlotIndex()+1)] = {abilID,'Ability'}
    else
        JOYSTICK_QUICKSLOT_ON_DROP_OLD(frame, control, argStr, argNum)
        return
    end
    slot:SetEventScript(ui.RBUTTONUP, 'HOTKEYABILITY_RBTN_FUNC');        
    acutil.saveJSON(g.settingPath..g.user..'.json',g.setting)
end
function MAKE_ABILITY_ICON_HOOK(frame, pc, detail, abilClass, posY, listindex)

	local row = (listindex-1) % 1; -- 예전에는 한줄에 두개씩 보여줬다. /1을 2로 바꾸면 다시 복구됨
	local col = math.floor((listindex-1) / 1);

	local skilltreeframe = ui.GetFrame('skilltree')
	local CTL_WIDTH = skilltreeframe:GetUserConfig("ControlWidth")
	local CTL_HEIGHT = skilltreeframe:GetUserConfig("ControlHeight")
	local xBetweenMargin = 10
	local yBetweenMargin = 10

	local classCtrl = detail:CreateOrGetControlSet('ability_set', 'ABIL_'..abilClass.ClassName, 10 + (CTL_WIDTH + xBetweenMargin) * row, posY + 20 + (CTL_HEIGHT + yBetweenMargin) * col);
	classCtrl:ShowWindow(1);
	
    -- 항상 활성화 된 특성은 특성 활성화 버튼을 안보여준다.
	if abilClass.AlwaysActive == 'NO' then
		-- 특성 활성화 버튼
		local activeImg = GET_CHILD(classCtrl, "activeImg", "ui::CPicture");
	    activeImg:EnableHitTest(1);
	    activeImg:SetEventScript(ui.LBUTTONUP, "TOGGLE_ABILITY_ACTIVE");
	    activeImg:SetEventScriptArgString(ui.LBUTTONUP, abilClass.ClassName);
	    activeImg:SetEventScriptArgNumber(ui.LBUTTONUP, abilClass.ClassID);
	    activeImg:SetOverSound('button_over');
	    activeImg:SetClickSound('button_click_big');

    	if abilClass.ActiveState == 1 then
		    activeImg:SetImage("ability_on");
	    else
		    activeImg:SetImage("ability_off");
	    end
	    activeImg:ShowWindow(1);
	end
	
	-- 특성 아이콘
	local classSlot = GET_CHILD(classCtrl, "slot", "ui::CSlot");
	local icon = CreateIcon(classSlot);	
	icon:SetImage(abilClass.Icon);
	icon:SetTooltipType('ability');
	icon:SetTooltipStrArg(abilClass.Name);
	icon:SetTooltipNumArg(abilClass.ClassID);
	icon:SetUserValue('ABILID',abilClass.ClassID)
	local abilIES = GetAbilityIESObject(pc, abilClass.ClassName);
	icon:SetTooltipIESID(GetIESGuid(abilIES));
    icon:SetUserValue("ABILID",abilClass.ClassID)

	-- 특성 이름
	local nameCtrl = GET_CHILD(classCtrl, "abilName", "ui::CRichText");
	nameCtrl:SetText("{@st41}{s16}".. abilClass.Name);

	-- 특성 레벨
	local abilLv = abilIES.Level;

	local levelCtrl = GET_CHILD(classCtrl, "abilLevel", "ui::CRichText");
	levelCtrl:SetText("Lv.".. abilLv);
	--classCtrl:SetSkinName("test_skin_gary_01");
	return classCtrl:GetY() + classCtrl:GetHeight() + 30;
end

function JOYSTICK_QUICKSLOT_EXECUTE_EVENT(addonFrame, eventMsg)
    local slotIndex = acutil.getEventArgs(eventMsg);
	local quickFrame = ui.GetFrame('joystickquickslot')
	local Set1 = GET_CHILD_RECURSIVELY(quickFrame,'Set1','ui::CGroupBox');
	local Set2 = GET_CHILD_RECURSIVELY(quickFrame,'Set2','ui::CGroupBox');

	local input_L1  = joystick.IsKeyPressed("JOY_BTN_5")
	local input_R1  = joystick.IsKeyPressed("JOY_BTN_6")
    local joystickextend = ui.GetFrame('joystickextender')
    if joystickextend then
        if Set2:IsGrayStyle() == 1 then
	    	slotIndex = slotIndex + 20
    	end
	
        if input_L1 == 1 and input_R1 == 1 then
            if Set2:IsGrayStyle() == 0 then
                if	slotIndex == 2  or slotIndex == 14 then
                    slotIndex = 10
                elseif	slotIndex == 0  or slotIndex == 12 then
                    slotIndex = 8
                elseif	slotIndex == 1  or slotIndex == 13 then
                    slotIndex = 9
                elseif	slotIndex == 3  or slotIndex == 15 then
                    slotIndex = 11
                end
            else
                if	slotIndex == 22  or slotIndex == 34 then
                    slotIndex = 30
                elseif	slotIndex == 20  or slotIndex == 32 then
                    slotIndex = 28
                elseif	slotIndex == 21  or slotIndex == 33 then
                    slotIndex = 29
                elseif	slotIndex == 23  or slotIndex == 35 then
                    slotIndex = 31
                end
            end

        end
    else
        if Set2:IsVisible() == 1 then
                slotIndex = slotIndex + 20
        end
        if input_L1 == 1 and input_R1 == 1 then
            if Set1:IsVisible() == 1 then
                if	slotIndex == 2  or slotIndex == 14 then
                    slotIndex = 10
                elseif	slotIndex == 0  or slotIndex == 12 then
                    slotIndex = 8
                elseif	slotIndex == 1  or slotIndex == 13 then
                    slotIndex = 9
                elseif	slotIndex == 3  or slotIndex == 15 then
                    slotIndex = 11
                end
            end	

            if Set2:IsVisible() == 1 then
                if	slotIndex == 22  or slotIndex == 34 then
                    slotIndex = 30
                elseif	slotIndex == 20  or slotIndex == 32 then
                    slotIndex = 28
                elseif	slotIndex == 21  or slotIndex == 33 then
                    slotIndex = 29
                elseif	slotIndex == 23  or slotIndex == 35 then
                    slotIndex = 31
                end
            end
        end
    end
    local key = tostring(slotIndex + 1)
    local value = g.setting[key]
    if value then
        if value[2] == 'Pose' then
            local poseCls = GetClassByType('Pose', value[1]);
            if poseCls ~= nil then
                control.Pose(poseCls.ClassName);
            end
        elseif value[2] == 'Macro' then
            EXEC_CHATMACRO(tonumber(value[1]))
        else
            HOTKEYABILITY_TOGGLE_ABILITIY(key,value[1])
        end
    end
end

function HOTKEYABILITY_RBTN_FUNC(frame,control,str,num)
    local slot 	= tolua.cast(control, 'ui::CSlot');
    local index = slot:GetSlotIndex()
    if g.setting[tostring(index + 1)] then
        g.setting[tostring(index + 1)] = nil
        slot:ClearIcon()
        CreateIcon(slot)
    end
    acutil.saveJSON(g.settingPath..g.user..'.json',g.setting)
end

function LOAD_SESSION_CHAT_MACRO_HOOK(frame)

	local macroGbox = frame:GetChild('macroGroupbox');
	local clslist = GetClassList("Pose");
	local list = session.GetChatMacroList();
	local cnt = list:Count();
	
	for i = 0 , cnt - 1 do
		local info = list:PtrAt(i);
		local ctrl = macroGbox:GetChild("CHAT_MACRO_" .. info.index);
		ctrl:SetText(info.macro);
		ctrl:ShowWindow(1);

		local slot = macroGbox:GetChild("CHAT_MACRO_SLOT_" .. info.index);
		tolua.cast(slot, "ui::CSlot");		
		slot:SetUserValue('POSEID', info.poseID);
		
		local cls = GetClassByTypeFromList(clslist, info.poseID);
		if cls ~= nil then			
			local icon = slot:GetIcon();
			icon:SetImage(cls.Icon);
			icon:SetColorTone("FFFFFFFF");
		end		
	end
    for i = 1 , MAX_MACRO_CNT do
		local slot = macroGbox:GetChild("CHAT_MACRO_SLOT_" .. i);
		tolua.cast(slot, "ui::CSlot");
		local icon = slot:GetIcon();
        if icon then
            icon:SetUserValue('MacroID',i)
        end
    end
end

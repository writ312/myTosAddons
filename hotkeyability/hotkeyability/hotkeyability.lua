_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['HOTKEYABILITY'] = _G['ADDONS']['HOTKEYABILITY'] or {};
local g = _G['ADDONS']['HOTKEYABILITY'];
local acutil = require('acutil')

g.user = nil;
g.setting = {}
g.settingPath = '../addons/hotkeyability/'

CHAT_SYSTEM('on load hotkey')   
local function _isAfterRebuild()
    if ui.GetFrame('skillability') then 
        return true
    else
        return false
    end
end
function HOTKEYABILITY_ON_INIT(addon,frame)
    g.addon = addon
    if _isAfterRebuild() then
        acutil.setupEvent(addon, 'QUICKSLOTNEXPBAR_EXECUTE', 'QUICKSLOTNEXPBAR_EXECUTE_EVENT')
      else
        acutil.setupHook(QUICKSLOTNEXPBAR_EXECUTE_HOOK,'QUICKSLOTNEXPBAR_EXECUTE')
        acutil.setupHook(MAKE_ABILITY_ICON_HOOK,'MAKE_ABILITY_ICON')
    end
    acutil.setupEvent(addon, 'QUICKSLOTNEXPBAR_EXECUTE', 'QUICKSLOTNEXPBAR_EXECUTE_EVENT')
    acutil.setupEvent(addon, 'QUICKSLOTNEXPBAR_ON_DROP', 'QUICKSLOTNEXPBAR_ON_DROP_HOOK')
    acutil.setupEvent(addon, 'CHATMACRO_OPEN', 'LOAD_SESSION_CHAT_MACRO_HOOK')
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
    if  g.setting then
        local frame = ui.GetFrame('quickslotnexpbar')
        for k,v in pairs(g.setting) do
            if v[2] == 'Pose' then
                HOTKEYABILITY_SET_POSE_ICON(k,v[1])
            elseif v[2] == 'Macro' then
                local imageNum = tonumber(v[1])%10
                local slot = ui.GetFrame('quickslotnexpbar'):GetChild('slot'..k)
                local icon = slot:GetIcon()
                if not icon then icon = CreateIcon(slot) end
                icon:SetImage('key'..imageNum)
            else
                if _isAfterRebuild() then
                    g.setting[k] = nil
                else
                    HOTKEYABILITY_SET_ABIL_ICON(k,v[1])
                end
            end         
            frame:GetChild('slot'..k):SetEventScript(ui.RBUTTONUP, 'HOTKEYABILITY_RBTN_FUNC');
        end
    end
end

function HOTKEYABILITY_COMMAND(command)
    local key = table.remove(command,1);
    
    if( key == 'd') then
        g.setting[table.remove(command,1)] = nil
        local slot = ui.GetFrame('quickslotnexpbar'):GetChild('slot'..k)
        slot:ClearIcon()
        CreateIcon(slot)
        acutil.saveJSON(g.settingPath..GetMyName()..'.json',g.setting)
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
    acutil.saveJSON(g.settingPath..GetMyName()..'.json',g.setting)
    HOTKEYABILITY_SET_ABIL_ICON(key,abilID)
end

function HOTKEYABILITY_TOGGLE_ABILITIY(key,abilID)
    local abilID,abilName,abilClass = GetAbilityData(abilID)
    if not abilID then return end 
    local status = abilClass.ActiveState
    local icon  = ui.GetFrame('quickslotnexpbar'):GetChild('slot'..key):GetIcon()
    icon:SetColorTone(status == 1 and "FF222222" or "FFFFFFFF")
   
    local topFrame = ui.GetFrame('skilltree');
	topFrame:SetUserValue("CLICK_ABIL_ACTIVE_TIME",imcTime.GetAppTime()-10);
    local fn = _G['TOGGLE_ABILITY_ACTIVE']
    fn(nil, nil,abilName,abilID)

end

function HOTKEYABILITY_SET_ABIL_ICON(key,abilID)
    local abilID,abilName,abilClass = GetAbilityData(abilID)
    if not abilID then return end 
    
    local icon = ui.GetFrame('quickslotnexpbar'):GetChild('slot'..key):GetIcon()
    icon:SetImage(abilClass.Icon);
    local status = abilClass.ActiveState
    icon:SetColorTone(status ~= 1 and "FF222222" or "FFFFFFFF")
    
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
    local slot = ui.GetFrame('quickslotnexpbar'):GetChild('slot'..k)
    local icon = slot:GetIcon()
    if not icon then icon = CreateIcon(slot) end
    local cls = GetClassByType("Pose", poseID);
    local isPremiumTokenState = session.loginInfo.IsPremiumState(ITEM_TOKEN);
    if isPremiumTokenState == false then
        if (_isAfterRebuild() == true and cls.PoseType == "Premium") or cls.Premium == "YES" then
        g.setting[k] = nil
        return
        end
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

function QUICKSLOTNEXPBAR_ON_DROP_HOOK(addonFrame, eventMsg)
    local frame, control, argStr, argNum = acutil.getEventArgs(eventMsg)
    local liftIcon 				= ui.GetLiftIcon();
    local FromFrameName			= liftIcon:GetTopParentFrame():GetName();
	local slot 					= tolua.cast(control, 'ui::CSlot');
    local icon                  = slot:GetIcon()
    if not icon then icon = CreateIcon(slot) end
    if(FromFrameName == 'chatmacro') then
        local poseID = liftIcon:GetUserValue('POSEID');
        local macroID =  liftIcon:GetUserValue('MacroID')
        if poseID ~='None' then
            local cls = GetClassByType("Pose", poseID);
            local isPremiumTokenState = session.loginInfo.IsPremiumState(ITEM_TOKEN);
            if isPremiumTokenState == false then
                if (_isAfterRebuild() == true and cls.PoseType == "Premium") or cls.Premium == "YES" then
                    return
                end
            end
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
        icon:SetColorTone(status ~= 1 and "FF222222" or "FFFFFFFF")
        g.setting[tostring(slot:GetSlotIndex()+1)] = {abilID,'Ability'}
    else
        -- QUICKSLOTNEXPBAR_ON_DROP_OLD(frame, control, argStr, argNum)
        return
    end
    slot:SetEventScript(ui.RBUTTONUP, 'HOTKEYABILITY_RBTN_FUNC');        
    acutil.saveJSON(g.settingPath..GetMyName()..'.json',g.setting)
end

function QUICKSLOTNEXPBAR_EXECUTE_HOOK(number)
    local key = tostring(number + 1)
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
    else
        QUICKSLOTNEXPBAR_EXECUTE_OLD(number)
    end
  end
  
  function QUICKSLOTNEXPBAR_EXECUTE_EVENT(addonFrame, eventMsg)
      local number = acutil.getEventArgs(eventMsg)
      local key = tostring(number + 1)
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
    acutil.saveJSON(g.settingPath..GetMyName()..'.json',g.setting)
end

function LOAD_SESSION_CHAT_MACRO_HOOK()
    local frame = ui.GetFrame('chatmacro')
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

-- After Rebuild. Delte.
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
HOTKEYABILITY_ON_INIT(g.addon)
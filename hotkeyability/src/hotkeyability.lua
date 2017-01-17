_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['HOTKEYABILITY'] = _G['ADDONS']['HOTKEYABILITY'] or {};
local g = _G['ADDONS']['HOTKEYABILITY'];

g.user = nil;
g.setting = {}
g.settingPath = '../addons/hotkeyability/'

CHAT_SYSTEM('on load hotkey')

function HOTKEYABILITY_ON_INIT(addon,frame)
    local acutil = require('acutil')
    acutil.setupHook(QUICKSLOTNEXPBAR_EXECUTE_HOOK,'QUICKSLOTNEXPBAR_EXECUTE')
    acutil.slashCommand('/hotkey', HOTKEYABILITY_COMMAND)
    local g = _G['ADDONS']['HOTKEYABILITY'];
    g.addon = addon
    g.frame = frame
    frame:ShowWindow(1)
    local user = GETMYPCNAME()
    if(g.user ~= user) then
        g.setting = {}
        g.user = user
    end
  
    g.setting ,e = acutil.loadJSON(g.settingPath..user..'.json',nil)
  
    if(e) then
        g.setting = {}
    return;end

    if  g.setting then
        for k,v in pairs(g.setting) do
            HOTKEYABILITY_SET_ICON(k,GetAbilityData(v[1]))
        end
    end
end

function HOTKEYABILITY_COMMAND(command)
    local acutil = require('acutil')
    local g = _G['ADDONS']['HOTKEYABILITY'];
    local key = table.remove(command,1);
    
    if( key == 'd') then
        g.setting[table.remove(command,1)] = nil
        acutil.saveJSON(g.settingPath..GETMYPCNAME()..'.json',g.setting)
    end
    
    if(key == 'list') then
        for k,v in pairs(g.setting) do
            local abilID,abilName,abilClass = GetAbilityData(v[1])
            CHAT_SYSTEM(string.format("%s : %s",k,abilClass.Name))
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
    acutil.saveJSON(g.settingPath..GETMYPCNAME()..'.json',g.setting)
    HOTKEYABILITY_SET_ICON(key,abilID)
end

function QUICKSLOTNEXPBAR_EXECUTE_HOOK(number)
    local g = _G['ADDONS']['HOTKEYABILITY']
    local key = tostring(number + 1)
    local abil = g.setting[key]
    if abil then
        HOTKEYABILITY_TOGGLE_ABILITIY(key,abil[1])
    else
        QUICKSLOTNEXPBAR_EXECUTE_OLD(number)
    end
end

function HOTKEYABILITY_TOGGLE_ABILITIY(key,abilID)
    local abilID,abilName,abilClass = GetAbilityData(abilID)
    if not abilID then return end 

    local status = abilClass.ActiveState

    local icon  = GetIcon(ui.GetFrame('quickslotnexpbar'):GetChild('slot'..key))
    icon:SetGrayStyle(status)

    local topFrame = ui.GetFrame('skilltree');
	topFrame:SetUserValue("CLICK_ABIL_ACTIVE_TIME",imcTime.GetAppTime()-10);
    local fn = _G['TOGGLE_ABILITY_ACTIVE']
    fn(nil, nil,abilName,abilID)

end

function HOTKEYABILITY_SET_ICON(key,abilID)
    local abilID,abilName,abilClass = GetAbilityData(abilID)
    if not abilID then return end 

    local frame = ui.GetFrame('quickslotnexpbar')
    local slot = frame:GetChild('slot'..key)
    local icon = CreateIcon(slot);	
    icon:SetImage(abilClass.Icon);
    
    local cid = info.GetCID(session.GetMyHandle())
    local pc = GetPCObjectByCID(cid)
    
    icon:SetTooltipType('ability');
	icon:SetTooltipStrArg(abilClass.Name);
	icon:SetTooltipNumArg(abilID);
	local abilIES = GetAbilityIESObject(pc, abilName);
	icon:SetTooltipIESID(GetIESGuid(abilIES));

    local status = abilClass.ActiveState
    icon:SetGrayStyle((status == 1) and 0 or 1)
    return icon
end

 function GetAbilityData(abilID)
    local abil = session.GetAbility(abilID);
	if not abil then
    return;end
    
    local abilClass = GetIES(abil:GetObject());
	local abilName = abilClass.ClassName;
    return abilID,abilName,abilClass;
end
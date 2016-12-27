_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['HOTKEYABILITY'] = _G['ADDONS']['HOTKEYABILITY'] or {};
local g = _G['ADDONS']['HOTKEYABILITY'];

g.setting = {}
g.settingPath = '../addons/hotkeyability/'
CHAT_SYSTEM('on load hotkey')

function HOTKEYABILITY_ON_INIT(addon,frame)
    local acutil = require('acutil')
    acutil.setupHook(QUICKSLOTNEXPBAR_EXECUTE_HOOK,'QUICKSLOTNEXPBAR_EXECUTE')
    acutil.slashCommand('/hotkey', HOTKEYABILITY_COMMAND)
    local g = _G['ADDONS']['HOTKEYABILITY'];    
    g.setting ,e = acutil.loadJSON(g.settingPath..GETMYPCNAME()..'.json',g.setting)
    if(e) then
        g.setting = {}
    return;end
    if  g.setting then
        for k,v in pairs(g.setting) do
            HOTKEYABILITY_SET_ICON(k,v[1])
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

    local num = tonumber(table.remove(command,1))
    local abil = session.GetAbility(num);
	if not abil then
        CHAT_SYSTEM('無効な数値')
        return;
    end
    local abilClass = GetIES(abil:GetObject());
	local abilName = abilClass.ClassName;
	local abilID = abilClass.ClassID;
    g.setting[key] = {abilID,abilName}
    acutil.saveJSON(g.settingPath..GETMYPCNAME()..'.json',g.setting)
    HOTKEYABILITY_SET_ICON(key,abilClass.ClassID)
end

function QUICKSLOTNEXPBAR_EXECUTE_HOOK(number)
    local g = _G['ADDONS']['HOTKEYABILITY']
    local key = tostring(number + 1)
    local abil = g.setting[key]
    if abil then
        HOTKEYABILITY_TOGGLE_ABILITIY(key,abil[1],abil[2])
    else
        QUICKSLOTNEXPBAR_EXECUTE_OLD(number)
    end
end

function HOTKEYABILITY_TOGGLE_ABILITIY(key,abilID,abilName)
    local abilClass = GetIES(session.GetAbility(abilID):GetObject())
    local frame = ui.GetFrame('quickslotnexpbar')
    local slot = frame:GetChild('slot'..key)
    local icon = CreateIcon(slot);	
    icon:SetImage(abilClass.Icon);
    local status = abilClass.ActiveState
    icon:SetGrayStyle(status)
    local topFrame = ui.GetFrame('skilltree');
	topFrame:SetUserValue("CLICK_ABIL_ACTIVE_TIME",imcTime.GetAppTime()-10);
    local fn = _G['TOGGLE_ABILITY_ACTIVE']
    fn(nil, nil,abilName,abilID)
end
function HOTKEYABILITY_SET_ICON(key,abilID)
    local abilClass = GetIES(session.GetAbility(abilID):GetObject())
    local frame = ui.GetFrame('quickslotnexpbar')
    local slot = frame:GetChild('slot'..key)
    local icon = CreateIcon(slot);	
    icon:SetImage(abilClass.Icon);
    local status = abilClass.ActiveState
    icon:SetGrayStyle((status == 1) and 0 or 1)
end

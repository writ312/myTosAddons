_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['AUSRINEHIGHLIGHT'] = _G['ADDONS']['AUSRINEHIGHLIGHT'] or {};
local g = _G['ADDONS']['AUSRINEHIGHLIGHT'] 
local acutil = require('acutil')
g.fileLoc = '../addons/ausrinehighlight/'

g.effectlist = acutil.loadJSON(g.fileLoc..'effectlist.json',nil)
if not g.effectlist then
    g.effectlist = {
        'F_warrior_SpecialForceFormation_active_ground',
        'F_spin023',
        'F_bubble002_red_loop',
        'F_magic_prison_line_blue',
        'F_magic_prison_line_green',
        'F_magic_prison_line_white',
        'F_magic_prison_line_dark'   
    }
    acutil.saveJSON(g.fileLoc..'effectlist.json',g.effectlist)
end

g.setting = acutil.loadJSON(g.fileLoc..'setting.json',nil)
if not g.setting then
    g.setting = {}
    g.setting.effect = 'F_warrior_SpecialForceFormation_active_ground'
    g.setting.scale = 1
    acutil.saveJSON(g.fileLoc..'setting.json',g.setting)
end

function AUSRINE_ENTER_SCENE(frame, msg, str, handle)
	local actor = world.GetActor(handle);
    local flag = (actor:GetType() == 58287) or nil
    if g.debugmode then
       flag = (actor:GetType() == 58283) or (actor:GetType() == 58285) or (actor:GetType() == 58286) or nil
    end
    if flag then
        ReserveScript(string.format('pcall(effect.AddActorEffectByOffset(world.GetActor(%d) or 0, "%s", %d, 0))', handle, g.setting.effect,g.setting.scale), 0.7);
    end    
end
function AUSRINE_HIGHLIGHT_SAVE_SETTING()
    local gbox =  g.frame:GetChild('settingGbox')
    local effectlist = GET_CHILD(gbox,'effectList','ui::CDropList')
    local scalelist = GET_CHILD(gbox,'scaleList','ui::CDropList')
    
    g.setting.effect = effectlist:GetSelItemKey()
    g.setting.scale = scalelist:GetSelItemKey()
    acutil.saveJSON(g.fileLoc..'setting.json',g.setting)
end

function AUSRINE_HIGHLIGHT_COMMAND(command)
    g.frame:ShowWindow(1)
end

function AUSRINE_HIGHLIGHT_DEBUGMODE()
    g.debugmode = not g.debugmode
    CHAT_SYSTEM('Debug Mode '..acutil.tostring(g.debugmode))
end

function AUSRINEHIGHLIGHT_ON_INIT(addon,frame)
    g.addon = addon
    g.frame = frame
    addon:RegisterMsg('MON_ENTER_SCENE','AUSRINE_ENTER_SCENE')

    g.debugmode = false    
    acutil.slashCommand("/aus", AUSRINE_HIGHLIGHT_COMMAND);

    g.effectlist = acutil.loadJSON(g.fileLoc..'effectlist.json',nil)
    g.setting = acutil.loadJSON(g.fileLoc..'setting.json',nil)
    
    local gbox =  frame:GetChild('settingGbox')
    
    local effectlist = GET_CHILD(gbox,'effectList','ui::CDropList')
    effectlist:ClearItems()
    for i ,v in ipairs(g.effectlist) do
        effectlist:AddItem(v,'{s20}'..v);
    end
    effectlist:SelectItemByKey(g.setting.effect)

    local scalelist = GET_CHILD(gbox,'scaleList','ui::CDropList')
    scalelist:ClearItems()
    for i = 1 , 6 do 
        scalelist:AddItem(i,"{s20}"..i);
    end
    scalelist:SelectItemByKey(g.setting.scale)
 end

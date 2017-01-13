_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['RESOURCEMANAGER'] = _G['ADDONS']['RESOURCEMANAGER'] or {};
local g = _G['ADDONS']['RESOURCEMANAGER'] 

g.table = {
    {
        --flecher
        645250,
        645251,
        645252,
        645349,
        645567,
        645568
    },
    {
        -- dievdirbys
        645238,
        645239,
        645240,
        645241
    },{
        -- rune
        645750
    },
    {
        -- sapper
        645239,
        645240,
        645604,
        645605
    },{ 
        --Inquisitor
        645924
    },
    {
        --Daoshi
        645821
    },
    {
        --Chronomancer
        645606
    }
}

g.presetTable = {}
g.addonName = 'resourcemanager'
g.frameVisual = 1
g.settingsFileLoc = string.format("../addons/%slite/settings.json", g.addonName);
if not g.loaded then
  g.settings = {
    position = {
      x = 1575,
      y = 300
    }
  };
end
g.tableMerge = function(t1,t2)
    for i,v in ipairs(t2) do
        table.insert(t1,t2[i])
    end
    return t1
end

local acutil = require('acutil');

CHAT_SYSTEM("load Resource Manager");

function RESOURCEMANAGER_ON_INIT(addon,frame)
    if not g.loaded then
        local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings);
        if err then
            CHAT_SYSTEM(string.format("[%s] cannot load setting files", g.addonName));
        else
            g.settings = t;
        end
        g.loaded = true;
    end
    g.addnon = addnon;
    g.frame = frame;
    existPresetJobs()
    frame:ShowWindow(g.frameVisual)
    frame:SetEventScript(ui.LBUTTONUP, "RESOURCEMANAGER_END_DRAG")
    acutil.slashCommand("/rscm", RESOURCEMANAGER_COMMAND);
    acutil.setupEvent(addon,"FPS_UPDATE","RESOURCEMANAGER_UPDATE_TXT")
    RESOURCEMANAGER_SET_ICON()
end


function RESOURCEMANAGER_COMMAND(command)
    local cmd = table.remove(command, 1);
    if cmd == nil then
        RESOURCEMANAGER_TOGGLE()
        return
    end
    CHAT_SYSTEM('/rscm : toggle on or off')
    CHAT_SYSTEM('/rscm number  1:Flecher 2:Dievdirbys 3:Sapper 4:RuneCaster')
end

function RESOURCEMANAGER_TOGGLE()
    ui.ToggleFrame(g.addonName)    
    g.frameVisual = ui.IsFrameVisible(g.addonName)
    local msg = (g.frameVisual == 1) and 'ON' or 'OFF'
    CHAT_SYSTEM(g.addonName..' is '..msg)
end
function existPresetJobs()
    local jobTable = {}
    jobTable[3011] = 1 -- Flecher
    jobTable[4007] = 2 -- Dievdirbys
    jobTable[2017] = 3 -- RuneCaster
    jobTable[3005] = 4 -- Sapper
    jobTable[4016] = 5 -- Inquisitor
    jobTable[4017] = 6 -- Daoshi
    jobTable[2008] = 7 -- Chronomancer
    local cid = info.GetCID(session.GetMyHandle())
    local pcSession = session.GetSessionByCID(cid);
    local pcJobInfo = pcSession.pcJobInfo;
    local cnt = pcJobInfo:GetJobCount();
    local n = 1
    g.presetTable = {}
    for i = 0 , cnt - 1 do
        local jobID = pcJobInfo:GetJobByIndex(i);
        if jobID == -1 then
            break;
        end
        if jobTable[jobID] then
            g.presetTable[1] = g.presetTable[1] or {}
            local tempTable = g.table[jobTable[jobID]]
            if (#tempTable == 1 ) or (#g.presetTable[1] == 1) and (n == 2) then
                g.presetTable[1] = g.tableMerge(g.presetTable[1],tempTable)
            else
                g.presetTable[n] = tempTable
            end
            n = n + 1;
        end
    end
end

function RESOURCEMANAGER_SET_ICON()
    if g.presetTable == {} then
        return
    end
    local frame = g.frame
    frame:SetPos(g.settings.position.x ,g.settings.position.y)
    frame:RemoveAllChild()
    _RESOURCEMANAGER_SET_ICON(frame,0,g.presetTable[1])
    if #g.presetTable == 2 then
        _RESOURCEMANAGER_SET_ICON(frame,1,g.presetTable[2])
    end
end

function _RESOURCEMANAGER_SET_ICON(frame,col,list)
    local items = GET_ITEM_COUNT(list);
    local i = 0;
     for k,v in pairs(items) do
        if v ~= 0 then
            local item = GetClassByType('Item',k)
            local slot = frame:CreateOrGetControl("slot","slot"..k,50*i,-100 + 50*col,45,45)
            tolua.cast(slot, 'ui::CSlot')
            slot:SetSkinName('slot')
            local icon = CreateIcon(slot);
            icon:SetImage(item.Icon)
            local text = slot:CreateOrGetControl("richtext","txt"..k,0,0,60,20)
            tolua.cast(text, 'ui::CRichText')
            text:SetText(string.format("{#%s}{s%d}%d{/}{/}",getTextColorByCount(v),20,v));
            text:SetGravity(ui.RIGHT,ui.BOTTOM)
            i = i + 1;
        end
    end
end

function GET_ITEM_COUNT(list)
    local items = {}
    if not list then
        return items
    end
    for i,value in ipairs(list) do
        local item = GetClassByType('Item',value)
        item = session.GetInvItemByName(item.ClassName)    
        if item ~= nil then
            items[value] = item.count
        else 
            items[value] = 0;
        end
    end
    return items
end

function getTextColorByCount(count)
    local color = (count < 100) and 'FF4500';
    color = (count < 50) and 'FF0000' or color
    return color or 'FFFFFF'
end


function RESOURCEMANAGER_UPDATE_TXT()
    if g.presetTable == {} then
        return
    end
        
    local frame = ui.GetFrame('resourcemanager')    
    _RESOURCEMANAGER_UPDATE_TXT(frame, GET_ITEM_COUNT(g.presetTable[1]));
    if #g.presetTable == 2 then
        _RESOURCEMANAGER_UPDATE_TXT(frame, GET_ITEM_COUNT(g.presetTable[2]));
    end
end

function _RESOURCEMANAGER_UPDATE_TXT(frame,items)
    for k,v in pairs(items) do
        local text = GET_CHILD_RECURSIVELY(frame, "txt"..k, "ui::CRichText");
        if text then
            text:SetText(string.format("{#%s}{s%d}%d{/}{/}",getTextColorByCount(v),20,v));
        end
    end
end

function RESOURCEMANAGER_SAVE_SETTINGS()
  acutil.saveJSON(g.settingsFileLoc, g.settings);
end

function RESOURCEMANAGER_END_DRAG()
  g.settings.position.x = g.frame:GetX();
  g.settings.position.y = g.frame:GetY();
  RESOURCEMANAGER_SAVE_SETTINGS();
end

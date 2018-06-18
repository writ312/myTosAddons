_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['RESOURCEMANAGER'] = _G['ADDONS']['RESOURCEMANAGER'] or {};
local g = _G['ADDONS']['RESOURCEMANAGER'] 
local maxRow = 8
local colLength = 0
g.jobTable = {}
-- Sapper
g.jobTable[3005] = { 
    {
        645604,
        645240
    },{
        645239,
    },{
        645605
    }
}
-- Flecher
g.jobTable[3011] = {
    { -- arrows
        645250,
        645251,
        645349,
        645252,
    },{
        645568
    },{
        645567
    },{ -- materials
        645238,
        645239,
        645241,
        645240
    },{
        645232
    },{
        645571
    }
} 
-- Priest
g.jobTable[4002] = {
    {
        640069,
        640068
    },{
        640031
    }
}
-- Dievdirbys
g.jobTable[4007] = {
    {
        645238,
        645240,
        645241
    },{
        645239
    }
}
-- Paladin
g.jobTable[4011] = {
    {},{
        640068
    }
}
-- Inquisitor
g.jobTable[4016] = {
    {
        645924
    }
} 
-- Daoshi
g.jobTable[4017] = {
    {
        645821
    }
}
-- Pyromancer
g.jobTable[2002] = {
    {},{},{
        649208
    }
}
-- Cryomancer
g.jobTable[2003] = {
    {},{},{
        649210
    }
}
-- Thaumaturge
g.jobTable[2010] = {
    {
        645810
    }
}
-- Sorcerer
g.jobTable[2006] = {
    {
        645923
    }
}
-- Chronomancer
g.jobTable[2008] = {
    {
        646070
    },{},{
        645606
    }
}
-- Alchemist
g.jobTable[2005] = {
    {
        645533
    }
}
-- RuneCaster
g.jobTable[2017] = {
    {
        645750
    }
}
-- Sage 
g.jobTable[2014] = {
    {},{
        646064
    }
}
-- Enchanter
g.jobTable[2018] = {
    {
        640240
    }
}
-- Onmyoji
g.jobTable[2020] = {
    {
        646074
    }
}
-- Squire
g.jobTable[1011] = {
    {
        645534,
        645525,
    },{
        645570,
        640044,
        640125,
        640254,
        640124,
        640251,
        640123,
        640253
    }
}

g.presetTable = {}
g.addonName = 'resourcemanager'

local acutil = require('acutil');
g.settingsFileLoc = string.format("../addons/%slite/settings.json", g.addonName);

local function resourcemanagerSaveSetting()
  acutil.saveJSON(g.settingsFileLoc, g.settings);
end

local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings);
if err then
    g.settings = {
        position = {
            x = 1575,
            y = 300
        },
        size = 'm',
        frameVisual = 1
    };
else
    g.settings = t;
end 
g.settings.frameVisual = g.settings.frameVisual or 1 
g.settings.size = g.settings.size or 'm'
resourcemanagerSaveSetting()

g.tableMerge = function(t1,t2)
    for i,v in ipairs(t2) do
        table.insert(t1,t2[i])
    end
    return t1
end

g.tableSplit = function(t,n)
    local t1 = {}
    for i = 1, n do
        table.insert(t1,table.remove(t,1))
    end
    return t1,t
end
CHAT_SYSTEM("load Resource Manager");

local function optimizationPresetTanle(tempTable)
    local n = 1
    g.presetTable[1] = {}
    local insertLast = {}
    for i , v in ipairs(tempTable) do
        if (#v + #g.presetTable[n]) < maxRow then
            g.tableMerge(g.presetTable[n],v)
        else
            n = n + 1
            g.presetTable[n] = v
        end
    end    
end

local function existPresetJobs()
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
        if g.jobTable[jobID] then
            local jobGrade = session.GetJobGrade(jobID)
            for i = 1 , jobGrade do
                if(g.jobTable[jobID][i] and unpack(g.jobTable[jobID][i])) then
                    tempTable[n] = g.tableMerge(tempTable[n] or {},{unpack(g.jobTable[jobID][i])})
                end
            end
            n = n + 1
            if jobID == 3011 then
                for i = 4 , jobGrade + 3 do
                    tempTable[n] = g.tableMerge(tempTable[n] or {},{unpack(g.jobTable[jobID][i])})
                end
                n = n + 1
            end
        end
    end
    optimizationPresetTanle(tempTable)
end

function RESOURCEMANAGER_ON_INIT(addon,frame)
    g.addnon = addon;
    g.frame = frame;
    frame:ShowWindow(g.settings.frameVisual)
    frame:ShowTitleBar(1)
    frame:ShowTitleBarFrame(1)
    frame:SetEventScript(ui.LBUTTONUP, "RESOURCEMANAGER_END_DRAG")
    acutil.slashCommand("/rscm", RESOURCEMANAGER_COMMAND);
    addon:RegisterMsg('INV_ITEM_ADD', 'RESOURCEMANAGER_UPDATE_TXT');
    addon:RegisterMsg('INV_ITEM_CHANGE_COUNT', 'RESOURCEMANAGER_UPDATE_TXT');
    addon:RegisterMsg("INV_ITEM_REMOVE","RESOURCEMANAGER_UPDATE_TXT")

    RESOURCEMANAGER_SET_ICON()
end


function RESOURCEMANAGER_COMMAND(command)
    local cmd = table.remove(command,1)
    if cmd == 'resize' or '-r' then
        g.settings.size = string.lower(table.remove(command) or 'm')
        resourcemanagerSaveSetting()
        RESOURCEMANAGER_SET_ICON()
        return
    end
    RESOURCEMANAGER_TOGGLE()
end

function RESOURCEMANAGER_TOGGLE()
    ui.ToggleFrame(g.addonName)    
    g.settings.frameVisual = ui.IsFrameVisible(g.addonName)
    local msg = (g.settings.frameVisual == 1) and 'ON' or 'OFF'
    CHAT_SYSTEM(g.addonName..' is '..msg)
    resourcemanagerSaveSetting()    
end

local function getTextColorByCount(count)
    local color = (count < 100) and 'FF4500';
    color = (count < 50) and 'FF0000' or color
    return color or 'FFFFFF'
end

local function getResourceItemCount(list)
    local items = {}
    if not list then
        return items
    end
    for i,value in ipairs(list) do
        local item = GetClassByType('Item',value)
        item = session.GetInvItemByName(item.ClassName)    
        if item ~= nil then
            table.insert(items,{value,item.count})
        else 
            table.insert(items,{value,0})
        end
    end
    return items
end
function RESOURCEMANAGER_SET_ICON()
    existPresetJobs()
    if not unpack(g.presetTable) then
      return
    end
    local frame = g.frame
    frame:SetPos(g.settings.position.x ,g.settings.position.y)
    frame:Resize(380,300)
    local gbox = frame:CreateOrGetControl('groupbox','gbox',0,10,450,250)
    gbox:RemoveAllChild()
    tolua.cast(gbox,'ui::CGroupBox')
    gbox:SetSkinName('none')
    gbox:EnableScrollBar(0)
    gbox:SetGravity('0','0')
    local col = 0
    for i ,v in ipairs(g.presetTable) do
      if unpack(v) then
            col = _RESOURCEMANAGER_SET_ICON(gbox,col,v)
        end
    end
    colLength = col
end

function _RESOURCEMANAGER_SET_ICON(frame,col,list)
    local size = g.settings.size
    local w = (size == 's') and 30 or (size == 'm' and 40) or (size == 'l' and 50) or 40
    local h = w+20
    frame:Resize(w*maxRow,250)
    local items = getResourceItemCount(list);
    local i = 0;
     for i,v in ipairs(items) do
        if v ~= 0 then
            if i == maxRow then
                local t1,t2 = g.tableSplit(list,maxRow -1)
                return _RESOURCEMANAGER_SET_ICON(frame,col+1,t2)
            end 
            local item = GetClassByType('Item',v[1])
            local baseSlot = frame:CreateOrGetControl("slot","slot"..col..v[1], 10+w*(i-1), h*col,w-5,h-5)
            tolua.cast(baseSlot, 'ui::CSlot')
            baseSlot:SetSkinName('slot')
            baseSlot:SetTextTooltip(item.Name)
            baseSlot:EnableHitTest(1)
            baseSlot:SetGravity(ui.LEFT,'0')
		   	local icon = baseSlot:CreateOrGetControl("picture","icon"..col..v[1],0,0,w-8,w-8)               
            tolua.cast(icon, 'ui::CPicture')
			icon:SetImage(item.Icon)
            icon:EnableHitTest(0)
            icon:SetEnableStretch(1)

			local text = baseSlot:CreateOrGetControl("richtext","txt"..col..v[1],0,0,w,h-w)
            tolua.cast(text, 'ui::CRichText')
            text:SetText(string.format("{#%s}{s%d}%d{/}{/}",getTextColorByCount(v[2]),18,v[2]));
            text:SetGravity(2,1)
            text:EnableHitTest(0)
            i = i + 1;
        end
    end
    return col + 1
end
function RESOURCEMANAGER_UPDATE_TXT()
    if not unpack(g.presetTable)  then return end
    local frame = ui.GetFrame('resourcemanager')  
    for i ,v in ipairs(g.presetTable) do
        _RESOURCEMANAGER_UPDATE_TXT(frame,v);
    end
end

function _RESOURCEMANAGER_UPDATE_TXT(frame,list)
    local items = getResourceItemCount(list)
    for i,v in ipairs(items) do
        for i = 0 , colLength do
            local text = GET_CHILD_RECURSIVELY(frame, "txt"..i..v[1], "ui::CRichText");
            if text then
                text:SetText(string.format("{#%s}{s%d}%d{/}{/}",getTextColorByCount(v[2]),18,v[2]));
            end
        end
    end
end

function RESOURCEMANAGER_END_DRAG()
  g.settings.position.x = g.frame:GetX();
  g.settings.position.y = g.frame:GetY();
  resourcemanagerSaveSetting();
end
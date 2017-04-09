_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['EXPPOPUP'] = _G['ADDONS']['EXPPOPUP'] or {};
local g = _G['ADDONS']['EXPPOPUP']
local acutil = require('acutil')

g.style = acutil.loadJSON('../addons/exppopup/style.json') or 'simple'
acutil.saveJSON('../addons/exppopup/style.json',g.style)

g.base = {}
g.base.style = '{@st43}{#FFCC66}{nl}'
g.base.mapTotal = 0
g.job = {}
g.job.style = '{@st43_green}{nl}'
g.job.mapTotal = 0
g.user = nil
g.log = {}
g.log[0] = {} --base logs
g.log[1] = {} --job logs

function EXPPOPUP_JOBEXP_UPDATE(frame, msg, str, exp, tableinfo)
    FRAME_AUTO_POS_TO_OBJ(g.frame,session.GetMyHandle(),0,0,3,3)  
	
    -- jobexp
    local curExp = exp - tableinfo.startExp;
    local level = tableinfo.level
    local getExp = curExp - g.job.exp
    if level ~= g.job.level then
        getExp = tableinfo.before:GetLevelExp() + curExp - g.job.exp 
        g.job.level = level
    end
    
    g.job.exp = curExp
    local maxExp = tableinfo.endExp - tableinfo.startExp;
	if tableinfo.isLastLevel == true then
		curExp = tableinfo.before:GetLevelExp();
		maxExp = curExp;
	end
    g.job.tempTotal = g.job.tempTotal + getExp
	local percent = g.job.tempTotal  / maxExp * 100;
    EXPPOPUP_SHOW_POPUP('job',getExp,percent)

    -- exp
    curExp =  session.GetEXP();
    level = info.GetLevel(session.GetMyHandle())
    getExp = curExp - g.base.exp
    if getExp < 0 then
        local TotalXp =  GetClassByType("Xp", g.base.level).TotalXp - GetClassByType("Xp", (g.base.level - 1)).TotalXp
        getExp = TotalXp +  curExp - g.base.exp
    end

    g.base.level = level
    g.base.exp = curExp
    g.base.tempTotal = g.base.tempTotal + getExp
    percent =  g.base.tempTotal / session.GetMaxEXP() * 100;
    EXPPOPUP_SHOW_POPUP('base',getExp,percent)
end  
 
function EXPPOPUP_SHOW_POPUP(type,getExp,percent)
    local frame = g.frame
    frame:ShowWindow(1)
    local richtxt = frame:GetChild(type..'txt')
    if g.style == 'simple' then
        richtxt:SetText(string.format('%s%d(%.2f%%)[%d]',g[type].style,g[type].tempTotal,percent,getExp))
    else
        local v = string.format('         %s',acutil.addThousandsSeparator(getExp))
        local k =  (type == 'base') and 0 or 1
        table.insert(g.log[k],v)
        if #g.log[k] > 5 then
            table.remove(g.log[k],1)
        end

        local str = g[type].style
        for i , s in ipairs(g.log[k]) do
            str = str .. s .. '{nl}'
        end
        str = str .. string.format('{nl}Total : %d(%.2f%%)',g[type].tempTotal,percent)
        richtxt:SetText(str)
    end
    frame:StopUpdateScript("EXPPOPUP_CLOSE_FUNC");
    frame:RunUpdateScript("EXPPOPUP_CLOSE_FUNC",  5, 0.0, 0, 5);
end

function EXPPOPUP_CLOSE_FUNC()
    local frame = g.frame
    frame:StopUpdateScript("EXPPOPUP_CLOSE_FUNC");    
    frame:ShowWindow(0)
    g.base.mapTotal = g.base.mapTotal + g.base.tempTotal
    g.base.tempTotal = 0
    g.job.mapTotal = g.job.mapTotal + g.job.tempTotal
    g.job.tempTotal = 0

    g.base.level = info.GetLevel(session.GetMyHandle())
    local pc = GetMyPCObject()
    g.job.level = GetJobLevelByName(pc, pc.JobName)

    g.log[0] = {} --base logs
    g.log[1] = {} --job logs

end


function EXPPOPUP_COMMAND(cmd)
    g.style = (g.style == 'simple') and 'detail' or 'simple'
    acutil.saveJSON('../addons/exppopup/style.json',g.style)
    CHAT_SYSTEM('Exp Popup MODE : ' .. g.style)
    local basetxt = g.frame:GetChild('basetxt')
    local jobtxt = g.frame:GetChild('jobtxt')
    if g.style == 'simple' then
        basetxt:SetOffset(0,0)
        basetxt:SetGravity(2,2)
        jobtxt:SetOffset(0,30)
        jobtxt:SetGravity(2,2)
    else
        basetxt:SetOffset(100,00)
        basetxt:SetGravity(0,1)
        jobtxt:SetOffset(340,0)
        jobtxt:SetGravity(0,1)
    end
end

function EXPPOPUP_INIT()
    FRAME_AUTO_POS_TO_OBJ(g.frame,session.GetMyHandle(),0,0,1,3)  
    local basetxt = g.frame:GetChild('basetxt')
    local jobtxt = g.frame:GetChild('jobtxt')
    if g.style == 'simple' then
        basetxt:SetOffset(0,30)
        jobtxt:SetOffset(0,70)
    else
        basetxt:SetOffset(0,30)
        jobtxt:SetOffset(0,200)
    end
    local frame = ui.GetFrame('charbaseinfo')
    local gauge = GET_CHILD(frame,'skillexp','ui::CGauge')

    local user = GETMYPCNAME()

    if g.user ~= user then
        g.user = user
        g.base.exp = session.GetEXP()
        g.job.exp = gauge:GetCurPoint()
    else 
        if (g.base.mapTotal > 10000) or (g.job.mapTotal > 10000) then
            CHAT_SYSTEM(string.format('BaseExp %s',acutil.addThousandsSeparator(g.base.mapTotal)))
            CHAT_SYSTEM(string.format('JobExp %s',acutil.addThousandsSeparator(g.job.mapTotal)))
        end
    end

    local basetxt = g.frame:GetChild('basetxt')
    local jobtxt = g.frame:GetChild('jobtxt')
    if g.style == 'simple' then
        basetxt:SetOffset(0,0)
        basetxt:SetGravity(2,2)
        jobtxt:SetOffset(0,30)
        jobtxt:SetGravity(2,2)
    else
        basetxt:SetOffset(100,00)
        basetxt:SetGravity(0,1)
        jobtxt:SetOffset(340,0)
        jobtxt:SetGravity(0,1)
    end

    g.base.tempTotal = 0
    g.base.mapTotal = 0
    g.base.level = info.GetLevel(session.GetMyHandle())
    
    g.job.tempTotal = 0
    g.job.mapTotal = 0
    local pc = GetMyPCObject()
    g.job.level = GetJobLevelByName(pc, pc.JobName)

    g.log[0] = {} --base logs
    g.log[1] = {} --job logs

end
function EXPPOPUP_ON_INIT(addon,frame)
	g.addon = addon
    g.frame = frame
    acutil.slashCommand("/exppop", EXPPOPUP_COMMAND);

	addon:RegisterMsg('JOB_EXP_ADD', 'EXPPOPUP_JOBEXP_UPDATE');
 	addon:RegisterMsg('JOB_EXP_UPDATE', 'EXPPOPUP_JOBEXP_UPDATE');
    addon:RegisterMsg('GAME_START_3SEC','EXPPOPUP_INIT')
end

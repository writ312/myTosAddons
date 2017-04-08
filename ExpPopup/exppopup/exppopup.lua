_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['EXPPOPUP'] = _G['ADDONS']['EXPPOPUP'] or {};
local g = _G['ADDONS']['EXPPOPUP']
g.base = {}
g.base.style = '{@st43}{#FFCC66}'
g.job = {}
g.job.style =  '{@st43_green}'
g.user = nil
local acutil = require('acutil')

function GetTotalMaxExp(level,diff)
    if diff < 0 then
        return 0
    else
        return GetTotalMaxExp(level,diff - 1) + GetClassByType("Xp", level + diff ).TotalXp - GetClassByType("Xp", g.base.level + diff - 1 ).TotalXp
    end
end

function EXPPOPUP_JOBEXP_UPDATE(frame, msg, str, exp, tableinfo)
    FRAME_AUTO_POS_TO_OBJ(g.frame,session.GetMyHandle(),0,0,1,3)  
	
    -- Job Exp
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

    -- Base Exp
    curExp =  session.GetEXP();
    level = GETMYPCLEVEL()
    getExp = GetTotalMaxExp(level,level - g.base.level - 1) +  curExp - g.base.exp
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
    richtxt:SetText(string.format('%s%d(%.2f%%)[%d]',g[type].style,g[type].tempTotal,percent,getExp))

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

    g.base.level = GETMYPCLEVEL()
    local pc = GetMyPCObject()
    g.job.level = GetJobLevelByName(pc, pc.JobName)
end

function EXPPOPUP_INIT()
    FRAME_AUTO_POS_TO_OBJ(g.frame,session.GetMyHandle(),0,0,1,3)  
    local frame = ui.GetFrame('charbaseinfo')
    local gauge = GET_CHILD(frame,'skillexp','ui::CGauge')

    local user = GETMYPCNAME()
    if g.user ~= user then
        g.user = user
        g.base.exp = session.GetEXP()
        g.job.exp = gauge:GetCurPoint()
    else
        if (g.base.mapTotal > 10000) and (g.job.mapTotal > 10000) then
            CHAT_SYSTEM(string.format('BaseExp %s',acutil.addThousandsSeparator(g.base.mapTotal)))
            CHAT_SYSTEM(string.format('JobExp %s',acutil.addThousandsSeparator(g.job.mapTotal)))
        end
    end
    g.base.tempTotal = 0
    g.base.mapTotal = 0
    g.base.level = GETMYPCLEVEL()
 
    g.job.tempTotal = 0
    g.job.mapTotal = 0
    local pc = GetMyPCObject()
    g.job.level = GetJobLevelByName(pc, pc.JobName)
end
function EXPPOPUP_ON_INIT(addon,frame)
	g.addon = addon
    g.frame = frame
	addon:RegisterMsg('JOB_EXP_ADD', 'EXPPOPUP_JOBEXP_UPDATE');
 	addon:RegisterMsg('JOB_EXP_UPDATE', 'EXPPOPUP_JOBEXP_UPDATE');
    addon:RegisterMsg('GAME_START_3SEC','EXPPOPUP_INIT')
end
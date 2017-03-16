-- Deeds of Valor ,SkillID : 11001,BuffID : 46
_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['DOVCOUNTER'] = _G['ADDONS']['DOVCOUNTER'] or {};
local g = _G['ADDONS']['DOVCOUNTER'];
local acutil = require('acutil')
g.settings = acutil.loadJSON('../addons/dovcounter/setting.json',{}) or {}

local function DoV_UPDATE_DIGIT_COLOR(frame, cnt,color, digit2, digit3)
	local colorTone 
    if color > 128 then
        colorTone = string.format('FFFF00%02x',(255 - color)*2)
    else
        colorTone = string.format('FF%02x00FF',color * 2)
    end
	digit2:SetColorTone(colorTone);
	digit3:SetColorTone(colorTone);
end
local function SetStackPic(frame,stack,color)
    local digit2 = GET_CHILD(frame, "digit2", "ui::CPicture");
    local digit3 = GET_CHILD(frame, "digit3", "ui::CPicture");

    if stack >= 10 then
        digit2:ShowWindow(1)
        digit2:SetImage(tostring(math.floor(stack/10)))
        digit3:SetImage(tostring(stack%10))
    else
        digit2:ShowWindow(0)
        digit3:SetImage(tostring(stack%10))
    end
    DoV_UPDATE_DIGIT_COLOR(frame,stack,color,digit2,digit3)
end

local function DoV_Buff_Check()
        local handle = session.GetMyHandle();
        for i = 0, info.GetBuffCount(handle) - 1 do
            if 46 == info.GetBuffIndexed(handle, i).buffID then
                return info.GetBuffIndexed(handle, i);
            end
        end
    return false;
end

function DoV_UPDATE()
	local dov = DoV_Buff_Check()
	if dov then
        g.frame:ShowWindow(1)
        local stack = dov.over
		-- local skillLv = dov.arg1
        local buffMaxTime = dov.arg1 * 3 + 20
        local buffTime = dov.time/1000
        local rightGauge = GET_CHILD(g.frame, "combo_gauge_right", "ui::CGauge");
        rightGauge:SetPoint(buffTime,buffMaxTime);
    	rightGauge:SetPointWithTime(0, buffTime);
        local color = math.floor(buffTime/buffMaxTime * 255)
        rightGauge:SetColorTone(string.format('FFFF%x00',color));
        
        if g.stack <= stack  then
            if stack == 1 then
               SetStackPic(g.frame,stack,0) 
            else
               SetStackPic(g.frame,stack,dov.over/dov.arg1*255)
            end
           g.stack = stack
        end
    else
        g.stack = 0
        g.frame:ShowWindow(0)
    end
end

function DoV_UPDATE_GAUGE()
        local rightGauge = GET_CHILD(g.frame, "combo_gauge_right", "ui::CGauge");
        rightGauge:SetPoint(dov.time/1000, dov.arg1 * 3 + 20);
    	rightGauge:SetPointWithTime(0, dov.time/1000);
        local color = math.floor((dov.time/1000)/(dov.arg1 * 3 + 20) * 255)
        DEVELOPERCONSOLE_PRINT_TEXT(color)
        rightGauge:SetColorTone(string.format('FFFF%x00',color));
       
end

function DoV_END_DRAG()
  g.settings.position.x = g.frame:GetX();
  g.settings.position.y = g.frame:GetY();
  acutil.saveJSON('../addons/dovcounter/setting.json',g.settings)
end

function DOVCOUNTER_ON_INIT(addon,frame)
    g.frame = frame
	g.stack = 0
    if g.settings.position then
         frame:SetOffset(g.settings.position.x, g.settings.position.y);
    else
        g.settings.position = {}
        g.settings.position.x = frame:GetX();
        g.settings.position.y = frame:GetY();
    end
	addon:RegisterMsg('BUFF_ADD', 'DoV_UPDATE');
	addon:RegisterMsg('BUFF_REMOVE', 'DoV_UPDATE');
    addon:RegisterMsg('BUFF_UPDATE', 'DoV_UPDATE');
    frame:SetEventScript(ui.LBUTTONUP, "DoV_END_DRAG");
end
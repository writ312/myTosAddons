-- Deeds of Valor ,SkillID : 11001,BuffID : 46
_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['DOVCOUNTER'] = _G['ADDONS']['DOVCOUNTER'] or {};
local g = _G['ADDONS']['DOVCOUNTER'];
local acutil = require('acutil')
g.settings = acutil.loadJSON('../addons/dovcounter/setting.json',{}) or {}

local function DoV_UPDATE_DIGIT_COLOR(frame, cnt, digit2, digit3)

	local configName = "";
	if cnt < 3 then
		configName = "Color_0_9";
	elseif cnt < 5 then
		configName = "Color_10_29";
	elseif cnt < 10 then
		configName = "Color_30_49";
	elseif cnt < 15 then
		configName = "Color_50_99";
	else
		configName = "Color_100";
	end
	
	local colorTone = frame:GetUserConfig(configName);
	DEVELOPERCONSOLE_PRINT_TEXT(colorTone)
	digit2:SetColorTone(colorTone);
	digit3:SetColorTone(colorTone);

end
local function SetStackPic(frame,stack)
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
	-- local colorTone = DoV_UPDATE_DIGIT_COLOR(frame,stack)
    DoV_UPDATE_DIGIT_COLOR(frame,stack,digit2,digit3)
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
		-- local skillLv = dov.arg1
		local stack = dov.over
        if g.stack < stack  then
           SetStackPic(g.frame,stack)
           g.stack = stack
        end
    else
        g.stack = 0
        g.frame:ShowWindow(0)
    end
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

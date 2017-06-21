_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['QUICKMENU'] = _G['ADDONS']['QUICKMENU'] or {};
local g = _G['ADDONS']['QUICKMENU']
local acutil = require('acutil')
g.user = 'fill'
g.index = 1
g.counter = 0
g.setting = {}
g.settingPath = '../addons/quickmenu/'

function QUICKMENU_ON_INIT(addon,frame)
	local user = GetMyName()
	if(g.user ~= user) then
		g.setting = {}
		g.user = user
        g.index = 1
	end
	local setting ,e = acutil.loadJSON(g.settingPath..user..'.json',nil) or {}
	if(e or #setting == 0) then
		table.insert(setting,{title = 'indun',type = 'chat',msg = '$indun'})
		table.insert(setting,{title = 'よろ',type = 'chat',msg = 'よろー'})
		table.insert(setting,{title = 'おつ',type = 'chat',msg = 'おつー'})
		table.insert(setting,{title = 'おはよ',type = 'chat',msg = 'おはよー'})
		table.insert(setting,{title = 'ばんわ',type = 'chat',msg = 'ばんわー'})
		table.insert(setting,{title = 'うう～い',type = 'chat',msg = 'うう～い'})
        g.setting.menu = setting
        g.setting.interval = 5
    else
        g.setting = setting
    end
    for i = 1 ,12 do
        if g.setting.menu[i] then
            frame:GetChild('menu'..i):SetText('{#000000}'..g.setting.menu[i].title)
        else
             g.setting.menu[i] = {}
        end
    end

	acutil.saveJSON(g.settingPath..g.user..'.json',g.setting)
    acutil.setupHook(OPEN_QUICKMENU_FRAME,'UI_TOGGLE_HELPLIST')
    acutil.slashCommand('/qm',QUICKMENU_COMMAND)
    acutil.slashCommand('/quickmenu',QUICKMENU_COMMAND)

    local edit = frame:CreateOrGetControl('edit','edit',0,0,0,0)
    local timer = frame:CreateOrGetControl('timer','timer',0,0,0,0)
    tolua.cast(timer,'ui::CAddOnTimer')
    timer:SetUpdateScript('QUICKMENU_UPDATE')
end

function QUICKMENU_UPDATE(frame,msg,argStr,argNum)
    g.counter = g.counter - 1
    if g.counter > 0 then return end
    local frame = ui.GetFrame('quickmenu')
	if keyboard.GetDownKey() == 'ESC' or keyboard.GetDownKey() == 'F10' or joystick.IsKeyPressed('JOY_BTN_2') == 1 or GET_CHILD(frame,'edit','ui::CEditControl'):IsHaveFocus() == 0 then 
        GET_CHILD(frame,'timer','ui::CAddOnTimer'):Stop()
		frame:ShowWindow(0)
        return
	end
	if keyboard.GetDownKey() == 'SPACE' or keyboard.GetDownKey() == 'ENTER' or joystick.IsKeyPressed('JOY_BTN_3') == 1 then
		EXCUTE_QUICKMENU_ITEM(frame,g.index)
		return
	end
	if keyboard.GetDownKey() == 'DOWN' or joystick.IsKeyPressed('JOY_DOWN') == 1 then
		g.index = g.index + 1
		if g.index == 7 then
			g.index = 1
        elseif g.index == 13 then
            g.index = 7
		end
		SELECT_QUICKMENU_ITEM(frame,g.index)
		return 
	end
	if keyboard.GetDownKey() == 'UP' or joystick.IsKeyPressed('JOY_UP') == 1 then
		g.index = g.index - 1
		if g.index == 0 then
			g.index = 6
		elseif g.index == 6 then
            g.index = 12
        end
		SELECT_QUICKMENU_ITEM(frame,g.index)
		return
	end
    if keyboard.GetDownKey() == 'RIGHT' or joystick.IsKeyPressed('JOY_RIGHT') == 1 then
		g.index = g.index + 6
		if g.index > 12 then
			g.index = g.index - 12
        end
		SELECT_QUICKMENU_ITEM(frame,g.index)
		return
	end
    if keyboard.GetDownKey() == 'LEFT' or joystick.IsKeyPressed('JOY_LEFT') == 1 then
		g.index = g.index - 6
		if g.index < 1 then
			g.index = g.index + 12
        end
		SELECT_QUICKMENU_ITEM(frame,g.index)
		return
	end
end

function escapeCommand(string)
    if string.sub(string, 1, 1) == "/" then
        string = "$"..string.sub(string, 2, #string);
    end
    return string;
end

local function unescapeCommand(string)
    if string.sub(string, 1, 1) == "$" then
        string = "/"..string.sub(string, 2, #string);
    end
    return string;
end

function QUICKMENU_COMMAND(command)
    local cmd = table.remove(command, 1);
    if not cmd then
        CHAT_SYSTEM("/qm [num] [title] [message]")
        CHAT_SYSTEM("/qm msg [num] [message]");
        CHAT_SYSTEM("/qm title [num] [title]");
        CHAT_SYSTEM("/qm interval [num]");
    elseif cmd == 'msg' then
        -- /qm msg [num] [message]
        local msg = "";
        num = tonumber(table.remove(command, 1));
        for index, item in ipairs(command) do
            msg = msg..item.." ";
        end
        msg = string.sub(msg, 1, #msg - 1);
        if 1 <= num and num <= 12 then
            g.setting.menu[num].msg = escapeCommand(msg)
        end
    elseif cmd == 'title' then
        -- /qm title [num] [title]
        local title = "";
        num = table.remove(command, 1);
        title = table.remove(command, 1);
        if 1 <= num and num <= 12 then
            g.setting.menu[num].title = title
        end
    elseif cmd == 'interval' then
        g.setting.interval = tonumber(table.remove(command,1))
    else
    -- /qm [num] [title] [message]
        num = tonumber(cmd)
        if 1 <= num and num <= 12 then
            -- タイトルの取得
            title = table.remove(command, 1);
            
            -- メッセージの取得
            local msg = "";
            for index, item in ipairs(command) do
                msg = msg..item.." ";
            end
            msg = string.sub(msg, 1, #msg - 1);
            g.setting.menu[num].msg = escapeCommand(msg) 
            g.setting.menu[num].title = title
        end
    end
    acutil.saveJSON(g.settingPath..g.user..'.json',g.setting)
    local frame = ui.GetFrame('quickmenu')
    for i = 1 ,12 do
        if g.setting.menu[i] then
            frame:GetChild('menu'..i):SetText('{#000000}'..g.setting.menu[i].title)
        end
    end
end

function OPEN_QUICKMENU_FRAME()
    local frame = ui.GetFrame('quickmenu')
    if frame:IsVisible() == 1 then frame:ShowWindow(0);return end
    local edit = GET_CHILD(frame,'edit','ui::CEditControl')
    edit:Focus()
    local timer = GET_CHILD(frame,'timer','ui::CAddOnTimer')
    timer:Stop()
    timer:Start(0.01)
    frame:Resize(frame:GetWidth(), 10 * 40 + 30);
	frame:ShowWindow(1);
	SELECT_QUICKMENU_ITEM(frame,g.index)
end

function SELECT_QUICKMENU_ITEM(frame,index)
	local childName = 'menu' .. index 
	local ItemBtn = frame:GetChild(childName);
	local x, y = GET_SCREEN_XY(ItemBtn);
	mouse.SetPos(x + ItemBtn:GetWidth()*0.25,y);
	mouse.SetHidable(0);
    g.counter = g.setting.interval
end

function EXCUTE_QUICKMENU_ITEM(frame,index)
	local item = g.setting.menu[index]
    ui.Chat(unescapeCommand(item.msg))
	frame:ShowWindow(0)
end
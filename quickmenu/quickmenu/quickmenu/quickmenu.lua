_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['QUICKMENU'] = _G['ADDONS']['QUICKMENU'] or {};
local g = _G['ADDONS']['QUICKMENU']
local acutil = require('acutil')
g.user = nil
g.index = 1
g.counter = 0
g.settingPath = '../addons/quickmenu/setting.json'

local function escapeCommand(string)
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

local function QUICKMENU_UPDATE_UI()
    local frame = ui.GetFrame('quickmenu')
    local name =  GETMYPCNAME()
    for i = 1, 12 do
        local item = g.setting.user[name][i]
        item = next(item) and item or g.setting.menu[i]
        local menu = frame:GetChild('menu'..i)
        if item.type == 'skill' then
            local skill = GetClassByType('Skill',item.SkillID)
            menu:SetText(string.format('{img icon_%s 30 30}{#000000}%s',skill.Icon,skill.Name)) 
            menu:SetTextTooltip(string.gsub(" "..menu:GetText(),'000000','FFFFFF').." ")       
        elseif item.type == 'item' then
            local obj = GetClassByType('Item',item.ClassID)
            local invitem = session.GetInvItemByName(obj.ClassName)
            if invitem then
                menu:SetText(string.format('{img %s 30 30}{#000000}%s : %d',obj.Icon,obj.Name,invitem.count))
                menu:SetTextTooltip(string.gsub(" "..menu:GetText(),'000000','FFFFFF').." ")   
            end
        else 
            menu:SetText('{#000000}'..(g.setting.menu[i].title or 'None'))
            menu:SetTextTooltip(string.format('{#ffffff} %s ',unescapeCommand(g.setting.menu[i].msg or 'None')))
        end
        menu:Resize(200,40)
    end
end

function QUICKMENU_ON_INIT(addon,frame)
	local setting ,e = acutil.loadJSON(g.settingPath,nil) or {}
	if(e or setting.version ~= '1.0.2' or (not next(setting))) then
        g.setting = {}
        setting = {}
		table.insert(setting,{title = 'indun',type = 'chat',msg = '$indun'})
		table.insert(setting,{title = 'よろ',type = 'chat',msg = '$cc'})
		table.insert(setting,{title = 'おつ',type = 'chat',msg = 'おつー'})
		table.insert(setting,{title = 'おはよ',type = 'chat',msg = 'おはよー'})
		table.insert(setting,{title = 'ばんわ',type = 'chat',msg = 'ばんわー'})
		table.insert(setting,{title = 'うう～い',type = 'chat',msg = 'うう～い'})
        for i = 7 , 12 do
            setting[i] = {}
        end
        g.setting.menu = setting
        g.setting.interval = 5
        g.setting.version = '1.0.2'
    else
        g.setting = setting
    end
    local userName = GETMYPCNAME()
    if g.userName ~= userName then
        g.setting.user = g.setting.user or {}
        g.setting.user[userName] = g.setting.user[userName] or {} 
        for i = 1,12 do
            g.setting.user[userName][i] = g.setting.user[userName][i] or {}
        end
    end


	acutil.saveJSON(g.settingPath,g.setting)
    acutil.setupHook(OPEN_QUICKMENU_FRAME,'UI_TOGGLE_HELPLIST')
    acutil.slashCommand('/qm',QUICKMENU_COMMAND)
    acutil.slashCommand('/quickmenu',QUICKMENU_COMMAND)

    QUICKMENU_UPDATE_UI()

    local edit = frame:CreateOrGetControl('edit','edit',0,0,0,0)
    local timer = frame:CreateOrGetControl('timer','timer',0,0,0,0)
    tolua.cast(timer,'ui::CAddOnTimer')
    timer:SetUpdateScript('QUICKMENU_UPDATE')
end

function QUICKMENU_UPDATE(frame,msg,argStr,argNum)
    g.counter = g.counter - 1
    if g.counter > 0 then return end
    local frame = ui.GetFrame('quickmenu')
	if keyboard.GetDownKey() == 'ESC' or keyboard.GetDownKey() == 'F10' or joystick.IsKeyaessed('JOY_BTN_2') == 1 or joystick.IsKeyPressed('JOY_BTN_10') == 1 or GET_CHILD(frame,'edit','ui::CEditControl'):IsHaveFocus() == 0 then 
        GET_CHILD(frame,'timer','ui::CAddOnTimer'):Stop()
		frame:ShowWindow(0)
        ui.GetFrame('quickmenu_setting'):ShowWindow(0)
        return
	end
	if keyboard.GetDownKey() == 'SPACE' or keyboard.GetDownKey() == 'ENTER' or joystick.IsKeyPressed('JOY_BTN_3') == 1 then
		EXECUTE_QUICKMENU_ITEM(frame,g.index)
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

function QUICKMENU_COMMAND(command)
    local cmd = table.remove(command, 1);
    if not cmd then
        CHAT_SYSTEM("/qm [num] [title] [message]")
        CHAT_SYSTEM("/qm msg [num] [message]");
        CHAT_SYSTEM("/qm title [num] [title]");
        CHAT_SYSTEM("/qm interval [num]");
        CHAT_SYSTEM("/qm open")
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
    elseif cmd == 'open' then
        OPEN_QUICKMENU_FRAME()
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
    acutil.saveJSON(g.settingPath,g.setting)
    local frame = ui.GetFrame('quickmenu')
    for i = 1 ,12 do
        g.setting.menu[i] = g.setting.menu[i] or {}
        frame:GetChild('menu'..i):SetText('{#000000}'..(g.setting.menu[i].title or "None"))
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
    QUICKMENU_UPDATE_UI()
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

function EXECUTE_QUICKMENU_ITEM(frame,index)
    local item = g.setting.user[GETMYPCNAME()][index]
    item = next(item) and item or g.setting.menu[index]
    if not item then return end

    if item.type == 'skill' then
        control.Skill(item.SkillID)
    elseif item.type == 'item' then
        local obj = GetClassByType('Item',item.ClassID)
        local invitem = session.GetInvItemByName(obj.ClassName) 
        INV_ICON_USE(invitem)
    else
        ui.Chat(unescapeCommand(item.msg))
    end
	frame:ShowWindow(0)
end

-- ui click event
function QUICKMENU_LBTN_CLICK(frame,control,argStr,index)
    g.index = index
    EXECUTE_QUICKMENU_ITEM(frame,index)
end

function QUICKMENU_RBTN_CLICK(frame,control,argStr,index)
    g.index = index
    OPEN_QUICKMENU_SETTING_FRAME(index)
end

-- QuickMenu Setting Frame Function
function OPEN_QUICKMENU_SETTING_FRAME(index)
    local quickmenu = ui.GetFrame('quickmenu')
    GET_CHILD(quickmenu,'timer','ui::CAddOnTimer'):Stop()
    GET_CHILD(quickmenu,'edit','ui::CEditControl'):ReleaseFocus()
    
    local frame = ui.GetFrame('quickmenu_setting')
    if frame:IsVisible() == 1 then return end
    frame:SetUserValue('index',index)
    
    local slot = GET_CHILD(frame,'slot','ui::CSlot')
    slot:ClearIcon()
    CreateIcon(slot)

    frame:GetChild('titleEdit'):SetText('') 
    frame:GetChild('msgEdit'):SetText('')

    local item = g.setting.user[GETMYPCNAME()][index] or {}
    if  next(item) then
        if item.type == 'skill' then
            local obj = GetClassByType('Skill',item.SkillID)
        else
             obj = GetClassByType('Item',item.ClassID)
        end
        slot:SetImage((item.type == 'item' and '' or 'icon_')..obj.Icon)
    else
        item = g.setting.menu[index] or {}
        frame:GetChild('titleEdit'):SetText(item.title or '') 
        frame:GetChild('msgEdit'):SetText(unescapeCommand(item.msg or ''))
    end

    frame:ShowWindow(1)

    g.tempObj = nil
end

function QUICKMENU_ON_DROP(frame,control,argStr,argNum)
    local liftIcon 	= ui.GetLiftIcon();
    local liftIconInfo = liftIcon:GetInfo()
    local FromFrameName	= liftIcon:GetTopParentFrame():GetName();
    if FromFrameName ~= 'inventory' and FromFrameName ~= 'skilltree'  then return end
    local slot = tolua.cast(control, 'ui::CSlot');
    local obj = GetObjectByGuid(liftIconInfo:GetIESID()) or  GetClassByType('Skill',liftIconInfo.type)
    if not obj then 
        return
    end
    local icon = CreateIcon(slot)
    icon:SetImage((FromFrameName == 'inventory' and '' or 'icon_')..obj.Icon)
    icon:SetTextTooltip(obj.Name)
    slot:SetEventScript(ui.RBUTTONUP, 'QUICKMENU_SLOT_CLEAR')
    icon:SetEventScript(ui.RBUTTONUP, 'QUICKMENU_SLOT_CLEAR')
    g.tempObj = liftIconInfo
end

function QUICKMENU_SLOT_CLEAR(frame,control,argStr,argNum)
    local slot = GET_CHILD(frame,'slot','ui::CSlot');
    slot:ClearIcon()
    g.tempObj = nil
end

function QUICKMENU_TEMP_SAVE_ITEM(frame,control,argStr,argNum)
    local index = frame:GetUserIValue('index')
    local slot = GET_CHILD(frame,'slot','ui::CSlot')
    local icon = slot:GetIcon()
    local iconinfo = g.tempObj
    if icon and iconinfo then
        if iconinfo.category == 'Skill' then
            g.temp = {
                type = 'skill',
                SkillID = iconinfo.type
            }

            QUICKMENU_SAVE_ITEM(index,false)
        elseif iconinfo.category == 'Item' then
            g.temp = {
                type = 'item',
                ClassID = iconinfo.type
            }
            ui.MsgBox("Would you like to set this item to all your characters?","QUICKMENU_SAVE_ITEM("..index..",true)","QUICKMENU_SAVE_ITEM("..index..",false)")
        end
    else
        local title = frame:GetChild('titleEdit'):GetText() 
        local msg = frame:GetChild('msgEdit'):GetText()
        g.temp = {
            title = title,
            type = 'chat',
            msg = escapeCommand(msg)
        }
        ui.MsgBox("Would you like to set this chat message to all your characters?","QUICKMENU_SAVE_ITEM("..index..",true)","QUICKMENU_SAVE_ITEM("..index..",false)")
    end 
end

function QUICKMENU_SAVE_ITEM(index,isGloabalSetting)
    if isGloabalSetting then
        g.setting.menu[index] = g.temp
    else
        g.setting.user[GETMYPCNAME()][index] = g.temp
    end
    acutil.saveJSON(g.settingPath,g.setting) 
    g.setting = acutil.loadJSON(g.settingPath,nil)
    local quickmenu = ui.GetFrame('quickmenu')
    GET_CHILD(quickmenu,'edit','ui::CEditControl'):Focus()
    GET_CHILD(quickmenu,'timer','ui::CAddOnTimer'):Start(0.01)
    QUICKMENU_UPDATE_UI()
    ui.GetFrame('quickmenu_setting'):ShowWindow(0)
end

function QUICKMENU_REMOVE_SETTING(frame,control,argStr,argNum)
    local i = frame:GetUserIValue('index')
    local item = g.setting.user[GETMYPCNAME()][i]
    if  next(item) then
        g.setting.user[GETMYPCNAME()][i] = {}
    else
        g.setting.menu[i] = {}
    end
    acutil.saveJSON(g.settingPath,g.setting)
    local quickmenu = ui.GetFrame('quickmenu')
    GET_CHILD(quickmenu,'edit','ui::CEditControl'):Focus()
    GET_CHILD(quickmenu,'timer','ui::CAddOnTimer'):Start(0.01)
    QUICKMENU_UPDATE_UI()
    ui.GetFrame('quickmenu_setting'):ShowWindow(0)
end
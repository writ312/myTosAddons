_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['ITEMNOTICE'] = _G['ADDONS']['ITEMNOTICE'] or {};
local g = _G['ADDONS']['ITEMNOTICE'] 
local acutil = require('acutil');

g.items = {}
g.continueItems = {}
g.name = nil

function ITEMNOTICE_UPDATE()
    for i , item in ipairs(g.items) do
        local obj = GetClassByType('Item',item.ClassID)
        local invitem = session.GetInvItemByName(obj.ClassName) 
        if invitem and (invitem.count == item.count) and (item.status == 1) then
            ui.SysMsg("You've completed requirement items.")
            ui.SysMsg(string.format("You got %s %d.",item.Name,invitem.count))
            item.status = false
            acutil.saveJSON('../addons/itemnotice/noticeItem.json',g.items)
        end
    end
end

local function createNoticeDetailList(frame,gbox,index,item)
    local list = gbox:CreateOrGetControl('groupbox','Gbox'..index,25,50*(index - 1),700,45)
    list:SetSkinName("market_listbase")
    list:SetEventScript(ui.RBUTTONUP, 'CHANGE_COUNT_NOTICE_ITEM');
    list:SetEventScriptArgNumber(ui.RBUTTONUP,index)
    
    local closeBtn = list:CreateOrGetControl('button','closeBtn',10,5,35,35)
    closeBtn:SetSkinName("test_red_button")
    closeBtn:SetText("{s25}×")
    closeBtn:SetEventScript(ui.LBUTTONUP, 'DELETE_NOTICE_ITEM');
    closeBtn:SetEventScriptArgNumber(ui.LBUTTONUP,index) 

    local txt = list:CreateOrGetControl('richtext','detailTxt',60,5,150,45)
    txt:SetText(string.format("{img %s 35 35}{#000000}%s : %d",item.Icon,item.Name,item.count))
    txt:SetEventScript(ui.RBUTTONUP, 'CHANGE_COUNT_NOTICE_ITEM');
    txt:SetEventScriptArgNumber(ui.RBUTTONUP,index)
    
    local restartBtn = list:CreateOrGetControl('button','restartBtn',600,5,70,35)
    restartBtn:SetText("Restart")
    restartBtn:SetEventScript(ui.LBUTTONUP, 'CHANGE_STATUS_NOTICE_ITEM');
    restartBtn:SetEventScriptArgNumber(ui.LBUTTONUP,index) 

    local stopBtn = list:CreateOrGetControl('button','stopBtn',600,5,70,35)
    stopBtn:SetText('Checking')
    stopBtn:SetEventScript(ui.LBUTTONUP, 'CHANGE_STATUS_NOTICE_ITEM');
    stopBtn:SetEventScriptArgNumber(ui.LBUTTONUP,index) 
   
    local checkbox = list:CreateOrGetControl('checkbox','checkBox',400,5,100,35) 
    tolua.cast(checkbox,'ui::CCheckBox')
    if (item.autoRestart == 1 )then checkbox:SetCheck(1) end
    checkbox:SetEventScript(ui.LOST_FOCUS , 'CHANGE_AUTO_RESTART_NOTICE_ITEM');
    checkbox:SetEventScriptArgNumber(ui.LOST_FOCUS ,index) 
    checkbox:SetText("{#000000}Automatic Restart")

    local item = g.items[index]
    if item.status == 1 then
        stopBtn:ShowWindow(1)
        restartBtn:ShowWindow(0)
    else
        stopBtn:ShowWindow(0)
        restartBtn:ShowWindow(1)
    end
end

local function createNoticeList()
    local frame = ui.GetFrame('itemnotice')
    local gbox = frame:GetChild('itemListGbox')
    gbox:RemoveAllChild()
    for i , item in ipairs(g.items) do
        createNoticeDetailList(frame,gbox,i,item)
    end
end

function CHANGE_AUTO_RESTART_NOTICE_ITEM(frame,control,argStr,index)
    local item = g.items[index]
    local checkbox = tolua.cast(control,'ui::CCheckBox')   
    item.autoRestart = (checkbox:IsChecked() == 1) and 1 or 0
    acutil.saveJSON('../addons/itemnotice/noticeItem.json',g.items)
end
function CHANGE_STATUS_NOTICE_ITEM(frame,control,argStr,index)
    local item = g.items[index]
    item.status = (item.status == 1) and 0 or 1
    acutil.saveJSON('../addons/itemnotice/noticeItem.json',g.items)
    createNoticeList()
end

function CHANGE_COUNT_NOTICE_ITEM(frame,control,argStr,index)
    frame = ui.GetFrame('itemnotice')
    local item = table.remove(g.items,index)
    local obj = GetClassByType('Item',item.ClassID)
    g.obj = obj;
    local edit = frame:GetChildRecursively("countEdit");
    edit:SetText(item.count)
    local slot = GET_CHILD_RECURSIVELY(frame,'itemSlot','ui::CSlot')
    CreateIcon(slot):SetImage(item.Icon)
    local checkbox = GET_CHILD_RECURSIVELY(frame,"continueChbox",'ui::CCheckBox')
    checkbox:SetCheck(item.autoRestart)
    acutil.saveJSON('../addons/itemnotice/noticeItem.json',g.items)
    createNoticeList()
    
end


function DELETE_NOTICE_ITEM(frame,control,argStr,index)
    table.remove(g.items,index)
    acutil.saveJSON('../addons/itemnotice/noticeItem.json',g.items)
    createNoticeList()
end

function ITEMNOTICE_DROP_SLOT(frame, control, argStr, argNum)
    local liftIcon 	= ui.GetLiftIcon();
    local liftIconInfo = liftIcon:GetInfo()
    local FromFrameName	= liftIcon:GetTopParentFrame():GetName();
    if FromFrameName ~= 'inventory' then return end
	local slot = tolua.cast(control, 'ui::CSlot');
    local obj = GetObjectByGuid(liftIconInfo:GetIESID())
    if not obj then return end
    g.obj = obj
    local icon = CreateIcon(slot)
    icon:SetImage(obj.Icon)
    icon:SetTextTooltip(obj.Name)
end

function ITEMNOTICE_REGISTER_ITEM(frame, control, argStr, argNum)
    local frame = ui.GetFrame('itemnotice')
    local edit = frame:GetChildRecursively("countEdit");
    local count = tonumber(edit:GetText())
    if count <= 0 then return end;
    local slot = tolua.cast(frame:GetChildRecursively('itemSlot'),'ui::CSlot')
    slot:ClearIcon()
    CreateIcon(slot);
    edit:SetText(0);
    local checkbox = GET_CHILD_RECURSIVELY(frame,"continueChbox",'ui::CCheckBox')
    local autoRestart = 1
    if checkbox:IsChecked() ~= 1 then
        autoRestart = 0
    end
    local obj = g.obj
    table.insert(g.items,{
        ClassID = obj.ClassID,
        Name = obj.Name,
        Icon = obj.Icon,
        count = count,
        status = 1,
        autoRestart = autoRestart
    })
    acutil.saveJSON('../addons/itemnotice/noticeItem.json',g.items)
    createNoticeList()
end

function ITEMNOTICE_OPEN_WINDOW(cmd)
    ui.GetFrame('itemnotice'):ShowWindow(1)
    ui.GetFrame('inventory'):ShowWindow(1)
end

function ITEMNOTICE_INIT()
    if g.name ~= GETMYPCNAME() then
        g.name = GETMYPCNAME()
        g.items = g.items or {}
        g.items ,e = acutil.loadJSON('../addons/itemnotice/noticeItem.json')
        if not g.items or g.items == {} then
            table.insert(g.items,{
                ClassID = 666165,
                Name = "몬스터 증표",
                Icon = "cathedral_puzzle_piece",
                isChecking = 1,
                autoRestart = 1,
                count = 10
            })
            acutil.saveJSON('../addons/itemnotice/noticeItem.json',g.items)
        end
    end

    for i , item in ipairs(g.items) do
        if item and (item.autoRestart == 1)then
            item.status = 1
        end
    end
    createNoticeList()
end


function ITEMNOTICE_ON_INIT(addon,frame)
    acutil.slashCommand('/itemnotice',ITEMNOTICE_OPEN_WINDOW)
    addon:RegisterMsg('INV_ITEM_ADD', 'ITEMNOTICE_UPDATE');
    addon:RegisterMsg('INV_ITEM_CHANGE_COUNT', 'ITEMNOTICE_UPDATE');
    ITEMNOTICE_INIT()
end

-- for zclass list function

function SetItemByClassList(frame,control,argstr,ClassID)
    local frame = ui.GetFrame('itemnotice')
    local slot = tolua.cast(frame:GetChildRecursively('itemSlot'),'ui::CSlot')
    local icon = CreateIcon(slot)
    local obj = GetClassByType('Item',ClassID)
    if not ClassID then return end   
    icon:SetImage(obj.Icon)
    icon:SetTextTooltip(obj.Name)
    g.obj = obj
end


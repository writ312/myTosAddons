--アドオン名（大文字）
local addonName = "Muteki2ex";
local addonNameUpper = string.upper(addonName);
local addonNameLower = string.lower(addonName);
--作者名
local author = "WRIT";

--アドオン内で使用する領域を作成。以下、ファイル内のスコープではグローバル変数gでアクセス可
_G["ADDONS"] = _G["ADDONS"] or {};
_G["ADDONS"][author] = _G["ADDONS"][author] or {};
_G["ADDONS"][author][addonNameUpper] = _G["ADDONS"][author][addonNameUpper] or {};
local g = _G["ADDONS"][author][addonNameUpper];
local acutil = require('acutil')
local defaultColor = "FFCCCC22"

function MUTEKI2SETTING_ON_INIT(addon,frame)
    g.settingAddon = addon
    g.settingFrame = frame
    acutil.setupEvent(addon,'SET_BUFF_SLOT',"MUTEKI2_SET_BUFFSLOT_LBTNCLICK")
    acutil.addSysIcon("Muteki2_Setting", "sysmenu_skill", "Muteki2_Setting", "MUTEKI2_FRAME_OPEN")  
    MUTEKI2_CREATE_SETTING_FRAME()
end

function MUTEKI2_FRAME_OPEN(cmd)
    if g.settingFrame:IsVisible() == 0 then
      MUTEKI2_CREATE_SETTING_FRAME()
        g.settingFrame:ShowWindow(1)
    else
        g.settingFrame:ShowWindow(0)
    end
end

function MUTEKI2_CREATE_SETTING_FRAME()
  MUTEKI2_SAVE_SETTINGS()  
  local frame = g.settingFrame
  local txt = frame:CreateOrGetControl('richtext','buffTimeTxt',20,-10,30,25)
  txt:SetText('{#000000}指定されたバフの時間を超えている場合は隠されています{nl}Hidden if it is more than specified buff time')
  
  local edit = frame:CreateOrGetControl('edit','buffTimeEdit',430,0,70,25)
  tolua.cast(edit,'ui::CEditControl')
  edit:SetNumberMode(1)
  edit:SetOffsetYForDraw(-5)
  edit:SetOffsetXForDraw(10)
  edit:SetText(g.settings.hiddenBuffTime or 0)
  edit:SetEventScript(ui.ENTERKEY  , 'MUTEKI2_SET_HIDDEN_BUFF_TIME')

  local gbox = frame:GetChild('settingGbox')
  gbox:RemoveAllChild()
  local i = 1
  for buffid , obj in pairs(g.settings.buffList) do
      MUTEKI2_CREATE_SETTING_LIST(frame,gbox,i,tonumber(buffid),obj)
      i = i + 1
  end
  MUTEKI2_CREATE_SETTING_LIST(frame,gbox,i,0,{})
end

function MUTEKI2_CREATE_SETTING_LIST(frame,gbox,index,buffid,gaugeBuff)
  local buff = GetClassByType('Buff',buffid)
  local list = gbox:CreateOrGetControl('groupbox','List'..index,15,20+80*(index - 1),515,75)
  list:SetSkinName("market_listbase")
  list:SetUserValue('buffid',buffid)
  -- print(index)
  list:SetUserValue('index',index)
  -- print(list:GetUserIValue('index'))
  local closeBtn = list:CreateOrGetControl('button','c      loseBtn',10,20,35,35)
  closeBtn:SetSkinName("test_red_button")
  closeBtn:SetText("{s25}×")
  closeBtn:SetEventScript(ui.LBUTTONUP, "MUTEKI2_DELETE_BUFFID");
  closeBtn:SetEventScriptArgString(ui.LBUTTONUP,buffid) 

  local buffSlot = list:CreateOrGetControl('slot','buffSlot',60,10,55,55)
  tolua.cast(buffSlot,'ui::CSlot')
  -- buffSlot:SetEventScript(ui.DROP, 'ITEMNOTICE_DROP_SLOT');
  -- slot:SetEventScriptArgNumber(ui.DROP,index)
  buffSlot:SetSkinName('slot')
  if buff and buff.Icon then
    local buffIcon = CreateIcon(buffSlot)
    buffIcon:SetImage('icon_'..buff.Icon)
    buffIcon:SetTextTooltip(buff.Name)

    local buffidText = list:CreateOrGetControl('richtext','buffidText',120,15,60,30)
    buffidText:SetText('{#000000}'..buff.Name)
  end

  local edit = list:CreateOrGetControl('edit','edit',120,40,60,30)
  tolua.cast(edit,'ui::CEditControl')
  edit:SetNumberMode(1)
  edit:SetUserValue('index',index)
  edit:SetOffsetYForDraw(-5)
  edit:SetText(buffid or '')
  edit:SetLostFocusingScp('MUTEKI2_CHANGE_BUFFID')
  edit:SetEventScript(ui.ENTERKEY  , 'MUTEKI2_CHANGE_BUFFID')
  edit:SetEventScriptArgString(ui.ENTERKEY,buffid) 


  local checkbox = list:CreateOrGetControl('checkbox','circleIcon',200,35,100,35) 
  tolua.cast(checkbox,'ui::CCheckBox')
  checkbox:SetCheck(gaugeBuff.circleIcon and 1 or 0)
  checkbox:SetEventScript(ui.LOST_FOCUS , 'MUTEKI2_CHANGE_CIRCLE_MODE')
  checkbox:SetEventScriptArgNumber(ui.LOST_FOCUS,index) 
  checkbox:SetEventScriptArgString(ui.LOST_FOCUS,buffid) 
  checkbox:SetText("{#000000}アイコンを{nl}回転させるだけ")

  local colorTonePic = list:CreateOrGetControl('picture','colorTonePic',350,10,55,55)
  tolua.cast(colorTonePic,'ui::CPicture')
  colorTonePic:SetEnableStretch(1)
  colorTonePic:SetImage('hoge')
  colorTonePic:SetColorTone(gaugeBuff.color and gaugeBuff.color or defaultColor)
  local colorToneEdit = list:CreateOrGetControl('edit','colorToneEdit',420,45,80,30)
  tolua.cast(colorToneEdit,'ui::CEditControl')
  colorToneEdit:SetUserValue('index',index)
  colorToneEdit:SetOffsetYForDraw(-5)
  colorToneEdit:SetMaxLen(8)
  colorToneEdit:SetText(gaugeBuff.color and gaugeBuff.color or defaultColor)
  colorToneEdit:SetLostFocusingScp('MUTEKI2_CHANGE_COLORTONE')
  colorToneEdit:SetEventScriptArgString(15,buffid) 
  colorToneEdit:SetEventScript(ui.ENTERKEY  , 'MUTEKI2_CHANGE_COLORTONE')
  colorToneEdit:SetEventScriptArgString(ui.ENTERKEY,buffid) 

  
  local colorToneText = list:CreateOrGetControl('richtext','colorToneText',420,5,60,30)
  colorToneText:SetText('{#000000}Color Tone{nl}(AlphaRGB)')

end

function MUTEKI2_UPDATE_LIST_VIEW(list,buffid)
  MUTEKI2_SAVE_SETTINGS()
  local index = list:GetUserIValue('index')
  MUTEKI2_CREATE_SETTING_LIST(list:GetParent(),index,buffid,MUTEKI2_GET_GAUGE_BUFF(buffid))
end

function MUTEKI2_CHANGE_BUFFID(list,control,oldIDbuffid,argNum)
  
  local newID = tostring(control:GetText())    
  local index = control:GetUserIValue('index')
  if oldID == newID or GetClassByType('Buff',tonumber(newID)) then return end
  if oldID and g.settings.buffList[oldID] then
    g.settings.buffList[newID] = g.settings.buffList[oldID]
    g.settings.buffList[oldID] = nil
  else
    g.settings.buffList[newID] = {
      color = defaultColor
    }
  end
  MUTEKI2_CREATE_SETTING_FRAME()
end

function MUTEKI2_DELETE_BUFFID(list,control,buffid,argNum)
  g.settings.buffList[buffid] = nil
  ui.SysMsg(string.format("MUTEKI2の%sを`削除しました.",GetClassByType('Buff',buffid).Name))
  g.frame:RemoveChild(g.gauge[buffid]:GetName())
  MUTEKI2_CREATE_SETTING_FRAME()
end

function MUTEKI2_CHANGE_COLORTONE(list,control,buffid,argNum)
  local obj =  g.settings.buffList[buffid]
  local newColor = tostring(control:GetText()) 
  local oldColor = obj.color
  if #newColor ~= 8 or newColor == oldColor then return end
  obj.color = newColor
  local buff = GetClassByType('Buff',tonumber(buffid))
  -- MUTEKI2_UPDATE_LIST_VIEW(list,buffid)
  if obj.circleIcon then
    g.circle[buffid] = MUTEKI2_INIT_CIRCLE(frame,buff)
  else
    g.gauge[buffid]:SetColorTone(newColor)
  end
  
  MUTEKI2_SAVE_SETTINGS()
end

function MUTEKI2_CHANGE_CIRCLE_MODE(list,control,buffid,index)
  
    local checkbox = tolua.cast(control,'ui::CCheckBox')   
    g.settings.buffList[buffid].circleIcon = (checkbox:IsChecked() == 1) and true or false
    MUTEKI2_CREATE_SETTING_FRAME()
    -- MUTEKI2_UPDATE_LIST_VIEW(list,buffid)
end

function MUTEKI2_ADD_BUFFID(frame,control,argStr,buffid)
  if not g.settings.buffList[tostring(buffid)] then
    local buff = GetClassByType('Buff',buffid)
    g.settings.buffList[tostring(buffid)] = {color = defaultColor}
    ui.SysMsg(string.format("MUTEKI2に%sを追加しました.",buff.Name))
    g.gauge[tostring(buffid)] = MUTEKI2_INIT_GAUGE(g.frame,buff,defaultColor)
    g.gauge[tostring(buffid)]:ShowWindow(1)
    MUTEKI2_ADD_GAUGE_BUFF(MUTEKI2_GET_BUFF(buffid),g.gauge[tostring(buffid)])
    MUTEKI2_CREATE_SETTING_FRAME()    
  end
end

function MUTEKI2_SET_HIDDEN_BUFF_TIME(frame,control,argStr,argNum)
  local bufftime = tonumber(control:GetText())    
  if bufftime > 0  and bufftime ~= g.settings.hiddenBuffTime  then
    g.settings.hiddenBuffTime = bufftime
    ui.SysMsg(string.format('MUTEKI2 : Hide gauge with remaining time more than %d seconds',bufftime))
  end
end

function MUTEKI2_SET_BUFFSLOT_LBTNCLICK(frame,eventMsg)
  local slot, capt, class, buffType = acutil.getEventArgs(eventMsg)
  tolua.cast(slot,'ui::CSlot')
  slot:SetEventScript(ui.LBUTTONUP, 'MUTEKI2_ADD_BUFFID');
  slot:SetEventScriptArgNumber(ui.LBUTTONUP, buffType);
  slot:SetEventScriptArgString(ui.LBUTTONUP, class.Name);
end

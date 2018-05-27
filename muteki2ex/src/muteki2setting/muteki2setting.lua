local function toboolean(str)
  return str == 'true' and true or false
end

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

g.translations = {
	GLOBAL = {
		gaugeDescription = 'Show gauges below specific buff time (in seconds)',
		rotateIcons = '{#000000}Display icon',
		addBuff = 'MUTEKI2 - Added %s in settings ',
		deleteBuff = 'MUTEKI2 - Removed %s in settings ',
		colorTone = '{#000000}Color Tone{nl}(AlphaRGB)',
    hideGauge = 'MUTEKI2 : Hide gauge with remaining time more than %d seconds',
    isNotNotify = "{#000000}Hide with this character",
    isEffect = "{#000000}With effect"
	},
	JP = {
		gaugeDescription = '指定されたバフの時間を超えている場合は隠されています';
		rotateIcons = '{#000000}アイコンを{nl}回転させるだけ',
		addBuff = 'MUTEKI2に%sを追加しました.',
		deleteBuff = "MUTEKI2の%sを`削除しました.",
		colorTone = '{#000000}Color Tone{nl}(AlphaRGB)',
    hideGauge = 'MUTEKI2 : %d秒以上のバフは非表示になります',
    isNotNotify = "{#000000}このキャラクターでは{nl}表示しない",
    isEffect = "{#000000}バフがf追加されたときに{nl}エフェクトを表示する"
	}
} 
local serviceNation = config.GetServiceNation()
local function _translate(key)
	local localization = g.translations[serviceNation] or g.translations["GLOBAL"]
	return localization[key] or "Translation not provided"
end

function MUTEKI2SETTING_ON_INIT(addon,frame)
    g.settingAddon = addon
    g.settingFrame = frame
    acutil.setupEvent(addon,'SET_BUFF_SLOT',"MUTEKI2_SET_BUFFICON_LBTNCLICK")
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
  local buffTimeTxt = frame:CreateOrGetControl('richtext','buffTimeTxt',20,-10,30,25)
  buffTimeTxt:SetText('{#000000}'.._translate('gaugeDescription')..'{/}')
  
  local buffTimeEdit = frame:CreateOrGetControl('edit','buffTimeEdit',430,0,70,25)
  tolua.cast(buffTimeEdit,'ui::CEditControl')
  buffTimeEdit:SetNumberMode(1)
  buffTimeEdit:SetOffsetYForDraw(-5)
  buffTimeEdit:SetOffsetXForDraw(10)
  buffTimeEdit:SetText(g.settings.hiddenBuffTime or 0)
  buffTimeEdit:SetEventScript(ui.ENTERKEY  , 'MUTEKI2_SET_HIDDEN_BUFF_TIME')

  local gbox = frame:GetChild('settingGbox')
  gbox:RemoveAllChild()
  local i = 1
  for buffid , buffSetting in pairs(g.settings.buffList) do
      buffSetting.isNotNotify = buffSetting.isNotNotify or {} 
      MUTEKI2_CREATE_SETTING_LIST(frame,gbox,i,tonumber(buffid),buffSetting)
      i = i + 1
  end 
  MUTEKI2_CREATE_SETTING_LIST(frame,gbox,i,0,{})
end

function MUTEKI2_CREATE_SETTING_LIST(frame,gbox,index,buffid,buffSetting)
  local height = 120
  local buff = GetClassByType('Buff',buffid)
  local list = gbox:CreateOrGetControl('groupbox','List'..index,15,20+(height+5)*(index - 1),515,height)
  list:SetSkinName("market_listbase")
  list:SetUserValue('buffid',buffid)
  list:SetUserValue('index',index)

  local closeBtn = list:CreateOrGetControl('button','closeBtn',10,20,35,35)
  closeBtn:SetSkinName("test_red_button")
  closeBtn:SetText("{s25}×")
  closeBtn:SetEventScript(ui.LBUTTONUP, "MUTEKI2_DELETE_BUFFID");
  closeBtn:SetEventScriptArgString(ui.LBUTTONUP,buffid) 

  local buffPic = list:CreateOrGetControl('picture','buffPic',60,10,55,55)
  tolua.cast(buffPic,'ui::CPicture')
  buffPic:SetEnableStretch(1)
  if buff and buff.Icon then
    local buffIcon = CreateIcon(buffSlot)
    buffPic:SetImage('icon_'..buff.Icon)
    buffPic:SetTextTooltip(buff.Name)
  
    local buffnameTxt = list:CreateOrGetControl('richtext','buffnameTxt',120,15,60,30)
    buffnameTxt:SetText('{#000000}'..buff.Name)
  end

  local buffidEdit = list:CreateOrGetControl('edit','buffidEdit',120,40,60,30)
  tolua.cast(buffidEdit,'ui::CEditControl')
  buffidEdit:SetNumberMode(1)
  buffidEdit:SetUserValue('index',index)
  buffidEdit:SetOffsetYForDraw(-5)
  buffidEdit:SetText(buffid or '')
  buffidEdit:SetLostFocusingScp('MUTEKI2_CHANGE_BUFFID')
  buffidEdit:SetEventScript(ui.ENTERKEY  , 'MUTEKI2_CHANGE_BUFFID')
  buffidEdit:SetEventScriptArgString(ui.ENTERKEY,buffid) 


  local isCircle = list:CreateOrGetControl('checkbox','isCircle',200,35,100,35) 
  tolua.cast(isCircle,'ui::CCheckBox')
  isCircle:SetCheck(buffSetting.circleIcon and 1 or 0)
  isCircle:SetEventScript(ui.LBUTTONDOWN  , 'MUTEKI2_CHANGE_CIRCLE_MODE')
  isCircle:SetEventScriptArgNumber(ui.LBUTTONDOWN ,buffid) 
  isCircle:SetText(_translate('rotateIcons'))

  local colorTonePic = list:CreateOrGetControl('picture','colorTonePic',350,10,55,55)
  tolua.cast(colorTonePic,'ui::CPicture')
  colorTonePic:SetEnableStretch(1)
  colorTonePic:SetImage('hoge')
  colorTonePic:SetColorTone(buffSetting.color or defaultColor)

  local colorToneEdit = list:CreateOrGetControl('edit','colorToneEdit',420,45,80,30)
  tolua.cast(colorToneEdit,'ui::CEditControl')
  colorToneEdit:SetUserValue('index',index)
  colorToneEdit:SetOffsetYForDraw(-5)
  colorToneEdit:SetMaxLen(8)
  colorToneEdit:SetText(buffSetting.color and buffSetting.color or defaultColor)
  colorToneEdit:SetLostFocusingScp('MUTEKI2_CHANGE_COLORTONE')
  colorToneEdit:SetEventScriptArgString(15,buffid) 
  colorToneEdit:SetEventScript(ui.ENTERKEY  , 'MUTEKI2_CHANGE_COLORTONE')
  colorToneEdit:SetEventScriptArgString(ui.ENTERKEY,buffid) 
  
  local colorToneTxt = list:CreateOrGetControl('richtext','colorToneTxt',420,5,60,30)
  colorToneTxt:SetText(_translate('colorTone'))

  buffSetting.isNotNotify = buffSetting.isNotNotify or {}
  local isNotNotify = list:CreateOrGetControl('checkbox','isNotNotify',10,75,200,20) 
  tolua.cast(isNotNotify,'ui::CCheckBox')
  isNotNotify:SetCheck(buffSetting.isNotNotify[g.user] and 1 or 0)
  isNotNotify:SetEventScript(ui.LBUTTONDOWN  , 'MUTEKI2_CHANGE_NOTIFY')
  isNotNotify:SetEventScriptArgNumber(ui.LBUTTONDOWN ,buffid) 
  isNotNotify:SetText(_translate('isNotNotify'))
  
  local isEffect = list:CreateOrGetControl('checkbox','isEffect',250,75,200,20) 
  tolua.cast(isEffect,'ui::CCheckBox')
  isEffect:SetCheck(buffSetting.isEffect and 1 or 0)
  isEffect:SetEventScript(ui.LBUTTONDOWN  , 'MUTEKI2_CHANGE_EFFECT')
  isEffect:SetEventScriptArgNumber(ui.LBUTTONDOWN ,buffid) 
  isEffect:SetText(_translate('isEffect'))
end

function MUTEKI2_CHANGE_BUFFID(list,control,oldID,argNum)
  local newID = tostring(control:GetText())    
  local index = control:GetUserIValue('index')
  local buff = GetClassByType('Buff',tonumber(newID))
  if oldID == newID or not buff then return end
  if oldID and g.settings.buffList[oldID] then
    g.settings.buffList[newID] = {unpack(g.settings.buffList[oldID])}
    g.settings.buffList[oldID] = nil
    g.frame:RemoveChild(g.gauge[oldID]:GetName())
    g.gauge[oldID] = nil
    else
  g.settings.buffList[newID] = {
      color = defaultColor
    }
  end
  MUTEKI2_CREATE_SETTING_FRAME()
  g.gauge[newID] = MUTEKI2_INIT_GAUGE(g.frame,buff,g.settings.buffList[newID].color)
  MUTEKI2_ADD_GAUGE_BUFF(MUTEKI2_GET_BUFF(newID),g.gauge[newID])
end

function MUTEKI2_DELETE_BUFFID(list,control,buffid,argNum)
  g.settings.buffList[buffid] = nil
  ui.SysMsg(string.format(_translate('deleteBuff'),GetClassByType('Buff',buffid).Name))
  g.frame:RemoveChild(g.gauge[buffid]:GetName())
  g.gauge[buffid] = nil
  MUTEKI2_CREATE_SETTING_FRAME()
end

function MUTEKI2_CHANGE_COLORTONE(list,control,buffid,argNum)
  local buffSetting =  g.settings.buffList[buffid]
  local newColor = tostring(control:GetText()) 
  local oldColor = buffSetting.color
  if #newColor ~= 8 or newColor == oldColor then return end
  buffSetting.color = newColor
  if not buffSetting.circleIcon then
    g.gauge[buffid]:SetColorTone(newColor)
  end
  list:GetChild('colorTonePic'):SetColorTone(newColor)
  MUTEKI2_SAVE_SETTINGS()
end

function MUTEKI2_CHANGE_CIRCLE_MODE(list,control,isChecked,buffid)
  local buff = GetClassByType('Buff',buffid) 
  g.settings.buffList[tostring(buffid)].circleIcon = toboolean(isChecked)
  MUTEKI2_UPDATE_CONTROL(buffid)
  MUTEKI2_SAVE_SETTINGS()
end

function MUTEKI2_ADD_BUFFID(frame,control,argStr,buffid)
  if not g.settings.buffList[tostring(buffid)] then
    local buffObj = GetClassByType('Buff',buffid)
    g.settings.buffList[tostring(buffid)] = {color = defaultColor}
    ui.SysMsg(string.format(_translate('addBuff'),buffObj.Name))
    MUTEKI2_UPDATE_CONTROL(buffid)
    MUTEKI2_CREATE_SETTING_FRAME()    
  end
end

function MUTEKI2_SET_HIDDEN_BUFF_TIME(frame,control,argStr,argNum)
  local bufftime = tonumber(control:GetText())    
  if bufftime > 0  and bufftime ~= g.settings.hiddenBuffTime  then
    g.settings.hiddenBuffTime = bufftime
    ui.SysMsg(string.format(_translate('hideGauge'),bufftime))
    MUTEKI2_UPDATE_GAUGE_POS()
  end
end

function MUTEKI2_SET_BUFFICON_LBTNCLICK(frame,eventMsg)
  local slot, capt, class, buffType = acutil.getEventArgs(eventMsg)
  tolua.cast(slot,'ui::CSlot')
  slot:SetEventScript(ui.LBUTTONUP, 'MUTEKI2_ADD_BUFFID');
  slot:SetEventScriptArgNumber(ui.LBUTTONUP, buffType);
  slot:SetEventScriptArgString(ui.LBUTTONUP, class.Name);
end


function MUTEKI2_CHANGE_NOTIFY(list,control,isChecked,buffid)
  g.settings.buffList[tostring(buffid)].isNotNotify[g.user] = toboolean(isChecked)
  MUTEKI2_UPDATE_CONTROL(buffid)
  MUTEKI2_SAVE_SETTINGS()
end

function MUTEKI2_CHANGE_EFFECT(list,control,isChecked,buffid)
  g.settings.buffList[tostring(buffid)].isEffect = toboolean(isChecked)
  MUTEKI2_SAVE_SETTINGS()
end

function MUTEKI2_UPDATE_CONTROL(buffid)
  buffid = tostring(buffid)
  local frame = g.frame
  local buffSetting , buffObj , buff =  MUTEKI2_GET_BUFFS(buffid)
  local control = MUTEKI2_GET_CONTROL(buffid)
  if control then
    frame:RemoveChild(control:GetName())
    g.gauge[buffid] = nil
    g.circle[buffid] = nil
  end
  if not buff then return end
  if buffSetting.circleIcon then
    g.circle[buffid] =  MUTEKI2_INIT_CIRCLE(frame,buffObj)
    if not buffSetting.isNotNotify[g.user] then
      MUTEKI2_ADD_CIRCLE_BUFF(nil,g.circle[buffid])
    end
  else
    g.gauge[buffid] = MUTEKI2_INIT_GAUGE(frame,buffObj,buffSetting.color)
    if not buffSetting.isNotNotify[g.user] then
      MUTEKI2_ADD_GAUGE_BUFF(buff,g.gauge[buffid])
      end
    end
end
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
    gaugeDescription = '{#000000}Show gauges below specific buff time (in seconds){/}',
    positionMode = '{#000000)Position Mode{/}',
    lockText = '{#000000)Lock{/}',
    layerLvlText = '{#000000}Layer{nl}Level{/}',
    rotateIcons = '{#000000}Display icon{/}',
    addBuff = 'MUTEKI2 - Added %s in settings',
    deleteBuff = 'MUTEKI2 - Removed %s in settings',
    colorTone = '{#000000}Color Tone{/}',
    hideGauge = 'MUTEKI2 - Hide gauge with remaining time more than %d seconds',
    isNotNotify = "{#000000}Hide with this character{/}",
    isEffect = "{#000000}With effect{/}"
  },
  JP = {
    gaugeDescription = '{#000000}指定されたバフの時間を超えている場合は隠されています{/}';
    positionMode = '{#000000)ポジションモード{/}',
    lockText = '{#000000)ロック{/}',
    layerLvlText = '{#000000}レイヤー{nl}レベル{/}',
    rotateIcons = '{#000000}アイコンを回転させるだけ{/}',
    addBuff = 'MUTEKI2に%sを追加しました.',
    deleteBuff = "MUTEKI2の%sを`削除しました.",
    colorTone = '{#000000}カラートーン{/}',
    hideGauge = 'MUTEKI2 - %d秒以上のバフは非表示になります',
    isNotNotify = "{#000000}このキャラクターでは表示しない{/}",
    isEffect = "{#000000}バフが追加されたときにエフェクトを表示する{/}"
  },
  KOR = {
    gaugeDescription = "{#000000}설정된 초 이상 남은 버프 숨기기{/}";
    positionMode = "{#000000)버프 표시 모드{/}",
    lockText = "{#000000)잠금{/}",
    layerLvlText = "{#000000}레이어{nl}레벨{/}",
    rotateIcons = "{#000000}아이콘 회전{/}",
    addBuff = "MUTEKI2 - %s 버프를 추가했습니다.",
    deleteBuff = "MUTEKI2 - %s 버프를 삭제했습니다.",
    colorTone = "{#000000}색상{/}",
    hideGauge = "MUTEKI2 - %d초 이상 남은 버프는 표시하지 않습니다.",
    isNotNotify = "{#000000}이 캐릭터에서 숨기기{/}",
    isEffect = "{#000000}버프 시 이펙트 표시{/}"
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
  acutil.addSysIcon("muteki2ex", "sysmenu_skill", "muteki2ex", "MUTEKI2_FRAME_OPEN")
  MUTEKI2_CREATE_SETTING_FRAME()
end

function MUTEKI2_FRAME_OPEN(cmd)
  if g.settingFrame:IsVisible() == 0 then
    g.settingFrame:ShowWindow(1)
    MUTEKI2_CREATE_SETTING_FRAME()
  else
    g.settingFrame:ShowWindow(0)
  end
end

function MUTEKI2_CREATE_SETTING_FRAME()
  MUTEKI2_SAVE_SETTINGS()
  local frame = g.settingFrame
  local buffTimeTxt = AUTO_CAST(frame:GetChild('buffTimeText'))
  buffTimeTxt:SetText(_translate('gaugeDescription'))

  local modeTxt = AUTO_CAST(frame:GetChild('modeText'))
  modeTxt:SetText(_translate('positionMode'))
  frame:GetChild(g.settings.mode..'modeBtn'):SetSkinName('test_red_button')

  local isLock = g.settings.position.lock
  local lockModeBtn = frame:GetChild('lockmodeBtn')
  lockModeBtn:SetSkinName(isLock and 'test_cardtext_btn' or  'textbutton')
  lockModeBtn:SetText(isLock and '{s20}ON{/}' or '{s20}OFF{/}')

  local lockTxt = AUTO_CAST(frame:GetChild('lockText'))
  lockTxt:SetText(_translate('lockText'))

  local buffTimeEdit = frame:CreateOrGetControl('edit','buffTimeEdit',495,-10,70,25)
  tolua.cast(buffTimeEdit,'ui::CEditControl')
  buffTimeEdit:SetNumberMode(1)
  buffTimeEdit:SetOffsetYForDraw(-5)
  buffTimeEdit:SetOffsetXForDraw(10)
  buffTimeEdit:SetText(g.settings.hiddenBuffTime or 0)
  buffTimeEdit:SetEventScript(ui.ENTERKEY  , 'MUTEKI2_SET_HIDDEN_BUFF_TIME')

  local layerLvlTxt = AUTO_CAST(frame:GetChild('layerLvlText'))
  layerLvlTxt:SetText(_translate('layerLvlText'))

  local layerLvlEdit = frame:CreateOrGetControl('edit','layerLvlEdit',515,30,50,25)
  tolua.cast(layerLvlEdit,'ui::CEditControl')
  layerLvlEdit:SetNumberMode(1)
  layerLvlEdit:SetOffsetYForDraw(-5)
  layerLvlEdit:SetOffsetXForDraw(10)
  layerLvlEdit:SetText(g.settings.layerLvl or 80)
  layerLvlEdit:SetEventScript(ui.ENTERKEY  , 'MUTEKI2_SET_LAYER_LAVEL')

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
  local height = 155
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

    local buffnameTxt = list:CreateOrGetControl('richtext','buffnameTxt',120,10,60,30)
    buffnameTxt:SetText('{#000000}'..buff.Name)
  end

  local buffidEdit = list:CreateOrGetControl('edit','buffidEdit',120,35,60,30)
  tolua.cast(buffidEdit,'ui::CEditControl')
  buffidEdit:SetNumberMode(1)
  buffidEdit:SetUserValue('index',index)
  buffidEdit:SetOffsetYForDraw(-5)
  buffidEdit:SetText(buffid or '')
  buffidEdit:SetLostFocusingScp('MUTEKI2_CHANGE_BUFFID')
  buffidEdit:SetEventScript(ui.ENTERKEY  , 'MUTEKI2_CHANGE_BUFFID')
  buffidEdit:SetEventScriptArgString(ui.ENTERKEY,buffid)

  local colorTonePic = list:CreateOrGetControl('picture','colorTonePic',320,10,55,55)
  tolua.cast(colorTonePic,'ui::CPicture')
  colorTonePic:SetEnableStretch(1)
  colorTonePic:SetImage('hoge')
  colorTonePic:SetColorTone(buffSetting.color or defaultColor)

  local colorToneEdit = list:CreateOrGetControl('edit','colorToneEdit',380,35,100,30)
  tolua.cast(colorToneEdit,'ui::CEditControl')
  colorToneEdit:SetUserValue('index',index)
  colorToneEdit:SetOffsetYForDraw(-5)
  colorToneEdit:SetMaxLen(8)
  colorToneEdit:SetText(buffSetting.color and buffSetting.color or defaultColor)
  colorToneEdit:SetLostFocusingScp('MUTEKI2_CHANGE_COLORTONE')
  colorToneEdit:SetEventScriptArgString(15,buffid)
  colorToneEdit:SetEventScript(ui.ENTERKEY  , 'MUTEKI2_CHANGE_COLORTONE')
  colorToneEdit:SetEventScriptArgString(ui.ENTERKEY,buffid)

  local colorToneTxt = list:CreateOrGetControl('richtext','colorToneTxt',380,10,60,30)
  colorToneTxt:SetText(_translate('colorTone'))

  local isCircle = list:CreateOrGetControl('checkbox','isCircle',10,65,200,35)
  tolua.cast(isCircle,'ui::CCheckBox')
  isCircle:SetCheck(buffSetting.circleIcon and 1 or 0)
  isCircle:SetEventScript(ui.LBUTTONDOWN  , 'MUTEKI2_CHANGE_CIRCLE_MODE')
  isCircle:SetEventScriptArgNumber(ui.LBUTTONDOWN ,buffid)
  isCircle:SetText(_translate('rotateIcons'))

  buffSetting.isNotNotify = buffSetting.isNotNotify or {}
  local isNotNotify = list:CreateOrGetControl('checkbox','isNotNotify',10,90,200,35)
  tolua.cast(isNotNotify,'ui::CCheckBox')
  isNotNotify:SetCheck(buffSetting.isNotNotify[g.user] and 1 or 0)
  isNotNotify:SetEventScript(ui.LBUTTONDOWN  , 'MUTEKI2_CHANGE_NOTIFY')
  isNotNotify:SetEventScriptArgNumber(ui.LBUTTONDOWN ,buffid)
  isNotNotify:SetText(_translate('isNotNotify'))

  local isEffect = list:CreateOrGetControl('checkbox','isEffect',10,115,200,35)
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
    g.gauge[buffid]:SetSkinName('muteki2_gauge_white')
    g.gauge[buffid]:SetColorTone(newColor)
  end
  list:GetChild('colorTonePic'):SetColorTone(newColor)
  MUTEKI2_SAVE_SETTINGS()
end

function MUTEKI2_CHANGE_CIRCLE_MODE(list,control,isChecked,buffid)
  local buff = GetClassByType('Buff',buffid)
  g.settings.buffList[tostring(buffid)].circleIcon = (control:IsChecked() == 1) and true or false
  MUTEKI2_UPDATE_CONTROL(buffid)
  MUTEKI2_SAVE_SETTINGS()
end

function MUTEKI2_ADD_BUFFID(frame,control,argStr,buffid)
  if not g.settings.buffList[tostring(buffid)] then
    local buffObj = GetClassByType('Buff',buffid)
    g.settings.buffList[tostring(buffid)] = {color = defaultColor,isNotNotify={}}
    ui.SysMsg(string.format(_translate('addBuff'),buffObj.Name))
    MUTEKI2_UPDATE_POSITIONS()
    MUTEKI2_UPDATE_CONTROL(buffid)
    MUTEKI2_CREATE_SETTING_FRAME()
  end
end

function MUTEKI2_SET_HIDDEN_BUFF_TIME(frame,control,argStr,argNum)
  local bufftime = tonumber(control:GetText())
  if bufftime > 0  and bufftime ~= g.settings.hiddenBuffTime  then
    g.settings.hiddenBuffTime = bufftime
    ui.SysMsg(string.format(_translate('hideGauge'),bufftime))
    -- MUTEKI2_UPDATE_GAUGE_POS()
    MUTEKI2_UPDATE_POSITIONS()
  end
end

function MUTEKI2_SET_LAYER_LAVEL(frame,control,argStr,argNum)
  local layerLvl = tonumber(control:GetText())
  g.settings.layerLvl = layerLvl
  g.frame:SetLayerLevel(layerLvl)
  MUTEKI2_SAVE_SETTINGS()
end

function MUTEKI2_SET_BUFFICON_LBTNCLICK(frame,eventMsg)
  local slot, capt, class, buffType = acutil.getEventArgs(eventMsg)
  tolua.cast(slot,'ui::CSlot')
  slot:SetEventScript(ui.LBUTTONUP, 'MUTEKI2_ADD_BUFFID');
  slot:SetEventScriptArgNumber(ui.LBUTTONUP, buffType);
  slot:SetEventScriptArgString(ui.LBUTTONUP, class.Name);
end


function MUTEKI2_CHANGE_NOTIFY(list,control,isChecked,buffid)
  g.settings.buffList[tostring(buffid)].isNotNotify[g.user] = (control:IsChecked() == 1) and true or false
  MUTEKI2_UPDATE_CONTROL(buffid)
  MUTEKI2_SAVE_SETTINGS()
end

function MUTEKI2_CHANGE_EFFECT(list,control,isChecked,buffid)
  g.settings.buffList[tostring(buffid)].isEffect = (control:IsChecked() == 1) and true or false
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
  if not buff then
    return
  end
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

function MUTEKI2_CHANGE_MODE_BTN(frame,control,mode,argNum)
  local thisMode = g.settings.mode
  local beforeModeBtn = frame:GetChild(thisMode..'modeBtn')
  beforeModeBtn:SetSkinName('textbutton')
  control:SetSkinName('test_red_button')
  MUTEKI2_CHANGE_MODE(mode)
  local isLock = g.settings.position.lock
  local lockModeBtn = frame:GetChild('lockmodeBtn')
  lockModeBtn:SetSkinName(isLock and 'test_cardtext_btn' or  'textbutton')
  lockModeBtn:SetText(isLock and '{s20}ON{/}' or '{s20}OFF{/}')
end

function MUTEKI2_CHANGE_LOCK_BTN(frame,control,argStr,argNum)
  MUTEKI2_TOGGLE_LOCK()
  local isLock = g.settings.position.lock
  local lockModeBtn = frame:GetChild('lockmodeBtn')
  control:SetSkinName(isLock and 'test_cardtext_btn' or 'textbutton')
  control:SetText(isLock and '{s20}ON{/}' or '{s20}OFF{/}')
end

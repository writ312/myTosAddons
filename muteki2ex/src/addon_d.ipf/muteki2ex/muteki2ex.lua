-- ##issues##
-- possition update script  error
-- check skill remove event
-- no time buff (ex.Safety) 's gauge ...

-- ##Finished##
-- color tone error. change colortone view pic to gauge
-- fix height. 4th bar hidden

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

--設定ファイル保存先
g.settingsFileLoc = string.format("../addons/%s/settings.json", addonNameLower);
g.oldAddonSettingFileLoc = '../addons/muteki2/settings.json'

--ライブラリ読み込み
local acutil = require('acutil');

--デフォルト設定
if not g.loaded then
  g.hooked = false;
  g.settings = {
    --有効/無効
    enable = true,
    mode = "fixed", --"FIXED" or "TRACE"
    --フレーム表示場所
    position = {
      lock = false;
      x = 640,
      y = 480
    },
    buffList = 
    {
   },
   hiddenBuffTime = 300,
   version = 1.0,
   layerLvl = 80
  };
end
g.settings.layerLvl = g.settings.layerLvl or 80

--lua読み込み時のメッセージ
CHAT_SYSTEM(string.format("%s.lua is loaded", addonNameLower));

local function isAfterRebuild()
  if ui.GetFrame('skillability') then 
      return true
  else
      return false
  end
end

function MUTEKI2_SAVE_SETTINGS()
  acutil.saveJSON(g.settingsFileLoc, g.settings);
end

function MUTEKI2_UPDATE_SAVEDATA()
  if g.settings.version < 1.1 then
    for buffid , buffSetting in  pairs(g.settings.buffList) do
      buffSetting.isNotNotify =  buffSetting.isNotNotify or {}
    end
    g.settings.version = 1.1
    MUTEKI2_SAVE_SETTINGS()
  end
end

--マップ読み込み時処理（1度だけ）
function MUTEKI2EX_ON_INIT(addon, frame)
  g.addon = addon;
  g.frame = frame;
  g.melstis = false;
  g.gauge = {};
  g.circle = {};

  frame:ShowWindow(0);
  acutil.slashCommand("/"..addonNameLower, MUTEKI2_PROCESS_COMMAND);
  acutil.slashCommand("/muteki", MUTEKI2_PROCESS_COMMAND);
  acutil.slashCommand("/muteki2", MUTEKI2_PROCESS_COMMAND);
  if not g.loaded then
    local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings);
    if err then
      --設定ファイル読み込み失敗時処理
        local oldSetting , error = acutil.loadJSON(g.oldAddonSettingFileLoc,g.settings)
        if error then
          CHAT_SYSTEM(string.format("[%s] cannot load setting files", addonName));
        else
            g.settings = oldSetting
        end
    else
      --設定ファイル読み込み成功時処理
      g.settings = t;
    end
    g.loaded = true;
  end
  --セーブデータのアップデート
  MUTEKI2_UPDATE_SAVEDATA()

  --設定ファイル保存処理
  MUTEKI2_SAVE_SETTINGS();
  --メッセージ受信登録処理
  addon:RegisterMsg("BUFF_ADD", "MUTEKI2_UPDATE_BUFF");
  addon:RegisterMsg("BUFF_UPDATE", "MUTEKI2_UPDATE_BUFF");
  addon:RegisterMsg("BUFF_REMOVE", "MUTEKI2_UPDATE_BUFF");

  --コンテキストメニュー
  frame:SetEventScript(ui.RBUTTONDOWN, "MUTEKI2_CONTEXT_MENU");
  --ドラッグ
  frame:SetEventScript(ui.LBUTTONUP, "MUTEKI2_END_DRAG");

  --フレーム初期化処理
  MUTEKI2_CHANGE_MODE()
  MUTEKI2_INIT_FRAME(frame);

  --再表示処理
  if g.settings.enable then
    frame:ShowWindow(1);
    frame:Resize(300,200)
  else
    frame:ShowWindow(0);
  end

  --Moveではうまくいかないので、OffSetを使用する…
  frame:Move(0, 0);
  frame:SetOffset(g.settings.position.x, g.settings.position.y);
  
  g.user = GETMYPCNAME()
  addon:RegisterMsg("GAME_START_3SEC","MUTEKI2_INIT")

end

function MUTEKI2_CHANGE_MODE(mode)
  local frame = g.frame;
  if not mode then
    mode = g.settings.mode;
  end
  
  mode = string.lower(mode);
  if mode == "trace" then
    local handle = session.GetMyHandle();
    local actor = world.GetActor(handle)
    FRAME_AUTO_POS_TO_OBJ(frame, handle, - frame:GetWidth() / 2, -100, 3, 1);
    g.settings.position.lock = true
  else
    --Moveではうまくいかないので、OffSetを使用する…
    frame:Move(0, 0);
    frame:SetOffset(g.settings.position.x, g.settings.position.y);
    frame:StopUpdateScript("_FRAME_AUTOPOS");
    -- MUTEKI2_INIT_FRAME(g.frame)
    mode = "fixed";
  end

  local txt = frame:CreateOrGetControl('richtext','disableAutoHide',0,0,1,1)
  if g.settings.position.lock then
    g.frame:SetSkinName("none");
    g.frame:EnableHittestFrame(0);
    txt:SetText(' ')
  else
    g.frame:SetSkinName("shadow_box");
    g.frame:EnableHittestFrame(1);
    g.frame:EnableMove(1)
    txt:SetText('  ')
  end

  g.settings.mode = mode;
  MUTEKI2_SAVE_SETTINGS();
  MUTEKI2_UPDATE_POSITIONS()
end

--コンテキストメニュー表示処理
function MUTEKI2_CONTEXT_MENU(frame, msg, clickedGroupName, argNum)
  local context = ui.CreateContextMenu("MUTEKI2_RBTN", addonName, 0, 0, 150, 100);

  -- if not g.settings.position.lock then
    ui.AddContextMenuItem(context,g.settings.position.lock and "Release Lock" or "Lock Position", "MUTEKI2_TOGGLE_LOCK()");
  -- end
  context:Resize(150, context:GetHeight());
  ui.OpenContextMenu(context);
end
--表示非表示切り替え処理
function MUTEKI2_TOGGLE_FRAME()
  if g.frame:IsVisible() == 0 then
    --非表示->表示
    g.frame:ShowWindow(1);
    g.settings.enable = true;
  else
    --表示->非表示
    g.frame:ShowWindow(0);
    g.settings.enable = false;
  end

  MUTEKI2_SAVE_SETTINGS();
end

--フレーム場所保存処理
function MUTEKI2_END_DRAG()
  g.settings.position.x = g.frame:GetX();
  g.settings.position.y = g.frame:GetY();
  MUTEKI2_SAVE_SETTINGS();
end

function MUTEKI2_INIT_FRAME(frame)
  --フレーム初期化処理
--   frame:Resize(300,200)
    frame:RemoveAllChild()
    frame:CreateOrGetControl('richtext','disableAutoHide',0,0,1,1):SetText('   ')
    g.circle = {}
    g.gauge = {}
  
  -- レイヤーの表示位置を再設定
  frame:SetLayerLevel(g.settings.layerLvl)

  -- ゲージ生成はここ
  for buffid , buffSetting in pairs(g.settings.buffList) do
    local buffObj = GetClassByType('Buff',tonumber(buffid))
    if buffSetting.circleIcon then
        g.circle[buffid] = MUTEKI2_INIT_CIRCLE(frame,buffObj)
    elseif buffObj then
        g.gauge[buffid] = MUTEKI2_INIT_GAUGE(frame,buffObj,buffSetting.color)
    end
  end
end

function MUTEKI2_INIT_CIRCLE(frame, buffObj)
  local image = frame:CreateOrGetControl("picture", "circle_"..buffObj.ClassName,0,0, 40, 40);
  tolua.cast(image, "ui::CPicture");
  image:ShowWindow(0);
  image:SetGravity(ui.CENTER_HORZ, ui.TOP);
  image:SetImage('icon_'..buffObj.Icon)
  image:SetEnableStretch(1);
  image:EnableHitTest(0);
  return image;
end

function MUTEKI2_INIT_GAUGE(frame, buffObj, colorTone)
  --ゲージを生成
  local gauge = frame:CreateOrGetControl("gauge", "gauge_"..buffObj.ClassName,0,0, 262, 20);
  tolua.cast(gauge, "ui::CGauge");
  gauge:SetSkinName('muteki2_gauge_white')
  gauge:SetColorTone(colorTone or 'FFFF0000')
  gauge:ShowWindow(0);
  gauge:SetGravity(ui.CENTER_HORZ, ui.TOP);
  gauge:SetUserValue("PAUSE", 1);
  gauge:EnableHitTest(0);

  --テキスト1 時間
  gauge:AddStat("");
  gauge:SetStatOffset(0, -10, -2);
  if isAfterRebuild() then
    gauge:SetStatAlign(0, ui.RIGHT, ui.CENTER_HORZ);
  else
    gauge:SetStatAlign(0, 'right', 'center');
  end

  --テキスト2 技名
  gauge:AddStat("{@st62}"..buffObj.Name.."{/}");
  if isAfterRebuild() then
    gauge:SetStatAlign(0, ui.CENTER_HORZ, ui.CENTER_HORZ);
  else
    gauge:SetStatAlign(1, 'center', 'center');
  end
  gauge:SetStatOffset(1, 0, -2);

  if not g.settings.position.lock then
    -- gauge:ShowWindow(1);
    -- gauge:SetPoint(60, 60);
  end

  return gauge;
end

function MUTEKI2_SET_POINT(gauge, curPoint, play)
  local maxPoint = gauge:GetMaxPoint();
  gauge:SetPoint(curPoint, maxPoint);

  if play then
    gauge:SetPointWithTime(maxPoint, maxPoint - curPoint, 1);
  else
    gauge:StopTimeProcess();
  end
end

--ゲージを減らす
function MUTEKI2_START_GAUGE_DOWN(gauge, curPoint, maxPoint)

  gauge:ShowWindow(1);

  if not curPoint or not maxPoint then
    curPoint = gauge:GetCurPoint();
    maxPoint = gauge:GetMaxPoint();
  end
  --ミリ秒単位で開始時間を計測
  local elapsedMS = (maxPoint - curPoint) * 1000;
  local startTime = imcTime.GetAppTimeMS() - elapsedMS;
  gauge:SetUserValue("STARTTIME", startTime);
  gauge:SetUserValue("PAUSE", 0);
  gauge:SetTotalTime(maxPoint);
  --   gauge:SetSkinName(gauge:GetUserValue("SKINNAME"));
  MUTEKI2_SET_POINT(gauge, maxPoint - curPoint, false);
  gauge:RunUpdateScript("MUTEKI2_UPDATE_GAUGE_DOWN");
end

--ゲージ更新処理
function MUTEKI2_UPDATE_GAUGE_DOWN(gauge)
  --経過時間
  local elapsedMS = imcTime.GetAppTimeMS() - gauge:GetUserIValue("STARTTIME");
  local pause = gauge:GetUserIValue("PAUSE");
  local maxPoint = gauge:GetMaxPoint();
  local curPoint =  elapsedMS ~= 0 and maxPoint - elapsedMS / 1000 or maxPoint
  gauge:SetPoint(curPoint, maxPoint)

  local sec = math.floor(curPoint);
  local msec = math.floor((curPoint - sec) * 100);
  -- if sec < 0 or sec > hiddenBuffTime then
    if sec < 0  then
        gauge:ShowWindow(0);
      return 0;
    end
  
  local text = "{@st48}00.00{/}"

  if sec >= 0 then
    text = pause ~= 1 and string.format("{@st48}%02d.%02d{/}", sec, msec) or string.format("{@st48}{#00FF00}%02d.%02d{/}{/}", sec, msec);
end

  gauge:SetTextStat(0, text);
  
  if pause == 1 then
    -- gauge:SetSkinName("muteki2_gauge_green");
    return 0;
  end
  if sec > g.settings.hiddenBuffTime then
    gauge:ShowWindow(0)
  else
    if not gauge:IsVisible() then
        MUTEKI2_UPDATE_POSITIONS()
    end
    gauge:ShowWindow(1)
  end

  return 1;  
end

--バフ取得時処理
function MUTEKI2_UPDATE_BUFF(frame, msg, argStr, buffid)
  local buffSetting , buffObj , buff = MUTEKI2_GET_BUFFS(buffid)
  if buffSetting and not buffSetting.isNotNotify[g.user] then
    local control = MUTEKI2_GET_CONTROL(buffid)
    if buffSetting.circleIcon then
      if msg == 'BUFF_REMOVE' then
        MUTEKI2_REMOVE_CIRCLE_BUFF(buff,control)
      elseif msg == 'BUFF_UPDATE' or msg == 'BUFF_ADD' then
        if buffSetting.isEffect then
          MUTEKI2_EXEC_EFFECT()
        end
        MUTEKI2_ADD_CIRCLE_BUFF(buff,control)
      end      
    else
      if msg == 'BUFF_REMOVE' then
          MUTEKI2_REMOVE_GAUGE_BUFF(buff,control)
      elseif msg == 'BUFF_UPDATE' or msg == 'BUFF_ADD' then
        if buffSetting.isEffect then
          MUTEKI2_EXEC_EFFECT()
        end
        MUTEKI2_ADD_GAUGE_BUFF(buff,control)
      end
      -- MUTEKI2_UPDATE_POSITIONS()
    end
    -- MUTEKI2_UPDATE_POSITIONS()
    -- MUTEKI2_UPDATE_CIRCLE_POS()
  end
  MUTEKI2_UPDATE_POSITIONS()
end

function MUTEKI2_ADD_CIRCLE_BUFF(buff, frame)
  local image = frame;
  image:ShowWindow(1);
  image:SetAngleLoop(5);
  -- MUTEKI2_UPDATE_CIRCLE_POS()
  MUTEKI2_UPDATE_POSITIONS()
end

function MUTEKI2_REMOVE_CIRCLE_BUFF(buff, frame)
  local image = frame;
  image:ShowWindow(0);
  MUTEKI2_UPDATE_POSITIONS()
end

function MUTEKI2_UPDATE_POSITIONS()
  local circleList = {}
  local gaugeList = {}
  local noTimeBuffs = {}
  local offsetY = 25
  local circleIconHeight = 50
  local handle = session.GetMyHandle()
  local buffCount = info.GetBuffCount(handle);
  for i = 0, buffCount - 1 do
    local buff = info.GetBuffIndexed(handle, i);    
    local buffSetting , buffObj = MUTEKI2_GET_BUFFS(buff.buffID)
    local circle = g.circle[tostring(buff.buffID)]
    local gauge = g.gauge[tostring(buff.buffID)]

    if circle and not buffSetting.isNotNotify[g.user] then
      table.insert(circleList,circle)
    elseif gauge and not buffSetting.isNotNotify[g.user] then
      if buff.time/1000 <= g.settings.hiddenBuffTime then
        if buffSetting.isNoTimeBuff then
          table.insert(noTimeBuffs,gauge)
        else
          table.insert(gaugeList,{gauge = gauge,time = buff.time})
        end
      elseif gauge then
        gauge:ShowWindow(0)
      end
    end  
  end

  local maxLen = #circleList
  if #circleList > 0 then
    for i , circle in ipairs(circleList) do
      circle:SetOffset(-25*(maxLen-1)+(i-1)*50,0)
    end
  end
    if #gaugeList > 0 then
    table.sort(gaugeList,function(a,b) return (a.time < b.time) end)
    for i , obj in ipairs(gaugeList) do
      obj.gauge:ShowWindow(1)
      obj.gauge:Resize(262,25)
      obj.gauge:SetGravity(ui.CENTER_HORZ, ui.TOP)      
      obj.gauge:SetOffset(0,(i-1)*offsetY + circleIconHeight)
    end
  end

  if #noTimeBuffs > 0 then
    local defaultOffsetY = #gaugeList*offsetY + circleIconHeight
    for i , ctrl in ipairs(noTimeBuffs) do
      ctrl:Resize(131,25)
      ctrl:SetGravity(0,0)
      ctrl:SetOffset(19+(i-1)%2*131,math.floor((i-1)/2)*(offsetY-5)+defaultOffsetY)
      ctrl:SetPoint(60,60)
      ctrl:ShowWindow(1)
    end
  end
  local height = circleIconHeight+(#gaugeList+math.floor(#noTimeBuffs/2))*offsetY + 20
  g.frame:Resize(300,(height < 200) and 200 or height + 20)
end

function MUTEKI2_EXEC_EFFECT()
  local handle = session.GetMyHandle();
  local actor = world.GetActor(handle)
  pcall(effect.PlayActorEffect(actor, "F_sys_TPBOX_great_300", "None", 1.0, 6.0) or nil);
end

function MUTEKI2_ADD_GAUGE_BUFF(buff, frame)
  local gauge = frame;
  local time = math.floor(buff.time / 1000);
  local buffSetting = MUTEKI2_GET_BUFF_SETTING(buff.buffID)
  if time == 0 then
    buffSetting.isNoTimeBuff = true
  else
    buffSetting.isNoTimeBuff = false
    MUTEKI2_START_GAUGE_DOWN(gauge, time, time+1)
  end
  gauge:ShowWindow(1);
  MUTEKI2_UPDATE_POSITIONS()
end

function MUTEKI2_REMOVE_GAUGE_BUFF(buff,frame)
  local gauge = frame;
  gauge:ShowWindow(0);
  gauge:StopUpdateScript("MUTEKI2_UPDATE_GAUGE_DOWN")
  MUTEKI2_UPDATE_POSITIONS()
end

function MUTEKI2_TOGGLE_LOCK()
  local txt = g.frame:CreateOrGetControl('richtext','disableAutoHide',0,0,1,1)
  g.settings.position.lock = not g.settings.position.lock;
  if g.settings.position.lock then
    --ロック
    g.frame:SetSkinName("none");
    g.frame:EnableHittestFrame(0);
    -- g.frame:EnableMove(0)
    txt:SetText(' ')
    for k, gauge in pairs(g.gauge) do
      gauge:ShowWindow(0);
    end
  else
    --ロック解除（移動モード）
    g.frame:SetSkinName("shadow_box");
    g.frame:EnableHittestFrame(1);
    g.frame:EnableMove(1)
    txt:SetText('  ')
    for k, gauge in pairs(g.gauge) do
      -- MUTEKI2_START_GAUGE_DOWN(gauge, 60, 60);
    end
  end

  MUTEKI2_SAVE_SETTINGS();

  if g.settings.position.lock then
    CHAT_SYSTEM(string.format("[%s] save position", addonName));
  end
end


--チャットコマンド処理（acutil使用時）
function MUTEKI2_PROCESS_COMMAND(command)
  command = command or ''
  local cmd = "";

  if #command > 0 then
    cmd = string.lower(table.remove(command, 1));
  else
    local msg = "Muteki2 説明{nl}"
    msg = msg .. "/muteki2 lock{nl}"
    msg = msg .. "位置のロック{nl}"
    msg = msg .. "/muteki2 trace{nl}"
    msg = msg .. "自キャラ追従モード{nl}"
    msg = msg .. "/muteki2 fixed{nl}"
    msg = msg .. "固定表示モード{nl}"
    CHAT_SYSTEM(msg);
    return
  end

  if cmd == "lock" then
    MUTEKI2_CHANGE_MODE("fixed")
    MUTEKI2_TOGGLE_LOCK();
    return;
  elseif cmd == "trace" then
    MUTEKI2_CHANGE_MODE("trace");
    CHAT_SYSTEM(string.format("[%s] trace mode", addonName));
    return;
  elseif cmd == "fixed" then
    MUTEKI2_CHANGE_MODE("fixed");
    CHAT_SYSTEM(string.format("[%s] fixed mode", addonName));
    return;
  end

  CHAT_SYSTEM(string.format("[%s] Invalid Command", addonName));
end

function MUTEKI2_GET_BUFFS(buffid)
  buffid = tonumber(buffid)
  local buffSetting = g.settings.buffList[tostring(buffid)]
  local buffObj = GetClassByType('Buff',buffid)
  local handle = session.GetMyHandle();
  local buff = buffid and info.GetBuff(handle, buffid) or nil    
  return buffSetting , buffObj , buff;
end


function MUTEKI2_GET_BUFF(id)
  local handle = session.GetMyHandle();
  local buff = info.GetBuff(handle, id);
  return buff;
end

function MUTEKI2_GET_BUFF_SETTING(buffid)
    return g.settings.buffList[tostring(buffid)]
end

function MUTEKI2_GET_CONTROL(buffid)
  buffid = tostring(buffid)
  return not  g.settings.buffList[buffid] and nil or  g.circle[buffid] or g.gauge[buffid]  
end
function MUTEKI2_CHANGE_COLORTONE(list,control,buffid,argNum)
  local buffSetting =  g.settings.buffList[buffid]
  local newColor = tostring(control:GetText()) 
  local oldColor = buffSetting.color
  if #newColor ~= 8 or newColor == oldColor then
    return
  end
  buffSetting.color = newColor
  if not buffSetting.circleIcon then
    g.gauge[buffid]:SetSkinName('muteki2_gauge_white')
    g.gauge[buffid]:SetColorTone(newColor)
    -- g.gauge[buffid]:SetDrawStyle(ui.GAUGE_DRAW_CONTINOUS);
  end
  list:GetChild('colorTonePic'):SetColorTone(newColor)
  MUTEKI2_SAVE_SETTINGS()
end

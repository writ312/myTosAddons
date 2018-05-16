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
      ['229'] = {color='EEFFFFFF'},
      ['4506'] = {color='EEFFFFFF'},
      ['4508'] = {color='EEFFFFFF'},
      ['6020'] = {color='EEFFFFFF'},
      ['104'] = {color='EEFFFFFF'},
      ['3022'] = {color='EEFFFFFF'},
      ['67'] = {color='EEFFFFFF'},
      ['94'] = {color='EEFFFFFF',circleIcon = true},
      ['1021'] = {color='EEFFFFFF',circleIcon = true},
      ['126'] = {color='EEFFFFFF'},
      ['146'] = { color = 'EEFFFFFF'},
      ['147'] = { color = 'EEFFFFFF'}
   }   
  };
end

--lua読み込み時のメッセージ
CHAT_SYSTEM(string.format("%s.lua is loaded", addonNameLower));

function MUTEKI2_SAVE_SETTINGS()
  acutil.saveJSON(g.settingsFileLoc, g.settings);
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

  --設定ファイル保存処理
  MUTEKI2_SAVE_SETTINGS();
  --メッセージ受信登録処理
  addon:RegisterMsg("BUFF_ADD", "MUTEKI2_UPDATE_BUFF");
  addon:RegisterMsg("BUFF_UPDATE", "MUTEKI2_UPDATE_BUFF");
  addon:RegisterMsg("BUFF_REMOVE", "MUTEKI2_UPDATE_BUFF");
--   addon:RegisterMsg("MON_ENTER_SCENE", "MUTEKI2_ON_MON_ENTER_SCENE");
  --addon:RegisterMsg("MON_ENTER_SCENE", "MUTEKI_ON_MON_ENTER_SCENE");

  --コンテキストメニュー
  frame:SetEventScript(ui.RBUTTONDOWN, "MUTEKI2_CONTEXT_MENU");
  --ドラッグ
  frame:SetEventScript(ui.LBUTTONUP, "MUTEKI2_END_DRAG");

  --フレーム初期化処理
  MUTEKI2_INIT_FRAME(frame);

  --再表示処理
  if g.settings.enable then
    frame:ShowWindow(1);
  else
    frame:ShowWindow(0);
  end

  --Moveではうまくいかないので、OffSetを使用する…
  frame:Move(0, 0);
  frame:SetOffset(g.settings.position.x, g.settings.position.y);
  
  ReserveScript("MUTEKI2_CHANGE_MODE()", 1.0);
end


function MUTEKI2_CHANGE_MODE(mode)
  local frame = g.frame;
  if not mode then
    mode = g.settings.mode;
  end
  
  mode = string.lower(mode);
  MUTEKI2_UPDATE_GAUGE_POS()

  if mode == "trace" then
    local handle = session.GetMyHandle();
    local actor = world.GetActor(handle)
    FRAME_AUTO_POS_TO_OBJ(frame, handle, - frame:GetWidth() / 2, -100, 3, 1);
  else
    --Moveではうまくいかないので、OffSetを使用する…
    frame:Move(0, 0);
    frame:SetOffset(g.settings.position.x, g.settings.position.y);
    frame:StopUpdateScript("_FRAME_AUTOPOS");
    mode = "fixed";
  end
  
  g.settings.mode = mode;
  MUTEKI2_SAVE_SETTINGS();
end

function MUTEKI2_INIT_FRAME(frame)
  --フレーム初期化処理
  if g.settings.position.lock then
    frame:SetSkinName("none");
    frame:EnableHitTest(0);
  else
    frame:SetSkinName("shadow_box");
    frame:EnableHitTest(1);
  end
  -- ゲージ生成はここ
  for buffid , obj in pairs(g.settings.buffList) do
    local buff = GetClassByType('Buff',tonumber(buffid))
    if obj.circleIcon then
        g.circle[buffid] = MUTEKI2_INIT_CIRCLE(frame,buff)
    else
        g.gauge[buffid] = MUTEKI2_INIT_GAUGE(frame,buff,obj.color)
    end
  end
--   g.gauge.ausirine = MUTEKI2_INIT_GAUGE(frame, "Ausirine", 0, 0, "muteki2_gauge_yellow");
--   g.gauge.potion = MUTEKI2_INIT_GAUGE(frame, "Potion", 0, 18, "muteki2_gauge_blue");
--   g.gauge.retreat = MUTEKI2_INIT_GAUGE(frame, "Retreat", 0, 36, "muteki2_gauge_orange");
  
--   g.circle.sz = MUTEKI2_INIT_CIRCLE(frame, "sz", 10, 54, "icon_cler_SafetyZone");
--   g.circle.st = MUTEKI2_INIT_CIRCLE(frame, "st", 60, 54, "icon_cler_steraTrofh");
end

function MUTEKI2_INIT_CIRCLE(frame, buff)
    local image = frame:CreateOrGetControl("picture", "circle_"..buff.ClassName,0,0, 40, 40);
    tolua.cast(image, "ui::CPicture");
    image:ShowWindow(0);
    image:SetGravity(ui.CENTER_HORZ, ui.TOP);
    image:SetImage('icon_'..buff.Icon);
    image:SetEnableStretch(1);
    image:EnableHitTest(0);
    return image;
end

function MUTEKI2_INIT_GAUGE(frame, buff, colorTone)
  --ゲージを生成
  local gauge = frame:CreateOrGetControl("gauge", "gauge_"..buff.ClassName,0,0, 280, 20);
  tolua.cast(gauge, "ui::CGauge");
  gauge:SetColorTone(colorTone or 'FFFF0000')
--   gauge:SetSkinName(defaultSkinName);
--   gauge:SetUserValue("SKINNAME", defaultSkinName);
  gauge:ShowWindow(0);
  gauge:SetGravity(ui.CENTER_HORZ, ui.TOP);
  gauge:SetUserValue("PAUSE", 1);
  gauge:EnableHitTest(0);

  --テキスト1 時間
  gauge:AddStat("");
  gauge:SetStatOffset(0, -10, -2);
  gauge:SetStatAlign(0, 'right', 'center');

  --テキスト2 技名
  gauge:AddStat("{@st62}"..buff.Name.."{/}");
  gauge:SetStatAlign(1, 'center', 'center');
  gauge:SetStatOffset(1, 0, -2);

  if not g.settings.position.lock then
    -- gauge:ShowWindow(1);
    gauge:SetPoint(60, 60);
  end

  return gauge;
end


--コンテキストメニュー表示処理
function MUTEKI2_CONTEXT_MENU(frame, msg, clickedGroupName, argNum)
  local context = ui.CreateContextMenu("MUTEKI2_RBTN", addonName, 0, 0, 150, 100);

  if not g.settings.position.lock then
    ui.AddContextMenuItem(context, "Lock Position", "MUTEKI2_TOGGLE_LOCK()");
  end
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

  if sec < 0 then
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

  return 1;  
end

function MUTEKI2_TEST()
  local handle = session.GetMyHandle();
  local actor = world.GetActor(handle)
  FRAME_AUTO_POS_TO_OBJ(g.frame, handle, - g.frame:GetWidth() / 2, -100, 3, 1);
end

--バフ取得時処理
function MUTEKI2_UPDATE_BUFF(frame, msg, argStr, argNum)
  local gaugeBuff = MUTEKI2_GET_GAUGE_BUFF(argNum);
  if gaugeBuff then
    local buff = MUTEKI2_GET_BUFF(argNum);
    local control = gaugeBuff.circleIcon and g.circle[tostring(argNum)] or g.gauge[tostring(argNum)]
    if gaugeBuff.circleIcon then
      if msg == 'BUFF_REMOVE' then
        MUTEKI2_REMOVE_CIRCLE_BUFF(buff,control)
      elseif msg == 'BUFF_UPDATE' or msg == 'BUFF_ADD' then
        MUTEKI2_ADD_CIRCLE_BUFF(buff,control)
      end
      MUTEKI2_UPDATE_CIRCLE_POS()
      
    else
      if msg == 'BUFF_REMOVE' then
          MUTEKI2_REMOVE_GAUGE_BUFF(buff,control)
      elseif msg == 'BUFF_UPDATE' or msg == 'BUFF_ADD' then
        MUTEKI2_ADD_GAUGE_BUFF(buff,control)
      end
      MUTEKI2_UPDATE_GAUGE_POS()
    end
  end
end

function MUTEKI2_GET_BUFF(id)
  local handle = session.GetMyHandle();
  local buff = info.GetBuff(handle, id);
  return buff;
end

function MUTEKI2_GET_GAUGE_BUFF(buffid)
    return g.settings.buffList[tostring(buffid)]
end


function MUTEKI2_ADD_CIRCLE_BUFF(buff, frame)
  local image = frame;
  image:ShowWindow(1);
  image:SetAngleLoop(10);
end

function MUTEKI2_REMOVE_CIRCLE_BUFF(buff, frame)
  local image = frame;
  image:ShowWindow(0);
end

function MUTEKI2_UPDATE_CIRCLE_POS()
  local circleList = {}
  local buffCount = info.GetBuffCount(handle);
  for i = 0, buffCount - 1 do
    local buff = info.GetBuffIndexed(handle, i);
    local circle = g.circle[tostring(buff.buffID)]
    if circle then
      table.insert(circleList,circle)
    end       
  end
  local maxLen = #circleList
  for i , circle in ipairs(circleList) do
    circle:SetOffset((i%2 and -1 or 1)*50*(maxLen/2),10)
  end
end
-- function MUTEKI2_ADD_POTION_BUFF(buff, frame, label)
--   MUTEKI2_ADD_GAUGE_BUFF(buff, frame, label);
--   local handle = session.GetMyHandle();
--   local actor = world.GetActor(handle)
--   pcall(effect.PlayActorEffect(actor, "F_sys_TPBOX_great_300", "None", 1.0, 6.0));
-- end


-- function MUTEKI2_ADD_AUSIRINE_BUFF(buff, frame, label)
--   imcSound.PlaySoundEvent("premium_enchantchip");
--   MUTEKI2_ADD_GAUGE_BUFF(buff, frame, label);
-- end

function MUTEKI2_ADD_GAUGE_BUFF(buff, frame)
  local gauge = frame;
  gauge:ShowWindow(1);
  local time = math.floor(buff.time / 1000);
  MUTEKI2_START_GAUGE_DOWN(gauge, time, time);

  -- if g.melstis then
  --   gauge:SetTextStat(1, "{@st48}{#00FF00}"..buff.Name.."{/}{/}")
  --   gauge:SetUserValue("PAUSE", 1);
  -- else
    gauge:AddStat("{@st62}"..buff.Name.."{/}");
    gauge:SetStatAlign(1, 'center', 'center');
    gauge:SetStatOffset(1, 0, -2);
  
    -- gauge:SetTextStat(1, "{@st48}"..buff.Name.."{/}")
  -- end
end

function MUTEKI2_REMOVE_GAUGE_BUFF(buff,frame)
  local gauge = frame;
  gauge:ShowWindow(0);
end

function MUTEKI2_UPDATE_GAUGE_POS()
  local offsetY = 18
  local circleIconHeight = 50
  local gaugeList = {}
  local handle = session.GetMyHandle()
  local buffCount = info.GetBuffCount(handle);
  for i = 0, buffCount - 1 do
    local buff = info.GetBuffIndexed(handle, i);
    local gauge = g.gauge[tostring(buff.buffID)]
    if gauge then
      local curPoint = gauge:GetCurPoint()
      table.insert(gaugeList,{gauge = gauge,time = curPoint})
    end       
  end
  table.sort(gaugeList,function(a,b) return (a.time < b.time) end)
  for i , obj in ipairs(gaugeList) do
    print(i)
    obj.gauge:SetOffset(0,(i-1)*offsetY + circleIconHeight)
  end
end

-- function MUTEKI2_ADD_MELSTIS(buff)
--   g.melstis = true;

--   for k, gauge in pairs(g.gauge) do
--     if gauge:IsVisible() then
--       gauge:SetUserValue("PAUSE", 1);
--     end
--   end
-- end

-- function MUTEKI2_REMOVE_MELSTIS(buff)
--   g.melstis = false;
--   for k, gauge in pairs(g.gauge) do
--     if gauge:IsVisible() then
--       MUTEKI2_START_GAUGE_DOWN(gauge)
--     end
--   end
-- end

function MUTEKI2_TOGGLE_LOCK()

  g.settings.position.lock = not g.settings.position.lock;

  if g.settings.position.lock then
    --ロック
    g.frame:SetSkinName("none");
    g.frame:EnableHitTest(0);
    for k, gauge in pairs(g.gauge) do
      gauge:ShowWindow(0);
    end
  else
    --ロック解除（移動モード）
    g.frame:SetSkinName("shadow_box");
    g.frame:EnableHitTest(1);
    for k, gauge in pairs(g.gauge) do
      MUTEKI2_START_GAUGE_DOWN(gauge, 60, 60);
    end
  end

  MUTEKI2_SAVE_SETTINGS();

  if g.settings.position.lock then
    CHAT_SYSTEM(string.format("[%s] save position", addonName));
  end

end

--チャットコマンド処理（acutil使用時）
function MUTEKI2_PROCESS_COMMAND(command)
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

function MUTEKI2_ON_MON_ENTER_SCENE(frame, msg, str, handle)
  if not g.settings.enable then
    return;
  end

  local actor = world.GetActor(handle);
  if actor:GetObjType() == GT_MONSTER then
    local monCls = GetClassByType("Monster", actor:GetType());

    if monCls.ClassName == "pcskill_wood_ausrine2" or monCls.ClassName == "pcskill_wood_ausrine" then

      local popup= ui.CreateNewFrame("hair_gacha_popup", "Ausirine_"..handle, 0);
      popup:ShowWindow(1);
      popup:EnableHitTest(0);
      local bonusimg = GET_CHILD_RECURSIVELY(popup, "bonusimg");
      local itembgimg = GET_CHILD_RECURSIVELY(popup, "itembgimg");
      bonusimg:ShowWindow(0);
      itembgimg:ShowWindow(0);

      local itemimg = GET_CHILD_RECURSIVELY(popup, "itemimg");
      itemimg:SetImage("icon_cler_craveAusirine");
      itemimg:SetColorTone("EEFFFFFF");

      FRAME_AUTO_POS_TO_OBJ(popup, handle, - popup:GetWidth() / 2, -50, 3, 1);
    end
  end

end
_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['POISONPOTAUTOCHARGE'] = _G['ADDONS']['POISONPOTAUTOCHARGE'] or {};
local g = _G['ADDONS']['POISONPOTAUTOCHARGE'] 
local acutil = require('acutil');
-- CHAT_SYSTEM("Load Poisonpot Auto Charge.open frame /ppac ")

g.PoisonAmountList ,e = acutil.loadJSON('../addons/poisonpotautocharge/PoisonAmountList.json',nil)
  
if(e) then
    g.PoisonAmountList = {'misc_poisonpot'}
    acutil.saveJSON('../addons/poisonpotautocharge/PoisonAmountList.json',g.PoisonAmountList)
end    


local function createPoisonSlotSet(frame)
	
	local slotSet = GET_CHILD_RECURSIVELY(frame,"slotlist","ui::CSlotSet")
	slotSet:ClearIconAll();

	local invItemList = session.GetInvItemList();

	local i = invItemList:Head();
	local slotindex = 0
	while 1 do
		
		if i == invItemList:InvalidIndex() then
			break;
		end

		local invItem = invItemList:Element(i);
		local obj = GetIES(invItem:GetObject());
		if IS_USEABLEITEM_IN_POISONPOT(obj) == 1 then
      local poisonObj = GetClass("item_poisonpot", obj.ClassName)
			local slot = slotSet:GetSlotByIndex(slotindex)
			
			while slot == nil do 
				slotSet:ExpandRow()
				slot = slotSet:GetSlotByIndex(slotindex)
			end

			slot:SetMaxSelectCount(invItem.count);
			slot:CreateOrGetControl('richtext','txt'..slotindex,2,2,10,10):SetText("{s20}{#FFFF00}"..poisonObj.PoisonAmount)
			local icon = CreateIcon(slot);
			
			icon:Set(obj.Icon, 'Item', invItem.type, i, invItem:GetIESID(), invItem.count);
			local class 			= GetClassByType('Item', invItem.type);
			SET_SLOT_ITEM_TEXT_USE_INVCOUNT(slot, invItem, obj, invItem.count);
			ICON_SET_INVENTORY_TOOLTIP(icon, invItem, "poisonpot", class);
			icon:SetUserValue('CLASSNAME',class.ClassName)
			slotindex = slotindex + 1

		end

		i = invItemList:Next(i);
	end

  for i = slotindex,slotindex+4 do
    local ctrl = frame:GetChildRecursively('txt'..i)
    if ctrl then ctrl:SetText("") end
  end

  -- update myFrame`s gauge
  local myEtc = GetMyEtcObject();
  local poisonAmount = myEtc['Wugushi_PoisonAmount'];
  local poisonMaxAmount = myEtc['Wugushi_PoisonMaxAmount']
  local emptyPoisonAmount = poisonMaxAmount - poisonAmount
  tolua.cast(frame:GetChild('poisonAmountGauge'),'ui::CGauge'):SetPoint(poisonMaxAmount - emptyPoisonAmount, poisonMaxAmount);

end

function POISONPOTAUTOCHARGE_ON_INIT(addon, frame)
  acutil.slashCommand('/ppac', POISONPOT_AUTO_CHARGE)
  acutil.setupEvent(addon, 'POISONPOT_FRAME_OPEN', 'POISONPOTAUTOCHARGE_OPEN')
  acutil.setupEvent(addon, 'POISONPOT_FRAME_CLOSE', 'POISONPOTAUTOCHARGE_CLOSE')
  
  g.frame = frame
  POISONPOTAUTOCHARGE_INIT()
end

function POISONPOTAUTOCHARGE_INIT()
  local frame = g.frame;
  frame:SetPos(480,100)
  local primaryGbox = frame:GetChild('primaryGbox')
  local slotset = primaryGbox:GetChild('poisonslotset')
  tolua.cast(slotset, "ui::CSlotSet")

  for i = 1, 5 do
      local slot = slotset:GetSlotByIndex(i - 1)
  frame:CreateOrGetControl('richtext','text'..i,60*i - 40,100,20,20):SetText('{s15}{#000000}'..i)
  if g.PoisonAmountList[i] then
    local invitem = session.GetInvItemByName(g.PoisonAmountList[i])    
    local poisonobj = GetClass("item_poisonpot", g.PoisonAmountList[i])
    if invitem and poisonobj then 
      local itemobj = GetIES(invitem:GetObject())
      CreateIcon(slot):SetImage(itemobj.Icon)
    end
  end
  end
  createPoisonSlotSet(frame)
  POISONPOT_AUTO_CHARGE()
  POISONPOTAUTOCHARGE_AUTO_UPDATER()
end



function PPAC_DROP_SLOT(frame, control, argStr, argNum)
	local liftIcon 					= ui.GetLiftIcon();
	local iconParentFrame 			= liftIcon:GetTopParentFrame();
	local slot 						= tolua.cast(control, 'ui::CSlot');
	local objName = liftIcon:GetUserValue('CLASSNAME')

	local poisonobj = GetClass("item_poisonpot", objName)
    if not poisonobj then return end 
	local invitem = session.GetInvItemByName(objName)    
	local itemobj = GetIES(invitem:GetObject())
    local index = slot:GetSlotIndex() 
    g.PoisonAmountList[index+ 1] = itemobj.ClassName
    local icon = CreateIcon(slot)
    icon:SetImage(itemobj.Icon)
    acutil.saveJSON('../addons/poisonpotautocharge/PoisonAmountList.json',g.PoisonAmountList)
end

function PPAC_CLEAR_SLOT(frame, control, argStr, argNum)
    local slot  = tolua.cast(control, 'ui::CSlot');
	local index = slot:GetSlotIndex() 
    g.PoisonAmountList[index + 1] = nil
	acutil.saveJSON('../addons/poisonpotautocharge/PoisonAmountList.json',g.PoisonAmountList)
    slot:ClearIcon()
    CreateIcon(slot)
end


function POISONPOTAUTOCHARGE_OPEN()
    g.frame:ShowWindow(1)
end
function POISONPOTAUTOCHARGE_CLOSE()
    g.frame:ShowWindow(0)
end

function POISONPOT_AUTO_CHARGE()
   local frame = ui.GetFrame("sysmenu");
	local poisonpot = GET_CHILD(frame, "poisonpot", "ui::CButton");
	if not poisonpot then return end
    
  local myEtc = GetMyEtcObject();
  local poisonAmount = myEtc['Wugushi_PoisonAmount'];
  local poisonMaxAmount = myEtc['Wugushi_PoisonMaxAmount']
  local emptyPoisonAmount = poisonMaxAmount - poisonAmount
  session.ResetItemList()
  for i = 1, 5 do
    if g.PoisonAmountList[i] then
      local invitem = session.GetInvItemByName(g.PoisonAmountList[i])    
      local poisonobj = GetClass("item_poisonpot", g.PoisonAmountList[i])
      if  invitem and  poisonobj then      
        local cnt = math.floor( emptyPoisonAmount / poisonobj.PoisonAmount);
        if cnt < invitem.count then
          session.AddItemID(invitem:GetIESID(), cnt);    
          emptyPoisonAmount = emptyPoisonAmount - (poisonobj.PoisonAmount * cnt)
        else
          session.AddItemID(invitem:GetIESID(), invitem.count)
          emptyPoisonAmount = emptyPoisonAmount - (poisonobj.PoisonAmount * invitem.count)
        end
      end
    end
  end
  
  EXECUTE_POISONPOT_COMMIT()

  createPoisonSlotSet(g.frame)
end

function POISONPOTAUTOCHARGE_AUTO_UPDATER()
  POISONPOT_AUTO_CHARGE()
  ReserveScript("POISONPOTAUTOCHARGE_AUTO_UPDATER()",30)
end
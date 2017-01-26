function JOYSTICKEXTENDER_ON_INIT(addon,frame)
	local acutil = require('acutil')
	acutil.setupHook(JOYSTICK_QUICKSLOT_EXECUTE_HOOK, "JOYSTICK_QUICKSLOT_EXECUTE");
	acutil.setupHook(UPDATE_JOYSTICK_INPUT_HOOK, "UPDATE_JOYSTICK_INPUT");
	acutil.setupHook(JOYSTICK_QUICKSLOT_SWAP_HOOK, "JOYSTICK_QUICKSLOT_SWAP");
	acutil.setupHook(QUICKSLOT_INIT_HOOK, "QUICKSLOT_INIT");
	addon:RegisterMsg('GAME_START_3SEC','JOYSTICKEXTENDER_INIT')    
end

function JOYSTICK_QUICKSLOT_EXECUTE_HOOK(slotIndex)

	local quickFrame = ui.GetFrame('joystickquickslot')
	local Set1 = GET_CHILD_RECURSIVELY(quickFrame,'Set1','ui::CGroupBox');
	local Set2 = GET_CHILD_RECURSIVELY(quickFrame,'Set2','ui::CGroupBox');

	local input_L1  = joystick.IsKeyPressed("JOY_BTN_5")
	local input_R1  = joystick.IsKeyPressed("JOY_BTN_6")

	local joystickRestFrame = ui.GetFrame('joystickrestquickslot')
	if joystickRestFrame:IsVisible() == 1 then
		REST_JOYSTICK_SLOT_USE(joystickRestFrame, slotIndex);
		return;
	end

	if Set2:IsGrayStyle() == 1 then
		slotIndex = slotIndex + 20
	end
	
	if input_L1 == 1 and input_R1 == 1 then
		if Set2:IsGrayStyle() == 0 then
			if	slotIndex == 2  or slotIndex == 14 then
				slotIndex = 10
			elseif	slotIndex == 0  or slotIndex == 12 then
				slotIndex = 8
			elseif	slotIndex == 1  or slotIndex == 13 then
				slotIndex = 9
			elseif	slotIndex == 3  or slotIndex == 15 then
				slotIndex = 11
			end
		else
			if	slotIndex == 22  or slotIndex == 34 then
				slotIndex = 30
			elseif	slotIndex == 20  or slotIndex == 32 then
				slotIndex = 28
			elseif	slotIndex == 21  or slotIndex == 33 then
				slotIndex = 29
			elseif	slotIndex == 23  or slotIndex == 35 then
				slotIndex = 31
			end
		end
	else

	end
	 
	local quickslotFrame = ui.GetFrame('joystickquickslot');
	local slot = quickslotFrame:GetChildRecursively("slot"..slotIndex+1);
	QUICKSLOTNEXPBAR_SLOT_USE(quickSlotFrame, slot, 'None', 0);	

end
function UPDATE_JOYSTICK_INPUT_HOOK(frame)
	if IsJoyStickMode() == 0 then
		return;
	end
	
	--print(joystick.IsKeyPressed("JOY_TARGET_CHANGE"))
	local input_L1 = joystick.IsKeyPressed("JOY_BTN_5")
	local input_L2 = joystick.IsKeyPressed("JOY_BTN_7")
	local input_R1 = joystick.IsKeyPressed("JOY_BTN_6")
	local input_R2 = joystick.IsKeyPressed("JOY_BTN_8")

	local set1 = frame:GetChildRecursively("Set1");
	local set2 = frame:GetChildRecursively("Set2");
	local set1_Button = frame:GetChildRecursively("L2R2_Set1");
	local set2_Button = frame:GetChildRecursively("L2R2_Set2");
	
	--print(joystick.IsKeyPressed("JOY_L1L2"))
	
	if joystick.IsKeyPressed("JOY_UP") == 1 and joystick.IsKeyPressed("JOY_L1L2") == 1  then
		ON_RIDING_VEHICLE(1)
	end

	if joystick.IsKeyPressed("JOY_DOWN") == 1 and joystick.IsKeyPressed("JOY_L1L2") == 1  then
		ON_RIDING_VEHICLE(0)
	end

	if joystick.IsKeyPressed("JOY_LEFT") == 1 and joystick.IsKeyPressed("JOY_L1L2") == 1  then
		COMPANION_INTERACTION(2)
	end

	if joystick.IsKeyPressed("JOY_RIGHT") == 1 and joystick.IsKeyPressed("JOY_L1L2") == 1  then
		COMPANION_INTERACTION(1)
	end
	
	local setIndex = 0;

	if set2:IsGrayStyle() == 0 then
		setIndex = 1;
		set1_Button:SetSkinName(setButton_onSkin);
		set2_Button:SetSkinName(setButton_offSkin);
	else
		setIndex = 2;
		set1_Button:SetSkinName(setButton_offSkin);
		set2_Button:SetSkinName(setButton_onSkin);
	end
	
	if input_L1 == 1 and input_R1 == 0 then
		local gbox = frame:GetChildRecursively("L1_slot_Set"..setIndex);
		if joystick.IsKeyPressed("JOY_L1L2") == 0 then
			gbox:SetSkinName(padslot_onskin);
		end
	elseif input_L1 == 0 or input_L1 == 1 and input_R1 == 1 then
		local gbox = frame:GetChildRecursively("L1_slot_Set"..setIndex);
		gbox:SetSkinName(padslot_offskin);
	end

	if input_R1 == 1 and input_L1 == 0 then
		local gbox = frame:GetChildRecursively("R1_slot_Set"..setIndex);
		if joystick.IsKeyPressed("JOY_R1R2") == 0 then
			gbox:SetSkinName(padslot_onskin);
		end
	elseif input_R1 == 0 or input_L1 == 1 and input_R1 == 1 then
		local gbox = frame:GetChildRecursively("R1_slot_Set"..setIndex);
		gbox:SetSkinName(padslot_offskin);
	end

	if input_L2 == 1 and input_R2 == 0 then
		local gbox = frame:GetChildRecursively("L2_slot_Set"..setIndex);
		if joystick.IsKeyPressed("JOY_L1L2") == 0 then
			if SYSMENU_JOYSTICK_IS_OPENED() == 1 then
				SYSMENU_JOYSTICK_MOVE_LEFT();
			end
			gbox:SetSkinName(padslot_onskin);
		end
	elseif input_L2 == 0 then
		local gbox = frame:GetChildRecursively("L2_slot_Set"..setIndex);
		gbox:SetSkinName(padslot_offskin);
	end

	if input_R2 == 1 and input_L2 == 0 then
		local gbox = frame:GetChildRecursively("R2_slot_Set"..setIndex);
		if joystick.IsKeyPressed("JOY_R1R2") == 0 then
			if SYSMENU_JOYSTICK_IS_OPENED() == 1 then
				SYSMENU_JOYSTICK_MOVE_RIGHT();
			end
			gbox:SetSkinName(padslot_onskin);
		end
	elseif input_R2 == 0 then
		local gbox = frame:GetChildRecursively("R2_slot_Set"..setIndex);
		gbox:SetSkinName(padslot_offskin);
	end

	if input_R1 == 1 and input_L1 == 1 then
		local gbox = frame:GetChildRecursively("L1R1_slot_Set"..setIndex);
		gbox:SetSkinName(padslot_onskin);
	elseif input_R2 == 0 then
		local gbox = frame:GetChildRecursively("L1R1_slot_Set"..setIndex);
		gbox:SetSkinName(padslot_offskin);
	end

end

function JOYSTICK_QUICKSLOT_SWAP_HOOK(test)
	local quickFrame = ui.GetFrame('joystickquickslot')
	local Set1 = GET_CHILD_RECURSIVELY(quickFrame,'Set1','ui::CGroupBox');
	local Set2 = GET_CHILD_RECURSIVELY(quickFrame,'Set2','ui::CGroupBox');
	local setIndex
	if Set2:IsGrayStyle() == 0 then
		Set1:SetGrayStyle(0);
		Set2:SetGrayStyle(1);
		setIndex = 1
	else
		Set1:SetGrayStyle(1);
		Set2:SetGrayStyle(0);
		setIndex = 2
	end
	quickFrame:GetChildRecursively("L1_slot_Set"..setIndex):SetSkinName(padslot_offskin)
    quickFrame:GetChildRecursively("R1_slot_Set"..setIndex):SetSkinName(padslot_offskin)
    quickFrame:GetChildRecursively("L2_slot_Set"..setIndex):SetSkinName(padslot_offskin)
    quickFrame:GetChildRecursively("R2_slot_Set"..setIndex):SetSkinName(padslot_offskin)
    quickFrame:GetChildRecursively("L1R1_slot_Set"..setIndex):SetSkinName(padslot_offskin)

end

function QUICKSLOT_INIT_HOOK(frame, msg, argStr, argNum)

	qframe = ui.GetFrame('joystickquickslot')
	qframe:Resize(1920,270)
	qframe:SetOffset(0,810)
	qframe:GetChild("Set2"):SetOffset(0,120)
	qframe:GetChild("Set1"):ShowWindow(1)
	qframe:GetChild("Set2"):ShowWindow(1)

	 qframe:GetChild("Set1"):SetGrayStyle(1);

	local set1_Button = qframe:GetChildRecursively("L2R2_Set1");
	local set2_Button = qframe:GetChildRecursively("L2R2_Set2");

    set1_Button:SetSkinName(setButton_onSkin);
    set2_Button:SetSkinName(setButton_offSkin);
	UPDATE_JOYSTICK_INPUT_HOOK(qframe)
	JOYSTICK_QUICKSLOT_UPDATE_ALL_SLOT()
end

function JOYSTICKEXTENDER_INIT()
	QUICKSLOT_INIT_HOOK()
	JOYSTICK_QUICKSLOT_UPDATE_ALL_SLOT()
end
CHAT_SYSTEM('load Joystick Extend')

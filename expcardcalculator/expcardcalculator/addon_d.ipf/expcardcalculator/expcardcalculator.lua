--dofile("../data/addon_d/expcardcalculator/expcardcalculator.lua");

function EXPCARDCALCULATOR_ON_INIT(addon, frame)
	local acutil = require("acutil");

	acutil.slashCommand("/cardcalc", EXPCARDCALCULATOR_TOGGLE_FRAME);
	acutil.slashCommand("/expcardcalculator", EXPCARDCALCULATOR_TOGGLE_FRAME);

	addon:RegisterMsg("JOB_EXP_ADD", "EXPCARDCALCULATOR_ON_JOB_EXP_UPDATE");
	addon:RegisterMsg("JOB_EXP_UPDATE", "EXPCARDCALCULATOR_ON_JOB_EXP_UPDATE");

	-- acutil.setupHook(SYSMENU_CHECK_HIDE_VAR_ICONS_HOOKED, "SYSMENU_CHECK_HIDE_VAR_ICONS");
    acutil.addSysIcon("expcardcalculator", "addonmenu_expcard", "Experience Card Calculator", "EXPCARDCALCULATOR_TOGGLE_FRAME")    

	local sysmenuFrame = ui.GetFrame("sysmenu");
	-- SYSMENU_CHECK_HIDE_VAR_ICONS(sysmenuFrame);
end

function EXPCARDCALCULATOR_TOGGLE_FRAME()
	ui.ToggleFrame("expcardcalculator");
end

function EXPCARDCALCULATOR_ON_JOB_EXP_UPDATE(frame, msg, str, exp, tableinfo)
	_G["EXPCARDCALCULATOR"] = _G["EXPCARDCALCULATOR"] or {};
	_G["EXPCARDCALCULATOR"].totalClassExperience = exp;
	_G["EXPCARDCALCULATOR"].currentClassExperience = exp - tableinfo.startExp;
	_G["EXPCARDCALCULATOR"].requiredClassExperience = tableinfo.endExp - tableinfo.startExp;
	_G["EXPCARDCALCULATOR"].classLevel = tableinfo.level;
	_G["EXPCARDCALCULATOR"].startExperience = tableinfo.startExp;
end

function string.starts(String,Start)
   return string.sub(String, 1, string.len(Start)) == Start;
end

local function createExperienceRow(index, itemName, numberOfItems, totalExperience, yPosition)
	local expCardCalculatorFrame = ui.GetFrame("expcardcalculator");

	if expCardCalculatorFrame ~= nil then
		local gbox = expCardCalculatorFrame:GetChild("experienceCardGroupBox");

		if gbox ~= nil then
			local cardList = gbox:GetChild("internalExperienceCardGroupBox");

			if cardList ~= nil then
				tolua.cast(cardList, "ui::CGroupBox");

				local cardItem = cardList:CreateOrGetControlSet("status_stat", "expCard_" .. index, -5, yPosition);
				tolua.cast(cardItem, "ui::CControlSet");

				local title = GET_CHILD(cardItem, "title", "ui::CRichText");
				--may add number of cards back later
				--title:SetText(itemName .. " (" .. numberOfItems .. ")");
				title:SetText(itemName);

				local stat = GET_CHILD(cardItem, "stat", "ui::CRichText");
				stat:SetText(GetCommaedText(totalExperience));
				title:SetUseOrifaceRect(true);
				stat:SetUseOrifaceRect(true);

				cardItem:Resize(cardItem:GetWidth(), stat:GetHeight());

				GBOX_AUTO_ALIGN(cardList, 10, 0, 0, true, false);
				expCardCalculatorFrame:Invalidate();

				yPosition = yPosition + cardItem:GetHeight();

				expCardCalculatorFrame:Invalidate();
			end
		end
	end

	return yPosition;
end

local function clearExperienceRows()
	local expCardCalculatorFrame = ui.GetFrame("expcardcalculator");

	if expCardCalculatorFrame ~= nil then
		local gbox = expCardCalculatorFrame:GetChild("experienceCardGroupBox");

		if gbox ~= nil then
			local cardList = gbox:GetChild("internalExperienceCardGroupBox");

			if cardList ~= nil then
				tolua.cast(cardList, "ui::CGroupBox");
				cardList:DeleteAllControl();
			end
		end
	end
end

local function createExperienceRows(experienceCardData)
	clearExperienceRows();

	local index = 0;
	local yPosition = 10;

	for k,v in pairs(experienceCardData["base"]["cards"]) do
		yPosition = createExperienceRow(index, k .. " Base", 1, v, yPosition);

		index = index + 1;
	end

	for k,v in pairs(experienceCardData["class"]["cards"]) do
		yPosition = createExperienceRow(index, k .. " Class", 1, v, yPosition);

		index = index + 1;
	end
end

function EXP_CARD_CALCULATOR_OPEN()
	local experienceCardData = getTotalExperienceFromCards();
	local baseExperienceFromCards = experienceCardData["base"].totalBaseExperience;
	local classExperienceFromCards = experienceCardData["class"].totalClassExperience;

	createExperienceRows(experienceCardData);

	local calculatedClassData = calculateClassRankAndLevel(classExperienceFromCards);
	local expCardCalculatorFrame = ui.GetFrame("expcardcalculator");
	local totalBaseExperience = 0;
	local finalBaseLevel = 0;
	local finalBaseLevelPercent = 0;
	local pc = GetMyPCObject();

	if pc ~= nil then
		local currentLevel = pc.Lv-1;
		local currentBaseExperienceClass = GetClassByType("Xp", currentLevel);
		local currentTotalBaseExperience = session.GetEXP() + currentBaseExperienceClass.TotalXp;
		local finalBaseExperience = currentTotalBaseExperience + totalBaseExperience + baseExperienceFromCards;

		local currentLevelClass = GetClassByType("Xp", currentLevel);
		while finalBaseExperience > currentLevelClass.TotalXp do
			currentLevel = currentLevel + 1;
			currentLevelClass = GetClassByType("Xp", currentLevel);
		end

		finalBaseLevel = currentLevel;

		local previousLevelClass = GetClassByType("Xp", currentLevel-1);
		local requiredBaseExperience = currentLevelClass.TotalXp - previousLevelClass.TotalXp;
		local baseExperienceIntoLevel = finalBaseExperience - previousLevelClass.TotalXp;

		--base level text
		local baseLevelText = expCardCalculatorFrame:CreateOrGetControl("richtext", "baseCardLevel", 30, 70, 200, 50);
		if baseLevelText ~= nil then
			tolua.cast(baseLevelText, "ui::CRichText");
			baseLevelText:SetText("{@st43}Base Card Level: " .. finalBaseLevel .. "{/}");
			baseLevelText:ShowWindow(1);
		end

		local baseExperiencePercent = (baseExperienceIntoLevel / requiredBaseExperience) * 100;

		local baseExperienceGauge = GET_CHILD(expCardCalculatorFrame, "baseExperienceGauge", "ui::CGauge");
		baseExperienceGauge:SetTextTooltip("{@st42b}" .. GetCommaedText(baseExperienceIntoLevel) .. " / " .. GetCommaedText(requiredBaseExperience) .. " (" .. baseExperiencePercent .. "%){/}");
		baseExperienceGauge:SetPoint(baseExperienceIntoLevel, requiredBaseExperience);
		baseExperienceGauge:Resize(expCardCalculatorFrame:GetWidth() - 50, baseExperienceGauge:GetHeight());
		baseExperienceGauge:ShowWindow(1);

		--class level text
		local classLevelText = expCardCalculatorFrame:CreateOrGetControl("richtext", "classCardLevel", 30, 150, 200, 50);
		if classLevelText ~= nil then
			tolua.cast(classLevelText, "ui::CRichText");
			classLevelText:SetText("{@st43}Class Card Level: " .. calculatedClassData.rank .. "-" .. calculatedClassData.level .. "{/}");
			classLevelText:ShowWindow(1);
		end

		local classExperiencePercent = calculatedClassData.percent;--(102 / 1000) * 100;

		local classExperienceGauge = GET_CHILD(expCardCalculatorFrame, "classExperienceGauge", "ui::CGauge");
		classExperienceGauge:SetTextTooltip("{@st42b}" .. GetCommaedText(calculatedClassData.currentExperience) .. " / " .. GetCommaedText(calculatedClassData.requiredExperience) .. " (" .. classExperiencePercent .. "%){/}");
		classExperienceGauge:SetPoint(calculatedClassData.currentExperience, calculatedClassData.requiredExperience);
		classExperienceGauge:Resize(expCardCalculatorFrame:GetWidth() - 50, classExperienceGauge:GetHeight());
		classExperienceGauge:ShowWindow(1);
	end
end

function EXP_CARD_CALCULATOR_CLOSE()
end

--[[
function SYSMENU_CHECK_HIDE_VAR_ICONS_HOOKED(frame)
	if false == VARICON_VISIBLE_STATE_CHANTED(frame, "necronomicon", "necronomicon")
	and false == VARICON_VISIBLE_STATE_CHANTED(frame, "grimoire", "grimoire")
	and false == VARICON_VISIBLE_STATE_CHANTED(frame, "guild", "guild")
	and false == VARICON_VISIBLE_STATE_CHANTED(frame, "poisonpot", "poisonpot")
	then
		return;
	end

	DESTROY_CHILD_BY_USERVALUE(frame, "IS_VAR_ICON", "YES");

    local extraBag = frame:GetChild('extraBag');
	local status = frame:GetChild("status");
	local offsetX = status:GetX() - extraBag:GetX();
	local rightMargin = extraBag:GetMargin().right + offsetX;

	rightMargin = SYSMENU_CREATE_VARICON(frame, extraBag, "guild", "guild", "sysmenu_guild", rightMargin, offsetX, "Guild");
	rightMargin = SYSMENU_CREATE_VARICON(frame, extraBag, "necronomicon", "necronomicon", "sysmenu_card", rightMargin, offsetX);
	rightMargin = SYSMENU_CREATE_VARICON(frame, extraBag, "grimoire", "grimoire", "sysmenu_neacro", rightMargin, offsetX);
	rightMargin = SYSMENU_CREATE_VARICON(frame, extraBag, "poisonpot", "poisonpot", "sysmenu_wugushi", rightMargin, offsetX);	
	rightMargin = SYSMENU_CREATE_VARICON(frame, status, "expcardcalculator", "expcardcalculator", "addonmenu_expcard", rightMargin, offsetX, "Experience Card Calculator");

	local expcardcalculatorButton = GET_CHILD(frame, "expcardcalculator", "ui::CButton");
	if expcardcalculatorButton ~= nil then
		expcardcalculatorButton:SetTextTooltip("{@st59}Experience Card Calculator");
	end
end
]]--

function getTotalExperienceFromCards()
	local experienceCardData = {};
	experienceCardData["base"] = {};
	experienceCardData["base"]["cards"] = {};
	experienceCardData["class"] = {};
	experienceCardData["class"]["cards"] = {};

	experienceCardData["base"].totalBaseExperience = 0;
	experienceCardData["class"].totalClassExperience = 0;

	local inventoryItems = session.GetInvItemList();

	if inventoryItems ~= nil then
		local index = inventoryItems:Head();
		local itemCount = session.GetInvItemList():Count();

		for i = 0, itemCount - 1 do
			local inventoryItem = inventoryItems:Element(index);
			if inventoryItem ~= nil then
				local itemObj = GetIES(inventoryItem:GetObject());

				if itemObj ~= nil then
					if string.starts(itemObj.ClassName, "expCard") then
						local inventoryItemCount = GET_REMAIN_INVITEM_COUNT(inventoryItem);

						local totalBaseCardExperience = 0;
						local totalClassCardExperience = 0;

						for i = 1, inventoryItemCount do
							totalBaseCardExperience = totalBaseCardExperience + itemObj.NumberArg1;
							totalClassCardExperience = totalClassCardExperience + math.floor((itemObj.NumberArg1 * 0.77));
						end

						experienceCardData["base"]["cards"][itemObj.Name] = totalBaseCardExperience;
						experienceCardData["class"]["cards"][itemObj.Name] = totalClassCardExperience

						experienceCardData["base"].totalBaseExperience = experienceCardData["base"].totalBaseExperience + totalBaseCardExperience;
						experienceCardData["class"].totalClassExperience = experienceCardData["class"].totalClassExperience + totalClassCardExperience;
					end
				end
			end

			index = inventoryItems:Next(index);
		end
	end

	return experienceCardData;
end

function calculateClassRankAndLevel(totalClassExperienceFromCards)
	local calculatedClassData = {};
	local foundLevel = false;
	local tempTotalClassExperience = totalClassExperienceFromCards + _G["EXPCARDCALCULATOR"].currentClassExperience;
	local MAX_RANK = 10;
	local MAX_CLASS_LEVEL = 14; --only do 14 because you can only level up 14 times. 15 is a duplicate row.
	local clsList, cnt = GetClassList("Xp_Job");

	local startingClassLevel = _G["EXPCARDCALCULATOR"].classLevel;

	for rank = session.GetPcTotalJobGrade(), MAX_RANK do
		for classLevel = startingClassLevel, MAX_CLASS_LEVEL do
			local className = "Job_" .. rank .. "_" .. classLevel;
			local currentClassAndRankData = GetClassByNameFromList(clsList, className);
			local previousRankAndClassLevelName = getRankAndClassLevelName(getNextRankAndClassLevel(rank, classLevel, -1));
			local previousClassAndRankData = GetClassByNameFromList(clsList, previousRankAndClassLevelName);
			local requiredClassExperience = currentClassAndRankData.TotalXp - previousClassAndRankData.TotalXp;

			tempTotalClassExperience = tempTotalClassExperience - requiredClassExperience;

			if tempTotalClassExperience < 0 then
				local currentClassExperienceIntoResultLevel = tempTotalClassExperience + requiredClassExperience;

				calculatedClassData.rank = rank;
				calculatedClassData.level = classLevel;
				calculatedClassData.currentExperience = currentClassExperienceIntoResultLevel;
				calculatedClassData.requiredExperience = requiredClassExperience;
				calculatedClassData.percent = (currentClassExperienceIntoResultLevel / requiredClassExperience) * 100;

				foundLevel = true;
				break;
			end
		end

		startingClassLevel = 1;

		if foundLevel == true then
			break;
		end
	end

	return calculatedClassData;
end

function getNextRankAndClassLevel(rank, classLevel, levelIncrement)
	classLevel = classLevel + levelIncrement;

	if classLevel > 14 then
		rank = rank + 1;
		classLevel = 1;
	elseif classLevel < 1 then
		rank = rank - 1;
		classLevel = 1;
	end

	if rank < 1 then
		rank = 1;
	elseif rank > 10 then
		rank = 10;
	end

	return rank, classLevel;
end

function getRankAndClassLevelName(rank, classLevel)
	return "Job_" .. rank .. "_" .. classLevel;
end

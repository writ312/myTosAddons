_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['STATUSEXTEND'] = _G['ADDONS']['STATUSEXTEND'] or {};
local g = _G['ADDONS']['STATUSEXTEND'] 
local acutil = require("acutil")
g.status = {}
g.statusTable = {
        "MINATK",
        "MAXATK",
        "ADD_MAXATK",
        "ADD_MINATK",
        "ADD_MATK",
        "ADD_MATK",
        "PATK",
        "MATK",
        "DEF",
        "ADD_DEF",
        "MDEF",
        "ADD_MDEF"        
}
local function GetObjByIcon(icon)
    local info = icon:GetInfo()
    local IESID = info:GetIESID()
    return GetObjectByGuid(IESID)
end

local function GetEquipsStatus()
    g.status = {}
    local frame = ui.GetFrame('inventory')
    for i,v in ipairs({
        "HAT",
        "HAT_T",
        "HAT_L",
        "SHIRT",
        "GLOVES",
        "PANTS",
        "BOOTS",
        "RH",
        "LH",
        "RING1",
        "RING2",
        "NECK"
    }) do
        local slot = frame:GetChildRecursively(v)
        tolua.cast(slot, 'ui::CSlot')
        if slot:GetIcon() then
            local obj = GetObjByIcon(slot:GetIcon())
            for j,type in ipairs(g.statusTable) do
                if obj[type] ~= 0 then
                    local name = obj.Name
                    if v == "RING1" then
                        name = name.."_L"
                    elseif v == "RING2" then
                        name = name .."_R"
                    end
                    if v == "RH" and string.find(type,"ADD") and string.find(type,"DEF") then
                        g.status["SUB_"..type] = g.status["SUB_"..type] or {}
                        g.status["SUB_"..type][name] = obj[type]
                    else
                        g.status[type] = g.status[type] or {}
                        g.status[type][name] = obj[type]
                    end
                end
            end
        end
    end

end
local function GetStatusSum(status)
    local sum = 0;
    local text = ''
    for k,v in pairs(status) do
        text = string.format("%s%s : %d{nl}",text,k,v)
        sum = sum + v
    end
    return sum,text
end

local function GetRangeStatusSum(stat,AddStat,DefStat)
    local status = {}
    local sum = 0;
    for k,v in pairs(stat or {}) do
        status[k] = v
        sum = sum + v
    end
    for k,v in pairs(AddStat or {}) do 
        status[k] = status[k] and (status[k] + v) or v
        sum = sum + v
    end
    for k,v in pairs(DefStat or {}) do 
        status[k] = status[k] and (status[k] + v) or v
        sum = sum + v
    end
    return sum,status
end

local function GetTextFromMinMaxTable(minTable,maxTable)
    local mergeTable = {}
    for k,v in pairs(minTable) do
        mergeTable[k] = v
    end
    for k,v in pairs(maxTable) do
        if mergeTable[k] and (mergeTable[k] ~= v) then
            mergeTable[k] = string.format("%d~%d",mergeTable[k],v)
        else
            mergeTable[k]= v
        end
    end
    local text = ''
    for k,v in pairs(mergeTable) do
        text = string.format("%s%s : %s{nl}",text,k,tostring(v))
    end
    return text
end

function STATUS_INFO_HOOK()
    GetEquipsStatus()
    STATUS_INFO_OLD()
end

function STATUS_ATTRIBUTE_VALUE_NEW_HOOK(pc, opc, frame, gboxctrl, attibuteName, y)
	local controlSet = gboxctrl:CreateOrGetControlSet('status_stat', attibuteName, 0, y);
	tolua.cast(controlSet, "ui::CControlSet");
	local title = GET_CHILD(controlSet, "title", "ui::CRichText");
	title:SetText(ScpArgMsg(attibuteName));

	local stat = GET_CHILD(controlSet, "stat", "ui::CRichText");
	title:SetUseOrifaceRect(true)
	stat:SetUseOrifaceRect(true)

	--stat:SetText('120');

	local grayStyle, value = SET_VALUE_ZERO(pc[attibuteName]);
	
	if 1 == grayStyle then
		stat:SetText('');
		controlSet:Resize(controlSet:GetWidth(), stat:GetHeight());
		return y + controlSet:GetHeight();
	end

	if opc ~= nil and opc[attibuteName] ~= value then
		local colBefore = frame:GetUserConfig("BEFORE_STAT_COLOR");
		local colStr = frame:GetUserConfig("ADD_STAT_COLOR")

		local beforeGray, beforeValue = SET_VALUE_ZERO(opc[attibuteName]);
		
		if beforeValue ~= value then
			stat:SetText(colBefore.. beforeValue..ScpArgMsg("Auto_{/}__{/}")..colStr .. value);
		else
			stat:SetText(value);
		end
	else
		stat:SetText(value);
	end
    local sum,text,tempTable;
    if attibuteName == "DEF" or attibuteName == "MDEF" then
        sum,tempTable = GetRangeStatusSum(g.status[attibuteName],g.status["ADD_"..attibuteName],{})
        sum ,text = GetStatusSum(tempTable);
    else
        sum,text = GetStatusSum(g.status[attibuteName] or {})
    end
    if sum ~= 0 then 
        stat:SetText(stat:GetText()..string.format("(%d)",sum))
        controlSet:SetTextTooltip(text)
    end

	controlSet:Resize(controlSet:GetWidth(), stat:GetHeight());
	return y + controlSet:GetHeight();
end

function STATUS_ATTRIBUTE_VALUE_RANGE_NEW_HOOK(pc, opc, frame, gboxctrl, attibuteName, minName, maxName, y)
	local controlSet = gboxctrl:CreateOrGetControlSet('status_stat', attibuteName, 0, y);
	tolua.cast(controlSet, "ui::CControlSet");
		
	local title = GET_CHILD(controlSet, "title", "ui::CRichText");
	title:SetText(ScpArgMsg(attibuteName));

	local stat = GET_CHILD(controlSet, "stat", "ui::CRichText");


	local minVal = pc[minName];
	local maxVal = pc[maxName];

	local grayStyle;
	local value;
	if maxVal == 0 then
		grayStyle = 1;
		value = 0;
	else
		grayStyle = 0;
		value = string.format("%d~%d", minVal, maxVal);		
	end


	if opc ~= nil and opc[maxName] ~= maxVal then
		local colBefore = frame:GetUserConfig("BEFORE_STAT_COLOR");
		local colStr = frame:GetUserConfig("ADD_STAT_COLOR")
		
		local beforeValue = value;
		beforeValue = string.format("%d~%d", opc[minName], opc[maxName]);		

		if beforeValue ~= value then
			stat:SetText(colBefore.. beforeValue..ScpArgMsg("Auto_{/}__{/}")..colStr .. value);
		else
			stat:SetText(value);
		end
	else
		stat:SetText(value);
	end
    local minSum,maxSum;
    local minTable,maxTable = {},{};
    if (attibuteName == "PATK") then
        minSum ,minTable = GetRangeStatusSum(g.status.MINATK,g.status.ADD_MINATK,g.status.PATK)
        maxSum ,maxTable = GetRangeStatusSum(g.status.MAXATK,g.status.ADD_MAXATK,g.status.PATK)
    elseif (attibuteName == "PATK_SUB") then
        minSum ,minTable = GetRangeStatusSum(g.status.SUB_MINATK,g.status.ADD_MINATK,g.status.PATK)
        maxSum ,maxTable = GetRangeStatusSum(g.status.SUB_MAXMATK,g.status.ADD_MAXATK,g.status.PATK)
    elseif (attibuteName == "MATK") then
        minSum ,minTable = GetRangeStatusSum(g.status.ADD_MATK,g.status.ADD_MINATK,g.status.MATK)
        maxSum ,maxTable = GetRangeStatusSum(g.status.ADD_MATK,g.status.ADD_MAXATK,g.status.MATK)
    end
    if minSum ~= maxSum and minSum ~= 0 then
        stat:SetText(stat:GetText()..string.format("(%d~%d)",minSum,maxSum))
    elseif minSum ~= 0 and maxSum ~= 0 then
        stat:SetText(stat:GetText()..string.format("(%d)",maxSum))
    end
    controlSet:SetTextTooltip(GetTextFromMinMaxTable(minTable,maxTable))

	controlSet:Resize(controlSet:GetWidth(), stat:GetHeight());
	return y + controlSet:GetHeight();
end

function STATUSEXTEND_ON_INIT(addon,frame)
	acutil.setupHook(STATUS_INFO_HOOK, "STATUS_INFO");
	acutil.setupHook(STATUS_ATTRIBUTE_VALUE_NEW_HOOK, "STATUS_ATTRIBUTE_VALUE_NEW");
	acutil.setupHook(STATUS_ATTRIBUTE_VALUE_RANGE_NEW_HOOK, "STATUS_ATTRIBUTE_VALUE_RANGE_NEW");
    GetEquipsStatus()
end
local acutil = require('acutil');
ui.SysMsg("Load poisonpot auto charge")

function POISONPOTAUTOCHARGE_ON_INIT(addon, frame)
    POISONPOT_AUTO_CHARGE()
end

function POISONPOT_AUTO_CHARGE()

    if hasPoisonJob() == nil then
        return;end

    local poisonAmount = getPoisonAmount()
    if  poisonAmount == nil then
        return;end

    local poisonpot = GET_POISONPOT_ID();

    if poisonpot == nil then
        return;end

    local cnt = math.floor((1000 - poisonAmount) / 200);
    session.AddItemID(poisonpot, cnt);    
    EXECUTE_POISONPOT_COMMIT()
end

function hasPoisonJob()
	local frame = ui.GetFrame("sysmenu");
	local poisonpot = GET_CHILD(frame, "poisonpot", "ui::CButton");
	if poisonpot == nil then
		return nil
	end
	    return true
end

function getPoisonAmount()
    local myEtc = GetMyEtcObject();
    local poisonAmount = myEtc['Wugushi_PoisonAmount'];
    if poisonAmount < 700 then
        return poisonAmount;
    end
    return nil
end

-- 645569 misc_poisonpot

function GET_POISONPOT_ID()
    local inventoryItems = session.GetInvItemList();
	
	if inventoryItems == nil then
        return nil;end

    local index = inventoryItems:Head();
    local itemCount = session.GetInvItemList():Count();

    for i = 0, itemCount - 1 do
        local inventoryItem = inventoryItems:Element(index);
        index = inventoryItems:Next(index);
        
        if inventoryItem == nil then
            break;end
        
        local itemObj = GetIES(inventoryItem:GetObject());
        if itemObj == nil then
            break;end

        if string.starts(itemObj.ClassName, "misc_poisonpot") then
            return inventoryItem:GetIESID();
        end        
    end
    return nil;
end
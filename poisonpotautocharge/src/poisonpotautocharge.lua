local acutil = require('acutil');

_G['ADDONS'] = _G['ADDONS'] or {};
poisonpotAutoCharge = _G["ADDONS"]["RESOURCEGAUGE"] or {};

function POISONPOT_AUTO_CHARGE_ON_INIT(addon, frame)
    poisonpotAutoCharge.addon = addon;
	poisonpotAutoCharge.frame = frame;
	
	POISONPOT_AUTO_CHARGE_INIT();
end

function POISONPOT_AUTO_CHARGE_INIT()
    ui.SysMsg("Load poisonpot auto charge")
    acutil.slashCommand('/ppc',POISONPOT_AUTO_CHARGE);
    acutil.setupEvent(poisonpotAutoCharge.addon,"FPS_UPDATE",POISONPOT_AUTO_CHARGE)
end

function POISONPOT_AUTO_CHARGE()
    if hasPoisonJob == nil then
        return;
    end
    
    if not needPoisonCharge() then
     return;

    local poisonpot = GET_BAGWORMPOISON_ID()
    local cnt = 1;
    session.AddItemID(poisonpot, cnt);    
    EXECUTE_POISONPOT_COMMIT()
end

local function hasPoisonJob()
	local frame = ui.GetFrame("sysmenu");
	local poisonpot = GET_CHILD(frame, "poisonpot", "ui::CButton");
	if poisonpot ~= nil then
		return true
	end
	    return false
end

local function needPoisonCharge()
    local myEtc = GetMyEtcObject();
    local poisonAmount = myEtc['Wugushi_PoisonAmount'];
    local poisonMaxAmount = myEtc['Wugushi_PoisonMaxAmount'];
    if ((poisonMaxAmount - poisonAmount) < 500) then
        return true
    else
        return false
    end
end

-- 645569 misc_poisonpot
function GET_BAGWORMPOISON_ID()
    local item = _GET_BAGWORMPOISON_ID()

    if item == nil then
        ui.SysMsg('dont exist poisonpot');
        return nil;
    end
    return item;
end

function _GET_BAGWORMPOISON_ID()
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

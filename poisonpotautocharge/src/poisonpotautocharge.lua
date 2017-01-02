local acutil = require('acutil');
ui.SysMsg("Load Poisonpot Auto Charge")

function POISONPOTAUTOCHARGE_ON_INIT(addon, frame)
    POISONPOT_AUTO_CHARGE()
end

function POISONPOT_AUTO_CHARGE()
    local frame = ui.GetFrame("sysmenu");
	local poisonpot = GET_CHILD(frame, "poisonpot", "ui::CButton");
	if not poisonpot then
        return;
    end
    
    local myEtc = GetMyEtcObject();
    local poisonAmount = myEtc['Wugushi_PoisonAmount'];
      
    local cnt = math.floor((1000 - poisonAmount) / 200);
    if cnt < 1 then
        return
    end
    
    local poison = session.GetInvItemByName('misc_poisonpot')
    local poisonGUID = poison:GetIESID()

    session.ResetItemList()
    session.AddItemID(poisonGUID, cnt);    
    EXECUTE_POISONPOT_COMMIT()
end

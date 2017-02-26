-- CHAT_SYSTEM("load Skill Scroll Icon");

function SKILLSCROLLICON_ON_INIT(addon,frame)
    addon:RegisterMsg('GAME_START_3SEC','SKILLSCROLL_SET_ICON')    
end
function SKILLSCROLL_SET_ICON()
    local scrolls = getScrollSlot('Item',910001)
    if scrolls == {} then return;end;
    local slotIndex,slot
    for i,value in ipairs(scrolls) do
        slotIndex = value[1]
        slot = value[2]
        local obj = GetObjByIcon(slot:GetIcon())
        local subslot = slot:CreateOrGetControl("slot","sub"..slot:GetName(),25,0,20,20)
        tolua.cast(subslot, 'ui::CSlot')
        subslot:EnableDrag(0)
        subslot:EnablePop(0)
        subslot:SetEventScript(ui.RBUTTONUP, 'SKILLSCROLLICON_RBTN_FUNC');
        subslot:SetEventScriptArgNumber(ui.RBUTTONUP,slotIndex) 
        local subIcon = CreateIcon(subslot);
        local skillObj = GetClassByType("Skill",obj.SkillType)
        subIcon:SetImage('icon_'..skillObj.Icon)
    end
end

function getScrollSlot(category, classID)
    local scrolls = {}
    local frame
    if(IsJoyStickMode() == 0) then
        frame = ui.GetFrame('quickslotnexpbar')
    else
        frame = ui.GetFrame('joystickquickslot')
    end
	for i = 0, MAX_QUICKSLOT_CNT - 1 do
		local slot = GET_CHILD_RECURSIVELY(frame, "slot"..(i+1), "ui::CSlot");
		local iconPt = slot:GetIcon();
		if iconPt  ~=  nil then
			local icon = tolua.cast(iconPt, 'ui::CIcon');
			local iconInfo = icon:GetInfo();
			if iconInfo.category == category and iconInfo.type == classID then
				 table.insert(scrolls,{i,slot})
			end
		end
	end

	return scrolls;
end

function GetObjByIcon(icon)
    local info = icon:GetInfo()
    local IESID = info:GetIESID()
    return GetObjectByGuid(IESID) ,IESID,info
end

function SKILLSCROLLICON_RBTN_FUNC(frame,obj,argstr,slotIndex)
    QUICKSLOTNEXPBAR_EXECUTE(slotIndex)
end

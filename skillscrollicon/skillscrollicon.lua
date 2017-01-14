CHAT_SYSTEM("load Skill Scroll Icon");

function SKILLSCROLLICON_ON_INIT(addon,frame)
    addon:RegisterMsg('GAME_START_3SEC','SKILLSCROLL_SET_ICON')    
end
function SKILLSCROLL_SET_ICON()
    local scrolls = getScrollSlot('Item',910001)
    if scrolls == {} then return;end;
    for i,slot in ipairs(scrolls) do
        local obj = GetObjByIcon(slot:GetIcon())
        local subslot = slot:CreateOrGetControl("slot","sub"..slot:GetName(),20,0,25,25)
        tolua.cast(subslot, 'ui::CSlot')
        subslot:EnableDrag(0)
        subslot:EnablePop(0)
        local subIcon = CreateIcon(subslot);
        local skillObj = GetClassByType("Skill",obj.SkillType)
        subIcon:SetImage('icon_'..skillObj.Icon)
    end
end

function getScrollSlot(category, classID)
    local scrolls = {}
    local frame = ui.GetFrame('quickslotnexpbar')
	for i = 0, MAX_QUICKSLOT_CNT - 1 do
		local slot = GET_CHILD(frame, "slot"..i+1, "ui::CSlot");
		local iconPt = slot:GetIcon();
		if iconPt  ~=  nil then
			local icon = tolua.cast(iconPt, 'ui::CIcon');
			local iconInfo = icon:GetInfo();
			if iconInfo.category == category and iconInfo.type == classID then
				 table.insert(scrolls,slot)
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
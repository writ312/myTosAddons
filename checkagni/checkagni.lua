function CHECKAGNI_ON_INIT(addon,frame)
	checkAgniJob()
end

function checkAgniJob()
	local jobTable = {2002,4014}
	local cid = info.GetCID(session.GetMyHandle())
    local pcSession = session.GetSessionByCID(cid);
    local pcJobInfo = pcSession.pcJobInfo;
    local cnt = pcJobInfo:GetJobCount();
    for i = 0 , cnt - 1 do
        local jobID = pcJobInfo:GetJobByIndex(i);
        if jobID == -1 then
            break;
        end
        for j = 1,#jobTable do
			if jobID == jobTable[j] then
				checkAgniNeck()
				return
			end
		end
	end

end

function checkAgniNeck()
   
	local frame = ui.GetFrame('inventory')
	local slot = frame:GetChildRecursively('NECK')
	tolua.cast(slot, 'ui::CSlot')
	local icon = slot:GetIcon() 
	if icon then
		local obj = GetObjByIcon(icon)
		if obj.ClassID == 582127 then return end  
	end
	CHAT_SYSTEM('アグニ装備してないよー')
end

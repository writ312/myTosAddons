-- local acutil = require("acutil");

function FRIENDINFO_ON_INIT(addon, frame)
	_G["POPUP_FRIEND_COMPLETE_CTRLSET_OLD"] = POPUP_FRIEND_COMPLETE_CTRLSET;
	_G["POPUP_FRIEND_COMPLETE_CTRLSET"] = POPUP_FRIEND_COMPLETE_CTRLSET_HOOKED;
	-- acutil.setupHook(POPUP_FRIEND_COMPLETE_CTRLSET_HOOKED, "POPUP_FRIEND_COMPLETE_CTRLSET");
end

function POPUP_FRIEND_COMPLETE_CTRLSET_HOOKED(parent, ctrlset)

	local aid = ctrlset:GetUserValue("AID");
	if aid == "" then
		return;
	end

	local f = session.friends.GetFriendByAID(FRIEND_LIST_COMPLETE, aid);

	if f == nil then
		return;
	end

	local info = f:GetInfo();
	local context = ui.CreateContextMenu("FRIEND_CONTEXT", "", 0, 0, 0, 0);

    local  CharacterInfo = string.format("OPEN_PARTY_MEMBER_INFO('%s')", info:GetFamilyName());
    ui.AddContextMenuItem(context, "キャラクター情報", CharacterInfo);

	if f.mapID ~= 0 then
		local partyinviteScp = string.format("PARTY_INVITE(\"%s\")", info:GetFamilyName());
		ui.AddContextMenuItem(context, ScpArgMsg("PARTY_INVITE"), partyinviteScp);
	end

	local whisperScp = string.format("ui.WhisperTo('%s')", info:GetFamilyName());
	ui.AddContextMenuItem(context, ScpArgMsg("WHISPER"), whisperScp);

	local memoScp = string.format("FRIEND_SET_MEMO(\"%s\")",aid);
	ui.AddContextMenuItem(context, ScpArgMsg("FriendAddMemo"), memoScp);
	
	local groupnamelist = {}
	local cnt = session.friends.GetFriendCount(FRIEND_LIST_COMPLETE);

	for i = 0 , cnt - 1 do
		local allfriend = session.friends.GetFriendByIndex(FRIEND_LIST_COMPLETE, i);		
		local groupname = allfriend:GetGroupName()

		if groupname ~= nil and groupname ~= "" and groupname ~= "None" and groupname ~= f:GetGroupName() and groupnamelist[groupname] == nil then
			
			table.insert(groupnamelist,groupname)
			
		end
	end


	local subcontext = ui.CreateContextMenu("SUB", "", 0, 0, 0, 0);	
	
	for k, customgroupname in pairs(groupnamelist) do
		local groupScp = string.format("FRIEND_SET_GROUPNAME('%d',\"%s\")",tonumber(aid), customgroupname);
		ui.AddContextMenuItem(subcontext, customgroupname, groupScp);
	end

	local nowgroupname = f:GetGroupName()
	if nowgroupname ~= nil and nowgroupname ~= "" and nowgroupname ~= "None"  then
		local groupScp = string.format("FRIEND_SET_GROUPNAME('%s','%s')",aid, '');
		ui.AddContextMenuItem(subcontext, ScpArgMsg(FRIEND_GET_GROUPNAME(FRIEND_LIST_COMPLETE)), groupScp);
	end
	
	local groupScp = string.format("FRIEND_SET_GROUP(\"%s\")",aid);
	ui.AddContextMenuItem(subcontext, ScpArgMsg("FriendAddNewGroup"), groupScp);

	local groupScp = string.format("POPUP_FRIEND_GROUP_CONTEXTMENU(\"%s\")",aid);
	ui.AddContextMenuItem(context, ScpArgMsg("FriendAddGroup"), groupScp , nil, 0,1, subcontext);

	local blockScp = string.format("friends.RequestBlock('%s')",info:GetFamilyName() );
	ui.AddContextMenuItem(context, ScpArgMsg("FriendBlock"), blockScp)

	local deleteScp = string.format("FRIEND_EXEC_DELETE(\"%s\")", aid);
	ui.AddContextMenuItem(context, ScpArgMsg("FriendDelete"), deleteScp);
	
	ui.AddContextMenuItem(context, ScpArgMsg("Cancel"), "None");
	ui.OpenContextMenu(context);

end
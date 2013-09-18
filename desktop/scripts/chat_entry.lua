-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	self.onSlashCommand = ChatManager.onSlashCommand;
end

function onDeliverMessage(msg, mode)
	if mode == "chat" then
		local bOptPCHT = OptionsManager.isOption("PCHT", "on");
		
		if User.isHost() then
			if bOptPCHT then
				msg.icon = "portrait_gm_token";
			end

			if not msg.sender or (msg.sender == "" or msg.sender == User.getUsername()) then
				gmid, isgm = GmIdentityManager.getCurrent();
				msg.sender = gmid;
				if isgm then
					msg.font = "chatgmfont";
				else
					msg.font = "chatnpcfont";
				end
			else
				msg.font = "chatnpcfont";
			end
		else
			if bOptPCHT then
				local sCurrentId = User.getCurrentIdentity();
				if sCurrentId then
					msg.icon = "portrait_" .. sCurrentId .. "_chat";
				end
			end
		end
	elseif mode == "emote" then
		if User.isHost() then
			local gmid, isgm = GmIdentityManager.getCurrent();
			if not isgm then
				msg.sender = "";
				msg.text = gmid .. " " .. msg.text;
			end
		end
	end
	
	return msg;
end

function onTab()
	ChatManager.doUserAutoComplete(self);
end

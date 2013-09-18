-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function importChar()
	local sFile = Interface.dialogFileOpen();
	if sFile then
		DB.import(sFile, "charsheet", "character");
		ChatManager.SystemMessage("Imported character(s) from: " .. sFile);
	end
end

function exportChar(nodeChar)
	local sFile = Interface.dialogFileSave();
	if sFile then
		if nodeChar then
			DB.export(sFile, nodeChar, "character");
			ChatManager.SystemMessage("Exported character: " .. DB.getValue(nodeChar, "name", ""));
		else
			DB.export(sFile, "charsheet", "character", true);
			ChatManager.SystemMessage("Exported all characters");
		end
	end
end

function setCharPortrait(nodeChar, sPortraitFile)
	if not nodeChar or not sPortraitFile then
		return;
	end
	
	User.setPortrait(nodeChar, sPortraitFile);
	
	local wnd = Interface.findWindow("charsheet", nodeChar)
	if wnd then
		if User.isLocal() then
			if wnd.localportrait then
				wnd.localportrait.setFile(sPortraitFile);
			end
		else
			if wnd.portrait then
				wnd.portrait.setIcon("portrait_" .. nodeChar.getName() .. "_charlist", true);
			end
		end
	end
	
	wnd = Interface.findWindow("charselect_client", "");
	if wnd then
		for _, v in pairs(wnd.list.getWindows()) do
			if v.localdatabasenode then
				if v.localdatabasenode == nodeChar then
					if v.localportrait then
						v.localportrait.setFile(sPortraitFile);
					end
				end
			end
		end
	end
end

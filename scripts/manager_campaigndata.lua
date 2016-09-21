-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	DB.onImport = onImport;
end

--
-- Drop handling
--

function handleDrop(sTarget, draginfo)
	if CampaignDataManager2 and CampaignDataManager2.handleDrop then
		if CampaignDataManager2.handleDrop(sTarget, draginfo) then
			return true;
		end
	end
	
	if not User.isHost() then
		return;
	end
	
	if sTarget == "quest" then
		local sClass, sRecord = draginfo.getShortcutData();
		if sClass == "quest" then
			local nodeSource = DB.findNode(sRecord);
			local nodeTarget = DB.createChild("quest");
			DB.copyNode(nodeSource, nodeTarget);
			DB.setValue(nodeTarget, "locked", "number", 1);
		end
		return true;
	elseif sTarget == "encounter" then
		local sClass, sRecord = draginfo.getShortcutData();
		if sClass == "encounter" then
			local nodeSource = DB.findNode(sRecord);
			local nodeTarget = DB.createChild("encounter");
			DB.copyNode(nodeSource, nodeTarget);
			DB.setValue(nodeTarget, "locked", "number", 1);
		end
		return true;
	elseif sTarget == "image" then
		if draginfo.isType("file") then
			Interface.addImageFile(draginfo.getStringData());
		end
		return true;
	elseif sTarget == "npc" then
		local sClass, sRecord = draginfo.getShortcutData();
		if sClass == "npc" then
			local nodeSource = DB.findNode(sRecord);
			local nodeTarget = DB.createChild("npc");
			DB.copyNode(nodeSource, nodeTarget);
			DB.setValue(nodeTarget, "locked", "number", 1);
		end
		return true;
	elseif sTarget == "battle" then
		local sClass, sRecord = draginfo.getShortcutData();
		if sClass == "battle" then
			local nodeSource = DB.findNode(sRecord);
			local nodeTarget = DB.createChild("battle");
			DB.copyNode(nodeSource, nodeTarget);
			DB.setValue(nodeTarget, "locked", "number", 1);
		end
		return true;
	elseif sTarget == "item" then
		ItemManager.handleAnyDrop(DB.createNode("item"), draginfo);
		return true;
	elseif sTarget == "treasureparcels" then
		local sClass, sRecord = draginfo.getShortcutData();
		if sClass == "treasureparcel" then
			local nodeSource = DB.findNode(sRecord);
			local nodeTarget = DB.createChild("treasureparcels");
			DB.copyNode(nodeSource, nodeTarget);
			DB.setValue(nodeTarget, "locked", "number", 1);
		end
		return true;
	elseif sTarget == "tables" then
		local sClass, sRecord = draginfo.getShortcutData();
		if sClass == "table" then
			local nodeSource = DB.findNode(sRecord);
			local nodeTarget = DB.createChild("tables");
			DB.copyNode(nodeSource, nodeTarget);
			DB.setValue(nodeTarget, "locked", "number", 1);
		end
		return true;
	elseif sTarget == "combattracker" then
		local sClass, sRecord = draginfo.getShortcutData();
		if sClass == "charsheet" then
			CombatManager.addPC(draginfo.getDatabaseNode());
			return true;
		elseif sClass == "npc" then
			CombatManager.addNPC(sClass, draginfo.getDatabaseNode());
			return true;
		elseif sClass == "battle" then
			CombatManager.addBattle(draginfo.getDatabaseNode());
			return true;
		end
	elseif sTarget == "charselect" then
		local sClass, sRecord = draginfo.getShortcutData();
		if sClass == "pregencharsheet" then
			addPregenChar(DB.findNode(sRecord));
			return true;
		end
	end
end

--
-- Character manaagement
--

function importChar()
	local sFile = Interface.dialogFileOpen();
	if sFile then
		DB.import(sFile, "charsheet", "character");
		ChatManager.SystemMessage(Interface.getString("message_slashimportsuccess") .. ": " .. sFile);
	end
end

function onImport(node)
	local aPath = StringManager.split(node.getNodeName(), ".");
	if #aPath == 2 and aPath[1] == "charsheet" then
		if DB.getValue(node, "token", ""):sub(1,9) == "portrait_" then
			DB.setValue(node, "token", "token", "portrait_" .. node.getName() .. "_token");
		end
	end
end

function exportChar(nodeChar)
	local sFile = Interface.dialogFileSave();
	if sFile then
		if nodeChar then
			DB.export(sFile, nodeChar, "character");
			ChatManager.SystemMessage(Interface.getString("message_slashexportsuccess") .. ": " .. DB.getValue(nodeChar, "name", ""));
		else
			DB.export(sFile, "charsheet", "character", true);
			ChatManager.SystemMessage(Interface.getString("message_slashexportsuccess"));
		end
	end
end

function setCharPortrait(nodeChar, sPortraitFile)
	if not nodeChar or not sPortraitFile then
		return;
	end
	
	User.setPortrait(nodeChar, sPortraitFile);
	
	if nodeChar and DB.getValue(nodeChar, "token", "") == "" then
		DB.setValue(nodeChar, "token", "token", "portrait_" .. nodeChar.getName() .. "_token");
	end
	
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

function addPregenChar(nodeSource)
	if CampaignDataManager2 and CampaignDataManager2.addPregenChar then
		CampaignDataManager2.addPregenChar(nodeSource);
		return;
	end
	
	local nodeTarget = DB.createChild("charsheet");
	DB.copyNode(nodeSource, nodeTarget);

	ChatManager.SystemMessage(Interface.getString("pregenchar_message_add"));
end

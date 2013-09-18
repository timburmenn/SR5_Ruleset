-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function handleDrop(sTarget, draginfo)
	if CampaignDataManager2 and CampaignDataManager2.handleDrop then
		if CampaignDataManager2.handleDrop(sTarget, draginfo) then
			return true;
		end
	end
	
	if sTarget == "image" then
		if User.isHost() then
			if draginfo.isType("file") then
				Interface.addImageFile(draginfo.getStringData());
			end
		end
		return true;
	elseif sTarget == "item" then
		if User.isHost() then
			ItemManager.handleDrop(DB.createNode("item"), draginfo);
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
	end
end
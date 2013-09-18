-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if User.isHost() then
		PartyLootManager.rebuild();
	end
	
	OptionsManager.registerCallback("MIID", onIDChanged);
end

function onClose()
	OptionsManager.unregisterCallback("MIID", onIDChanged);
end

function onIDChanged()
	for _,w in pairs(items.getWindows()) do
		w.onIDChanged();
	end
end

function onDrop(x, y, draginfo)
	local sDragType = draginfo.getType();

	if User.isHost() then
		if sDragType == "shortcut" then
			local sClass = draginfo.getShortcutData();
			local nodeSource = draginfo.getDatabaseNode();
			
			if sClass == "treasureparcel" then
				PartyLootManager.addParcel(nodeSource);
			elseif ItemManager.isItemClass(sClass) then
				PartyLootManager.addItem(sClass, nodeSource);
			end
		elseif sDragType == "number" then
			PartyManager.addCoins(draginfo.getDescription(), draginfo.getNumberData());
		end
	else
		if sDragType == "shortcut" then
			local sClass = draginfo.getShortcutData();
			local nodeSource = draginfo.getDatabaseNode();
			if sClass == "item" and ItemManager.getItemSourceType(nodeSource) == "charsheet" then
				PartyLootManager.addItem(sClass, nodeSource);
			end
		end
	end

	return true;
end


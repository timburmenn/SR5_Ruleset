-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

aExport = {};

function onInit()
	if User.isHost() then
		Comm.registerSlashHandler("export", processExport);

		-- Register Standard Camapign Nodes for /export
	    registerExportNode({ name = "encounter", class = "encounter", label = "Story" });
		registerExportNode({ name = "image", class = "imagewindow", label = "Images & Maps" });
		registerExportNode({ name = "npc", class = "npc", label = "Personalities" });
		registerExportNode({ name = "battle", class = "battle", label = "Encounters" });
		registerExportNode({ name = "item", class = "item", label = "Items" });
		registerExportNode({ name = "treasureparcels", class = "treasureparcel", label = "Parcels"});
		registerExportNode({ name = "tables", class = "table", label = "Tables"});
	end
end

function processExport(sCommand, sParams)
	Interface.openWindow("export", "");
end

function retrieveExportNodes()
	return aExport;
end

function registerExportNode(rExport)
	table.insert(aExport, rExport)
end

function unregisterExportNode(rExport)
	local nIndex = nil;
	
	for k,v in pairs(aExport) do
		if string.upper(v.name) == string.upper(rExport.name) then
			nIndex = k;
		end
	end
	
	if nIndex then
		table.remove(aExport, nIndex);
	end
end

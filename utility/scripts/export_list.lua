-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	addCategories();
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		for _,v in ipairs(getWindows()) do
			local sClass, sRecord = draginfo.getShortcutData();
		
			-- Find matching export category
			if string.find(sRecord, v.exportsource) == 1 then
				-- Check duplicates
				for _,c in ipairs(v.entries.getWindows()) do
					if c.getDatabaseNode().getNodeName() == sRecord then
						return true;
					end
				end
			
				-- Create entry
				local w = v.entries.createWindow(draginfo.getDatabaseNode());
				w.open.setValue(sClass, sRecord);
				
				v.all.setValue(0);
				break;
			end
		end
		
		return true;
	end
end

function addCategories()
	local aCategories = ExportManager.retrieveExportNodes();
	
	for _,r in ipairs(aCategories) do
		local w = createWindow();
		w.setExportName(r.name);
		w.setExportClass(r.class);
		w.label.setValue(r.label);
	end
end

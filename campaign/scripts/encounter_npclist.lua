-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onListChanged()
	update();
end

function update()
	local bEditMode = (window.npcs_iedit.getValue() == 1);
	if window.idelete_header then
		window.idelete_header.setVisible(bEditMode);
	end
	for _,w in ipairs(getWindows()) do
		w.idelete.setVisible(bEditMode);
	end
end

function addEntry(bFocus)
	local w = createWindow();
	if bFocus then
		w.count.setFocus();
	end
	return w;
end

function onDrop(x, y, draginfo)
	if isReadOnly() then
		return;
	end
	
	if draginfo.isType("shortcut") then
		local source = draginfo.getDatabaseNode();
		if source then
			local sClass,_ = draginfo.getShortcutData();
			local bAccept = false;
			if self.allowLink then
				bAccept = self.allowLink(sClass);
			elseif sClass == "npc" then
				bAccept = true;
			end
			if bAccept then
				local w = addEntry(true);
				if w then
					w.name.setValue(DB.getValue(source, "name", ""));
					w.link.setValue(sClass, source.getNodeName());

					local tokenval = DB.getValue(source, "token", nil);
					if tokenval then
						w.token.setPrototype(tokenval);
					end
				end
			end
		end

		return true;
	end
end

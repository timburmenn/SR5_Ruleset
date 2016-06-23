-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerMenuItem(Interface.getString("ct_menu_effectadd"), "pointer", 2);
end

function addEntry(bFocus)
	local win = createWindow();
	if bFocus and win then
		win.label.setFocus();
	end
	return win;
end

function onEnter()
	addEntry(true);
	return true;
end

function onMenuSelection(selection)
	if selection == 2 then
		addEntry(true);
	end
end

function deleteChild(child)
	local nodeChild = child.getDatabaseNode();
	if nodeChild then
		nodeChild.delete();
	else
		child.close();
	end
end

function reset()
	for _,v in pairs(getWindows()) do
		local nodeWin = v.getDatabaseNode();
		if nodeWin then
			nodeWin.delete();
		else
			v.close();
		end
	end
end

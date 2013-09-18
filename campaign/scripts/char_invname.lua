-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onDeleteUp()
	if isReadOnly() then
		return;
	end
	
	if getValue() == "" and not nodelete then
		local target = window.windowlist.getPrevWindow(window);
		if target then
			target[getName()].setFocus();
			target[getName()].setCursorPosition(#target[getName()].getValue()+1);
			target[getName()].setSelectionPosition(#target[getName()].getValue()+1);
		end

		delete();
	end
end

function onDeleteDown()
	if isReadOnly() then
		return;
	end
	
	if getValue() == "" and not nodelete then
		local target = window.windowlist.getNextWindow(window);
		if target then
			target[getName()].setFocus();
			target[getName()].setCursorPosition(1);
			target[getName()].setSelectionPosition(1);
		end

		delete();
	end
end

function delete()
	local nodeWin = window.getDatabaseNode();
	if nodeWin then
		nodeWin.delete();
	else
		window.close();
	end
end

function onLoseFocus()
	super.onLoseFocus();
	window.windowlist.applySort();
	window.windowlist.updateContainers();
end

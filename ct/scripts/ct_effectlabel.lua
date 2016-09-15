-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onDragStart(button, x, y, draginfo)
	if window.onDragStart then
		return window.onDragStart(button, x, y, draginfo);
	end
end

function onDrop(x, y, draginfo)
	if window.onDrop then
		return window.onDrop(x, y, draginfo);
	end
end

function onEnter()
	if window.windowlist and window.windowlist.onEnter then
		return window.windowlist.onEnter();
	end
end

function onNavigateLeft()
	local prev = window.windowlist.getPrevWindow(window);
	if prev then
		prev[getName()].setFocus();
		prev[getName()].setCursorPosition(#prev[getName()].getValue()+1);
		prev[getName()].setSelectionPosition(#prev[getName()].getValue()+1);
	end
end

function onNavigateRight()
	local next = window.windowlist.getNextWindow(window);
	if next then
		next[getName()].setFocus();
		next[getName()].setCursorPosition(1);
		next[getName()].setSelectionPosition(1);
	end
end

function onDeleteUp()
	local prev = window.windowlist.getPrevWindow(window);

	if prev then
		prev[getName()].setFocus();
		prev[getName()].setCursorPosition(#prev[getName()].getValue()+1);
		prev[getName()].setSelectionPosition(#prev[getName()].getValue()+1);
		
		if getValue() == "" then
			delete();
		end
	elseif getValue() == "" then
		local next = window.windowlist.getNextWindow(window);

		if next then
			next[getName()].setFocus();
			next[getName()].setCursorPosition(1);
			next[getName()].setSelectionPosition(1);
		end
		
		delete();
	end
end

function onDeleteDown()
	local next = window.windowlist.getNextWindow(window);
	
	if next then
		next[getName()].setFocus();
		next[getName()].setCursorPosition(1);
		next[getName()].setSelectionPosition(1);

		if getValue() == "" then
			delete();
		end
	elseif getValue() == "" then
		local prev = window.windowlist.getPrevWindow(window);

		if prev then
			prev[getName()].setFocus();
			prev[getName()].setCursorPosition(#prev[getName()].getValue()+1);
			prev[getName()].setSelectionPosition(#prev[getName()].getValue()+1);
		end
		
		delete();
	end
end

function delete()
	if window.windowlist.deleteChild then
		window.windowlist.deleteChild(window, true);
	else
		local nodeWin = window.getDatabaseNode();
		if nodeWin then
			nodeWin.delete();
		else
			window.close();
		end
	end
end

function onGainFocus()
	window.setFrame("rowshade");
end

function onLoseFocus()
	window.setFrame(nil);
end

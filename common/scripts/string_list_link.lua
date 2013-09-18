-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if not static then
		setEditMode(false);
	end
end

function onMenuSelection(...)
	setEditMode(isReadOnly());
end

function setEditMode(state)
	if state then
		setReadOnly(false);
		resetMenuItems();
		registerMenuItem("Stop editing", "stopedit", 5);

		setUnderline(false);
		setFocus();
		
		setCursorPosition(#getValue()+1);
		setSelectionPosition(0);
	else
		setReadOnly(true);
		resetMenuItems();
		registerMenuItem("Edit", "edit", 4);
	end
end

function onHover(oncontrol)
	if isReadOnly() then
		setUnderline(oncontrol);
	end
end

function onLoseFocus()
	setEditMode(false);
end

function onClickDown(button, x, y)
	if isReadOnly() then
		return true;
	end
end

function onClickRelease(button, x, y)
	if isReadOnly() then
		if self.activate then
			self.activate();
		elseif linktarget then
			window[linktarget[1]].activate();
		end
	end
	return true;
end

function onDragStart(button, x, y, draginfo)
	if isReadOnly() and linktarget and window[linktarget[1]].onDragStart then
		window[linktarget[1]].onDragStart(button, x, y, draginfo);
		return true;
	end
end
					
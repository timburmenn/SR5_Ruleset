-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if rollable or (gmrollable and User.isHost()) then
		local w = addBitmapWidget("field_rollable");
		w.setPosition("bottomleft", -1, -4);
		setHoverCursor("hand");
	elseif rollable2 or (gmrollable2 and User.isHost()) then
		local w = addBitmapWidget("field_rollable_transparent");
		w.setPosition("topright", 0, 2);
		w.sendToBack();
		setHoverCursor("hand");
	end
end

function onDrop(x, y, draginfo)
	if draginfo.getType() ~= "number" then
		return false;
	end
end

function onWheel(n)
	if isReadOnly() then
		return false;
	end
	
	if not OptionsManager.isMouseWheelEditEnabled() then
		return false;
	end
	
	setValue(getValue() + n);
	return true;
end

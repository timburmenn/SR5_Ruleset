-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

slots = {};

function resetCounters()
	for k, v in ipairs(slots) do
		v.destroy();
	end
	
	slots = {};
end

function addCounter()
	local widget = addBitmapWidget(counters[1].icon[1]);
	widget.setPosition("topleft", counters[1].offset[1].x[1] + counters[1].spacing[1] * #slots, counters[1].offset[1].y[1]);
	table.insert(slots, widget);
end

function onHoverUpdate(x, y)
	ModifierStack.hoverDisplay(getCounterAt(x, y));
end

function onHover(oncontrol)
	if not oncontrol then
		ModifierStack.hoverDisplay(0);
	end
end

function getCounterAt(x, y)
	for i = 1, #slots do
		local slotcenterx = counters[1].offset[1].x[1] + counters[1].spacing[1] * (i-1);
		local slotcentery = counters[1].offset[1].y[1];
		
		local size = tonumber(counters[1].hoversize[1]);
		
		if math.abs(slotcenterx - x) <= size and math.abs(slotcenterx - x) <= size then
			return i;
		end
	end
	
	return 0;
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	local n = getCounterAt(x, y);
	if n ~= 0 then
		ModifierStack.removeSlot(n);
	end
	return true;
end

function onDrop(x, y, draginfo)
	local sDragType = draginfo.getType();
	
	-- Special handling for numbers, since they may come from chat window
	if sDragType == "number" then
		-- Strip any names that were added
		local sDragText = draginfo.getDescription();

		-- Then, add to the modifier stack
		ModifierStack.addSlot(sDragText, draginfo.getNumberData());
		return true;
	
	else
		-- See which other potential drop types we want to accept (ignoring dice)
		for _,v in pairs(acceptdrop) do
			if v.type[1] == sDragType then
				draginfo.setSlot(1);
				ModifierStack.addSlot(draginfo.getStringData(), draginfo.getNumberData());
				return true;
			end
		end
	end

	return false;
end

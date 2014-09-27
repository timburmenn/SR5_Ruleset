-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

slots = {};
local nMaxSlotRow = 10;
local nDefaultSpacing = 10;
local nSpacing = nDefaultSpacing;

local nodeMax = nil;
local sMaxNodeName = "";
local nodeCurr = nil;
local sCurrNodeName = "";
local nodeOverflow = nil;
local sOverflowNodeName = "";

function onInit()
	-- Get any custom fields
	if sourcefields then
		if sourcefields[1].maximum then
			sMaxNodeName = sourcefields[1].maximum[1];
		end
		if sourcefields[1].current then
			sCurrNodeName = sourcefields[1].current[1];
		end
		if sourcefields[1].overflow then
			sOverflowNodeName = sourcefields[1].overflow[1];
		end
	end
	
	if rows then
		nMaxSlotRow = tonumber(rows[1])
	end

	-- Synch to the data nodes
	local nodeWin = window.getDatabaseNode();
	if nodeWin then
		local bWatchUpdate = false;
		if sMaxNodeName ~= "" then
			-- If this is a new counter, then set our max value to 1 by default.
			nodeMax = nodeWin.getChild(sMaxNodeName);
			if not nodeMax then
				nodeMax = nodeWin.createChild(sMaxNodeName, "number");
				if nodeMax then
					nodeMax.setValue(1);
				end
			end
			if nodeMax then
				nodeMax.onUpdate = update;
			else
				bWatchUpdate = true;
			end
		end
		if sCurrNodeName ~= "" then
			nodeCurr = nodeWin.createChild(sCurrNodeName, "number");
			if nodeCurr then
				nodeCurr.onUpdate = update;
			else
				bWatchUpdate = true;
			end
		end
		if sOverflowNodeName ~= "" then
			print("Overflow node!!");
			nodeOverflow = nodeWin.createChild(sOverflowNodeName, "number");
			if nodeOverflow then
				nodeOverflow.onUpdate = update;
			else
				bWatchUpdate = true;
			end
		end
		if bWatchUpdate then
			nodeWin.onChildAdded = registerUpdate;
		end
	end
	
	if spacing then
		nSpacing = tonumber(spacing[1]) or nDefaultSpacing;
	end
	setAnchoredHeight(nSpacing*2);
	setAnchoredWidth(math.ceil(nSpacing*nMaxSlotRow/10));

	updateSlots();

	registerMenuItem(Interface.getString("counter_menu_clear"), "erase", 4);
end

function registerUpdate(nodeSource, nodeChild)
	if nodeChild.getName() == sMaxNodeName then
		nodeMax = nodeChild;
	elseif nodeChild.getName() == sCurrNodeName then
		nodeCurr = nodeChild;
	else
		return;
	end

	if nodeMax and nodeCurr then
		nodeSource.onChildAdded = function () end;
	end
	
	nodeChild.onUpdate = update;
	update();
end

function onMenuSelection(selection)
	if selection == 4 then
		setCurrentValue(0);
	end
end

function update()
	updateSlots();
	
	if self.onValueChanged then
		self.onValueChanged();
	end
end

function onWheel(notches)
	if not isReadOnly() then
		if not OptionsManager.isMouseWheelEditEnabled() then
			return false;
		end

		adjustCounter(notches);
		return true;
	end
end

function onClickDown(button, x, y)
	if not isReadOnly() then
		return true;
	end
end

function onClickRelease(button, x, y)
	if not isReadOnly() then
		local m = getMaxValue();
		local c = getCurrentValue();

		local nClickH = math.floor(x / nSpacing) + 1;
		local nClickV;
		if m > nMaxSlotRow then
			nClickV	= math.floor(y / nSpacing);
		else
			nClickV = 0;
		end
		local nClick = (nClickV * nMaxSlotRow) + nClickH;

		if nClick > c then
			adjustCounter(1);
		else
			adjustCounter(-1);
		end

		return true;
	end
end

function updateSlots()
	local m = getMaxValue();
	local o = getOverflowValue();
	local c = getCurrentValue();
	
	print("MOC = "..m.." "..o.." "..c);
	
	if #slots ~= m+o then
		-- Clear
		for _,v in ipairs(slots) do
			v.destroy();
		end
		slots = {};

		-- Build slots
		for i = 1, m+o do
			local widget = nil;

			if (i <= m and i > c) then 
				widget = addBitmapWidget(stateicons[1].off[1]);
			elseif (i <= m and i <= c) then 
				widget = addBitmapWidget(stateicons[1].on[1]);
			elseif (i > m and i > c) then 
				widget = addBitmapWidget(stateicons[1].overflow_off[1]);
			else
				widget = addBitmapWidget(stateicons[1].overflow_on[1]);
			end

			local nW = (i - 1) % nMaxSlotRow;
			local nH = math.floor((i - 1) / nMaxSlotRow);
			local nX = (nSpacing * nW) + math.floor(nSpacing / 2);
			local nY;
			if m+o > nMaxSlotRow then
				nY = (nSpacing * nH) + math.floor(nSpacing / 2);
			else
				nY = (nSpacing * nH) + nSpacing;
			end
			widget.setPosition("topleft", nX, nY);

			slots[i] = widget;
		end
		
		if m+o > nMaxSlotRow then
			setAnchoredWidth(nMaxSlotRow * nSpacing);
			setAnchoredHeight((math.floor((m+o - 1) / nMaxSlotRow) + 1) * nSpacing);
		else
			setAnchoredWidth(nMaxSlotRow * nSpacing);
			setAnchoredHeight(nSpacing * 2);
		end
	else
		for i = 1, m+o do
			if (i <= m and i > c) then 
				slots[i].setBitmap(stateicons[1].off[1]);
				print("Off");
			elseif (i <= m and i <= c) then 
				slots[i].setBitmap(stateicons[1].on[1]);
				print("On");
			elseif (i > m and i > c) then 
				slots[i].setBitmap(stateicons[1].overflow_off[1]);
				print("RdOff");
			else
				slots[i].setBitmap(stateicons[1].overflow_on[1]);
				print("RdOn");
			end
		end
	end
end

function adjustCounter(nAdj)
	local m = getMaxValue();
	local o = getOverflowValue();
	local c = getCurrentValue() + nAdj;
	
	if c > m+o then
		setCurrentValue(m+o);
	elseif c < 0 then
		setCurrentValue(0);
	else
		setCurrentValue(c);
	end
end

function checkBounds()
	local m = getMaxValue();
	local o = getOverflowValue();
	local c = getCurrentValue();
	
	if c > m+o then
		setCurrentValue(m+o);
	elseif c < 0 then
		setCurrentValue(0);
	end
end

function getMaxValue()
	if nodeMax then
		return nodeMax.getValue();
	end
	return 0;
end

function setMaxValue(nMax)
	if nodeMax then
		nodeMax.setValue(nMax);
	end
end

function getCurrentValue()
	if nodeCurr then
		return nodeCurr.getValue();
	end
	return 0;
end

function setCurrentValue(nCount)
	if nodeCurr then
		nodeCurr.setValue(nCount);
	end
end

function getOverflowValue()
	if nodeOverflow then
		return nodeOverflow.getValue();
	end
	return 0;
end

function setOverflowValue(nCount)
	if nodeOverflow then
		nodeOverflow.setValue(nCount);
	end
end


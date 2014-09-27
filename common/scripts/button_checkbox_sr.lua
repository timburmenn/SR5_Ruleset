-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

slots = {};
local nMaxSlotRow = 1;
local nDefaultSpacing = 10;
local nSpacing = nDefaultSpacing;

local nodeCurr = nil;
local sCurrNodeName = "";

function onInit()
	-- Get any custom fields
	if sourcefields then
		if sourcefields[1].value then
			sCurrNodeName = sourcefields[1].value[1];
		end
	end
	
	-- Synch to the data nodes
	local nodeWin = window.getDatabaseNode();
	if nodeWin then
		local bWatchUpdate = false;
		if sCurrNodeName ~= "" then
			nodeCurr = nodeWin.createChild(sCurrNodeName, "number");
			if nodeCurr then
				nodeCurr.onUpdate = update;
			else
				bWatchUpdate = true;
			end
		end
		if bWatchUpdate then
			nodeWin.onChildAdded = registerUpdate;
		end
	end
	
	updateCheckBox();

	registerMenuItem(Interface.getString("counter_menu_clear"), "erase", 4);
end

function registerUpdate(nodeSource, nodeChild)
	if nodeChild.getName() == sCurrNodeName then
		nodeCurr = nodeChild;
	else
		return;
	end

	if nodeCurr then
		nodeSource.onChildAdded = function () end;
	end
	
	nodeChild.onUpdate = update;
	update();
end

function update()
	updateCheckBox();
	
	if self.onValueChanged then
		self.onValueChanged();
	end
end

function onClickDown(button, x, y)
	if not isReadOnly() then
		return true;
	end
end

function onClickRelease(button, x, y)
	if not isReadOnly() then
		local c = getCurrentValue();

		if c == 1 then
			setCurrentValue(0)
		else
			setCurrentValue(1)
		end

		return true;
	end
end

function updateCheckBox()
	local m = 1;
	local c = getCurrentValue();
	
	if #slots ~= m then
		-- Clear
		for _,v in ipairs(slots) do
			v.destroy();
		end
		slots = {};

		-- Build slots
		for i = 1, m do
			local widget = nil;

			if i > c then
				widget = addBitmapWidget(stateicons[1].off[1]);
			else
				widget = addBitmapWidget(stateicons[1].on[1]);
			end

			local nW = (i - 1) % nMaxSlotRow;
			local nH = math.floor((i - 1) / nMaxSlotRow);
			local nX = (nSpacing * nW) + math.floor(nSpacing / 2);
			local nY;
			if m > nMaxSlotRow then
				nY = (nSpacing * nH) + math.floor(nSpacing / 2);
			else
				nY = (nSpacing * nH) + nSpacing;
			end
			widget.setPosition("topleft", nX, nY);

			slots[i] = widget;
		end
		
		if m > nMaxSlotRow then
			setAnchoredWidth(nMaxSlotRow * nSpacing);
			setAnchoredHeight((math.floor((m - 1) / nMaxSlotRow) + 1) * nSpacing);
		else
			setAnchoredWidth(nMaxSlotRow * nSpacing);
			setAnchoredHeight(nSpacing * 2);
		end
	else
		for i = 1, m do
			if i > c then
				slots[i].setBitmap(stateicons[1].off[1]);
			else
				slots[i].setBitmap(stateicons[1].on[1]);
			end
		end
	end
end

function adjustCounter(nAdj)
	local c = getCurrentValue() + nAdj;
	
	if c > m then
		setCurrentValue(m);
	elseif c < 0 then
		setCurrentValue(0);
	else
		setCurrentValue(c);
	end
end

function checkBounds()
	local m = getMaxValue();
	local c = getCurrentValue();
	
	if c > m then
		setCurrentValue(m);
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

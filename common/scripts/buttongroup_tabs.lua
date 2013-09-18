-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local topWidget = nil;
local tabIndex = 1;

local aTabs = {};

local aTabOffset = { 7, 41 };
local aHelperOffset = { 8, 7 };
local nTabHeight = 67;
local nMargins = 25;

function onInit()
	-- Create a helper graphic widget to indicate that the selected tab is on top
	topWidget = addBitmapWidget("tabtop");
	topWidget.setVisible(false);

	-- Deactivate all labels
	if tab and type(tab) == "table" then
		for n, v in ipairs(tab) do
			if type(v) == "table" then
				setTab(n, v.subwindow[1], v.icon[1]);
			end
		end
	end

	if activate then
		activateTab(activate[1]);
	else
		activateTab(1);
	end
end

function hideControls(index)
	if aTabs[index] then
		for _,v in ipairs(aTabs[index].controls) do
			window[v].setVisible(false);
			if window[v].onTabVisChanged then
				window[v].onTabVisChanged(false);
			end
		end
	end
end

function showControls(index)
	if aTabs[index] then
		for _,v in ipairs(aTabs[index].controls) do
			window[v].setVisible(true);
			if window[v].onTabVisChanged then
				window[v].onTabVisChanged(true);
			end
		end
	end
end

function activateTab(index)
	if tabIndex >= 1 and tabIndex <= #aTabs then
		-- Hide active tab, fade text labels
		aTabs[tabIndex].widget.setColor("80ffffff");
		hideControls(tabIndex);
	end

	-- Set new index
	tabIndex = tonumber(index);

	-- Move helper graphic into position
	topWidget.setPosition("topleft", aHelperOffset[1], (nTabHeight * (tabIndex - 1)) + aHelperOffset[2]);
	if tabIndex == 1 then
		topWidget.setVisible(false);
	else
		topWidget.setVisible(true);
	end
		
	if tabIndex >= 1 and tabIndex <= #aTabs then
		-- Activate text label and subwindow
		aTabs[tabIndex].widget.setColor("ffffffff");
		showControls(tabIndex);
	end

	if self.onTabChanged then
		self.onTabChanged(tabIndex);
	end
end

function setTab(index, sSub, sGraphic)
	if aTabs[index] then
		if sSub and sGraphic then
			if index == tabIndex then
				hideControls(tabIndex);
				aTabs[index].sub = sSub;
				aTabs[index].controls = StringManager.split(sSub, ",", true);
				showControls(tabIndex);
			else
				aTabs[index].sub = sSub;
				aTabs[index].controls = StringManager.split(sSub, ",", true);
			end
			
			aTabs[index].widget.destroy();
			aTabs[index].icon = sGraphic;
			aTabs[index].widget = addBitmapWidget(sGraphic);
			aTabs[index].widget.setPosition("topleft", aTabOffset[1], (nTabHeight * (index - 1)) + aTabOffset[2]);
			if index == tabIndex then
				aTabs[index].widget.setColor("ffffffff");
			else
				aTabs[index].widget.setColor("80ffffff");
			end
		else
			aTabs[index].widget.destroy();
			aTabs[index] = nil;
		end
	else
		if sSub and sGraphic then
			local rTab = {};
			
			rTab.sub = sSub;
			rTab.controls = StringManager.split(sSub, ",", true);
			
			rTab.icon = sGraphic;
			rTab.widget = addBitmapWidget(sGraphic);
			rTab.widget.setPosition("topleft", aTabOffset[1], (nTabHeight * (index - 1)) + aTabOffset[2]);
			if index == tabIndex then
				rTab.widget.setColor("ffffffff");
			else
				rTab.widget.setColor("80ffffff");
			end
			
			aTabs[index] = rTab;

			if index == tabIndex then
				showControls(tabIndex);
			end
		end
	end
	
	local nMax = 0;
	for k,_ in pairs(aTabs) do
		nMax = math.max(k, nMax);
	end
	setAnchoredHeight(nMargins + (nTabHeight * nMax));
	
	if tabIndex > nMax then
		activateTab(nMax);
	end
end

function getIndex()
	return tabIndex;
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	local i = math.ceil(y / nTabHeight);

	if i >= 1 and i <= #aTabs then
		activateTab(i);
	end
	
	return true;
end

function onDoubleClick(x, y)
	-- Emulate click
	onClickRelease(1, x, y);
end

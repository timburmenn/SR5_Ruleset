-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local stackcolumns = 2;
local stackiconsize = { 47, 27 };
local stackspacing = { 0, 0 };
local stackoffset = { 5, 2 };

local stacktodockspacing = 5;

local dockiconsize = { 91, 86 };
local dockspacing = 2;
local dockoffset = { 5, 0 };

local stackcontrols = {};
local dockcontrols = {};
local subdockcontrols = {};

local delayedCreate = {};

-- Chat window registration for general purpose message dispatching
function registerContainerWindow(w)
	window = w;

	-- Create controls that were requested while the window wasn't ready
	for _,v in pairs(delayedCreate) do
		v();
	end
	
	-- Add event handler for the window resize event
	window.onSizeChanged = updateControls;
end

-- Recalculate control locations
function updateControls()
	local maxy = 0;

	-- Stack (the small icons)
	for k,v in ipairs(stackcontrols) do
		local n = k - 1;
		local nRow = math.floor(n / stackcolumns);
		local nColumn = n % stackcolumns;
	
		local nOffsetX = ((stackspacing[1] + stackiconsize[1]) * nColumn) + stackoffset[1];
		local nOffsetY = ((stackspacing[2] + stackiconsize[2]) * nRow) + stackoffset[2];
		v.setStaticBounds(nOffsetX, nOffsetY, stackiconsize[1], stackiconsize[2]);
		
		maxy = ((stackspacing[2] + stackiconsize[2]) * (nRow + 1)) + stackoffset[2];
	end
	maxy = maxy + stacktodockspacing;
	
	-- Calculate remaining available area
	local winw, winh = window.getSize();
	local availableheight = winh - maxy;
	local controlcount = #dockcontrols + #subdockcontrols;
	local neededheight = (dockspacing + dockiconsize[2]) * controlcount;
	
	local scaling = 1;
	if availableheight < neededheight then
		scaling = (availableheight - dockspacing * controlcount) / (dockiconsize[2] * controlcount);
	end

	-- Dock (the resource books)
	for k,v in pairs(dockcontrols) do
		local n = k-1;
		v.setStaticBounds(dockoffset[1] + (1-scaling)*dockiconsize[1]/2, maxy + (dockspacing + math.floor(dockiconsize[2]*scaling)) * n + dockoffset[2], math.floor(dockiconsize[1]*scaling), math.floor(dockiconsize[2]*scaling));
	end

	-- Subdock (the token icon)
	for k,v in pairs(subdockcontrols) do
		v.setStaticBounds(dockoffset[1] + (1-scaling)*dockiconsize[1]/2, winh - dockspacing*(k-1) - math.floor(dockiconsize[2]*scaling) * k + dockoffset[2], math.floor(dockiconsize[1]*scaling), math.floor(dockiconsize[2]*scaling));
	end
end

function registerStackShortcut(iconNormal, iconPressed, tooltipText, className, recordName)
	function createFunc()
		createStackShortcut(iconNormal, iconPressed, tooltipText, className, recordName);
	end

	if window == nil then
		table.insert(delayedCreate, createFunc);
	else
		createFunc();
	end
end

function createStackShortcut(iconNormal, iconPressed, tooltipText, className, recordName)
	local control = window.createControl("desktop_stackitem", tooltipText);
	
	table.insert(stackcontrols, control);
	
	control.setIcons(iconNormal, iconPressed);
	control.setValue(className, recordName or "");
	control.setTooltipText(tooltipText);
	
	updateControls();
end

function registerDockShortcut(iconNormal, iconPressed, tooltipText, className, recordName, useSubdock)
	function createFunc()
		createDockShortcut(iconNormal, iconPressed, tooltipText, className, recordName, useSubdock);
	end

	if window == nil then
		table.insert(delayedCreate, createFunc);
	else
		createFunc();
	end
end

function createDockShortcut(iconNormal, iconPressed, tooltipText, className, recordName, useSubdock)
	local control = window.createControl("desktop_dockitem", tooltipText);
	
	if useSubdock then
		table.insert(subdockcontrols, control);
	else
		table.insert(dockcontrols, control);
	end
	
	control.setIcons(iconNormal, iconPressed);
	control.setValue(className, recordName or "");
	control.setTooltipText(tooltipText);
	
	updateControls();
end


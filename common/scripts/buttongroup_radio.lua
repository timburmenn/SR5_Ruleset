-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sourcenode = nil;
local sourcenodename = "";

local labels = {};
local values = {};

local widgetfont = "sheetlabel";
local option_width = 50;
local labelwidgets = {};
local boxwidgets = {};

local radio_index = 0;
local default_index = 1;

function onInit()
	-- Get any custom fields
	local labeltext = "";
	local valuetext = "";
	local defaultval = "";
	local width = option_width;
	if parameters then
		if parameters[1].font then
			widgetfont = parameters[1].font[1];
		end
		if parameters[1].optionwidth then
			width = tonumber(parameters[1].optionwidth[1]);
		end

		if parameters[1].labels then
			labeltext = parameters[1].labels[1];
		end
		if parameters[1].values then
			valuetext = parameters[1].values[1];
		end
		if parameters[1].defaultindex then
			defaultval = parameters[1].defaultindex[1];
		end

		if parameters[1].sourcenode then
			sourcenodename = parameters[1].sourcenode[1];
		end
	end
	if font then
		widgetfont = font[1];
	end
	
	-- Initialize the labels, values, widgets and size
	initialize(labeltext, valuetext, width, tonumber(defaultval) or 1);

	-- SET ACCESS RIGHTS
	local bLocked = false;
	
	-- Get the data node set up and synched
	if not sourceless then
		sourcenodename = getName();
		if source then
			if source[1].name then
				sourcenodename = source[1].name[1];
			end
		end
	end
	if sourcenodename ~= "" then
		-- DETERMINE DB READ-ONLY STATE
		local node = window.getDatabaseNode();
		if node.isReadOnly() then
			bLocked = true;
		end

		-- Catch any future node updates
		sourcenode = node.createChild(sourcenodename, "string");
		if sourcenode then
			sourcenode.onUpdate = onSourceUpdate;
		elseif node then
			node.onChildAdded = registerUpdate;
		end
		
		-- Synchronize to the current source value
		synch_index(getStringValue());
	end
	
	-- Set the correct read only value
	if bLocked then
		setReadOnly(bLocked);
	end
	
	-- Set the right display
	updateDisplay();
end

function registerUpdate(nodeSource, nodeChild)
	if nodeChild.getName() == sourcenodename then
		nodeSource.onChildAdded = function () end;
		nodeChild.onUpdate = onSourceUpdate;
		sourcenode = nodeChild;
		update();
	end
end

function initialize(sLabels, sValues, nOptionWidth, varDefault)
	-- Clean up previous values, if any
	labels = {};
	values = {};
	for k, v in pairs(labelwidgets) do
		v.destroy();
	end
	labelwidgets = {};
	for k, v in pairs(boxwidgets) do
		v.destroy();
	end
	boxwidgets = {};
	
	-- Parse the labels to determine the options we should show
	if sLabels then
		labels = StringManager.split(sLabels, "|");
	end
	
	-- Parse the values to determine the underlying data
	if sValues then
		values = StringManager.split(sValues, "|");
	end
	
	-- Set the option width
	if nOptionWidth then
		option_width = nOptionWidth;
	end
	
	-- Create a set of widgets for each option
	for k,v in ipairs(values) do
		-- Create a label widget
		local w = 0;
		local h = 0;
		if labels[k] then
			labelwidgets[k] = addTextWidget(widgetfont, labels[k]);
			w,h = labelwidgets[k].getSize();
			labelwidgets[k].setPosition("topleft", ((k-1)*option_width)+(w/2)+20, h/2);
		end
		
		-- Create the checkbox widget
		boxwidgets[k] = addBitmapWidget(stateicons[1].off[1]);
		if h == 0 then
			w,h = boxwidgets[k].getSize();
		end
		boxwidgets[k].setPosition("topleft", ((k-1)*option_width)+10, h/2);
	end

	-- Set the width of the control
	setAnchoredWidth(#values * option_width);
	
	-- Set the selected value
	if varDefault then
		if type(varDefault) == "string" then
			synch_index(sDefault);
			default_index = radio_index;
		elseif type(varDefault) == "number" then
			radio_index = varDefault;
			default_index = varDefault;
		end
	end

	-- Set the right display
	updateDisplay();
end

function synch_index(srcval)
	local match = 0;
	for k, v in pairs(values) do
		if v == srcval then
			match = k;
		end
	end

	if match > 0 then
		radio_index = match;
	else
		radio_index = default_index;
	end
end

function updateDisplay()
	for k,v in ipairs(boxwidgets) do
		if radio_index == k then
			v.setBitmap(stateicons[1].on[1]);
		else
			v.setBitmap(stateicons[1].off[1]);
		end
	end
end

function update(val)
	synch_index(val);
	updateDisplay();

	if self.onValueChanged then
		self.onValueChanged();
	end
end

function onSourceUpdate()
	update(sourcenode.getValue());
end

function getDatabaseNode()
	return sourcenode;
end

function setStringValue(srcval)
	if sourcenode then
		sourcenode.setValue(srcval);
	else
		update(srcval);
	end
end

function getStringValue()
	local srcval = "";

	if sourcenode then
		srcval = sourcenode.getValue();
	else
		srcval = values[radio_index];
	end

	return srcval;
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	-- If we're in read-only mode, then don't change
	if isReadOnly() then
		return true;
	end
	
	-- Enable the option if different than current selection
	local k = math.floor(x / option_width) + 1;
	if radio_index ~= k then
		setIndex(k);
	end
	
	return true;
end

function getIndex()
	return radio_index;
end

function setIndex(index)
	if index > 0 and index <= #values then
		setStringValue(values[index]);
	else
		setStringValue(values[default_index]);
	end
end

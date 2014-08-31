-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local srcnode = nil;
local srcnodename = "";
local lockflag = false;

local cycleindex = 0;

local labels = {};
local values = {};
local defaultval = "-";

function onInit()
	-- GET PARAMETERS
	local sInitialValue = "";
	if parameters then
		if parameters[1].values then
			values = StringManager.split(parameters[1].values[1], "|");
		end
		if parameters[1].labels then
			labels = StringManager.split(parameters[1].labels[1], "|");
		end
		if parameters[1].defaultlabel then
			defaultval = parameters[1].defaultlabel[1];
			if type(defaultval) ~= "string" then
				defaultval = "";
			end
		end
		if parameters[1].defaultvalue then
			sInitialValue = parameters[1].defaultvalue[1];
		end
	end

	-- SET ACCESS RIGHTS
	if locked then
		lockflag = true;
	end
	if gmonly and not User.isHost() then
		lockflag = true;
	end
	
	-- SET UP DATA CONNECTION
	if not sourceless then
		srcnodename = getName();
		if source and source[1] and source[1].name then
			srcnodename = source[1].name[1];
		end
	end
	if srcnodename ~= "" then
		-- DETERMINE DB READ-ONLY STATE
		local node = window.getDatabaseNode();
		if node.isReadOnly() then
			lockflag = true;
		end

		-- CHECK TO SEE IF NODE EXISTS
		local nodeInitial = node.getChild(srcnodename);
		
		-- LINK TO DATABASE NODE, AND FUTURE UPDATES
		srcnode = DB.createChild(node, srcnodename, "string");
		if srcnode then
			if not nodeInitial then
				srcnode.setValue(sInitialValue);
			end
			srcnode.onUpdate = update;
		elseif node then
			node.onChildAdded = registerUpdate;
		end
		
		-- SYNCHRONIZE DATA VALUES
		synchData();
	end

	-- UPDATE DISPLAY
	updateDisplay();
end

function registerUpdate(nodeSource, nodeChild)
	if nodeChild.getName() == srcnodename then
		nodeSource.onChildAdded = function () end;
		nodeChild.onUpdate = update;
		srcnode = nodeChild;
		update();
	end
end

function synchData()
	local srcval = "";
	if srcnode then
		srcval = srcnode.getValue();
	end
	local match = 0;
	for k,v in pairs(values) do
		if v == srcval then
			match = k;
		end
	end

	if match > 0 then
		cycleindex = match;
	else
		cycleindex = 0;
	end
end

function updateDisplay()
	if cycleindex > 0 and cycleindex <= #labels then
		setValue(labels[cycleindex]);
	else
		setValue(defaultval);
	end
end

function update()
	synchData();
	updateDisplay();

	-- onValueChanged already called by stringcontrol on setValue
--	if self.onValueChanged then
--		self.onValueChanged();
--	end
end

function getDatabaseNode()
	return srcnode;
end

function setStringValue(srcval)
	if srcnode then
		srcnode.setValue(srcval);
	end
end

function getStringValue()
	if cycleindex > 0 and cycleindex <= #values then
		return values[cycleindex];
	end
	
	return "";
end

function cycleLabel(n)
	if cycleindex < #labels then
		cycleindex = cycleindex + n;
	else
		cycleindex = 0;
	end

	if srcnode then
		srcnode.setValue(getStringValue());
	else
		updateDisplay();
	end
end

function onWheel(n)
	if not OptionsManager.isMouseWheelEditEnabled() then
		return false;
	end
	if not lockflag then
		cycleLabel(n);
	end
	return true;
end


function onDoubleClick(button, x, y)
	-- If we're in read-only mode, then don't change
	if lockflag then
		return true;
	end

	-- Otherwise, cycle the label
	cycleLabel(1);
	return true;
end

function setLock(val)
	if val == nil or val == false or val == 0 then
		lockflag = false;
	else
		lockflag = true;
	end
end

function isLocked()
	return lockflag;
end

-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aGroups = {};
local aGroupSort = {};
local aOptions = {};
local aCallbacks = {};

function isMouseWheelEditEnabled()
	return isOption("MWHL", "on") or Input.isControlPressed();
end

function onInit()
	DB.addHandler("options.*", "onUpdate", onOptionChanged);

	registerOption("DCLK", true, "Client", "Mouse: Double click action", "option_entry_cycler", 
			{ labels = "Roll|Mod", values = "on|mod", baselabel = "Off", baseval = "off", default = "on" });
	registerOption("MWHL", true, "Client", "Mouse: Wheel editing", "option_entry_cycler", 
			{ labels = "Always", values = "on", baselabel = "Ctrl", baseval = "ctrl", default = "ctrl" });

	registerOption("CTAV", false, "Game (GM)", "Chat: Set GM voice to active CT", "option_entry_cycler", 
			{ labels = "On", values = "on", baselabel = "Off", baseval = "off", default = "off" });
	registerOption("SHPW", false, "Game (GM)", "Chat: Show all whispers to GM", "option_entry_cycler", 
			{ labels = "On", values = "on", baselabel = "Off", baseval = "off", default = "off" });
	registerOption("REVL", false, "Game (GM)", "Chat: Show GM rolls", "option_entry_cycler", 
			{ labels = "On", values = "on", baselabel = "Off", baseval = "off", default = "off" });
	registerOption("PCHT", false, "Game (GM)", "Chat: Show portraits", "option_entry_cycler", 
			{ labels = "On", values = "on", baselabel = "Off", baseval = "off", default = "on" });
	registerOption("TOTL", false, "Game (GM)", "Chat: Show roll totals", "option_entry_cycler", 
			{ labels = "On", values = "on", baselabel = "Off", baseval = "off", default = "on" });
	registerOption("MIID", false, "Game (GM)", "Item: Identification", "option_entry_cycler", 
			{ labels = "On", values = "on", baselabel = "Off", baseval = "off", default = "off" });
	registerOption("TBOX", false, "Game (GM)", "Table: Dice tower", "option_entry_cycler", 
			{ labels = "On", values = "on", baselabel = "Off", baseval = "off", default = "off" });
	registerOption("TFAC", false, "Game (GM)", "Token: Facing", "option_entry_cycler", 
			{ labels = "On", values = "on", baselabel = "Off", baseval = "off", default = "off" });

	registerOption("NNPC", false, "Combat (GM)", "Add: NPC numbering", "option_entry_cycler", 
			{ labels = "Append|Random", values = "append|random", baselabel = "Off", baseval = "off", default = "append" });
	registerOption("RING", false, "Combat (GM)", "Turn: Ring bell on PC turn", "option_entry_cycler", 
			{ labels = "On", values = "on", baselabel = "Off", baseval = "off", default = "off" });
	registerOption("RNDS", false, "Combat (GM)", "Turn: Stop at round start", "option_entry_cycler", 
			{ labels = "On", values = "on", baselabel = "Off", baseval = "off", default = "off" });

	registerOption("TNAM", false, "Token (GM)", "Token: Show name", "option_entry_cycler", 
			{ labels = "Tooltip|Title|Title Hover", values = "tooltip|on|hover", baselabel = "Off", baseval = "off", default = "tooltip" });
end

function populate(win)
	for keySet, rSet in pairs(aGroups) do
		local winSet = win.list.createWindow();
		if winSet then
			winSet.label.setValue(keySet);
			winSet.sort.setValue(aGroupSort[keySet]);
			
			for keyOption, rOption in pairs(rSet) do
				local winOption = winSet.options_list.createWindowWithClass(rOption.sType);
				if winOption then
					winOption.setLabel(rOption.sLabel);
					winOption.initialize(rOption.sKey, rOption.aCustom);
					winOption.setReadOnly(not (rOption.bLocal or User.isHost()));
				end
			end
			
			winSet.options_list.applySort();
		end
	end
	
	win.list.applySort();
end

function registerOption(sKey, bLocal, sGroup, sLabel, sOptionType, aCustom)
	local rOption = {};
	rOption.sKey = sKey;
	rOption.bLocal = bLocal;
	rOption.sLabel = sLabel;
	rOption.aCustom = aCustom;
	rOption.sType = sOptionType;
	
	if not aGroups[sGroup] then
		aGroups[sGroup] = {};
	end
	table.insert(aGroups[sGroup], rOption);
	
	if not aGroupSort[sGroup] then
		local nMax = 0;
		for _,v in pairs(aGroupSort) do
			nMax = math.max(v, nMax);
		end
		aGroupSort[sGroup] = nMax + 1;
	end
	
	aOptions[sKey] = rOption;
	aOptions[sKey].value = (aOptions[sKey].aCustom[default]) or "";
end

function onOptionChanged(nodeOption)
	local sKey = nodeOption.getName();
	makeCallback(sKey);
end

function registerCallback(sKey, fCallback)
	if not aCallbacks[sKey] then
		aCallbacks[sKey] = {};
	end
	
	table.insert(aCallbacks[sKey], fCallback);
end

function unregisterCallback(sKey, fCallback)
	if aCallbacks[sKey] then
		for k, v in pairs(aCallbacks[sKey]) do
			if v == fCallback then
				aCallbacks[sKey][k] = nil;
			end
		end
	end
end

function makeCallback(sKey)
	if aCallbacks[sKey] then
		for k, v in pairs(aCallbacks[sKey]) do
			v(sKey);
		end
	end
end

function setOption(sKey, sValue)
	if aOptions[sKey] then
		if aOptions[sKey].bLocal then
			CampaignRegistry["Opt" .. sKey] = sValue;
			makeCallback(sKey);
		else
			if User.isHost() or User.isLocal() then
				DB.setValue("options." .. sKey, "string", sValue);
			end
		end
	end
end

function isOption(sKey, sTargetValue)
	return (getOption(sKey) == sTargetValue);
end

function getOption(sKey)
	if aOptions[sKey] then
		local sValue = "";
		if aOptions[sKey].bLocal then
			if CampaignRegistry["Opt" .. sKey] then
				sValue = CampaignRegistry["Opt" .. sKey];
			end
		else
			sValue = DB.getValue("options." .. sKey, "");
		end
		if sValue ~= "" then
			return sValue;
		end

		return (aOptions[sKey].aCustom.default) or "";
	end

	return "";
end

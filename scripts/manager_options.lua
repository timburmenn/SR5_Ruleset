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

function deleteOption(sKey)
	if aOptions[sKey] then
		local bFound = false;
		for kGroup,vGroup in pairs(aGroups) do
			for kOption, vOption in pairs(vGroup) do
				if vOption.sKey == sKey then
					bFound = true;
					table.remove(vGroup, kOption);
					break;
				end
			end
			if bFound then
				local bRemaining = false;
				for _, _ in pairs(vGroup) do
					bRemaining = true;
					break;
				end
				if not bRemaining then
					aGroups[kGroup] = nil;
					aGroupSort[kGroup] = nil;
				end
				break;
			end
		end
		
		aOptions[sKey] = nil;
	end
end

function registerOption(sKey, bLocal, sGroup, sLabel, sOptionType, aCustom)
	deleteOption(sKey);
	
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

function registerOption2(sKey, bLocal, sGroupRes, sLabelRes, sOptionType, aCustom)
	deleteOption(sKey);
	
	if aCustom.labels then
		local aLabels = StringManager.split(aCustom.labels, "|");
		for k,v in ipairs(aLabels) do
			local sLabel = Interface.getString(v);
			if sLabel ~= "" then
				aLabels[k] = Interface.getString(v);
			end
		end
		aCustom.labels = table.concat(aLabels, "|");
	end
	if aCustom.labelsraw then
		aCustom.labels = aCustom.labelsraw;
	end
	aCustom.baselabel = Interface.getString(aCustom.baselabel);
	
	local rOption = {};
	rOption.sKey = sKey;
	rOption.bLocal = bLocal;
	rOption.sLabel = Interface.getString(sLabelRes);
	rOption.aCustom = aCustom;
	rOption.sType = sOptionType;
	
	local sGroup = Interface.getString(sGroupRes);
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
	if not User.isLocal() then
		CampaignRegistry["Opt" .. sKey] = getOption(sKey);
	end
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
		CampaignRegistry["Opt" .. sKey] = sValue;
		makeCallback(sKey);
		if not aOptions[sKey].bLocal then
			if User.isHost() then
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
		if User.isLocal() then
			if User.getCampaignName() ~= "" then
				if CampaignRegistry["Opt" .. sKey] then
					sValue = CampaignRegistry["Opt" .. sKey];
				end
			end
		else
			if aOptions[sKey].bLocal then
				if CampaignRegistry["Opt" .. sKey] then
					sValue = CampaignRegistry["Opt" .. sKey];
				end
			else
				sValue = DB.getValue("options." .. sKey, "");
			end
		end
		if sValue ~= "" then
			return sValue;
		end

		return (aOptions[sKey].aCustom.default) or "";
	end

	return "";
end

function addOptionValue(sKey, sLabel, sValue, bUseResource)
	local rOption = aOptions[sKey];
	if rOption and rOption.aCustom then
		if bUseResource then
			sLabel = Interface.getString(sLabel);
		end
		
		if rOption.aCustom.labels and (rOption.aCustom.labels ~= "") then
			rOption.aCustom.labels = rOption.aCustom.labels .. "|" .. sLabel;
		else
			rOption.aCustom.labels = sLabel;
		end
		
		if rOption.aCustom.values and (rOption.aCustom.values ~= "") then
			rOption.aCustom.values = rOption.aCustom.values .. "|" .. sValue;
		else
			rOption.aCustom.values = sValue;
		end
	end
end

function setOptionDefault(sKey, sDefaultValue)
	local rOption = aOptions[sKey];
	if rOption and rOption.aCustom then
		aOptions[sKey].aCustom.default = sDefaultValue;
	end
end

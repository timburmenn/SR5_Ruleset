-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local nTokenDragUnits = nil;

function onInit()
	if User.isHost() then
		Token.onContainerChanged = onContainerChanged;
		Token.onTargetUpdate = onTargetUpdate;

		DB.addHandler("options.TFAC", "onUpdate", onOptionChanged);

		DB.addHandler(CombatManager.CT_LIST .. ".*", "onDelete", onCTDelete);
		DB.addHandler(CombatManager.CT_LIST .. ".*.active", "onUpdate", updateActive);
		DB.addHandler(CombatManager.CT_LIST .. ".*.space", "onUpdate", updateSpaceReach);
		DB.addHandler(CombatManager.CT_LIST .. ".*.reach", "onUpdate", updateSpaceReach);
	else
		DB.addHandler("charsheet.*", "onDelete", deleteOwner);
		DB.addHandler("charsheet.*", "onObserverUpdate", updateOwner);
	end

	Token.onAdd = onAdd;
	Token.onDelete = onTokenDelete;
	Token.onDrop = onDrop;
	Token.onScaleChanged = onScaleChanged;
	Token.onHover = onHover;
	Token.onDoubleClick = onDoubleClick;

	DB.addHandler(CombatManager.CT_LIST .. ".*.tokenrefid", "onUpdate", updateAttributes);
	DB.addHandler(CombatManager.CT_LIST .. ".*.friendfoe", "onUpdate", updateFaction);
	DB.addHandler(CombatManager.CT_LIST .. ".*.name", "onUpdate", updateName);
	
	DB.addHandler("options.TNAM", "onUpdate", onOptionChanged);
end

function linkToken(nodeCT, newTokenInstance)
	local nodeContainer = nil;
	if newTokenInstance then
		nodeContainer = newTokenInstance.getContainerNode();
	end
	
	if nodeContainer then
		DB.setValue(nodeCT, "tokenrefnode", "string", nodeContainer.getNodeName());
		DB.setValue(nodeCT, "tokenrefid", "string", newTokenInstance.getId());
		DB.setValue(nodeCT, "tokenscale", "number", newTokenInstance.getScale());
	else
		DB.setValue(nodeCT, "tokenrefnode", "string", "");
		DB.setValue(nodeCT, "tokenrefid", "string", "");
		DB.setValue(nodeCT, "tokenscale", "number", 1);
	end

	return true;
end
function onOptionChanged(nodeOption)
	for _, nodeCT in pairs(DB.getChildren(CombatManager.CT_LIST)) do
		local tokenCT = CombatManager.getTokenFromCT(nodeCT);
		if tokenCT then
			updateAttributesHelper(tokenCT, nodeCT);
		end
	end
end

function onCTDelete(nodeCT)
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
		if sClass ~= "charsheet" then
			tokenCT.delete();
		else
			local aWidgets = getWidgetList(tokenCT);
			for _, vWidget in pairs(aWidgets) do
				vWidget.destroy();
			end

			tokenCT.setActive(false);
			tokenCT.setActivable(false);
			tokenCT.setTargetsVisible(false);
			tokenCT.setModifiable(true);
			tokenCT.setVisible(nil);

			tokenCT.setName();
			tokenCT.setGridSize(0);
			tokenCT.removeAllUnderlays();
		end
	end
end

function onTokenDelete(tokenMap)
	local wImage = Interface.findWindow("imagewindow", tokenMap.getContainerNode().getParent());
	if wImage then
		wImage.updateDisplay();
	end

	if User.isHost() then
		CombatManager.onTokenDelete(tokenMap);
		PartyManager.onTokenDelete(tokenMap);
	end
end

function onAdd(tokenMap)
	updateAttributesFromToken(tokenMap);
	
	if User.isHost() then
		if OptionsManager.getOption("TASG") ~= "off" then
			TokenManager.autoTokenScale(tokenMap);
		end
	end

	local wImage = Interface.findWindow("imagewindow", tokenMap.getContainerNode().getParent());
	if wImage then
		wImage.updateDisplay();
	end
end

function onContainerChanged(tokenCT, nodeOldContainer, nOldId)
	if nodeOldContainer then
		local nodeCT = CombatManager.getCTFromTokenRef(nodeOldContainer, nOldId);
		if nodeCT then
			local nodeNewContainer = tokenCT.getContainerNode();
			if nodeNewContainer then
				DB.setValue(nodeCT, "tokenrefnode", "string", nodeNewContainer.getNodeName());
				DB.setValue(nodeCT, "tokenrefid", "string", tokenCT.getId());
				DB.setValue(nodeCT, "tokenscale", "number", tokenCT.getScale());
			else
				DB.setValue(nodeCT, "tokenrefnode", "string", "");
				DB.setValue(nodeCT, "tokenrefid", "string", "");
				DB.setValue(nodeCT, "tokenscale", "number", 1);
			end
		end
	end
	local nodePS = PartyManager.getNodeFromTokenRef(nodeOldContainer, nOldId);
	if nodePS then
		local nodeNewContainer = tokenCT.getContainerNode();
		if nodeNewContainer then
			DB.setValue(nodePS, "tokenrefnode", "string", nodeNewContainer.getNodeName());
			DB.setValue(nodePS, "tokenrefid", "string", tokenCT.getId());
			DB.setValue(nodePS, "tokenscale", "number", tokenCT.getScale());
		else
			DB.setValue(nodePS, "tokenrefnode", "string", "");
			DB.setValue(nodePS, "tokenrefid", "string", "");
			DB.setValue(nodePS, "tokenscale", "number", 1);
		end
	end
end

function onWheelHelper(tokenCT, notches)
	if not tokenCT then
		return;
	end
	
	if Input.isShiftPressed() then
		newscale = math.floor(tokenCT.getScale() + notches);
		if newscale < 1 then
			newscale = 1;
		end
	else
		newscale = tokenCT.getScale() + (notches * 0.1);
		if newscale < 0.1 then
			newscale = 0.1;
		end
	end
	
	tokenCT.setScale(newscale);
end

function onWheelCT(nodeCT, notches)
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		onWheelHelper(tokenCT, notches);
	end
end

function onDrop(tokenCT, draginfo)
	local nodeCT = CombatManager.getCTFromToken(tokenCT);
	if nodeCT then
		CombatManager.onDrop("ct", nodeCT.getNodeName(), draginfo);
	else
		if draginfo.getType() == "targeting" then
			ChatManager.SystemMessage(Interface.getString("ct_error_targetingunlinkedtoken"));
		end
	end
end

function onScaleChanged(tokenCT)
	local nodeCT = CombatManager.getCTFromToken(tokenCT);

	if User.isHost() then
		if nodeCT then
			DB.setValue(nodeCT, "tokenscale", "number", tokenCT.getScale());
		end
		local nodePS = PartyManager.getNodeFromToken(tokenCT);
		if nodePS then
			DB.setValue(nodePS, "tokenscale", "number", tokenCT.getScale());
		end
	end
	
	if nodeCT then
		updateNameScale(tokenCT);
		if TokenManager2 then
			TokenManager2.onScaleChanged(tokenCT, nodeCT);
		end
	end
end

function onHover(tokenMap, bOver)
	local nodeCT = CombatManager.getCTFromToken(tokenMap);
	if nodeCT then
		local sOptName = OptionsManager.getOption("TNAM");
		
		local aWidgets = {};
		if sOptName == "hover" then
			aWidgets["name"] = tokenMap.findWidget("name");
			aWidgets["ordinal"] = tokenMap.findWidget("ordinal");
		end

		for _, vWidget in pairs(aWidgets) do
			vWidget.setVisible(bOver);
		end
		
		if TokenManager2 then
			TokenManager2.onHover(tokenMap, nodeCT, bOver);
		end
	end
end

function onDoubleClick(tokenMap, vImage)
	local nodeCT = CombatManager.getCTFromToken(tokenMap);
	if nodeCT then
		local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
		if sClass == "charsheet" then
			if DB.isOwner(sRecord) then
				Interface.openWindow(sClass, sRecord);
				vImage.clearSelectedTokens();
			end
		else
			if User.isHost() or (DB.getValue(nodeCT, "friendfoe", "") == "friend") then
				Interface.openWindow("npc", nodeCT);
				vImage.clearSelectedTokens();
			end
		end
	end
end

function onTargetUpdate(tokenMap)
	TargetingManager.onTargetUpdate(tokenMap);
end

function updateAttributesFromToken(tokenMap)
	local nodeCT = CombatManager.getCTFromToken(tokenMap);
	if nodeCT then
		updateAttributesHelper(tokenMap, nodeCT);
	end
	
	if User.isHost() then
		local nodePS = PartyManager.getNodeFromToken(tokenMap);
		if nodePS then
			tokenMap.setTargetable(false);
			tokenMap.setActivable(true);
			tokenMap.setActive(false);
			tokenMap.setVisible(true);
			
			tokenMap.setName(DB.getValue(nodePS, "name", ""));
		end
	end
end

function updateAttributes(nodeField)
	local nodeCT = nodeField.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		updateAttributesHelper(tokenCT, nodeCT);
	end
end

function updateAttributesHelper(tokenCT, nodeCT)
	if User.isHost() then
		tokenCT.setTargetable(true);
		tokenCT.setActivable(true);
		
		if OptionsManager.isOption("TFAC", "on") then
			tokenCT.setOrientationMode("facing");
		else
			tokenCT.setOrientationMode();
		end
		
		updateActiveHelper(tokenCT, nodeCT);
		updateFactionHelper(tokenCT, nodeCT);
		updateSizeHelper(tokenCT, nodeCT);
	else
		updateOwnerHelper(tokenCT, nodeCT);
	end
	
	updateNameHelper(tokenCT, nodeCT);
	updateTooltip(tokenCT, nodeCT);
	if TokenManager2 then
		TokenManager2.updateAttributesHelper(tokenCT, nodeCT);
	end
end

function updateTooltip(tokenCT, nodeCT)
	if TokenManager2 and TokenManager2.updateTooltip then
		TokenManager2.updateTooltip(tokenCT, nodeCT);
		return;
	end
	
	if User.isHost() then
		local sOptTNAM = OptionsManager.getOption("TNAM");
		
		local aTooltip = {};
		if sOptTNAM == "tooltip" then
			table.insert(aTooltip, DB.getValue(nodeCT, "name", ""));
		end
		
		tokenCT.setName(table.concat(aTooltip, "\r"));
	end
end

function updateName(nodeName)
	local nodeCT = nodeName.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		updateNameHelper(tokenCT, nodeCT);
		updateTooltip(tokenCT, nodeCT);
	end
end

function updateNameHelper(tokenCT, nodeCT)
	local sOptTNAM = OptionsManager.getOption("TNAM");
	
	local sName = DB.getValue(nodeCT, "name", "");
	local aWidgets = getWidgetList(tokenCT, "name");
	
	if sOptTNAM == "off" or sOptTNAM == "tooltip" then
		for _, vWidget in pairs(aWidgets) do
			vWidget.destroy();
		end
	else
		local w, h = tokenCT.getSize();
		if w > 10 then
			local nStarts, _, sNumber = string.find(sName, " ?(%d+)$");
			if nStarts then
				sName = string.sub(sName, 1, nStarts - 1);
			end
			local bWidgetsVisible = (sOptTNAM == "on");

			local widgetName = aWidgets["name"];
			if not widgetName then
				widgetName = tokenCT.addTextWidget("mini_name", "");
				widgetName.setPosition("top", 0, -2);
				widgetName.setFrame("mini_name", 5, 1, 5, 1);
				widgetName.setName("name");
			end
			if widgetName then
				widgetName.setVisible(bWidgetsVisible);
				widgetName.setText(sName);
				widgetName.setTooltipText(sName);
			end
			updateNameScale(tokenCT);

			if sNumber then
				local widgetOrdinal = aWidgets["ordinal"];
				if not widgetOrdinal then
					widgetOrdinal = tokenCT.addTextWidget("sheetlabel", "");
					widgetOrdinal.setPosition("topright", -4, -2);
					widgetOrdinal.setFrame("tokennumber", 7, 1, 7, 1);
					widgetOrdinal.setName("ordinal");
				end
				if widgetOrdinal then
					widgetOrdinal.setVisible(bWidgetsVisible);
					widgetOrdinal.setText(sNumber);
				end
			else
				if aWidgets["ordinal"] then
					aWidgets["ordinal"].destroy();
				end
			end
		end
	end
end

function updateNameScale(tokenCT)
	local widgetName = tokenCT.findWidget("name");
	if widgetName then
		local w, h = tokenCT.getSize();
		if w > 10 then
			widgetName.setMaxWidth(w - 10);
		else
			widgetName.setMaxWidth(0);
		end
	end
end

function updateVisibility(nodeCT)
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		updateVisibilityHelper(tokenCT, nodeCT);
	end
	
	if DB.getValue(nodeCT, "tokenvis", 0) == 0 then
		TargetingManager.removeCTTargeted(nodeCT);
	end
end

function updateVisibilityHelper(tokenCT, nodeCT)
	if DB.getValue(nodeCT, "friendfoe", "") == "friend" then
		tokenCT.setVisible(true);
	else
		if DB.getValue(nodeCT, "tokenvis", 0) == 1 then
			if tokenCT.isVisible() ~= true then
				tokenCT.setVisible(nil);
			end
		else
			tokenCT.setVisible(false);
		end
	end
end

function deleteOwner(nodePC)
	local nodeCT = CombatManager.getCTFromNode(nodePC);
	if nodeCT then
		local tokenCT = CombatManager.getTokenFromCT(nodeCT);
		if tokenCT then
			tokenCT.setTargetsVisible(false);
		end
	end
end

function updateOwner(nodePC)
	local nodeCT = CombatManager.getCTFromNode(nodePC);
	if nodeCT then
		local tokenCT = CombatManager.getTokenFromCT(nodeCT);
		if tokenCT then
			updateOwnerHelper(tokenCT, nodeCT);
		end
	end
end

function updateOwnerHelper(tokenCT, nodeCT)
	if not User.isHost() then
		local bOwned = false;
		
		local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
		if sClass == "charsheet" then
			if DB.isOwner(sRecord) then
				bOwned = true;
			end
		end

		tokenCT.setTargetsVisible(bOwned);
	end
end

function updateActive(nodeField)
	local nodeCT = nodeField.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		updateActiveHelper(tokenCT, nodeCT);
	end
end

function updateActiveHelper(tokenCT, nodeCT)
	if User.isHost() then
		if tokenCT.isActivable() then
			local bActive = (DB.getValue(nodeCT, "active", 0) == 1);
			if bActive then
				tokenCT.setActive(true);
			else
				tokenCT.setActive(false);
			end
		end
	end
end

function updateFaction(nodeFaction)
	local nodeCT = nodeFaction.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		if User.isHost() then
			updateFactionHelper(tokenCT, nodeCT);
		end
		updateTooltip(tokenCT, nodeCT);
		if TokenManager2 and TokenManager2.updateFaction then
			TokenManager2.updateFaction(tokenCT, nodeCT);
		end
	end
end

function updateFactionHelper(tokenCT, nodeCT)
	if DB.getValue(nodeCT, "friendfoe", "") == "friend" then
		tokenCT.setModifiable(true);
	else
		tokenCT.setModifiable(false);
	end

	updateVisibilityHelper(tokenCT, nodeCT);
	updateSizeHelper(tokenCT, nodeCT);
end

function updateSpaceReach(nodeField)
	local nodeCT = nodeField.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		updateSizeHelper(tokenCT, nodeCT);
	end
end

function updateSizeHelper(tokenCT, nodeCT)
	local nDU = GameSystem.getDistanceUnitsPerGrid();
	
	local nSpace = math.ceil(DB.getValue(nodeCT, "space", nDU) / nDU);
	local nHalfSpace = nSpace / 2;
	local nReach = math.ceil(DB.getValue(nodeCT, "reach", nDU) / nDU) + nHalfSpace;

	-- Clear underlays
	tokenCT.removeAllUnderlays();

	-- Reach underlay
	local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
	if sClass == "charsheet" then
		tokenCT.addUnderlay(nReach, "4f000000", "hover");
	else
		tokenCT.addUnderlay(nReach, "4f000000", "hover,gmonly");
	end

	-- Faction/space underlay
	local sFaction = DB.getValue(nodeCT, "friendfoe", "");
	if sFaction == "friend" then
		tokenCT.addUnderlay(nHalfSpace, "2f00ff00");
	elseif sFaction == "foe" then
		tokenCT.addUnderlay(nHalfSpace, "2fff0000");
	elseif sFaction == "neutral" then
		tokenCT.addUnderlay(nHalfSpace, "2fffff00");
	end
	
	-- Set grid spacing
	tokenCT.setGridSize(nSpace);
end

function getWidgetList(tokenCT, sSubset)
	local aWidgets = {};

	local w = nil;
	if not sSubset or sSubset == "name" then
		for _, vName in pairs({"name", "ordinal"}) do
			w = tokenCT.findWidget(vName);
			if w then
				aWidgets[vName] = w;
			end
		end
	end
	
	return aWidgets;
end

function setDragTokenUnits(nUnits)
	nTokenDragUnits = nUnits;
end

function endDragTokenWithUnits()
	nTokenDragUnits = nil;
end

function autoTokenScale(tokenMap)
	if tokenMap.getScale() ~= 1 then
		return;
	end
	
	local w, h = tokenMap.getImageSize();
	if w <= 0 or h <= 0 then
		return;
	end
	
	local aImage = tokenMap.getContainerNode().getValue();
	if not aImage or not aImage.gridsize or (aImage.gridsize <= 0) then
		return;
	end

	local nSpace = 1;
	if nTokenDragUnits then
		local nDU = GameSystem.getDistanceUnitsPerGrid();
		nSpace = math.max(math.ceil(nTokenDragUnits / nDU), 1);
	end
	local nSpacePixels = nSpace * aImage.gridsize;
	local sOptTASG = OptionsManager.getOption("TASG");
	if sOptTASG == "80" then
		nSpacePixels = nSpacePixels * 0.8;
	end

	if aImage.tokenscale then
		local fNewScale = math.min((nSpacePixels * aImage.tokenscale) / w, (nSpacePixels * aImage.tokenscale) / h);
		if fNewScale < 0.9 or fNewScale > 1.1 then
			tokenMap.setScale(fNewScale);
		end
	elseif nSpacePixels > 0 then
		local fNewScale = math.min(w / nSpacePixels, h / nSpacePixels);
		tokenMap.setContainerScale(fNewScale);
	end
end

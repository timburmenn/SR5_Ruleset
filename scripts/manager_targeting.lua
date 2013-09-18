-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function getFullTargets(rActor)
	local aTargets = {};

	if rActor then
		local tokenCT = CombatManager.getTokenFromCT(rActor.nodeCT);
		if tokenCT then
			local nodeContainer = tokenCT.getContainerNode();
			if nodeContainer then
				for _,nID in ipairs(tokenCT.getTargets()) do
					local nodeTarget = CombatManager.getCTFromTokenRef(nodeContainer, nID);
					if nodeTarget then
						local rTarget = ActorManager.getActorFromCT(nodeTarget);
						table.insert(aTargets, rTarget);
					end
				end
			end
		end
	end
	
	return aTargets;
end

function getActiveToken(vImage)
	local nodeCurrentCT = CombatManager.getCurrentUserCT();
	if nodeCurrentCT then
		local tokenCT = CombatManager.getTokenFromCT(nodeCurrentCT);
		if tokenCT then
			local nodeContainer = tokenCT.getContainerNode();
			if nodeContainer then
				if nodeContainer.getNodeName() == vImage.getDatabaseNode().getNodeName() then
					return tokenCT;
				end
			end
		end
	end
	
	return nil;
end

function getSelectionHelper(vImage)
	local aSelected = vImage.getSelectedTokens();
	if #aSelected > 0 then
		return aSelected;
	end
	
	local tokenCT = getActiveToken(vImage);
	if tokenCT then
		return { tokenCT };
	end
	
	return {};
end

function clearTargets(vImage)
	local aSelected = getSelectionHelper(vImage);

	for _,vToken in ipairs(aSelected) do
		vToken.clearTargets();
	end
end

function setFactionTargets(vImage, bNegated)
	-- Get selection or active CT
	local aSelected = getSelectionHelper(vImage);

	-- Determine faction of selection
	local sFaction = "friend";
	local sSelectedFaction = nil;
	for _,vToken in ipairs(aSelected) do
		local nodeCT = CombatManager.getCTFromToken(vToken);
		if not nodeCT then
			break;
		end
		local sCTFaction = DB.getValue(nodeCT, "friendfoe", "");
		if sCTFaction == "" then
			break;
		end
		if sSelectedFaction then
			if sSelectedFaction ~= sCTFaction then
				sSelectedFaction = nil;
				break;
			end
		else
			sSelectedFaction = sCTFaction;
		end
	end
	if sSelectedFaction then
		sFaction = sSelectedFaction;
	end
	
	-- Clear current selection targets
	for _,vToken in ipairs(aSelected) do
		vToken.clearTargets();
	end

	-- Iterate through tracker to target correct faction
	local bHost = User.isHost();
	local sContainer = vImage.getDatabaseNode().getNodeName();
	for _,nodeCT in pairs(DB.getChildren(CombatManager.CT_LIST)) do
		if DB.getValue(nodeCT, "tokenrefnode", "") == sContainer then
			if bHost or TokenManager.isClientVisible(nodeCT) then
				if bNegated then
					if DB.getValue(nodeCT, "friendfoe", "") ~= sFaction then
						for _,vToken in ipairs(aSelected) do
							vToken.setTarget(true, DB.getValue(nodeCT, "tokenrefid", 0));
						end
					end
				else
					if DB.getValue(nodeCT, "friendfoe", "") == sFaction then
						for _,vToken in ipairs(aSelected) do
							vToken.setTarget(true, DB.getValue(nodeCT, "tokenrefid", 0));
						end
					end
				end
			end
		end
	end
end

function removeTarget(sSourceNode, sTargetNode)
	local tokenSource = CombatManager.getTokenFromCT(sSourceNode);
	local tokenTarget = CombatManager.getTokenFromCT(sTargetNode);
	
	if tokenSource and tokenTarget then
		if tokenSource.getContainerNode() == tokenTarget.getContainerNode() then
			tokenSource.setTarget(false, tokenTarget.getId());
		end
	end
end

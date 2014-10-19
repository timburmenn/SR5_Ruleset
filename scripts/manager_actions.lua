-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

--  ACTION FLOW
--
--	1. INITIATE ACTION (DRAG OR DOUBLE-CLICK)
--	2. DETERMINE TARGETS (DROP OR TARGETING SUBSYSTEM)
--	3. APPLY MODIFIERS
--	4. PERFORM ROLLS (IF ANY)
--	5. RESOLVE ACTION

-- ROLL
--		.sType
--		.sDesc
--		.aDice
--		.nMod
--		(Any other fields added as string -> string map, if possible)

function onInit()
	Interface.onHotkeyActivated = actionHotkey;
end

--
-- HANDLERS
--

local aTargetingHandlers = {};
function registerTargetingHandler(sActionType, callback)
	aTargetingHandlers[sActionType] = callback;
end
function unregisterTargetingHandler(sRollType)
	if aTargetingHandlers then
		aTargetingHandlers[sActionType] = nil;
	end
end

local aModHandlers = {};
function registerModHandler(sActionType, callback)
	aModHandlers[sActionType] = callback;
end
function unregisterModHandler(sRollType)
	if aModHandlers then
		aModHandlers[sActionType] = nil;
	end
end

local aPostRollHandlers = {};
function registerPostRollHandler(sActionType, callback)
	aPostRollHandlers[sActionType] = callback;
end
function unregisterPostRollHandler(sRollType)
	if aPostRollHandlers then
		aPostRollHandlers[sActionType] = nil;
	end
end

local aResultHandlers = {};
function registerResultHandler(sActionType, callback)
	aResultHandlers[sActionType] = callback;
end
function unregisterResultHandler(sRollType)
	if aResultHandlers then
		aResultHandlers[sActionType] = nil;
	end
end

--
--  PERCENTILE HANDLING
--

function processPercentiles(draginfo)
	local aDragDieList = draginfo.getDieList();
	if not aDragDieList then
		return nil;
	end

	local aD100Indexes = {};
	local aD10Indexes = {};
	for k, v in pairs(aDragDieList) do
		if v["type"] == "d100" then
			table.insert(aD100Indexes, k);
		elseif v["type"] == "d10" then
			table.insert(aD10Indexes, k);
		end
	end

	local nMaxMatch = #aD100Indexes;
	if #aD10Indexes < nMaxMatch then
		nMaxMatch = #aD10Indexes;
	end
	if nMaxMatch <= 0 then
		return aDragDieList;
	end
	
	local nMatch = 1;
	local aNewDieList = {};
	for k, v in pairs(aDragDieList) do
		if v["type"] == "d100" then
			if nMatch > nMaxMatch then
				table.insert(aNewDieList, v);
			else
				v["result"] = aDragDieList[aD100Indexes[nMatch]]["result"] + aDragDieList[aD10Indexes[nMatch]]["result"];
				table.insert(aNewDieList, v);
				nMatch = nMatch + 1;
			end
		elseif v["type"] == "d10" then
			local bInsert = true;
			for i = 1, nMaxMatch do
				if aD10Indexes[i] == k then
					bInsert = false;
				end
			end
			if bInsert then
				table.insert(aNewDieList, v);
			end
		else
			table.insert(aNewDieList, v);
		end
	end

	return aNewDieList;
end

--
--  ACTIONS
--

function performAction(draginfo, rActor, rRoll)
	if not rRoll then
		return;
	end
	
	performMultiAction(draginfo, rActor, rRoll.sType, { rRoll });
end

function performMultiAction(draginfo, rActor, sType, rRolls)
	if not rRolls or #rRolls < 1 then
		return false;
	end
	
	if draginfo then
		encodeActionForDrag(draginfo, rActor, sType, rRolls);
	else
		actionDirect(rActor, sType, rRolls);
	end
	return true;
end

function actionHotkey(draginfo)
	local sDragType = draginfo.getType();
	if not GameSystem.actions[sDragType] then
		return;
	end
	
	local rSource, rRolls = decodeActionFromDrag(draginfo, false);
	actionDirect(rSource, sDragType, rRolls);
	return true;
end

function actionDrop(draginfo, rTarget)
	local sDragType = draginfo.getType();
	if not GameSystem.actions[sDragType] then
		return false;
	end
	
	if rTarget then
		local rSource, rRolls = decodeActionFromDrag(draginfo, false);

		local fTarget = aTargetingHandlers[sDragType];
		if fTarget then
			local aTargeting = { { rTarget } };
			fTarget(rSource, aTargeting, rRolls);
		end
		
		actionRoll(rSource, rTarget, false, rRolls)
	else
		actionDropHelper(draginfo, true);
	end
	return true;
end

function actionDropHelper(draginfo, bResolveIfNoDice)
	local rSource, aTargets = decodeActors(draginfo);
	
	local bModStackUsed = false;
	lockModifiers();
	
	draginfo.setSlot(1);
	for i = 1, draginfo.getSlotCount() do
		if applyModifiersToDragSlot(draginfo, i, rSource, bResolveIfNoDice) then
			bModStackUsed = true;
		end
	end
	
	unlockModifiers(bModStackUsed);
	
	return rSource, aTargets;
end

function actionDirect(rActor, sDragType, rRolls, aTargeting)
	if GameSystem.actions[sDragType] and GameSystem.actions[sDragType].sTargeting then
		if not aTargeting then
			if (#rRolls == 1) and rRolls[1].bSelfTarget then
				aTargeting = { { rActor } };
			elseif GameSystem.actions[sDragType].sTargeting == "all" then
				aTargeting = { TargetingManager.getFullTargets(rActor) };
			elseif GameSystem.actions[sDragType].sTargeting == "each" then
				local aTempTargets = TargetingManager.getFullTargets(rActor);
				if #aTempTargets <= 1 then
					aTargeting = { aTempTargets };
				else
					aTargeting = {};
					for _,vTarget in ipairs(aTempTargets) do
						table.insert(aTargeting, { vTarget });
					end
				end
			end
			
			local fTarget = aTargetingHandlers[sDragType];
			if fTarget then
				aTargeting = fTarget(rActor, aTargeting, rRolls);
			end
			if not aTargeting then
				aTargeting = {};
			end
		end
		if #aTargeting == 0 then
			table.insert(aTargeting, {});
		end
	else
		aTargeting = { { } };
	end
	
	actionRoll(rActor, aTargeting, true, rRolls);
end

function encodeActors(draginfo, rSource, aTargets)
	if rSource then
		local sActorType, sActorNode = ActorManager.getTypeAndNodeName(rSource);
		draginfo.addShortcut(sActorType, sActorNode);
	else
		draginfo.addShortcut();
	end
	
	if aTargets then
		for _,v in ipairs(aTargets) do
			local sActorType, sActorNode = ActorManager.getTypeAndNodeName(v);
			draginfo.addShortcut(sActorType, sActorNode);
		end
	end
end

function decodeActors(draginfo)
	local rSource = nil;
	local aTargets = {};
	
	for k,v in ipairs(draginfo.getShortcutList()) do
		if k == 1 then
			rSource = ActorManager.getActor(v.class, v.recordname);
		else
			local rTarget = ActorManager.getActor(v.class, v.recordname);
			if rTarget then
				table.insert(aTargets, rTarget);
			end
		end
	end
	
	return rSource, aTargets;
end

function encodeRollForDrag(draginfo, i, vRoll)
	draginfo.setSlot(i);

	for k,v in pairs(vRoll) do
		if k == "sType" then
			draginfo.setSlotType(v);
		elseif k == "sDesc" then
			draginfo.setStringData(v);
		elseif k == "aDice" then
			draginfo.setDieList(v);
		elseif k == "nMod" then
			draginfo.setNumberData(v);
		elseif type(k) ~= "table" then
			local sk = tostring(k) or "";
			if sk ~= "" then
				draginfo.setMetaData(sk, tostring(v) or "");
			end
		end
	end
end

function encodeActionForDrag(draginfo, rSource, sType, rRolls)
	encodeActors(draginfo, rSource);
	
	draginfo.setType(sType);
	
	if GameSystem.actions[sType] and GameSystem.actions[sType].sIcon then
		draginfo.setIcon(GameSystem.actions[sType].sIcon);
	elseif sType ~= "dice" then
		draginfo.setIcon("action_roll");
	end
	if #rRolls == 1 then
		draginfo.setDescription(rRolls[1].sDesc);
	end
	
	for kRoll, vRoll in ipairs(rRolls) do
		encodeRollForDrag(draginfo, kRoll, vRoll);
	end
end

function decodeRollFromDrag(draginfo, i, bFinal)
	draginfo.setSlot(i);
	
	local vRoll = draginfo.getMetaDataList();
	
	vRoll.sType = draginfo.getSlotType();
	if vRoll.sType == "" then
		vRoll.sType = draginfo.getType();
	end
	
	vRoll.sDesc = draginfo.getStringData();
	if bFinal and vRoll.sDesc == "" then
		vRoll.sDesc = draginfo.getDescription();
	end
	vRoll.nMod = draginfo.getNumberData();
	
	vRoll.aDice = {};
	if bFinal then
		vRoll.aDice = processPercentiles(draginfo) or {};
	else
		local aDragDice = draginfo.getDieList();
		if aDragDice then
			for k, v in pairs(aDragDice) do
				if type(v) == "string" then
					table.insert(vRoll.aDice, v);
				elseif type(v) == "table" then
					table.insert(vRoll.aDice, v["type"]);
				end
			end
		end
	end
	
	vRoll.bSecret = draginfo.getSecret();
	
	return vRoll;
end

function decodeActionFromDrag(draginfo, bFinal)
	local rSource, aTargets = decodeActors(draginfo);

	local rRolls = {};
	for i = 1, draginfo.getSlotCount() do
		table.insert(rRolls, decodeRollFromDrag(draginfo, i, bFinal));
	end
	
	return rSource, rRolls, aTargets;
end

--
--  APPLY MODIFIERS
--

function actionRoll(rSource, vTarget, bMultiTarget, rRolls)
	local bModStackUsed = false;
	lockModifiers();
	
	if bMultiTarget then
		for _,vTargetGroup in ipairs(vTarget) do
			for _,vRoll in ipairs(rRolls) do
				if applyModifiersAndRoll(rSource, vTargetGroup, true, vRoll) then
					bModStackUsed = true;
				end
			end
		end
	else
		for _,vRoll in ipairs(rRolls) do
			if applyModifiersAndRoll(rSource, vTarget, false, vRoll) then
				bModStackUsed = true;
			end
		end
	end
	
	unlockModifiers(bModStackUsed);
end

function applyModifiersAndRoll(rSource, vTarget, bMultiTarget, rRoll)
	local rNewRoll = UtilityManager.copyDeep(rRoll);

	local bModStackUsed = false;
	if bMultiTarget then
		if vTarget and #vTarget == 1 then
			bModStackUsed = applyModifiers(rSource, vTarget[1], rNewRoll);
		else
			-- Only apply non-target specific modifiers before roll
			bModStackUsed = applyModifiers(rSource, nil, rNewRoll);
		end
	else
		bModStackUsed = applyModifiers(rSource, vTarget, rNewRoll);
	end
	
	roll(rSource, vTarget, rNewRoll, bMultiTarget);
	
	return bModStackUsed;
end

function applyModifiersToDragSlot(draginfo, i, rSource, bResolveIfNoDice)
	local rRoll = decodeRollFromDrag(draginfo, i);

	local nDice = #(rRoll.aDice);
	local bModStackUsed = applyModifiers(rSource, nil, rRoll);
	
	if bResolveIfNoDice and #(rRoll.aDice) == 0 then
		resolveAction(rSource, nil, rRoll);
	else
		for k,v in pairs(rRoll) do
			if k == "sType" then
				draginfo.setSlotType(v);
			elseif k == "sDesc" then
				draginfo.setStringData(v);
			elseif k == "aDice" then
				local nNewDice = #(rRoll.aDice);
				for i = nDice + 1, nNewDice do
					draginfo.addDie(rRoll.aDice[i]);
				end
			elseif k == "nMod" then
				draginfo.setNumberData(v);
			else
				local sk = tostring(k) or "";
				if sk ~= "" then
					draginfo.setMetaData(sk, tostring(v) or "");
				end
			end
		end
	end
	
	return bModStackUsed;
end

function lockModifiers()
	ModifierStack.lock();
	EffectManager.lock();
end

function unlockModifiers(bReset)
	ModifierStack.unlock(bReset);
	EffectManager.unlock();
end

function applyModifiers(rSource, rTarget, rRoll, bSkipModStack)	
	local bAddModStack = (#(rRoll.aDice) > 0);
	if bSkipModStack then
		bAddModStack = false;
	elseif GameSystem.actions[rRoll.sType] then
		bAddModStack = GameSystem.actions[rRoll.sType].bUseModStack;
	end

	local fMod = aModHandlers[rRoll.sType];
	if fMod then
		fMod(rSource, rTarget, rRoll);
	end

	if bAddModStack then
		local bDescNotEmpty = (rRoll.sDesc ~= "");
		local sStackDesc, nStackMod = ModifierStack.getStack(bDescNotEmpty);
		
		if sStackDesc ~= "" then
			if bDescNotEmpty then
				rRoll.sDesc = rRoll.sDesc .. " [" .. sStackDesc .. "]";
			else
				rRoll.sDesc = sStackDesc;
			end
		end
		rRoll.nMod = rRoll.nMod + nStackMod;
	end
	
	return bAddModStack;
end

--
--	RESOLVE DICE
--

function buildThrow(rSource, vTargets, rRoll, bMultiTarget)
	local rThrow = {};
	
	rThrow.type = rRoll.sType;
	rThrow.description = rRoll.sDesc;
	rThrow.secret = rRoll.bSecret;
	
	rThrow.shortcuts = {};
	if rSource then
		local sActorType, sActorNode = ActorManager.getTypeAndNodeName(rSource);
		table.insert(rThrow.shortcuts, { class = sActorType, recordname = sActorNode });
	else
		table.insert(rThrow.shortcuts, {});
	end
	if vTargets then
		if bMultiTarget then
			for _,v in ipairs(vTargets) do
				local sActorType, sActorNode = ActorManager.getTypeAndNodeName(v);
				table.insert(rThrow.shortcuts, { class = sActorType, recordname = sActorNode });
			end
		else
			local sActorType, sActorNode = ActorManager.getTypeAndNodeName(vTargets);
			table.insert(rThrow.shortcuts, { class = sActorType, recordname = sActorNode });
		end
	end
	
	local rSlot = {};
	rSlot.number = rRoll.nMod;
	rSlot.dice = rRoll.aDice;
	rSlot.metadata = rRoll;
	rThrow.slots = { rSlot };
	
	return rThrow;
end

function roll(rSource, vTargets, rRoll, bMultiTarget)
	if #(rRoll.aDice) > 0 then
		local rThrow = buildThrow(rSource, vTargets, rRoll, bMultiTarget);
		Comm.throwDice(rThrow);
	else
		if bMultiTarget then
			if vTargets and #vTargets > 1 then
				for kTarget, rTarget in ipairs(vTargets) do
					rTarget.nOrder = kTarget;
					resolveAction(rSource, rTarget, rRoll); 
				end
			elseif vTargets and #vTargets == 1 then
				resolveAction(rSource, vTargets[1], rRoll);
			else
				resolveAction(rSource, nil, rRoll);
			end
		else
			resolveAction(rSource, vTargets, rRoll);
		end
	end
end 

function onDiceLanded(draginfo)
	print("On Dice Landed!");
	local sDragType = draginfo.getType();
	print ("Drag Type: "..sDragType);
	if GameSystem.actions[sDragType] then
		print("Decoding");
		local rSource, rRolls, aTargets = decodeActionFromDrag(draginfo, true);
		print("Decode done");
		for _,vRoll in ipairs(rRolls) do
			print("Looping again");
			if #(vRoll.aDice) > 0 then
				local fPostRoll = aPostRollHandlers[vRoll.sType];
				if fPostRoll then
					fPostRoll(rSource, vRoll);
				end
				
				if #aTargets == 0 then
					print("Resolving untargeted action");
					resolveAction(rSource, nil, vRoll);
				elseif #aTargets == 1 then
					print("Resolving single targeted action");
					resolveAction(rSource, aTargets[1], vRoll);
				else
					print("Resolving multitargeted action");
					for kTarget,rTarget in ipairs(aTargets) do
						rTarget.nOrder = kTarget;
						resolveAction(rSource, rTarget, vRoll);
					end
				end
			end
		end
		
		return true;
	end
end

function onChatDragStart(draginfo)
	local sDragType = draginfo.getType();
	if GameSystem.actions[sDragType] and GameSystem.actions[sDragType].sIcon then
		draginfo.setIcon(GameSystem.actions[sDragType].sIcon);
	end
end

-- 
--  RESOLVE ACTION
--  (I.E. DISPLAY CHAT MESSAGE, COMPARISONS, ETC.)
--

function resolveAction(rSource, rTarget, rRoll)
	local fResult = aResultHandlers[rRoll.sType];
	print("My roll type is: "..rRoll.sType);
	if fResult then
		print("Resolving "..rRoll.sType);
		fResult(rSource, rTarget, rRoll);
	else
		print("No roll type, standard handling");
		local rMessage = createActionMessage(rSource, rRoll);
		Comm.deliverChatMessage(rMessage);
	end
end

function createActionMessage(rSource, rRoll)
	local sDesc = rRoll.sDesc;
	
	-- Build the basic message to deliver
	local rMessage = ChatManager.createBaseMessage(rSource, rRoll.sUser);
	rMessage.type = rRoll.sType;
	rMessage.text = rMessage.text .. sDesc;
	rMessage.dice = rRoll.aDice;
	rMessage.diemodifier = rRoll.nMod;
	
	-- Check to see if this roll should be secret (GM or dice tower tag)
	if rRoll.bSecret then
		rMessage.secret = true;
		if rRoll.bTower then
			rMessage.icon = "dicetower_icon";
		end
	elseif User.isHost() and OptionsManager.isOption("REVL", "off") then
		rMessage.secret = true;
	end
	
	-- Show total if option enabled
	if OptionsManager.isOption("TOTL", "on") and rRoll.aDice and #(rRoll.aDice) > 0 then
		rMessage.dicedisplay = 1;
	end
	
	return rMessage;
end

function total(rRoll)
	local nTotal = 0;

	for _,v in ipairs(rRoll.aDice) do
		nTotal = nTotal + v.result;
	end
	nTotal = nTotal + rRoll.nMod;
	
	return nTotal;
end

function messageResult(bSecret, rSource, rTarget, rMessageGM, rMessagePlayer)
	local bShowResultsToPlayer;
	local sOptSHRR = OptionsManager.getOption("SHRR");
	if sOptSHRR == "off" then
		bShowResultsToPlayer = false;
	elseif sOptSHRR == "pc" then
		if (not rSource or rSource.sType == "pc") and (not rTarget or rTarget.sType == "pc") then
			bShowResultsToPlayer = true;
		else
			bShowResultsToPlayer = false;
		end
	else
		bShowResultsToPlayer = true;
	end

	if bShowResultsToPlayer then
		rMessageGM.secret = false;
		Comm.deliverChatMessage(rMessageGM);
	else
		rMessageGM.secret = true;
		Comm.deliverChatMessage(rMessageGM, "");

		if User.isHost() then
			local aUsers = User.getActiveUsers();
			if #aUsers > 0 then
				Comm.deliverChatMessage(rMessagePlayer, aUsers);
			end
		else
			Comm.addChatMessage(rMessagePlayer);
		end
	end
end

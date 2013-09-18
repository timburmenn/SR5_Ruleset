-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

CT_LIST = "combattracker.list";
CT_ROUND = "combattracker.round";

local sActiveCT = nil;
OOB_MSGTYPE_ENDTURN = "endturn";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_ENDTURN, handleEndTurn);
end

--
-- MULTI HANDLERS
-- NOTE: Handlers added here will all be called in the order they were added.
--

local aCustomDrop = {};
function setCustomDrop(fDrop)
	table.insert(aCustomDrop, fDrop);
end
function onDropEvent(rSource, rTarget, draginfo)
	if #aCustomDrop > 0 then
		for _,fCustomDrop in ipairs(aCustomDrop) do
			if fCustomDrop(rSource, rTarget, draginfo) then
				return true;
			end
		end
	end
end

local aCustomRoundStart = {};
function setCustomRoundStart(fRoundStart)
	table.insert(aCustomRoundStart, fRoundStart);
end
function onRoundStartEvent(nCurrent)
	if #aCustomRoundStart > 0 then
		for _,fCustomRoundStart in ipairs(aCustomRoundStart) do
			fCustomRoundStart(nCurrent);
		end
	end
end

local aCustomTurnStart = {};
function setCustomTurnStart(fTurnStart)
	table.insert(aCustomTurnStart, fTurnStart);
end
function onTurnStartEvent(nodeCT)
	if #aCustomTurnStart > 0 then
		for _,fCustomTurnStart in ipairs(aCustomTurnStart) do
			fCustomTurnStart(nodeCT);
		end
	end
end

local aCustomTurnEnd = {};
function setCustomTurnEnd(fTurnEnd)
	table.insert(aCustomTurnEnd, fTurnEnd);
end
function onTurnEndEvent(nodeCT)
	if #aCustomTurnEnd > 0 then
		for _,fCustomTurnEnd in ipairs(aCustomTurnEnd) do
			fCustomTurnEnd(nodeCT);
		end
	end
end

local aCustomInitChange = {};
function setCustomInitChange(fInitChange)
	table.insert(aCustomInitChange, fInitChange);
end
function onInitChangeEvent(nodeOldCT, nodeNewCT)
	if #aCustomInitChange > 0 then
		for _,fCustomInitChange in ipairs(aCustomInitChange) do
			fCustomInitChange(nodeOldCT, nodeNewCT);
		end
	end
end

local aCustomCombatReset = {};
function setCustomCombatReset(fCombatReset)
	table.insert(aCustomCombatReset, fCombatReset);
end
function onCombatResetEvent()
	if #aCustomCombatReset > 0 then
		for _,fCustomCombatReset in ipairs(aCustomCombatReset) do
			fCustomCombatReset();
		end
	end
end

--
-- SINGLE HANDLERS
-- NOTE: Setting these handlers will override previous handlers
--

local fCustomSort = nil;
function setCustomSort(fSort)
	fCustomSort = fSort;
end
-- NOTE: Lua sort function expects the opposite boolean value compared to built-in FG sorting
function onSortCompare(node1, node2)
	if fCustomSort then
		return not fCustomSort(node1, node2);
	end
	
	return not sortfunc(node1, node2);
end

local fCustomAddPC = nil;
function setCustomAddPC(fAddPC)
	fCustomAddPC = fAddPC;
end
local fCustomAddNPC = nil;
function setCustomAddNPC(fAddNPC)
	fCustomAddNPC = fAddNPC;
end
local fCustomAddNPCEnd = nil;
function setCustomAddNPCEnd(fAddNPCEnd)
	fCustomAddNPCEnd = fAddNPCEnd;
end
local fCustomAddBattle = nil;
function setCustomAddBattle(fAddBattle)
	fCustomAddBattle = fAddBattle;
end


--
-- GENERAL
--

function getActiveCT()
	for _,v in pairs(DB.getChildren(CT_LIST)) do
		if DB.getValue(v, "active", 0) == 1 then
			return v;
		end
	end
	return nil;
end

function getCTFromNode(varNode)
	-- Get path name desired
	local sNode = "";
	if type(varNode) == "string" then
		sNode = varNode;
	elseif type(varNode) == "databasenode" then
		sNode = varNode.getNodeName();
	else
		return nil;
	end
	
	-- Check for exact CT match
	for _,v in pairs(DB.getChildren(CT_LIST)) do
		if v.getNodeName() == sNode then
			return v;
		end
	end

	-- Otherwise, check for link match
	for _,v in pairs(DB.getChildren(CT_LIST)) do
		local sClass, sRecord = DB.getValue(v, "link", "", "");
		if sRecord == sNode then
			return v;
		end
	end

	return nil;	
end

function getCTFromTokenRef(vContainer, nId)
	local sContainerNode = nil;
	if type(vContainer) == "string" then
		sContainerNode = vContainer;
	elseif type(vContainer) == "databasenode" then
		sContainerNode = vContainer.getNodeName();
	else
		return nil;
	end
	
	for _,v in pairs(DB.getChildren(CT_LIST)) do
		local sCTContainerName = DB.getValue(v, "tokenrefnode", "");
		local nCTId = tonumber(DB.getValue(v, "tokenrefid", "")) or 0;
		if (sCTContainerName == sContainerNode) and (nCTId == nId) then
			return v;
		end
	end
	
	return nil;
end

function getCTFromToken(token)
	local nodeContainer = token.getContainerNode();
	local nID = token.getId();

	return getCTFromTokenRef(nodeContainer, nID);
end

function getTokenFromCT(vEntry)
	local nodeCT = nil;
	if type(vEntry) == "string" then
		nodeCT = DB.findNode(vEntry);
	elseif type(vEntry) == "databasenode" then
		nodeCT = vEntry;
	end
	
	if not nodeCT then
		return nil;
	end
	
	return Token.getToken(DB.getValue(nodeCT, "tokenrefnode", ""), DB.getValue(nodeCT, "tokenrefid", ""));
end

function getCurrentUserCT()
	if User.isHost() then
		return getActiveCT();
	end
	
	-- If active identity is owned, then use that one
	local nodeActive = getActiveCT();
	local sClass, sRecord = DB.getValue(nodeActive, "link", "", "");
	if sClass == "charsheet" then
		local aOwned = User.getOwnedIdentities();
		for _,v in ipairs(aOwned) do
			if sRecord == ("charsheet." .. v) then
				return nodeActive;
			end
		end
	end
	
	-- Otherwise, use active identity (if any)
	local sID = User.getCurrentIdentity();
	if sID then
		return getCTFromNode("charsheet." .. sID);
	end

	return nil;
end

function openMap(vNode)
	local nodeCT = getCTFromNode(vNode);
	if nodeCT then
		local tokeninstance = getTokenFromCT(nodeCT);
		if tokeninstance then
			local nodeImage = tokeninstance.getContainerNode();
			local w = Interface.openWindow("imagewindow", nodeImage.getParent());
			if w then
				local x,y = tokeninstance.getPosition();
				w.image.setViewpointCenter(x,y);
			end
		end
	end
end

--
-- COMBAT TRACKER SORT
--

function sortfunc(node1, node2)
	return node1.getNodeName() < node2.getNodeName();
end

function getSortedCombatantList()
	local aEntries = {};
	for _,vChild in pairs(DB.getChildren(CT_LIST)) do
		table.insert(aEntries, vChild);
	end
	if #aEntries > 0 then
		if fCustomSort then
			table.sort(aEntries, fCustomSort);
		else
			table.sort(aEntries, sortfunc);
		end
	end
	return aEntries;
end

--
-- TURN FUNCTIONS
--

function handleEndTurn(msgOOB)
	local rActor = ActorManager.getActorFromCT(getActiveCT());
	if rActor and rActor.sType == "pc" and rActor.nodeCreature then
		if rActor.nodeCreature.getOwner() == msgOOB.user then
			nextActor();
		end
	end
end

function notifyEndTurn()
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_ENDTURN;
	msgOOB.user = User.getUsername();

	Comm.deliverOOBMessage(msgOOB, "");
end

function addGMIdentity(sName, sClass)
	if OptionsManager.isOption("CTAV", "on") then
		if sClass == "charsheet" or sName == "" then
			GmIdentityManager.activateGMIdentity();
		else
			if GmIdentityManager.existsIdentity(sName) then
				GmIdentityManager.setCurrent(sName);
			else
				sActiveCT = sName;
				GmIdentityManager.addIdentity(sName);
			end
		end
	end
end

function clearGMIdentity()
	if sActiveCT then
		GmIdentityManager.removeIdentity(sActiveCT);
		sActiveCT = nil;
	end
end

function requestActivation(nodeEntry, bSkipBell)
	-- De-activate all other entries
	for _, vChild in pairs(DB.getChildren(CT_LIST)) do
		DB.setValue(vChild, "active", "number", 0);
	end
	
	-- Set active flag
	DB.setValue(nodeEntry, "active", "number", 1);

	-- Get key information
	local sName = DB.getValue(nodeEntry, "name", "");
	local sClass, sRecord = DB.getValue(nodeEntry, "link", "", "");
	
	-- Handle turn notification (including bell ring based on option)
	local msg = {font = "narratorfont", icon = "turn_flag"};
	msg.text = "[TURN] " .. sName;
	if sClass == "charsheet" then
		Comm.deliverChatMessage(msg);
		
		if not bSkipBell and OptionsManager.isOption("RING", "on") then
			if sRecord ~= "" then
				local nodePC = DB.findNode(sRecord);
				if nodePC then
					local sOwner = nodePC.getOwner();
					if sOwner then
						User.ringBell(sOwner);
					end
				end
			end
		end
	else
		if (DB.getValue(nodeEntry, "friendfoe", "") == "friend") or (DB.getValue(nodeEntry, "tokenvis", 0) == 1) then
			Comm.deliverChatMessage(msg);
		else
			msg.secret = true;
			Comm.addChatMessage(msg);
		end
	end

	-- Handle GM identity list updates (based on option)
	clearGMIdentity();
	addGMIdentity(sName, sClass);
end

function nextActor(bSkipBell)
	local nodeActive = getActiveCT();
	
	-- Determine the next actor
	local nodeNext = nil;
	local aEntries = getSortedCombatantList();
	if #aEntries > 0 then
		if nodeActive then
			for i = 1,#aEntries do
				if aEntries[i] == nodeActive then
					nodeNext = aEntries[i+1];
				end
			end
		else
			nodeNext = aEntries[1];
		end
	end

	-- If next actor available, advance effects, activate and start turn
	if nodeNext then
		-- End turn for current actor
		onTurnEndEvent(nodeActive);
	
		-- Process effects in between current and next actors
		if nodeActive then
			onInitChangeEvent(nodeActive, nodeNext);
		else
			onInitChangeEvent(nil, nodeNext);
		end
		
		-- Start turn for next actor
		requestActivation(nodeNext, bSkipBell);
		onTurnStartEvent(nodeNext);
	else
		nextRound(1);
	end
end

function nextRound(nRounds)
	local nodeActive = getActiveCT();

	-- If current actor, then advance based on that
	local nStartCounter = 1;
	local aEntries = getSortedCombatantList();
	if nodeActive then
		DB.setValue(nodeActive, "active", "number", 0);
		clearGMIdentity();

		local bFastTurn = false;
		for i = 1,#aEntries do
			if aEntries[i] == nodeActive then
				bFastTurn = true;
				onTurnEndEvent(nodeActive);
			elseif bFastTurn then
				onTurnStartEvent(aEntries[i]);
				onTurnEndEvent(aEntries[i]);
			end
		end
		
		onInitChangeEvent(nodeActive);

		nStartCounter = nStartCounter + 1;
	end
	for i = nStartCounter, nRounds do
		for i = 1,#aEntries do
			onTurnStartEvent(aEntries[i]);
			onTurnEndEvent(aEntries[i]);
		end
		
		onInitChangeEvent();
	end

	-- Update round counter
	local nCurrent = DB.getValue(CT_ROUND, 0) + nRounds;
	DB.setValue(CT_ROUND, "number", nCurrent);
	
	-- Announce new round
	local msg = {font = "narratorfont", icon = "turn_flag"};
	msg.text = "[ROUND " .. nCurrent .. "]";
	Comm.deliverChatMessage(msg);
	
	-- Custom round start callback (such as per round initiative rolling)
	onRoundStartEvent(nCurrent);
	
	-- Check option to see if we should advance to first actor or stop on round start
	if OptionsManager.isOption("RNDS", "off") then
		local bSkipBell = (nRounds > 1);
		if DB.getChildCount(CT_LIST) > 0 then
			nextActor(bSkipBell);
		end
	end
end

--
-- DROP HANDLING
--

function onDrop(nodetype, nodename, draginfo)
	local rSource = ActionsManager.decodeActors(draginfo);
	local rTarget = ActorManager.getActor(nodetype, nodename);
	if rTarget then
		local sDragType = draginfo.getType();

		-- Faction changes
		if sDragType == "combattrackerff" then
			if User.isHost() then
				DB.setValue(rTarget.nodeCT, "friendfoe", "string", draginfo.getStringData());
				return true;
			end
		end
	end
	
	return onDropEvent(rSource, rTarget, draginfo);
end

--
-- ADD FUNCTIONS
--

function addPC(nodePC)
	if fCustomAddPC then
		return fCustomAddPC(nodePC);
	end
	
	-- Parameter validation
	if not nodePC then
		return;
	end

	-- Create a new combat tracker window
	local nodeEntry = DB.createChild(CT_LIST);
	if not nodeEntry then
		return;
	end
	
	-- Set up the CT specific information
	DB.setValue(nodeEntry, "link", "windowreference", "charsheet", nodePC.getNodeName());
	DB.setValue(nodeEntry, "token", "token", DB.getValue(nodePC, "token", nil));
	DB.setValue(nodeEntry, "friendfoe", "string", "friend");
end

function addBattle(nodeBattle)
	if fCustomAddBattle then
		return fCustomAddBattle(nodeBattle);
	end
	
	-- Cycle through the NPC list, and add them to the tracker
	for _, vNPCItem in pairs(DB.getChildren(nodeBattle, "npclist")) do
		-- Get link database node
		local nodeNPC = nil;
		local sClass, sRecord = DB.getValue(vNPCItem, "link", "", "");
		if sRecord ~= "" then
			nodeNPC = DB.findNode(sRecord);
		end
		local sName = DB.getValue(vNPCItem, "name", "");
		
		if nodeNPC then
			local aPlacement = {};
			for _,vPlacement in pairs(DB.getChildren(vNPCItem, "maplink")) do
				local rPlacement = {};
				local _, sRecord = DB.getValue(vPlacement, "imageref", "", "");
				rPlacement.imagelink = sRecord;
				rPlacement.imagex = DB.getValue(vPlacement, "imagex", 0);
				rPlacement.imagey = DB.getValue(vPlacement, "imagey", 0);
				table.insert(aPlacement, rPlacement);
			end
			
			local nCount = DB.getValue(vNPCItem, "count", 0);
			for i = 1, nCount do
				local nodeEntry = addNPC(sClass, nodeNPC, sName);
				if nodeEntry then
					local sToken = DB.getValue(vNPCItem, "token", "");
					if sToken ~= "" then
						DB.setValue(nodeEntry, "token", "token", sToken);
						
						if aPlacement[i] and aPlacement[i].imagelink ~= "" then
							local tokenAdded = Token.addToken(aPlacement[i].imagelink, sToken, aPlacement[i].imagex, aPlacement[i].imagey);
							if tokenAdded then
								TokenManager.linkToken(nodeEntry, tokenAdded);
							end
						end
					end
				else
					ChatManager.SystemMessage("[ERROR] Unable to add '" .. sName .. "' to CT. NPC creation failed.");
				end
			end
		else
			ChatManager.SystemMessage("[ERROR] Unable to add '" .. sName .. "' to CT. Missing data record. Check your modules.");
		end
	end
end

function stripCreatureNumber(s)
	local nStarts, _, sNumber = string.find(s, " ?(%d+)$");
	if nStarts then
		return string.sub(s, 1, nStarts - 1), sNumber;
	end
	return s;
end

function randomName(sBaseName)
	local aNames = {};
	for _, v in pairs(DB.getChildren(CT_LIST)) do
		local sName = DB.getValue(v, "name", "");
		if sName ~= "" then
			table.insert(aNames, DB.getValue(v, "name", ""));
		end
	end
	
	local nRandomRange = DB.getChildCount(CT_LIST) * 2;
	local sNewName = sBaseName;
	local bContinue = true;
	while bContinue do
		bContinue = false;
		sNewName = sBaseName .. " " .. math.random(nRandomRange);
		if StringManager.contains(aNames, sNewName) then
			bContinue = true;
		end
	end

	return sNewName;
end

function addNPC(sClass, nodeNPC, sName)
	if fCustomAddNPC then
		return fCustomAddNPC(sClass, nodeNPC, sName);
	end
	
	local nodeEntry, nodeLastMatch = addNPCHelper(nodeNPC, sName);
	
	-- DEBUG
	if fCustomAddNPCEnd then
		return fCustomAddNPCEnd(sClass, nodeNPC, nodeEntry, nodeLastMatch, unpack(arg));
	end
	
	return nodeEntry;
end

function addNPCHelper(nodeNPC, sName)
	-- Parameter validation
	if not nodeNPC then
		return nil;
	end

	-- Create a new combat tracker window
	DB.createNode(CT_LIST);
	local nodeEntry = DB.createChild(CT_LIST);
	if not nodeEntry then
		return nil;
	end
	
	-- Make a full copy of the NPC
	DB.copyNode(nodeNPC, nodeEntry);
	
	-- Clear any effects copied over
	for _,v in pairs(DB.getChildren(nodeEntry, "effects")) do
		v.delete();
	end
	
	-- Lock NPC record view by default when copying to CT
	DB.setValue(nodeEntry, "locked", "number", 1);
	
	-- Set up the CT specific information
	DB.setValue(nodeEntry, "link", "windowreference", "npc", "");
	DB.setValue(nodeEntry, "friendfoe", "string", "foe");
	
	-- Get the name to use for this addition
	local sNameLocal = sName;
	if not sNameLocal then
		sNameLocal = DB.getValue(nodeNPC, "name", "");
		if CT_LIST == nodeNPC.getNodeName():sub(1, #(CT_LIST)) then
			sNameLocal = stripCreatureNumber(sNameLocal);
		end
	end
	
	local nodeLastMatch = nil;
	if sNameLocal:len() > 0 then
		-- Determine the number of NPCs with the same name
		local nNameHigh = 0;
		local aMatchesWithNumber = {};
		local aMatchesToNumber = {};
		for _,v in pairs(DB.getChildren(CT_LIST)) do
			if v.getName() ~= nodeEntry.getName() then
				local sEntryName = DB.getValue(v, "name", "");
				local sTemp, sNumber = stripCreatureNumber(sEntryName);
				if sTemp == sNameLocal then
					nodeLastMatch = v;
					
					local nNumber = tonumber(sNumber) or 0;
					if nNumber > 0 then
						if nNumber > nNameHigh then
							nNameHigh = nNumber;
						end
						table.insert(aMatchesWithNumber, v);
					else
						table.insert(aMatchesToNumber, v);
					end
				end
			end
		end
	
		-- If multiple NPCs of same name, then figure out whether we need to adjust the name based on options
		local sOptNNPC = OptionsManager.getOption("NNPC");
		if sOptNNPC ~= "off" then
			local nNameCount = #aMatchesWithNumber + #aMatchesToNumber;
			
			for _,v in ipairs(aMatchesToNumber) do
				local sEntryName = DB.getValue(v, "name", "");
				if sOptNNPC == "append" then
					nNameHigh = nNameHigh + 1;
					DB.setValue(v, "name", "string", sEntryName .. " " .. nNameHigh);
				elseif sOptNNPC == "random" then
					DB.setValue(v, "name", "string", randomName(sEntryName));
				end
			end
			
			if nNameCount > 0 then
				if sOptNNPC == "append" then
					nNameHigh = nNameHigh + 1;
					sNameLocal = sNameLocal .. " " .. nNameHigh;
				elseif sOptNNPC == "random" then
					sNameLocal = randomName(sNameLocal);
				end
			end
		end
	end
	
	-- Set the final name value
	DB.setValue(nodeEntry, "name", "string", sNameLocal);
	
	return nodeEntry, nodeLastMatch;
end

--
-- RESET FUNCTIONS
--

function resetInit()
	-- De-activate all entries
	for _, vChild in pairs(DB.getChildren(CT_LIST)) do
		DB.setValue(vChild, "active", "number", 0);
	end
	
	-- Clear GM identity additions (based on option)
	clearGMIdentity();

	-- Reset the round counter
	DB.setValue(CT_ROUND, "number", 1);
	
	onCombatResetEvent();
end

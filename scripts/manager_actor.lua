-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

--
--  DATA STRUCTURES
--
-- rActor
--		sType
--		sName
--		nodeCreature
--		sCreatureNode
--		nodeCT
-- 		sCTNode
--

function isPC(sActorNode)
	if sActorNode:sub(1,10) == "charsheet." then
		return true;
	end
	return false;
end

function getActor(sActorType, varActor)
	-- GET ACTOR NODE
	local nodeActor = nil;
	if type(varActor) == "string" then
		if varActor ~= "" then
			nodeActor = DB.findNode(varActor);
		end
	elseif type(varActor) == "databasenode" then
		nodeActor = varActor;
	end
	if not nodeActor then
		return nil;
	end

	-- Determine type unless specified
	if sActorType ~= "pc" and sActorType ~= "ct" and sActorType ~= "npc" then
		if isPC(nodeActor.getNodeName()) then
			sActorType = "pc";
		else
			sActorType = "npc";
		end
	end
	
	-- BASED ON ORIGINAL ACTOR NODE, FILL IN THE OTHER INFORMATION
	local rActor = nil;
	if sActorType == "pc" then
		rActor = {};
		rActor.sType = "pc";
		rActor.nodeCreature = nodeActor;
		rActor.nodeCT = CombatManager.getCTFromNode(nodeActor);
		rActor.sName = DB.getValue(rActor.nodeCreature, "name", "");

	elseif sActorType == "ct" or sActorType == "npc" then
		rActor = {};
		rActor.sType = "npc";
		rActor.nodeCreature = nodeActor;
		rActor.nodeCT = CombatManager.getCTFromNode(nodeActor);
		rActor.sName = DB.getValue(rActor.nodeCreature, "name", "");
	end
	
	-- TRACK THE NODE NAMES AS WELL
	if rActor.nodeCT then
		rActor.sCTNode = rActor.nodeCT.getNodeName();
	else
		rActor.sCTNode = "";
	end
	if rActor.nodeCreature then
		rActor.sCreatureNode = rActor.nodeCreature.getNodeName();
	else
		rActor.sCreatureNode = "";
	end
	
	-- RETURN ACTOR INFORMATION
	return rActor;
end

function getActorFromCT(nodeCT)
	local sClass, sRecord;
	if type(nodeCT) == "string" then
		sClass, sRecord = DB.getValue(nodeCT .. ".link", "", "");
	else
		sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
	end
	if sClass == "charsheet" then
		return getActor("pc", sRecord);
	end
	
	return getActor("npc", nodeCT);
end

function getActorFromToken(token)
	local nodeCT = CombatManager.getCTFromToken(token);
	if nodeCT then
		return getActorFromCT(nodeCT);
	end
	
	return nil;
end

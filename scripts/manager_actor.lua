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
--		sCreatureNode
-- 		sCTNode
--

function isPC(v)
	local sType = type(v);
	if sType == "string" then
		if v:sub(1,10) == "charsheet." then
			return true;
		end
	elseif sType == "databasenode" then
		if v.getNodeName():sub(1,10) == "charsheet." then
			return true;
		end
	elseif sType == "table" then
		if v.sType and v.sType == "pc" then
			return true;
		end
	end
	
	return false;
end

function getActor(sActorType, varActor)
	-- GET ACTOR NODE
	local nodeActor = nil;
	if type(varActor) == "string" then
		print("I am String! "..varActor);
		if varActor ~= "" then
			nodeActor = DB.findNode(varActor);

			-- Note: Handle cases where PC targets another PC they do not own, 
			--     	which means they do not have access to PC record but they
			--		do have access to CT record.
			if not nodeActor and sActorType == "pc" then
				sActorType = "ct";
				nodeActor = CombatManager.getCTFromNode(varActor);
			end
		end
	elseif type(varActor) == "databasenode" then
		print("I am DatabaseNode!");
		nodeActor = varActor;
	end
	print(varActor);
	if not nodeActor then
		return nil;
	end
	local sActorNode = nodeActor.getNodeName();

	-- Determine type unless specified
	if sActorType ~= "pc" and sActorType ~= "ct" and sActorType ~= "npc" then
		if isPC(nodeActor) then
			sActorType = "pc";
		else
			sActorType = "npc";
		end
	end
	
	-- BASED ON ORIGINAL ACTOR NODE, FILL IN THE OTHER INFORMATION
	local rActor = nil;
	if sActorType == "ct" then
		rActor = {};
		local sClass, sRecord = DB.getValue(nodeActor, "link", "", "");
		if sClass == "charsheet" then
			rActor.sType = "pc";
			rActor.sCreatureNode = sRecord;
		else
			rActor.sType = "npc";
			rActor.sCreatureNode = sActorNode;
		end
		rActor.sCTNode = sActorNode;
		rActor.sName = DB.getValue(nodeActor, "name", "");
		
	elseif sActorType == "pc" then
		rActor = {};
		rActor.sType = "pc";
		rActor.sCreatureNode = sActorNode;
		local nodeCT, sCTNode = CombatManager.getCTFromNode(nodeActor);
		rActor.sCTNode = sCTNode;
		if nodeCT then
			rActor.sName = DB.getValue(nodeCT, "name", "");
		else
			rActor.sName = DB.getValue(nodeActor, "name", "");
		end

	elseif sActorType == "npc" then
		rActor = {};
		rActor.sType = "npc";
		rActor.sCreatureNode = sActorNode;
		_, rActor.sCTNode = CombatManager.getCTFromNode(nodeActor);
		rActor.sName = DB.getValue(nodeActor, "name", "");
	end
	
	-- RETURN ACTOR INFORMATION
	return rActor;
end

function getActorFromCT(nodeCT)
	return getActor("ct", nodeCT);
end

function getActorFromToken(token)
	local nodeCT = CombatManager.getCTFromToken(token);
	if nodeCT then
		return getActorFromCT(nodeCT);
	end
	
	return nil;
end

function getType(rActor)
	if type(rActor) ~= "table" then
		return nil;
	end
	
	return rActor.sType;
end

function hasCT(rActor)
	return (getCTNodeName(rActor) ~= "");
end

function getCTNodeName(rActor)
	if type(rActor) ~= "table" then
		return "";
	end
	
	return rActor.sCTNode;
end

function getCTNode(rActor)
	local node = nil;
	
	local sNodeName = getCTNodeName(rActor);
	if sNodeName and sNodeName ~= "" then
		node = DB.findNode(sNodeName);
	end
	
	return node;
end

function getCreatureNodeName(rActor)
	if type(rActor) ~= "table" then
		return "";
	end
	
	return rActor.sCreatureNode;
end

function getCreatureNode(rActor)
	local node = nil;
	
	local sNodeName = getCreatureNodeName(rActor);
	if sNodeName and sNodeName ~= "" then
		node = DB.findNode(sNodeName);
	end
	
	return node;
end

function getTypeAndNodeName(rActor)
	if type(rActor) ~= "table" then
		return nil, nil;
	end
	
	if rActor.sType == "pc" then
		local sPCNode = getCreatureNodeName(rActor);
		if sPCNode ~= "" then
			return "pc", sPCNode;
		end
	end
	
	local sCTNode = getCTNodeName(rActor);
	if sCTNode ~= "" then
		return "ct", sCTNode;
	end
	
	if rActor.sType ~= "pc" then
		local sNPCNode = getCreatureNodeName(rActor);
		if sNPCNode ~= "" then
			return "npc", sNPCNode;
		end
	end
	
	return nil, nil;
end

function getTypeAndNode(rActor)
	if type(rActor) ~= "table" then
		return nil, nil;
	end
	
	if rActor.sType == "pc" then
		local nodeCreature = getCreatureNode(rActor);
		if nodeCreature then
			return "pc", nodeCreature;
		end
	end
	
	local nodeCT = getCTNode(rActor);
	if nodeCT then
		return "ct", nodeCT;
	end
	
	if rActor.sType ~= "pc" then
		local nodeNPC = getCreatureNode(rActor);
		if nodeNPC then
			return "npc", nodeNPC;
		end
	end
	
	return nil, nil;
end

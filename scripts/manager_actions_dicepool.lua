-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("dicepool", modRoll);
	ActionsManager.registerResultHandler("dicepool",onResolve);
end

function onResolve(rSource, rTarget, rRoll)
	-- Apply target specific modifiers before roll
	if rTarget and rTarget.nOrder then
		applyModifiers(rSource, rTarget, rRoll);
	end
	local sDesc, nStackMod = ModifierStack.getStack(true);
	print(nStackMod);
	local rMessage, rSource, rRoll = createExtendedRollTable(rSource, rRoll);
	rMessage, rSource, rRoll = ActionsManager.createActionMessage(rSource, rRoll, rMessage);
	Comm.deliverChatMessage(rMessage); 
end

function createExtendedRollTable(rSource, rRoll)
	local nSuccesses = 0;
	local nFailures = 0;
	local nGlitchDice = 0;
	local bNoPrint = false;
	local bEdge = false;
	local nRerollCount = 0
	local nTotalDice = 0
	local rMessage = ChatManager.createBaseMessage(rSource);
	local bNonD6 = false
	local nSuccessesCalling = 0
	local isEdge = string.match(rRoll.sDesc, "%[EDGE]");
		if isEdge then
			bEdge = true;
		end
		if rSource and rSource.sType == "pc" then
		local b = DB.findNode(rSource.sCreatureNode).getChild("edgecheckbox").getValue();
			if b == 1 then
				bEdge = true;
			end
		end

	if bEdge == true and rSource then
		local nEdgeUsed = 0
		nEdgeUsed = DB.findNode(rSource.sCreatureNode).getChild("base.attribute.edge.mod").getValue();
		if DB.findNode(rSource.sCreatureNode).getChild("edgecheckbox").getValue() == 1 then
		nEdgeUsed = (nEdgeUsed + 1)
		DB.findNode(rSource.sCreatureNode).getChild("base.attribute.edge.mod").setValue(nEdgeUsed);
		DB.findNode(rSource.sCreatureNode).getChild("edgecheckbox").setValue(0);
		end
	end

	-- Individual Dice Handling, Trooping the Color
		if rRoll.nTotalDice then
			nTotalDice = rRoll.nTotalDice
		end
--		if rRoll.nRerollSuccesses and rRoll.nRerollSuccesses > 0 then
--			nSuccesses = rRoll.nRerollSuccesses
--		end
	

		for i , v in ipairs (rRoll.aDice) do
			if rRoll.aDice[i].type ~= "d6" or rRoll.aDice[i].type ~= "d6" or rRoll.aDice[i].type ~= "d6" or rRoll.aDice[i].type ~= "d6" then
				bNonD6 = true
			elseif rRoll.aDice[i].type == "d6" then
				nTotalDice = nTotalDice + 1
				if rRoll.aDice[i].result >= 5 then 
					nSuccesses = nSuccesses + 1;
					nSuccessesCalling = nSuccessesCalling + 1;
					rRoll.aDice[i].type = "dg6";
				elseif rRoll.aDice[i].result == 1 then 
					nFailures = nFailures + 1;
					rRoll.aDice[i].type = "dr6";
				end
			end
		end
	if nRerollCount == 0 then
		bNoPrint = false	
	end
	if bNoPrint == true then 

		if rRoll.nRerollsuccesses then
			rRoll.nRerollSuccesses = rRoll.nRerollSuccesses + nSuccesses;
		else
			rRoll.nRerollSuccesses = nSuccesses
		end
		if rRoll.nTotalDice then
			rRoll.nTotalDice = nTotalDice
		end
		local isDiceTower = string.match(rRoll.sDesc, "^%[TOWER%]");
		local isGMOnly = string.match(rRoll.sDesc, "^%[GM%]");
		if isDiceTower then
			rMessage.dicesecret = true;
			rMessage.sender = "";
			rMessage.icon = "dicetower_icon";
		elseif isGMOnly then
			rMessage.dicesecret = true;
			rMessage.text = "[GM] " .. rMessage.text;
		elseif User.isHost() and OptionsManager.isOption("REVL", "off") then
			rMessage.dicesecret = true;
			rMessage.text = "[GM] " .. rMessage.text;
		end
		rRoll.sRerollDesc = rRoll.sDesc;
		rRoll. sDesc = "Reroll commenced";
		rRoll.nRerollCount = nRerollCount
		rMessage.text = rRoll.sDesc;
		rMessage.dice = rRoll.aDice;
		rRoll.sType = "reroll"
		return rMessage, rSource, rRoll;
	else
		rRoll.sDesc = rRoll.sDesc .. "\rHits: ".. nSuccesses .. " "
		rRoll.nSuccessesCalling = nSuccessesCalling
		
		local nHalfDice = math.ceil(nTotalDice / 2)
		if bEdge == false then
			if OptionsManager.isOption("SHGL", "on") then
				if (nSuccesses < nFailures or nHalfDice < nFailures) and nSuccesses >= 1 then
					rRoll.sDesc = rRoll.sDesc .. " ".. "\r[GLITCH]"
				elseif (nSuccesses < nFailures or nHalfDice < nFailures) and nSuccesses <= 0 then
					rRoll.sDesc = rRoll.sDesc .. " ".. "\r[CRITICAL GLITCH]"
				end
			else
				if nHalfDice <= nFailures and nSuccesses <= 0 then
					rRoll.sDesc = rRoll.sDesc .. " ".. "\r[CRITICAL GLITCH]"
				elseif nHalfDice <= nFailures and nSuccesses >= 1 then
					rRoll.sDesc = rRoll.sDesc .. " ".. "\r[GLITCH]"
				end
			end
		end	
	end
	
	return rMessage, rSource, rRoll;
end
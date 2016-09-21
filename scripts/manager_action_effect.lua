-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

--	
--	DATA STRUCTURES
--
-- rEffect
--		sName = ""
--		nGMOnly = 0, 1
--

function onInit()
	Interface.onHotkeyDrop = onHotkeyDrop;

	ActionsManager.registerResultHandler("effect", onEffect);
end

function onHotkeyDrop(draginfo)
	local rEffect = decodeEffectFromDrag(draginfo);
	if rEffect then
		draginfo.setSlot(1);
		draginfo.setStringData(encodeEffectAsText(rEffect));
	end
end

function getRoll(draginfo, rActor, rAction)
	local rRoll = encodeEffect(rAction);
	if rRoll.sDesc == "" then
		return nil;
	end
	
	return rRoll;
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = getRoll(draginfo, rActor, rAction);
	if not rRoll then
		return false;
	end
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
	return true;
end

function onEffect(rSource, rTarget, rRoll)
	-- If no target, then report to chat window and exit
	if not rTarget then
		-- Report effect to chat window
		local rMessage = ActionsManager.createActionMessage(nil, rRoll);
		rMessage.icon = "roll_effect";
		Comm.deliverChatMessage(rMessage);
		
		return;
	end

	-- If target not in combat tracker, then we're done
	local sTargetCT = ActorManager.getCTNodeName(rTarget);
	if sTargetCT == "" then
		ChatManager.SystemMessage(Interface.getString("ct_error_effectdroptargetnotinct"));
		return;
	end

	-- Decode effect from roll
	local rEffect = decodeEffect(rRoll);
	if not rEffect then
		ChatManager.SystemMessage(Interface.getString("ct_error_effectdecodefail"));
		return;
	end
	
	-- If source is non-friendly faction and target does not exist or is non-friendly, then effect should be GM only
	if (rSource and ActorManager.getFaction(rSource) ~= "friend") and (not rTarget or ActorManager.getFaction(rTarget) ~= "friend") then
		rEffect.nGMOnly = 1;
	end
	
	-- Apply effect
	EffectManager.notifyApply(rEffect, sTargetCT);
end

--
-- UTILITY FUNCTIONS
--

function decodeEffectFromDrag(draginfo)
	local sDragType = draginfo.getType();
	local sDragDesc = "";

	local bEffectDrag = false;
	if sDragType == "effect" then
		bEffectDrag = true;
		sDragDesc = draginfo.getStringData();
	elseif sDragType == "number" then
		if string.match(sDragDesc, "%[EFFECT") then
			bEffectDrag = true;
			sDragDesc = draginfo.getDescription();
		end
	end
	
	local rEffect = nil;
	if bEffectDrag then
		rEffect = decodeEffectFromText(sDragDesc, draginfo.getSecret());
	end
	
	return rEffect;
end

function encodeEffect(rAction)
	local rRoll = {};
	rRoll.sType = "effect";
	rRoll.sDesc = encodeEffectAsText(rAction);
	if rAction.nGMOnly then
		rRoll.bSecret = (rAction.nGMOnly ~= 0);
	end
	
	return rRoll;
end

function decodeEffect(rRoll)
	local rEffect = decodeEffectFromText(rRoll.sDesc, rRoll.bSecret);
	return rEffect;
end

function encodeEffectAsText(rEffect)
	local aMessage = {};
	
	if rEffect then
		table.insert(aMessage, "[EFFECT] " .. rEffect.sName);
	end
	
	return table.concat(aMessage, " ");
end

function decodeEffectFromText(sEffect, bSecret)
	local rEffect = nil;

	local sEffectName = sEffect:gsub("^%[EFFECT%] ", "");
	sEffectName = StringManager.trim(sEffectName);
	
	if sEffectName ~= "" then
		rEffect = {};
		
		if bSecret then
			rEffect.nGMOnly = 1;
		else
			rEffect.nGMOnly = 0;
		end

		rEffect.sName = sEffectName;
	end
	
	return rEffect;
end

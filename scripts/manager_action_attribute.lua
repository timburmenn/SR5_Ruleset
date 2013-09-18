-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("ability", modRoll);
	ActionsManager.registerResultHandler("ability", onRoll);
end

function getRoll(rActor, sAbilityStat, nTargetDC, bSecretRoll)
	local rRoll = {};
	rRoll.sType = "ability";
	rRoll.aDice = { "d20" };
	rRoll.nMod = ActorManager2.getAbilityBonus(rActor, sAbilityStat);
	
	rRoll.sDesc = "[ABILITY]";
	rRoll.sDesc = rRoll.sDesc .. " " .. StringManager.capitalize(sAbilityStat);
	rRoll.sDesc = rRoll.sDesc .. " check";

	rRoll.bSecret = bSecretRoll;

	rRoll.nTarget = nTargetDC;
	
	return rRoll;
end

function performRoll(draginfo, rActor, sAbilityStat, nTargetDC, bSecretRoll)
	local rRoll = getRoll(rActor, sAbilityStat, nTargetDC, bSecretRoll);
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modRoll(rSource, rTarget, rRoll)
	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;
	
	if rSource then
		local bEffects = false;

		local sActionStat = nil;
		local sAbility = string.match(rRoll.sDesc, "%[ABILITY%] (%w+) check");
		if sAbility then
			sAbility = string.lower(sAbility);
		else
			if string.match(rRoll.sDesc, "%[STABILIZATION%]") then
				sAbility = "constitution";
			end
		end

		-- GET ACTION MODIFIERS
		local nEffectCount;
		aAddDice, nAddMod, nEffectCount = EffectManager.getEffectsBonus(rSource, {"ABIL"}, false, {sAbility});
		if (nEffectCount > 0) then
			bEffects = true;
		end
		
		-- GET CONDITION MODIFIERS
		if EffectManager.hasEffectCondition(rSource, "Frightened") or 
				EffectManager.hasEffectCondition(rSource, "Panicked") or
				EffectManager.hasEffectCondition(rSource, "Shaken") then
			nAddMod = nAddMod - 2;
			bEffects = true;
		end
		if EffectManager.hasEffectCondition(rSource, "Sickened") then
			nAddMod = nAddMod - 2;
			bEffects = true;
		end

		-- GET STAT MODIFIERS
		local nBonusStat, nBonusEffects = ActorManager2.getAbilityEffectsBonus(rSource, sAbility);
		if nBonusEffects > 0 then
			bEffects = true;
			nAddMod = nAddMod + nBonusStat;
		end
		
		-- HANDLE NEGATIVE LEVELS
		local nNegLevelMod, nNegLevelCount = EffectManager.getEffectsBonus(rSource, {"NLVL"}, true);
		if nNegLevelCount > 0 then
			nAddMod = nAddMod - nNegLevelMod;
			bEffects = true;
		end

		-- IF EFFECTS HAPPENED, THEN ADD NOTE
		if bEffects then
			local sEffects = "";
			local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
			if sMod ~= "" then
				sEffects = "[EFFECTS " .. sMod .. "]";
			else
				sEffects = "[EFFECTS]";
			end
			table.insert(aAddDesc, sEffects);
		end
	end
	
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end
	for _,vDie in ipairs(aAddDice) do
		table.insert(rRoll.aDice, "p" .. string.sub(vDie, 2));
	end
	rRoll.nMod = rRoll.nMod + nAddMod;
end

function onRoll(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	if rRoll.nTarget then
		local nTotal = ActionsManager.total(rRoll);
		local nTargetDC = tonumber(rRoll.nTarget) or 0;
		
		rMessage.text = rMessage.text .. " (vs. DC " .. nTargetDC .. ")";
		if nTotal >= nTargetDC then
			rMessage.text = rMessage.text .. " [SUCCESS]";
		else
			rMessage.text = rMessage.text .. " [FAILURE]";
		end
	end
	
	Comm.deliverChatMessage(rMessage);
end


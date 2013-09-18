-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Ruleset action types
actions = {
	["dice"] = { bUseModStack = true },
	["table"] = { },
	["attack"] = { sIcon = "action_attack", sTargeting = "each", bUseModStack = true },
	["grapple"] = { sIcon = "action_attack", sTargeting = "each", bUseModStack = true },
	["damage"] = { sIcon = "action_damage", sTargeting = "each", bUseModStack = true },
	["heal"] = { sIcon = "action_heal", sTargeting = "all", bUseModStack = true },
	["effect"] = { sIcon = "action_effect", sTargeting = "all" },
	["cast"] = { sTargeting = "each" },
	["castclc"] = { sTargeting = "each" },
	["castsave"] = { sTargeting = "each" },
	["clc"] = { sTargeting = "each", bUseModStack = true },
	["spellsave"] = { sTargeting = "each" },
	["spdamage"] = { sIcon = "action_damage", sTargeting = "all", bUseModStack = true },
	["skill"] = { bUseModStack = true },
	["init"] = { bUseModStack = true },
	["save"] = { bUseModStack = true },
	["ability"] = { bUseModStack = true },
	-- PF SPECIFIC
	["concentration"] = { bUseModStack = true },
	-- TRIGGERED
	["critconfirm"] = { },
	["misschance"] = { },
	["stabilization"] = { },
};

targetactions = {
	"attack",
	"grapple",
	"damage",
	"spdamage",
	"heal",
	"effect",
	"cast",
	"clc",
	"spellsave"
};

function getCharSelectDetailHost(nodeChar)
	local sValue = "";
	local nLevel = DB.getValue(nodeChar, "level", 0);
	if nLevel > 0 then
		sValue = "Level " .. nLevel;
	end
	return sValue;
end

function requestCharSelectDetailClient()
	return "name,#level";
end

function receiveCharSelectDetailClient(vDetails)
	return vDetails[1], "Level " .. vDetails[2];
end

function getCharSelectDetailLocal(nodeLocal)
	local vDetails = {};
	table.insert(vDetails, DB.getValue(nodeLocal, "name", ""));
	table.insert(vDetails, DB.getValue(nodeLocal, "level", 0));
	return receiveCharSelectDetailClient(vDetails);
end

function getDistanceUnitsPerGrid()
	return 5;
end

function getDeathThreshold(rActor)
	local nDying = 10;

	if DataCommon.isPFRPG() then
		local nStat = ActorManager2.getAbilityScore(rActor, "constitution");
		if nStat < 0 then
			nDying = 10;
		else
			nDying = nStat - ActorManager2.getAbilityDamage(rActor, "constitution");
			if nDying < 1 then
				nDying = 1;
			end
		end
	end
	
	return nDying;
end

function getStabilizationRoll(rActor)
	local rRoll = { sType = "stabilization", sDesc = "[STABILIZATION]" };
	
	if DataCommon.isPFRPG() then
		rRoll.aDice = { "d20" };
		rRoll.nMod = ActorManager2.getAbilityBonus(rActor, "constitution");
		
		local nHP = 0;
		local nWounds = 0;
		if rActor.sType == "npc" then
			nHP = DB.getValue(rActor.nodeCT, "hp", 0);
			nWounds = DB.getValue(rActor.nodeCT, "wounds", 0);
		elseif rActor.sType == "pc" then
			nHP = DB.getValue(rActor.nodeCreature, "hp.total", 0);
			nWounds = DB.getValue(rActor.nodeCreature, "hp.wounds", 0);
		end
		if nHP > 0 and nWounds > nHP then
			rRoll.sDesc = string.format("%s [at %+d]", rRoll.sDesc, (nHP - nWounds));
			rRoll.nMod = rRoll.nMod + (nHP - nWounds);
		end
	
	else
		rRoll.aDice = { "d100", "d10" };
		rRoll.nMod = 0;
	end
	
	return rRoll;
end

function modStabilization(rSource, rTarget, rRoll)
	if DataCommon.isPFRPG() then
		ActionAbility.modRoll(rSource, rTarget, rRoll);
	end
end

function getStabilizationResult(rRoll)
	local bSuccess = false;
	
	local nTotal = ActionsManager.total(rRoll);

	if DataCommon.isPFRPG() then
		local nFirstDie = 0;
		if #(rRoll.aDice) > 0 then
			nFirstDie = rRoll.aDice[1].result or 0;
		end
		
		if nFirstDie >= 20 or nTotal >= 10 then
			bSuccess = true;
		end
	else
		if nTotal <= 10 then
			bSuccess = true;
		end
	end
	
	return bSuccess;
end

function performConcentrationCheck(draginfo, rActor, nodeSpellClass)
	if DataCommon.isPFRPG() then
		local rRoll = { sType = "concentration", sDesc = "[CONCENTRATION]", aDice = { "d20" } };
	
		local sAbility = DB.getValue(nodeSpellClass, "dc.ability", "");
		local sAbilityEffect = DataCommon.ability_ltos[sAbility];
		if sAbilityEffect then
			rRoll.sDesc = rRoll.sDesc .. " [MOD:" .. sAbilityEffect .. "]";
		end

		local nCL = DB.getValue(nodeSpellClass, "cl", 0);
		rRoll.nMod = nCL + ActorManager2.getAbilityBonus(rActor, sAbility);
		
		local nCCMisc = DB.getValue(nodeSpellClass, "cc.misc", 0);
		if nCCMisc ~= 0 then
			rRoll.nMod = rRoll.nMod + nCCMisc;
			rRoll.sDesc = string.format("%s (Spell Class %+d)", rRoll.sDesc, nCCMisc);
		end
		
		ActionsManager.performAction(draginfo, rActor, rRoll);
	else
		local sSkill = "Concentration";
		local nValue = 0;
		if rActor.sType == "pc" then
			nValue = CharManager.getSkillValue(rActor, sSkill);
		else
			local sSkills = DB.getValue(rActor.nodeCreature, "skills", "");
			local aSkillClauses = StringManager.split(sSkills, ",;\r", true);
			for i = 1, #aSkillClauses do
				local nStarts, nEnds, sLabel, sSign, sMod = string.find(aSkillClauses[i], "([%w%s\(\)]*[%w\(\)]+)%s*([%+%-–]?)(%d*)");
				if nStarts and string.lower(sSkill) == string.lower(sLabel) and sMod ~= "" then
					nValue = tonumber(sMod) or 0;
					if sSign == "-" or sSign == "–" then
						nValue = 0 - nValue;
					end
					break;
				end
			end
		end
		
		local sExtra = nil;
		local nCCMisc = DB.getValue(nodeSpellClass, "cc.misc", 0);
		if nCCMisc ~= 0 then
			nValue = nValue + nCCMisc;
			sExtra = string.format("(Spell Class %+d)", nCCMisc);
		end
		
		ActionSkill.performRoll(draginfo, rActor, sSkill, nValue, nil, nil, false, sExtra);
	end
end

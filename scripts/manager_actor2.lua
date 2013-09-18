-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function getPercentWounded(sNodeType, node)
	local nHP = 0;
	local nTemp = 0;
	local nWounds = 0;
	local nNonlethal = 0;
	
	if sNodeType == "ct" then
		nHP = math.max(DB.getValue(node, "hp", 0), 0);
		nTemp = math.max(DB.getValue(node, "hptemp", 0), 0);
		nWounds = math.max(DB.getValue(node, "wounds", 0), 0);
		nNonlethal = math.max(DB.getValue(node, "nonlethal", 0), 0);
	elseif sNodeType == "pc" then
		nHP = math.max(DB.getValue(node, "hp.total", 0), 0);
		nTemp = math.max(DB.getValue(node, "hp.temporary", 0), 0);
		nWounds = math.max(DB.getValue(node, "hp.wounds", 0), 0);
		nNonlethal = math.max(DB.getValue(node, "hp.nonlethal", 0), 0);
	end
	
	local nPercentWounded = 0;
	local nPercentNonlethal = 0;
	if nHP > 0 then
		nPercentWounded = nWounds / nHP;
		nPercentNonlethal = (nWounds + nNonlethal) / (nHP + nTemp);
	end
	
	local sStatus;
	if OptionsManager.isOption("WNDC", "detailed") then
		if nPercentWounded > 1 then
			local nNegative = nWounds - nHP;
			
			if nNegative < -9 then
				sStatius = "Dead";
			elseif nNegative < -6 then
				sStatus = "Mortally Wounded";
			else
				sStatus = "Greviously Wounded";
			end
		elseif nPercentNonlethal > 1 then
			sStatus = "Unconscious";
		elseif nPercentWounded == 1 then
			sStatus = "Disabled";
		elseif nPercentNonlethal == 1 then
			sStatus = "Staggered";
		elseif nPercentNonlethal >= .75 then
			sStatus = "Critical";
		elseif nPercentNonlethal >= .5 then
			sStatus = "Heavy";
		elseif nPercentNonlethal >= .25 then
			sStatus = "Moderate";
		elseif nPercentNonlethal > 0 then
			sStatus = "Light";
		else
			sStatus = "Healthy";
		end
	else
		if nPercentWounded > 1 then
			local nNegative = nWounds - nHP;
			
			if nNegative < -9 then
				sStatius = "Dead";
			elseif nNegative < -6 then
				sStatus = "Mortally Wounded";
			else
				sStatus = "Greviously Wounded";
			end
		elseif nPercentNonlethal > 1 then
			sStatus = "Unconscious";
		elseif nPercentWounded == 1 then
			sStatus = "Disabled";
		elseif nPercentNonlethal == 1 then
			sStatus = "Staggered";
		elseif nPercentNonlethal >= .5 then
			sStatus = "Heavy";
		elseif nPercentNonlethal > 0 then
			sStatus = "Wounded";
		else
			sStatus = "Healthy";
		end
	end
	
	return nPercentWounded, nPercentNonlethal, sStatus;
end

function getWoundColor(sNodeType, node)
	local nPercentWounded, nPercentNonlethal, sStatus = getPercentWounded(sNodeType, node);
	
	-- Based on the percent wounded, change the font color for the Wounds field
	local sColor;
	if OptionsManager.isOption("WNDC", "detailed") then
		if nPercentWounded > 1 then
			sColor = "404040";
		elseif nPercentNonlethal > 1 then
			sColor = "6C2DC7";
		elseif nPercentWounded == 1 then
			sColor = "C11B17";
		elseif nPercentNonlethal == 1 then
			sColor = "C11B17";
		elseif nPercentNonlethal >= 0.75 then
			sColor = "C11B17";
		elseif nPercentNonlethal >= 0.5 then
			sColor = "E56717";
		elseif nPercentNonlethal >= 0.25 then
			sColor = "AF7817";
		elseif nPercentNonlethal > 0 then
			sColor = "408000";
		else
			sColor = "006600";
		end
	else
		if nPercentWounded > 1 then
			sColor = "404040";
		elseif nPercentNonlethal > 1 then
			sColor = "6C2DC7";
		elseif nPercentWounded == 1 then
			sColor = "C11B17";
		elseif nPercentNonlethal == 1 then
			sColor = "C11B17";
		elseif nPercentNonlethal >= 0.5 then
			sColor = "C11B17";
		elseif nPercentNonlethal > 0 then
			sColor = "408000";
		else
			sColor = "006600";
		end
	end

	return sColor, nPercentWounded, nPercentNonlethal, sStatus;
end

function getWoundBarColor(sNodeType, node)
	local nPercentWounded, nPercentNonlethal, sStatus = getPercentWounded(sNodeType, node);
	
	local nRedR = 255;
	local nRedG = 0;
	local nRedB = 0;
	local nYellowR = 255;
	local nYellowG = 191;
	local nYellowB = 0;
	local nGreenR = 0;
	local nGreenG = 255;
	local nGreenB = 0;
	
	local sColor;
	if nPercentWounded > 1 then
		sColor = "C0C0C0";
	elseif nPercentNonlethal > 1 then
		sColor = "8C3BFF";
	else
		local nBarR, nBarG, nBarB;
		if nPercentNonlethal >= 0.5 then
			local nPercentGrade = (nPercentNonlethal - 0.5) * 2;
			nBarR = math.floor((nRedR * nPercentGrade) + (nYellowR * (1.0 - nPercentGrade)) + 0.5);
			nBarG = math.floor((nRedG * nPercentGrade) + (nYellowG * (1.0 - nPercentGrade)) + 0.5);
			nBarB = math.floor((nRedB * nPercentGrade) + (nYellowB * (1.0 - nPercentGrade)) + 0.5);
		else
			local nPercentGrade = nPercentNonlethal * 2;
			nBarR = math.floor((nYellowR * nPercentGrade) + (nGreenR * (1.0 - nPercentGrade)) + 0.5);
			nBarG = math.floor((nYellowG * nPercentGrade) + (nGreenG * (1.0 - nPercentGrade)) + 0.5);
			nBarB = math.floor((nYellowB * nPercentGrade) + (nGreenB * (1.0 - nPercentGrade)) + 0.5);
		end
		sColor = string.format("%02X%02X%02X", nBarR, nBarG, nBarB);
	end

	return sColor, nPercentWounded, nPercentNonlethal, sStatus;
end

function getAbilityEffectsBonus(rActor, sAbility)
	if not rActor or not sAbility then
		return 0, 0;
	end
	
	local sAbilityEffect = DataCommon.ability_ltos[sAbility];
	if not sAbilityEffect then
		return 0, 0;
	end
	
	local nEffectMod, nAbilityEffects = EffectManager.getEffectsBonus(rActor, sAbilityEffect, true);
	
	if sAbility == "dexterity" then
		if EffectManager.hasEffectCondition(rActor, "Entangled") then
			nEffectMod = nEffectMod - 4;
			nAbilityEffects = nAbilityEffects + 1;
		end
		if DataCommon.isPFRPG() and EffectManager.hasEffectCondition(rActor, "Grappled") then
			nEffectMod = nEffectMod - 4;
			nAbilityEffects = nAbilityEffects + 1;
		end
	end
	if sAbility == "dexterity" or sAbility == "strength" then
		if EffectManager.hasEffectCondition(rActor, "Exhausted") then
			nEffectMod = nEffectMod - 6;
			nAbilityEffects = nAbilityEffects + 1;
		elseif EffectManager.hasEffectCondition(rActor, "Fatigued") then
			nEffectMod = nEffectMod - 2;
			nAbilityEffects = nAbilityEffects + 1;
		end
	end
	
	local nAbilityMod = 0;
	local nAbilityScore = getAbilityScore(rActor, sAbility);
	if nAbilityScore > 0 and not DataCommon.isPFRPG() then
		local nAbilityDamage = getAbilityDamage(rActor, sAbility);
		local nAffectedScore = math.max(nAbilityScore - nAbilityDamage + nEffectMod, 0);
		
		local nCurrentBonus = math.floor((nAbilityScore - 10) / 2);
		local nAffectedBonus = math.floor((nAffectedScore - 10) / 2);
		
		nAbilityMod = nAffectedBonus - nCurrentBonus;
	else
		if nEffectMod > 0 then
			nAbilityMod = math.floor(nEffectMod / 2);
		else
			nAbilityMod = math.ceil(nEffectMod / 2);
		end
	end

	return nAbilityMod, nAbilityEffects;
end

function getAbilityDamage(rActor, sAbility)
	if not rActor or not rActor.nodeCreature or not sAbility then
		return -1;
	end
	
	local nStatDamage = -1;

	local sShort = string.sub(string.lower(sAbility), 1, 3);
	if rActor.sType == "npc" then
		nStatDamage = 0;
	elseif rActor.sType == "pc" then
		if sShort == "lev" then
			nStatDamage = 0;
		elseif sShort == "bab" then
			nStatDamage = 0;
		elseif sShort == "str" then
			nStatDamage = DB.getValue(rActor.nodeCreature, "abilities.strength.damage", 0);
		elseif sShort == "dex" then
			nStatDamage = DB.getValue(rActor.nodeCreature, "abilities.dexterity.damage", 0);
		elseif sShort == "con" then
			nStatDamage = DB.getValue(rActor.nodeCreature, "abilities.constitution.damage", 0);
		elseif sShort == "int" then
			nStatDamage = DB.getValue(rActor.nodeCreature, "abilities.intelligence.damage", 0);
		elseif sShort == "wis" then
			nStatDamage = DB.getValue(rActor.nodeCreature, "abilities.wisdom.damage", 0);
		elseif sShort == "cha" then
			nStatDamage = DB.getValue(rActor.nodeCreature, "abilities.charisma.damage", 0);
		end
	end
	
	return nStatDamage;
end

function getAbilityScore(rActor, sAbility)
	if not rActor or not rActor.nodeCreature or not sAbility then
		return -1;
	end
	
	local nStatScore = -1;
	
	local sShort = string.sub(string.lower(sAbility), 1, 3);
	if rActor.sType == "npc" then
		if sShort == "lev" then
			nStatScore = tonumber(string.match(DB.getValue(rActor.nodeCreature, "hd", ""), "^(%d+)")) or 0;
		elseif sShort == "bab" then
			nStatScore = 0;

			local sBABGrp = DB.getValue(rActor.nodeCreature, "babgrp", "");
			local sBAB = string.match(sBABGrp, "[+-]?%d+");
			if sBAB then
				nStatScore = tonumber(sBAB) or 0;
			end
		elseif sShort == "str" then
			nStatScore = DB.getValue(rActor.nodeCreature, "strength", 0);
		elseif sShort == "dex" then
			nStatScore = DB.getValue(rActor.nodeCreature, "dexterity", 0);
		elseif sShort == "con" then
			nStatScore = DB.getValue(rActor.nodeCreature, "constitution", 0);
		elseif sShort == "int" then
			nStatScore = DB.getValue(rActor.nodeCreature, "intelligence", 0);
		elseif sShort == "wis" then
			nStatScore = DB.getValue(rActor.nodeCreature, "wisdom", 0);
		elseif sShort == "cha" then
			nStatScore = DB.getValue(rActor.nodeCreature, "charisma", 0);
		end
	elseif rActor.sType == "pc" then
		if sShort == "lev" then
			nStatScore = DB.getValue(rActor.nodeCreature, "level", 0);
		elseif sShort == "bab" then
			nStatScore = DB.getValue(rActor.nodeCreature, "attackbonus.base", 0);
		elseif sShort == "str" then
			nStatScore = DB.getValue(rActor.nodeCreature, "abilities.strength.score", 0);
		elseif sShort == "dex" then
			nStatScore = DB.getValue(rActor.nodeCreature, "abilities.dexterity.score", 0);
		elseif sShort == "con" then
			nStatScore = DB.getValue(rActor.nodeCreature, "abilities.constitution.score", 0);
		elseif sShort == "int" then
			nStatScore = DB.getValue(rActor.nodeCreature, "abilities.intelligence.score", 0);
		elseif sShort == "wis" then
			nStatScore = DB.getValue(rActor.nodeCreature, "abilities.wisdom.score", 0);
		elseif sShort == "cha" then
			nStatScore = DB.getValue(rActor.nodeCreature, "abilities.charisma.score", 0);
		end
	end
	
	return nStatScore;
end

function getAbilityBonus(rActor, sAbility)
	-- VALIDATE
	if not rActor or not rActor.nodeCreature or not sAbility then
		return 0;
	end
	
	-- SETUP
	local sStat = sAbility;
	local bHalf = false;
	local bDouble = false;
	local nStatVal = 0;
	
	-- HANDLE HALF/DOUBLE MODIFIERS
	if string.match(sStat, "^half") then
		bHalf = true;
		sStat = string.sub(sStat, 5);
	end
	if string.match(sStat, "^double") then
		bDouble = true;
		sStat = string.sub(sStat, 7);
	end

	-- GET ABILITY VALUE
	local nStatScore = getAbilityScore(rActor, sStat);
	if nStatScore < 0 then
		return 0;
	end
	
	if StringManager.contains(DataCommon.abilities, sStat) then
		nStatVal = math.floor((nStatScore - 10) / 2);
		if rActor.sType == "pc" then
			nStatVal = nStatVal + DB.getValue(rActor.nodeCreature, "abilities." .. sStat .. ".bonusmodifier", 0);
			nStatVal = nStatVal - math.floor(DB.getValue(rActor.nodeCreature, "abilities." .. sStat .. ".damage", 0) / 2);
		end
	else
		nStatVal = nStatScore;
	end
	
	-- APPLY HALF/DOUBLE MODIFIERS
	if bDouble then
		nStatVal = nStatVal * 2;
	end
	if bHalf then
		nStatVal = math.floor(nStatVal / 2);
	end

	-- RESULTS
	return nStatVal;
end

function getSpellDefense(rActor)
	local nSR = 0;
	
	if rActor.nodeCT then
		nSR = DB.getValue(rActor.nodeCT, "sr", 0);
	elseif rActor.nodeCreature then
		if rActor.sType == "pc" then
			nSR = DB.getValue(rActor.nodeCreature, "defenses.sr.total", 0);
		else
			local sSpecialQualities = string.lower(DB.getValue(rActor.nodeCreature, "specialqualities", ""));
			local sSpellResist = string.match(sSpecialQualities, "spell resistance (%d+)");
			if not sSpellResist then
				sSpellResist = string.match(sSpecialQualities, "sr (%d+)");
			end
			if sSpellResist then
				nSR = tonumber(sSpellResist) or 0;
			end
		end
	end
	
	return nSR;
end

function getDefenseValue(rAttacker, rDefender, rRoll)
	-- VALIDATE
	if not rDefender or not rRoll then
		return nil, 0, 0, 0;
	end
	
	local sAttack = rRoll.sDesc;
	
	-- DETERMINE ATTACK TYPE AND DEFENSE
	local sAttackType = "M";
	if rRoll.sType == "attack" then
		sAttackType = string.match(sAttack, "%[ATTACK.*%((%w+)%)%]");
	end
	local bOpportunity = string.match(sAttack, "%[OPPORTUNITY%]");
	local bTouch = true;
	if rRoll.sType == "attack" then
		bTouch = string.match(sAttack, "%[TOUCH%]");
	end
	local bFlatFooted = string.match(sAttack, "%[FF%]");
	local nCover = tonumber(string.match(sAttack, "%[COVER %-(%d)%]")) or 0;
	local bConceal = string.match(sAttack, "%[CONCEAL%]");
	local bTotalConceal = string.match(sAttack, "%[TOTAL CONC%]");
	local bAttackerBlinded = string.match(sAttack, "%[BLINDED%]");

	-- Determine the defense database node name
	local nDefense = 10;
	local nFlatFootedMod = 0;
	local nTouchMod = 0;
	local sDefenseStat = "dexterity";
	local sDefenseStat2 = "";
	local sDefenseStat3 = "";
	if rRoll.sType == "grapple" then
		sDefenseStat3 = "strength";
	end

	if rDefender.nodeCreature and rDefender.sType == "pc" then
		if rRoll.sType == "attack" then
			nDefense = DB.getValue(rDefender.nodeCreature, "ac.totals.general", 10);
			nFlatFootedMod = nDefense - DB.getValue(rDefender.nodeCreature, "ac.totals.flatfooted", 10);
			nTouchMod = nDefense - DB.getValue(rDefender.nodeCreature, "ac.totals.touch", 10);
		else
			nDefense = DB.getValue(rDefender.nodeCreature, "ac.totals.cmd", 10);
			nFlatFootedMod = DB.getValue(rDefender.nodeCreature, "ac.totals.general", 10) - DB.getValue(rDefender.nodeCreature, "ac.totals.flatfooted", 10);
		end
		sDefenseStat = DB.getValue(rDefender.nodeCreature, "ac.sources.ability", "");
		if sDefenseStat == "" then
			sDefenseStat = "dexterity";
		end
		sDefenseStat2 = DB.getValue(rDefender.nodeCreature, "ac.sources.ability2", "");
		if rRoll.sType == "grapple" then
			sDefenseStat3 = DB.getValue(rDefender.nodeCreature, "ac.sources.cmdability", "");
			if sDefenseStat3 == "" then
				sDefenseStat3 = "strength";
			end
		end
	elseif rDefender.nodeCT then
		if rRoll.sType == "attack" then
			nDefense = DB.getValue(rDefender.nodeCT, "ac_final", 10);
			nFlatFootedMod = nDefense - DB.getValue(rDefender.nodeCT, "ac_flatfooted", 10);
			nTouchMod = nDefense - DB.getValue(rDefender.nodeCT, "ac_touch", 10);
		else
			nDefense = DB.getValue(rDefender.nodeCT, "cmd", 10);
			nFlatFootedMod = DB.getValue(rDefender.nodeCT, "ac_final", 10) - DB.getValue(rDefender.nodeCT, "ac_flatfooted", 10);
		end
	elseif rDefender.nodeCreature then
		if rRoll.sType == "attack" then
			local sAC = DB.getValue(rDefender.nodeCreature, "ac", "");
			nDefense = tonumber(string.match(sAC, "^%s*(%d+)")) or 10;

			local sFlatFootedAC = string.match(sAC, "flat-footed (%d+)");
			if sFlatFootedAC then
				nFlatFootedMod = nDefense - tonumber(sFlatFootedAC);
			else
				nFlatFootedMod = getAbilityBonus(rDefender, sDefenseStat);
			end
			
			local sTouchAC = string.match(sAC, "touch (%d+)");
			if sTouchAC then
				nTouchMod = nDefense - tonumber(sTouchAC);
			end
		else
			local sBABGrp = DB.getValue(rDefender.nodeCreature, "babgrp", "");
			local sMatch = string.match(sBABGrp, "CMD ([+-]?[0-9]+)");
			if sMatch then
				nDefense = tonumber(sMatch) or 10;
			else
				nDefense = 10;
			end
			
			local sAC = DB.getValue(rDefender.nodeCreature, "ac", "");
			local nAC = tonumber(string.match(sAC, "^%s*(%d+)")) or 10;

			local sFlatFootedAC = string.match(sAC, "flat-footed (%d+)");
			if sFlatFootedAC then
				nFlatFootedMod = nAC - tonumber(sFlatFootedAC);
			else
				nFlatFootedMod = getAbilityBonus(rDefender, sDefenseStat);
			end
		end
	else
		return nil, 0, 0, 0;
	end
	nDefenseStatMod = getAbilityBonus(rDefender, sDefenseStat) + getAbilityBonus(rDefender, sDefenseStat2);
	
	-- MAKE SURE FLAT-FOOTED AND TOUCH ADJUSTMENTS ARE POSITIVE
	if nTouchMod < 0 then
		nTouchMod = 0;
	end
	if nFlatFootedMod < 0 then
		nFlatFootedMod = 0;
	end
	
	-- APPLY FLAT-FOOTED AND TOUCH ADJUSTMENTS
	if bTouch then
		nDefense = nDefense - nTouchMod;
	end
	if bFlatFooted then
		nDefense = nDefense - nFlatFootedMod;
	end
	
	-- EFFECT MODIFIERS
	local nAttackEffectMod = 0;
	local nDefenseEffectMod = 0;
	local nMissChance = 0;
	if rDefender.nodeCT then
		-- SETUP
		local bCombatAdvantage = false;
		local bZeroAbility = false;
		local nBonusAC = 0;
		local nBonusStat = 0;
		local nBonusSituational = 0;
		
		local bPFMode = DataCommon.isPFRPG();
		
		-- BUILD ATTACK FILTER 
		local aAttackFilter = {};
		if sAttackType == "M" then
			table.insert(aAttackFilter, "melee");
		elseif sAttackType == "R" then
			table.insert(aAttackFilter, "ranged");
		end
		if bOpportunity then
			table.insert(aAttackFilter, "opportunity");
		end
		if not bFlatFooted then
			table.insert(aAttackFilter, "dodge");
		end

		-- GET ATTACKER BASE MODIFIER
		local aBonusTargetedAttackDice, nBonusTargetedAttack = EffectManager.getEffectsBonus(rAttacker, "ATK", false, aAttackFilter, rDefender, true);
		if rRoll.sType == "grapple" then
			local aPFDice, nPFMod, nPFCount = EffectManager.getEffectsBonus(rAttacker, {"CMB"}, false, aAttackFilter, rDefender, true);
			if nPFCount > 0 then
				bEffects = true;
				for k, v in ipairs(aPFDice) do
					table.insert(aBonusTargetedAttackDice, v);
				end
				nBonusTargetedAttack = nBonusTargetedAttack + nPFMod;
			end
		end
		nAttackEffectMod = nAttackEffectMod + StringManager.evalDice(aBonusTargetedAttackDice, nBonusTargetedAttack);
					
		-- CHECK IF COMBAT ADVANTAGE ALREADY SET BY ATTACKER EFFECT
		if string.match(sAttack, "%[CA%]") then
			bCombatAdvantage = true;
		end
		
		-- GET DEFENDER ALL DEFENSE MODIFIERS
		local aIgnoreEffects = {};
		if bTouch then
			table.insert(aIgnoreEffects, "armor");
			table.insert(aIgnoreEffects, "shield");
			table.insert(aIgnoreEffects, "natural");
		end
		if bFlatFooted then
			table.insert(aIgnoreEffects, "dodge");
		end
		local aACEffects, nACEffectCount = EffectManager.getEffectsBonusByType(rDefender, {"AC"}, true, aAttackFilter, rAttacker);
		for k,v in pairs(aACEffects) do
			if not StringManager.contains(aIgnoreEffects, k) then
				nBonusAC = nBonusAC + v.mod;
			end
		end
		if rRoll.sType == "grapple" then
			local nPFMod, nPFCount = EffectManager.getEffectsBonus(rDefender, {"CMD"}, true, aAttackFilter, rAttacker);
			if nPFCount > 0 then
				nBonusAC = nBonusAC + nPFMod;
			end
		end
		
		-- GET DEFENDER DEFENSE STAT MODIFIERS
		nBonusStat = getAbilityEffectsBonus(rDefender, sDefenseStat);
		nBonusStat = nBonusStat + getAbilityEffectsBonus(rDefender, sDefenseStat2);
		if bFlatFooted then
			-- IF NEGATIVE AND AC STAT BONUSES, THEN ONLY APPLY THE AMOUNT THAT EXCEEDS AC STAT BONUSES
			if nBonusStat < 0 then
				if nDefenseStatMod > 0 then
					nBonusStat = math.min(nDefenseStatMod + nBonusStat, 0);
				end
				
			-- IF POSITIVE AND AC STAT PENALTIES, THEN ONLY APPLY UP TO AC STAT PENALTIES
			else
				if nDefenseStatMod < 0 then
					nBonusStat = math.min(nBonusStat, -nDefenseStatMod);
				else
					nBonusStat = 0;
				end
			end
		end
		nBonusStat = nBonusStat + getAbilityEffectsBonus(rDefender, sDefenseStat3);
		
		-- GET DEFENDER SITUATIONAL MODIFIERS - GENERAL
		if EffectManager.hasEffect(rAttacker, "CA", rDefender, true) then
			bCombatAdvantage = true;
		end
		if EffectManager.hasEffect(rAttacker, "Invisible", rDefender, true) then
			nBonusSituational = nBonusSituational - 2;
			bCombatAdvantage = true;
		end
		if EffectManager.hasEffect(rDefender, "GRANTCA", rAttacker) then
			bCombatAdvantage = true;
		end
		if EffectManager.hasEffect(rDefender, "Blinded") then
			nBonusSituational = nBonusSituational - 2;
			bCombatAdvantage = true;
		end
		if EffectManager.hasEffect(rDefender, "Cowering") or
				EffectManager.hasEffect(rDefender, "Rebuked") then
			nBonusSituational = nBonusSituational - 2;
			bCombatAdvantage = true;
		end
		if EffectManager.hasEffect(rDefender, "Slowed") then
			nBonusSituational = nBonusSituational - 1;
			bCombatAdvantage = true;
		end
		if EffectManager.hasEffect(rDefender, "Flat-footed") or 
				EffectManager.hasEffect(rDefender, "Climbing") or 
				EffectManager.hasEffect(rDefender, "Running") then
			bCombatAdvantage = true;
		end
		if EffectManager.hasEffect(rDefender, "Pinned") then
			bCombatAdvantage = true;
			if bPFMode then
				nBonusSituational = nBonusSituational - 4;
			else
				if not EffectManager.hasEffect(rAttacker, "Grappled") then
					nBonusSituational = nBonusSituational - 4;
				end
			end
		elseif not bPFMode and EffectManager.hasEffect(rDefender, "Grappled") then
			if not EffectManager.hasEffect(rAttacker, "Grappled") then
				bCombatAdvantage = true;
			end
		end
		if EffectManager.hasEffect(rDefender, "Helpless") or 
				EffectManager.hasEffect(rDefender, "Paralyzed") or 
				EffectManager.hasEffect(rDefender, "Petrified") or
				EffectManager.hasEffect(rDefender, "Unconscious") then
			if sAttackType == "M" then
				nBonusSituational = nBonusSituational - 4;
			end
			bZeroAbility = true;
		end
		if EffectManager.hasEffect(rDefender, "Kneeling") or 
				EffectManager.hasEffect(rDefender, "Sitting") then
			if sAttackType == "M" then
				nBonusSituational = nBonusSituational - 2;
			elseif sAttackType == "R" then
				nBonusSituational = nBonusSituational + 2;
			end
		elseif EffectManager.hasEffect(rDefender, "Prone") then
			if sAttackType == "M" then
				nBonusSituational = nBonusSituational - 4;
			elseif sAttackType == "R" then
				nBonusSituational = nBonusSituational + 4;
			end
		end
		if EffectManager.hasEffect(rDefender, "Squeezing") then
			nBonusSituational = nBonusSituational - 4;
		end
		if EffectManager.hasEffect(rDefender, "Stunned") then
			nBonusSituational = nBonusSituational - 2;
			if rRoll.sType == "grapple" then
				nBonusSituational = nBonusSituational - 4;
			end
			bCombatAdvantage = true;
		end
		if EffectManager.hasEffect(rDefender, "Invisible", rAttacker) then
			bTotalConceal = true;
		end
		
		-- HANDLE NEGATIVE LEVELS
		if rRoll.sType == "grapple" then
			local nNegLevelMod, nNegLevelCount = EffectManager.getEffectsBonus(rDefender, {"NLVL"}, true);
			if nNegLevelCount > 0 then
				nBonusSituational = nBonusSituational - nNegLevelMod;
			end
		end
		
		-- HANDLE DEXTERITY MODIFIER REMOVAL
		if bZeroAbility then
			if bFlatFooted then
				nBonusSituational = nBonusSituational - 5;
			else
				nBonusSituational = nBonusSituational - nFlatFootedMod - 5;
			end
		elseif bCombatAdvantage and not bFlatFooted then
			nBonusSituational = nBonusSituational - nFlatFootedMod;
		end

		-- GET DEFENDER SITUATIONAL MODIFIERS - COVER
		if nCover < 8 then
			local aCover = EffectManager.getEffectsByType(rDefender, "SCOVER", aAttackFilter, rAttacker);
			if #aCover > 0 or EffectManager.hasEffect(rDefender, "SCOVER", rAttacker) then
				nBonusSituational = nBonusSituational + 8 - nCover;
			elseif nCover < 4 then
				aCover = EffectManager.getEffectsByType(rDefender, "COVER", aAttackFilter, rAttacker);
				if #aCover > 0 or EffectManager.hasEffect(rDefender, "COVER", rAttacker) then
					nBonusSituational = nBonusSituational + 4 - nCover;
				elseif nCover < 2 then
					aCover = EffectManager.getEffectsByType(rDefender, "PCOVER", aAttackFilter, rAttacker);
					if #aCover > 0 or EffectManager.hasEffect(rDefender, "PCOVER", rAttacker) then
						nBonusSituational = nBonusSitiational + 2 - nCover;
					end
				end
			end
		end
		
		-- GET DEFENDER SITUATIONAL MODIFIERS - CONCEALMENT
		local aConceal = EffectManager.getEffectsByType(rDefender, "TCONC", aAttackFilter, rAttacker);
		if #aConceal > 0 or EffectManager.hasEffect(rDefender, "TCONC", rAttacker) or bTotalConceal or bAttackerBlinded then
			nMissChance = 50;
		else
			aConceal = EffectManager.getEffectsByType(rDefender, "CONC", aAttackFilter, rAttacker);
			if #aConceal > 0 or EffectManager.hasEffect(rDefender, "CONC", rAttacker) or bConceal then
				nMissChance = 20;
			end
		end
		
		-- CHECK INCORPOREALITY
		if not bPFMode then
			local bIncorporealAttack = false;
			if string.match(sAttack, "%[INCORPOREAL%]") then
				bIncorporealAttack = true;
			end
			local bIncorporealDefender = EffectManager.hasEffect(rDefender, "Incorporeal", rAttacker);

			if bIncorporealAttack ~= bIncorporealDefender then
				nMissChance = 50;
			end
		end
		
		-- ADD IN EFFECT MODIFIERS
		nDefenseEffectMod = nBonusAC + nBonusStat + nBonusSituational;
	
	-- NO DEFENDER SPECIFIED, SO JUST LOOK AT THE ATTACK ROLL MODIFIERS
	else
		if bTotalConceal or bAttackerBlinded then
			nMissChance = 50;
		elseif bConceal then
			nMissChance = 20;
		end
		
		if bIncorporealAttack then
			nMissChance = 50;
		end
	end
	
	-- Return the final defense value
	return nDefense + nDefenseEffectMod - nAttackEffectMod, nAttackEffectMod, nDefenseEffectMod, nMissChance;
end

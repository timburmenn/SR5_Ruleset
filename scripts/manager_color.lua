-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

COLOR_FULL = "000000";
COLOR_THREE_QUARTER = "300000";
COLOR_HALF = "600000";
COLOR_QUARTER = "B00000";
COLOR_EMPTY = "C0C0C0";

COLOR_GRADIENT_TOP = { r = 0, g = 0, b = 0 };
COLOR_GRADIENT_MID = { r = 96, g = 0, b = 0 };
COLOR_GRADIENT_BOTTOM = { r = 255, g = 0, b = 0 };

COLOR_HEALTH_UNWOUNDED = "008000";
COLOR_HEALTH_DYING_OR_DEAD = "404040";

COLOR_HEALTH_SIMPLE_WOUNDED = "408000";
COLOR_HEALTH_SIMPLE_BLOODIED = "C11B17";

COLOR_HEALTH_LT_WOUNDS = "408000";
COLOR_HEALTH_MOD_WOUNDS = "AF7817";
COLOR_HEALTH_HVY_WOUNDS = "E56717";
COLOR_HEALTH_CRIT_WOUNDS = "C11B17";

COLOR_HEALTH_GRADIENT_TOP = { r = 0, g = 128, b = 0 };
COLOR_HEALTH_GRADIENT_MID = { r = 210, g = 112, b = 23 };
COLOR_HEALTH_GRADIENT_BOTTOM = { r = 192, g = 0, b = 0 };

COLOR_TOKEN_HEALTH_UNWOUNDED = "00C000";
COLOR_TOKEN_HEALTH_DYING_OR_DEAD = "C0C0C0";

COLOR_TOKEN_HEALTH_SIMPLE_WOUNDED = "80C000";
COLOR_TOKEN_HEALTH_SIMPLE_BLOODIED = "FF0000";

COLOR_TOKEN_HEALTH_LT_WOUNDS = "80C000";
COLOR_TOKEN_HEALTH_MOD_WOUNDS = "FFC000";
COLOR_TOKEN_HEALTH_HVY_WOUNDS = "FF6000";
COLOR_TOKEN_HEALTH_CRIT_WOUNDS = "FF0000";

COLOR_TOKEN_HEALTH_GRADIENT_TOP = { r = 0, g = 192, b = 0 };
COLOR_TOKEN_HEALTH_GRADIENT_MID = { r = 255, g = 192, b = 0 };
COLOR_TOKEN_HEALTH_GRADIENT_BOTTOM = { r = 255, g = 0, b = 0 };

function getUsageColor(nPercentUsed, bBar)
	local sColor;
	if not bBar or OptionsManager.isOption("BARC", "tiered") then
		sColor = getTieredUsageColor(nPercentUsed);
	else
		sColor = getGradientUsageColor(nPercentUsed);
	end
	return sColor;
end

function getTieredUsageColor(nPercentUsed)
	local sColor;
	if nPercentUsed <= 0 then
		sColor = COLOR_FULL;
	elseif nPercentUsed <= .25 then
		sColor = COLOR_THREE_QUARTER;
	elseif nPercentUsed <= .5 then
		sColor = COLOR_HALF;
	elseif nPercentUsed <= .75 then
		sColor = COLOR_QUARTER;
	else
		sColor = COLOR_EMPTY;
	end
	return sColor;
end

function getGradientUsageColor(nPercentUsed)
	local sColor;
	if nPercentUsed >= 1 then
		sColor = COLOR_EMPTY;
	elseif nPercentUsed <= 0 then
		sColor = COLOR_FULL;
	else
		local nBarR, nBarG, nBarB;
		if nPercentUsed >= 0.5 then
			local nPercentGrade = (nPercentUsed - 0.5) * 2;
			nBarR = math.floor((COLOR_GRADIENT_BOTTOM.r * nPercentGrade) + (COLOR_GRADIENT_MID.r * (1.0 - nPercentGrade)) + 0.5);
			nBarG = math.floor((COLOR_GRADIENT_BOTTOM.g * nPercentGrade) + (COLOR_GRADIENT_MID.g * (1.0 - nPercentGrade)) + 0.5);
			nBarB = math.floor((COLOR_GRADIENT_BOTTOM.b * nPercentGrade) + (COLOR_GRADIENT_MID.b * (1.0 - nPercentGrade)) + 0.5);
		else
			local nPercentGrade = nPercentUsed * 2;
			nBarR = math.floor((COLOR_GRADIENT_MID.r * nPercentGrade) + (COLOR_GRADIENT_TOP.r * (1.0 - nPercentGrade)) + 0.5);
			nBarG = math.floor((COLOR_GRADIENT_MID.g * nPercentGrade) + (COLOR_GRADIENT_TOP.g * (1.0 - nPercentGrade)) + 0.5);
			nBarB = math.floor((COLOR_GRADIENT_MID.b * nPercentGrade) + (COLOR_GRADIENT_TOP.b * (1.0 - nPercentGrade)) + 0.5);
		end
		sColor = string.format("%02X%02X%02X", nBarR, nBarG, nBarB);
	end
	return sColor;
end

function getHealthColor(nPercentWounded, bBar)
	local sColor;
	if not bBar or OptionsManager.isOption("BARC", "tiered") then
		sColor = getTieredHealthColor(nPercentWounded);
	else
		sColor = getGradientHealthColor(nPercentWounded);
	end
	return sColor;
end

function getTieredHealthColor(nPercentWounded)
	local sColor;
	if nPercentWounded >= 1 then
		sColor = COLOR_HEALTH_DYING_OR_DEAD;
	elseif nPercentWounded <= 0 then
		sColor = COLOR_HEALTH_UNWOUNDED;
	elseif OptionsManager.isOption("WNDC", "detailed") then
		if nPercentWounded >= 0.75 then
			sColor = COLOR_HEALTH_CRIT_WOUNDS;
		elseif nPercentWounded >= 0.5 then
			sColor = COLOR_HEALTH_HVY_WOUNDS;
		elseif nPercentWounded >= 0.25 then
			sColor = COLOR_HEALTH_MOD_WOUNDS;
		else
			sColor = COLOR_HEALTH_LT_WOUNDS;
		end
	else
		if nPercentWounded >= 0.5 then
			sColor = COLOR_HEALTH_SIMPLE_BLOODIED;
		else
			sColor = COLOR_HEALTH_SIMPLE_WOUNDED;
		end
	end
	return sColor;
end

function getGradientHealthColor(nPercentWounded)
	local sColor;
	if nPercentWounded >= 1 then
		sColor = COLOR_HEALTH_DYING_OR_DEAD;
	elseif nPercentWounded <= 0 then
		sColor = COLOR_HEALTH_UNWOUNDED;
	else
		local nBarR, nBarG, nBarB;
		if nPercentWounded >= 0.5 then
			local nPercentGrade = (nPercentWounded - 0.5) * 2;
			nBarR = math.floor((COLOR_HEALTH_GRADIENT_BOTTOM.r * nPercentGrade) + (COLOR_HEALTH_GRADIENT_MID.r * (1.0 - nPercentGrade)) + 0.5);
			nBarG = math.floor((COLOR_HEALTH_GRADIENT_BOTTOM.g * nPercentGrade) + (COLOR_HEALTH_GRADIENT_MID.g * (1.0 - nPercentGrade)) + 0.5);
			nBarB = math.floor((COLOR_HEALTH_GRADIENT_BOTTOM.b * nPercentGrade) + (COLOR_HEALTH_GRADIENT_MID.b * (1.0 - nPercentGrade)) + 0.5);
		else
			local nPercentGrade = nPercentWounded * 2;
			nBarR = math.floor((COLOR_HEALTH_GRADIENT_MID.r * nPercentGrade) + (COLOR_HEALTH_GRADIENT_TOP.r * (1.0 - nPercentGrade)) + 0.5);
			nBarG = math.floor((COLOR_HEALTH_GRADIENT_MID.g * nPercentGrade) + (COLOR_HEALTH_GRADIENT_TOP.g * (1.0 - nPercentGrade)) + 0.5);
			nBarB = math.floor((COLOR_HEALTH_GRADIENT_MID.b * nPercentGrade) + (COLOR_HEALTH_GRADIENT_TOP.b * (1.0 - nPercentGrade)) + 0.5);
		end
		sColor = string.format("%02X%02X%02X", nBarR, nBarG, nBarB);
	end
	return sColor;
end

function getTokenHealthColor(nPercentWounded, bBar)
	local sColor;
	if not bBar or OptionsManager.isOption("BARC", "tiered") then
		sColor = getTieredTokenHealthColor(nPercentWounded);
	else
		sColor = getGradientTokenHealthColor(nPercentWounded);
	end
	return sColor;
end

function getTieredTokenHealthColor(nPercentWounded)
	local sColor;
	if nPercentWounded >= 1 then
		sColor = COLOR_TOKEN_HEALTH_DYING_OR_DEAD;
	elseif nPercentWounded <= 0 then
		sColor = COLOR_TOKEN_HEALTH_UNWOUNDED;
	elseif OptionsManager.isOption("WNDC", "detailed") then
		if nPercentWounded >= 0.75 then
			sColor = COLOR_TOKEN_HEALTH_CRIT_WOUNDS;
		elseif nPercentWounded >= 0.5 then
			sColor = COLOR_TOKEN_HEALTH_HVY_WOUNDS;
		elseif nPercentWounded >= 0.25 then
			sColor = COLOR_TOKEN_HEALTH_MOD_WOUNDS;
		else
			sColor = COLOR_TOKEN_HEALTH_LT_WOUNDS;
		end
	else
		if nPercentWounded >= 0.5 then
			sColor = COLOR_TOKEN_HEALTH_SIMPLE_BLOODIED;
		else
			sColor = COLOR_TOKEN_HEALTH_SIMPLE_WOUNDED;
		end
	end
	return sColor;
end

function getGradientTokenHealthColor(nPercentWounded)
	local sColor;
	if nPercentWounded >= 1 then
		sColor = COLOR_TOKEN_HEALTH_DYING_OR_DEAD;
	elseif nPercentWounded <= 0 then
		sColor = COLOR_TOKEN_HEALTH_UNWOUNDED;
	else
		local nBarR, nBarG, nBarB;
		if nPercentWounded >= 0.5 then
			local nPercentGrade = (nPercentWounded - 0.5) * 2;
			nBarR = math.floor((COLOR_TOKEN_HEALTH_GRADIENT_BOTTOM.r * nPercentGrade) + (COLOR_TOKEN_HEALTH_GRADIENT_MID.r * (1.0 - nPercentGrade)) + 0.5);
			nBarG = math.floor((COLOR_TOKEN_HEALTH_GRADIENT_BOTTOM.g * nPercentGrade) + (COLOR_TOKEN_HEALTH_GRADIENT_MID.g * (1.0 - nPercentGrade)) + 0.5);
			nBarB = math.floor((COLOR_TOKEN_HEALTH_GRADIENT_BOTTOM.b * nPercentGrade) + (COLOR_TOKEN_HEALTH_GRADIENT_MID.b * (1.0 - nPercentGrade)) + 0.5);
		else
			local nPercentGrade = nPercentWounded * 2;
			nBarR = math.floor((COLOR_TOKEN_HEALTH_GRADIENT_MID.r * nPercentGrade) + (COLOR_TOKEN_HEALTH_GRADIENT_TOP.r * (1.0 - nPercentGrade)) + 0.5);
			nBarG = math.floor((COLOR_TOKEN_HEALTH_GRADIENT_MID.g * nPercentGrade) + (COLOR_TOKEN_HEALTH_GRADIENT_TOP.g * (1.0 - nPercentGrade)) + 0.5);
			nBarB = math.floor((COLOR_TOKEN_HEALTH_GRADIENT_MID.b * nPercentGrade) + (COLOR_TOKEN_HEALTH_GRADIENT_TOP.b * (1.0 - nPercentGrade)) + 0.5);
		end
		sColor = string.format("%02X%02X%02X", nBarR, nBarG, nBarB);
	end
	return sColor;
end


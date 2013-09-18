-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local nLocked = 0;

--
-- EFFECTS
--

function getEffectsString(nodeCTEntry, bPublicOnly)
	-- Start with an empty effects list string
	local aOutputEffects = {};
	
	-- Iterate through each effect
	local aSorted = {};
	for _,nodeChild in pairs(DB.getChildren(nodeCTEntry, "effects")) do
		table.insert(aSorted, nodeChild);
	end
	table.sort(aSorted, function (a, b) return a.getName() < b.getName() end);
	for _,v in pairs(aSorted) do
		local sLabel = DB.getValue(v, "label", "");

		local bAddEffect = true;
		local bGMOnly = false;
		if sLabel == "" then
			bAddEffect = false;
		elseif DB.getValue(v, "isgmonly", 0) == 1 then
			if User.isHost() and not bPublicOnly then
				bGMOnly = true;
			else
				bAddEffect = false;
			end
		end

		if bAddEffect then
			local sOutputLabel = sLabel;
			if bGMOnly then
				sOutputLabel = "(" .. sOutputLabel .. ")";
			end

			table.insert(aOutputEffects, sOutputLabel);
		end
	end
	
	-- Return the final effect list string
	return table.concat(aOutputEffects, " | ");
end

--
--  HANDLE EFFECT LOCKING
--

function lock()
	nLocked = nLocked + 1;
end

function unlock()
	nLocked = nLocked - 1;
	if nLocked < 0 then
		nLocked = 0;
	end

	if nLocked == 0 then
	end
end

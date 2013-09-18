-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-----------------------
--  EXISTENCE FUNCTIONS
-----------------------

function isWord(sWord, targetval)
	if sWord then
		if type(targetval) == "string" then
			if sWord == targetval then
				return true;
			end

		elseif type(targetval) == "table" then
			if contains(targetval, sWord) then
				return true;
			end
		end
	end
	
	return false;
end

function isNumberString(sWord)
	if sWord then
		if sWord:match("^[%+%-]?%d+$") then
			return true;
		end
	end
	return false;
end

function isDiceString(sWord)
	if sWord then
		if sWord:match("^[d%dF%+%-]+$") then
			return true;
		end
	end
	return false;
end

-----------------------
-- SET FUNCTIONS
-----------------------

function contains(set, item)
	for i = 1, #set do
		if set[i] == item then
			return true;
		end
	end
	return false;
end

function autoComplete(aSet, sItem, bIgnoreCase)
	if bIgnoreCase then
		for i = 1, #aSet do
			if sItem:lower() == string.lower(aSet[i]:sub(1, #sItem)) then
				return aSet[i]:sub(#sItem + 1);
			end
		end
	else
		for i = 1, #aSet do
			if sItem == aSet[i]:sub(1, #sItem) then
				return aSet[i]:sub(#sItem + 1);
			end
		end
	end

	return nil;
end

-----------------------
-- MODIFY FUNCTIONS
-----------------------

function capitalize(s)
	return s:gsub("^%l", string.upper);
end

function multireplace(s, aPatterns, sReplace)
	if type(aPatterns) == "string" then
		s = s:gsub(aPatterns, sReplace);
	elseif type(aPatterns) == "table" then
		for _,v in pairs(aPatterns) do
			s = s:gsub(v, sReplace);
		end
	end

	return s;
end

function addTrailing(s, c)
	if s:len() > 0 and s[-1] ~= c then
		s = s .. c;
	end
	return s;
end

function extract(s, nStart, nEnd)
	if not nStart or not nEnd then
		return "", s;
	end
	
	local sExtract = s:sub(nStart, nEnd);
	local sRemainder;
	if nStart == 1 then
		sRemainder = s:sub(nEnd + 1);
	else
		sRemainder = s:sub(1, nStart - 1) .. s:sub(nEnd + 1);
	end

	return sExtract, sRemainder;
end

function extractPattern(s, sPattern)
	local nStart, nEnd = s:find(sPattern);
	if not nStart then
		return "", s;
	end
	
	local sExtract = s:sub(nStart, nEnd);
	local sRemainder;
	if nStart == 1 then
		sRemainder = s:sub(nEnd + 1);
	else
		sRemainder = s:sub(1, nStart - 1) .. s:sub(nEnd + 1);
	end

	return sExtract, sRemainder;
end

function combine(sSeparator, ...)
	local aCombined = {};

	for i = 1, select("#", ...) do
		local v = select(i, ...);
		if type(v) == "string" and v:len() > 0 then
			table.insert(aCombined, v);
		end
	end

	return table.concat(aCombined, sSeparator);
end

--
-- TRIM STRING
--
-- Strips any spacing characters from the beginning and end of a string.
--
-- The function returns the following parameters:
--   1. The trimmed string
--   2. The starting position of the trimmed string within the original string
--   3. The ending position of the trimmed string within the original string
--

function trim(s)
	local pre_starts, pre_ends = s:find("^%s+");
	local post_starts, post_ends = s:find("%s+$");
	
	if pre_ends then
		s = s:gsub("^%s+", "");
	else
		pre_ends = 0;
	end
	if post_starts then
		s = s:gsub("%s+$", "");
	end
	
	return s, pre_ends + 1, pre_ends + #s;
end

-----------------------
-- PARSE FUNCTIONS
-----------------------

function parseWords(s, extra_delimiters)
	local delim = "^%w%+%-'’";
	if extra_delimiters then
		delim = delim .. extra_delimiters;
	end
	return split(s, delim, true); 
end

-- 
-- SPLIT CLAUSES
--
-- The source string is divided into substrings as defined by the delimiters parameter.  
-- Each resulting string is stored in a table along with the start and end position of
-- the result string within the original string.  The result tables are combined into
-- a table which is then returned.
--
-- NOTE: Set trimspace flag to trim any spaces that trail delimiters before next result 
-- string
--

function split(sToSplit, sDelimiters, bTrimSpace)
	-- SETUP
	local aStrings = {};
	local aStringStats = {};
  	local sNextString = "";
	
  	-- BUILD DELIMITER PATTERN
  	local sDelimiterPattern = "[" .. sDelimiters .. "]+";
  	if bTrimSpace then
  		sDelimiterPattern = sDelimiterPattern .. "%s*";
  	end
  	
  	-- DEAL WITH LEADING/TRAILING SPACES
  	local nStringStart = 1;
  	local nStringEnd = #sToSplit;
  	if bTrimSpace then
  		_, nStringStart, nStringEnd = trim(sToSplit);
  	end
  	
  	-- SPLIT THE STRING, BASED ON THE DELIMITERS
  	local nIndex = nStringStart;
  	local nDelimiterStart, nDelimiterEnd = sToSplit:find(sDelimiterPattern, nIndex);
  	while nDelimiterStart do
  		sNextString = sToSplit:sub(nIndex, nDelimiterStart - 1);
  		if sNextString ~= "" then
  			table.insert(aStrings, sNextString);
  			table.insert(aStringStats, {startpos = nIndex, endpos = nDelimiterStart});
  		end
  		
  		nIndex = nDelimiterEnd + 1;
  		nDelimiterStart, nDelimiterEnd = sToSplit:find(sDelimiterPattern, nIndex);
  	end
  	sNextString = sToSplit:sub(nIndex, nStringEnd);
	if sNextString ~= "" then
		table.insert(aStrings, sNextString);
		table.insert(aStringStats, {startpos = nIndex, endpos = nStringEnd + 1});
	end
	
	-- RESULTS
	return aStrings, aStringStats;
end

-----------------------
--  CONVERSION FUNCTIONS
-----------------------

-- NOTE: Ignores negative dice references
function convertStringToDice(s)
	-- SETUP
	local aDice = {};
	local nMod = 0;
	
	-- PARSING
	if s then
		for sSign, v in s:gmatch("([+-]?)([%ddDF]+)") do
			-- SIGN
			local nSignMult = 1;
			if sSign == "-" then
				nSignMult = -1;
			end

			-- DIE REFERENCE
			local sDieCount, sDieSides = v:match("^(%d*)[dD]([%dF]+)");
			if sDieSides then
				local nDieCount = tonumber(sDieCount) or 1;
				sDieType = "d" .. sDieSides;
				for i = 1, nDieCount do
					table.insert(aDice, sDieType);
					if sDieType == "d100" then
						table.insert(aDice, "d10");
					end
				end
			-- OR ASSUME NUMBER REFERENCE
			else
				local n = tonumber(v) or 0;
				nMod = nMod + (nSignMult * n);
			end
		end
	end
	
	-- RESULTS
	return aDice, nMod;
end

function convertDiceToString(aDice, nMod, bSign)
	local s = "";
	
	if aDice then
		local diecount = {};

		-- PARSING
		for k, v in pairs(aDice) do
	
			-- DRAGINFO DIE INFORMATION IS TWO LEVELS
			if type(v) == "table" then
				for k2, v2 in pairs(v) do
					if diecount[v2] then
						diecount[v2] = diecount[v2] + 1;
					else
						diecount[v2] = 1;
					end
				end

			-- OUTPUT FROM DIEFIELD IS ONE LEVEL
			else
				if diecount[v] then
					diecount[v] = diecount[v] + 1;
				else
					diecount[v] = 1;
				end

			end
		end

		-- HANDLE d100 DICE
		if (diecount["d100"] and diecount["d10"]) then
			diecount["d10"] = diecount["d10"] - diecount["d100"];
			if diecount["d10"] < 0 then
				diecount["d10"] = 0;
			end
		end
		
		-- BUILD STRING
		for k, v in pairs(diecount) do
			if s ~= "" then
				s = s .. "+";
			end
			s = s .. v .. k;
		end
	end
	
	-- ADD OPTIONAL MODIFIER
	if nMod then
		if nMod > 0 then
			if s == "" and not bSign then
				s = s .. nMod
			else
				s = s .. "+" .. nMod;
			end
		elseif nMod < 0 then
			s = s .. nMod;
		end
	end
	
	-- RESULTS
	return s;
end

-----------------------
-- EVALUATION FUNCTIONS
-----------------------

--
-- EVAL DICE STRING
--
-- Evaluates a string that contains an arbitrary number of numerical terms and dice expressions
-- 
-- NOTE: Dice expressions are automatically evaluated randomly without rolling the 
-- physical dice on-screen, or ignored if the bAllowDice flag not set.
--

function evalDiceString(sDice, bAllowDice, bMaxDice)
	local nTotal = 0;
	
	for sSign, sVal, sDieType in sDice:gmatch("([%-%+]?)(%d+)d?([%dF]*)") do
		local nVal = tonumber(sVal) or 0;
		local nSubtotal = 0;

		if sDieType ~= "" then
			if bAllowDice then
				local nDieSides;
				if sDieType == "F" then
					nDieSides = 3;
					if bMaxDice then
						nSubtotal = nSubtotal + (nVal * nDieSides);
					else
						for i = 1, nVal do
							local nRandom = math.random(3);
							if nRandom == 1 then
								nSubtotal = nSubtotal - 1;
							elseif nRandom == 3 then
								nSubtotal = nSubtotal + 1;
							end
						end
					end
				else
					nDieSides = tonumber(sDieType) or 0;
					if nDieSides > 0 then
						if bMaxDice then
							nSubtotal = nSubtotal + (nVal * nDieSides);
						else
							for i = 1, nVal do
								nSubtotal = nSubtotal + math.random(nDieSides);
							end
						end
					end
				end
			end
		else
			nSubtotal = nVal;
		end

		if sSign == "-" then
			nSubtotal = 0 - nSubtotal;
		end
		
		nTotal = nTotal + nSubtotal;
	end
	
	return nTotal;
end

function evalDice(aDice, nMod, bCritical)
	local nTotal = 0;
	for _,sDie in pairs(aDice) do
		local sDieType = sDie:match("d([%dF]+)");
		local nDieSides;
		if nDieSides == "F" then
			nDieSides = 3;
		else
			nDieSides = tonumber(sDieType) or 0;
		end
		if nDieSides > 0 then
			if bCritical then
				nTotal = nTotal + nDieSides;
			else
				nTotal = nTotal + math.random(nDieSides);
			end
		end
	end
	if nMod then
		nTotal = nTotal + nMod;
	end
	return nTotal;
end


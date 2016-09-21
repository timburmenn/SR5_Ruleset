-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- NOTE: Converts table into numerically indexed table, based on sort order of original keys. Original keys are not included in new table.
function getSortedTable(aOriginal)
	local aSorter = {};
	for k,_ in pairs(aOriginal) do
		table.insert(aSorter, k);
	end
	table.sort(aSorter);
	
	local aSorted = {};
	for _,v in ipairs(aSorter) do
		table.insert(aSorted, aOriginal[v]);
	end
	return aSorted;
end

-- NOTE: Performs a structure deep copy. Does not copy meta table information.
function copyDeep(v)
	if type(v) == "table" then
		local v2 = {};
		for kTable, vTable in next, v, nil do
			v2[copyDeep(kTable)] = copyDeep(vTable);
		end
		return v2;
	end
	
	return v;
end

function encodeXML(s)
	if not s then
		return "";
	end
	return s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("\"", "&quot;"):gsub("'", "&apos;");
end

-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	CombatManager.setCustomSort(sortfunc);
	CombatManager.setCustomCombatReset(resetInit);
end

--
-- CALLBACKS
--

-- NOTE: Lua sort function expects the opposite boolean value compared to built-in FG sorting
function sortfunc(node1, node2)
	local nValue1 = DB.getValue(node1, "initresult", 0);
	local nValue2 = DB.getValue(node2, "initresult", 0);
	if nValue1 ~= nValue2 then
		return nValue1 > nValue2;
	end
	
	local sValue1 = DB.getValue(node1, "name", "");
	local sValue2 = DB.getValue(node2, "name", "");
	if sValue1 ~= sValue2 then
		return sValue1 < sValue2;
	end

	return node1.getNodeName() < node2.getNodeName();
end

--
-- ACTIONS
--

function resetInit()
	for _, vChild in pairs(DB.getChildren(CombatManager.CT_LIST)) do
		DB.setValue(vChild, "initresult", "number", 0);
	end
end

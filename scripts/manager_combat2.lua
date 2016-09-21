-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	CombatManager.setCustomSort(CombatManager.sortfuncStandard);
	CombatManager.setCustomCombatReset(resetInit);
end

--
-- ACTIONS
--

function resetInit()
	for _, vChild in pairs(DB.getChildren(CombatManager.CT_LIST)) do
		DB.setValue(vChild, "initresult", "number", 0);
	end
end

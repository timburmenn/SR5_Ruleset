-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("skill", modRoll);
end

function performRoll(draginfo, rActor, sStatName)
	local rRoll = {};
	local nValue = 0;
	local aDice =  {};
	rRoll.sDesc = rActor.nodeCreature.getChild("name").getValue() .. " -> "
	rRoll.sDesc = rRoll.sDesc .. "[Skill check]"
	

	
	rRoll.aDice = aDice;
	rRoll.nValue = 0;
	rRoll.sDesc , nValue = ActorManager.getSkillScore(rActor, sStatName, rRoll.sDesc);
	
	-- SETUP
	for i = 1, nValue do
		table.insert (aDice, "d6");
	end
	
	ActionsManager.performSingleRollAction(draginfo, rActor, "skill", rRoll);
end
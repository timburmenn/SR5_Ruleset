-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onRefChanged();
end

function onRefChanged()
	local sPrototype = "";
	local sTooltip = "";

	local sCTNode = noderef.getValue();
	if sCTNode ~= "" then
		local nodeCT = DB.findNode(sCTNode);
		sPrototype = DB.getValue(nodeCT, "token", "");
		sTooltip = DB.getValue(nodeCT, "name", "");
	end
	
	token.setPrototype(sPrototype);
	token.setTooltipText(sTooltip);
end

function removeTarget()
	TargetingManager.removeCTTarget(windowlist.window.getDatabaseNode(), getDatabaseNode());
end

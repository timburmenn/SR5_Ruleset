-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onTargetsChanged();
	local nodeCT = window.getDatabaseNode();
	DB.addHandler(DB.getPath(nodeCT, "targets"), "onChildUpdate", onTargetsChanged);
	DB.addHandler(DB.getPath(nodeCT, "friendfoe"), "onUpdate", onTargetsChanged);
end

function onClose()
	local nodeCT = window.getDatabaseNode();
	DB.removeHandler(DB.getPath(nodeCT, "targets"), "onChildUpdate", onTargetsChanged);
	DB.addHandler(DB.getPath(nodeCT, "friendfoe"), "onUpdate", onTargetsChanged);
end

function onTargetsChanged()
	local nodeCT = window.getDatabaseNode();
	if not User.isHost() and DB.getValue(nodeCT, "friendfoe", "") ~= "friend" then
		setVisible(false);
		setValue(nil);
	else
		-- Get target names
		local aTargetNames = {};
		for _,vTarget in pairs(DB.getChildren(window.getDatabaseNode(), "targets")) do
			local sTargetName = "";
			local sCTNode = DB.getValue(vTarget, "noderef", "");
			local nodeCT = nil;
			if sCTNode ~= "" then
				nodeCT = DB.findNode(sCTNode);
			end
			if nodeCT then
				sTargetName = DB.getValue(nodeCT, "name", "");
			end
			if sTargetName == "" then
				sTargetName = "<Target>";
			end
			table.insert(aTargetNames, sTargetName);
		end

		-- Set the targeting summary string
		if #aTargetNames > 0 then
			setValue(Interface.getString("ct_label_targets") .. " " .. table.concat(aTargetNames, "; "));
		else
			setValue(nil);
		end
		
		-- Update visibility
		if #aTargetNames == 0 or (window.targetingicon and window.targetingicon.isVisible()) then
			setVisible(false);
		else
			setVisible(true);
		end
	end
end


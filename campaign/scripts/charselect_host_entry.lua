-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if User.isHost() then
		registerMenuItem("Clear owner", "erase", 4);
	end

	local node = getDatabaseNode();
	
	portrait.setIcon("portrait_" .. node.getName() .. "_charlist", true);
	node.onObserverUpdate = updateOwner;
	updateOwner();

	details.setValue(GameSystem.getCharSelectDetailHost(node));
end

function updateOwner()
	local sOwner = getDatabaseNode().getOwner();
	if sOwner then
		owner.setValue("Owned by: " .. sOwner);
	else
		owner.setValue("");
	end
end

function onMenuSelection(selection)
	if User.isHost() and selection == 4 then
		local node = getDatabaseNode();
		local owner = node.getOwner();
		if owner then
			node.removeHolder(owner);
		end
	end
end

function openCharacter()
	Interface.openWindow("charsheet", getDatabaseNode().getNodeName());
end

function dragCharacter(draginfo)
	local nodeWin = getDatabaseNode();
	if nodeWin then
		local sIdentity = nodeWin.getName();

		draginfo.setType("shortcut");
		draginfo.setIcon("portrait_" .. sIdentity .. "_charlist");
		draginfo.setTokenData("portrait_" .. sIdentity .. "_token");
		draginfo.setShortcutData("charsheet", "charsheet." .. sIdentity);
		draginfo.setDescription(DB.getValue(nodeWin, "name", ""));

		local base = draginfo.createBaseData();
		base.setType("token");
		base.setTokenData("portrait_" .. sIdentity .. "_token");
	end
end


-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aFieldMap = {};

function onInit()
	if User.isHost() then
		for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
			linkPCFields(v);
		end

		DB.addHandler("partysheet.*.name", "onUpdate", updateName);
		DB.addHandler("charsheet.*", "onDelete", onCharDelete);
	end
end

function mapChartoPS(nodeChar)
	if not nodeChar then
		return nil;
	end
	local sChar = nodeChar.getNodeName();

	for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
		local sClass, sRecord = DB.getValue(v, "link", "", "");
		if sRecord == sChar then
			return v;
		end
	end
	
	return nil;
end

function onCharDelete(nodeChar)
	local nodePS = mapChartoPS(nodeChar);
	if nodePS then
		nodePS.delete();
	end
end

function onLinkUpdated(nodeField)
	DB.setValue(aFieldMap[nodeField.getNodeName()], nodeField.getType(), nodeField.getValue());
end

function onLinkDeleted(nodeField)
	aFieldMap[nodeField.getNodeName()] = nil;
end

function linkRecordField(nodeRecord, nodePS, sField, sType, sPSField)
	if not sPSField then
		sPSField = sField;
	end

	local nodeField = nodeRecord.createChild(sField, sType);
	nodeField.onUpdate = onLinkUpdated;
	nodeField.onDelete = onLinkDeleted;
	
	aFieldMap[nodeField.getNodeName()] = nodePS.getNodeName() .. "." .. sPSField;
	onLinkUpdated(nodeField);
end

function linkPCFields(nodePS)
	if PartyManager2 and PartyManager2.linkPCFields then
		PartyManager2.linkPCFields(nodePS);
		return;
	end
	
	local sClass, sRecord = DB.getValue(nodePS, "link", "", "");
	if sRecord == "" then
		return;
	end
	local nodeChar = DB.findNode(sRecord);
	if not nodeChar then
		return;
	end
	
	linkRecordField(nodeChar, nodePS, "name", "string");
	linkRecordField(nodeChar, nodePS, "token", "token", "token");
end

function getNodeFromTokenRef(nodeContainer, nId)
	if not nodeContainer then
		return nil;
	end
	local sContainerNode = nodeContainer.getNodeName();
	
	for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
		local sChildContainerName = DB.getValue(v, "tokenrefnode", "");
		local nChildId = tonumber(DB.getValue(v, "tokenrefid", "")) or 0;
		if (sChildContainerName == sContainerNode) and (nChildId == nId) then
			return v;
		end
	end
	return nil;
end

function getNodeFromToken(token)
	local nodeContainer = token.getContainerNode();
	local nID = token.getId();

	return getNodeFromTokenRef(nodeContainer, nID);
end

function linkToken(nodePS, newTokenInstance)
	TokenManager.linkToken(nodePS, newTokenInstance);
	
	if newTokenInstance then
		newTokenInstance.setTargetable(false);
		newTokenInstance.setActivable(true);
		newTokenInstance.setActive(false);
		newTokenInstance.setVisible(true);

		newTokenInstance.setName(DB.getValue(nodePS, "name", ""));
	end

	return true;
end

function updateName(nodeName)
	local nodeEntry = nodeName.getParent();
	local tokeninstance = Token.getToken(DB.getValue(nodeEntry, "tokenrefnode", ""), DB.getValue(nodeEntry, "tokenrefid", ""));
	if tokeninstance then
		tokeninstance.setName(DB.getValue(nodeEntry, "name", ""));
	end
end

--
-- DROP HANDLING
--

function addChar(nodeChar)
	local nodePS = mapChartoPS(nodeChar)
	if nodePS then
		return;
	end
	
	nodePS = DB.createChild("partysheet.partyinformation");
	DB.setValue(nodePS, "link", "windowreference", "charsheet", nodeChar.getNodeName());
	linkPCFields(nodePS);
end

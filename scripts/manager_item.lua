-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_TRANSFERITEM = "transferitem";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_TRANSFERITEM, handleTransfer);
end

function notifyTransfer(sTargetInvRecord, sSourceClass, sSourceRecord)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_TRANSFERITEM;
	
	msgOOB.sTarget = sTargetInvRecord;
	msgOOB.sClass = sSourceClass;
	msgOOB.sSource = sSourceRecord;

	Comm.deliverOOBMessage(msgOOB, "");
end

--
-- HANDLERS
--

local fCustomCharAdd = nil;
function setCustomCharAdd(fCharAdd)
	fCustomCharAdd = fCharAdd;
end
function onCharAddEvent(nodeItem)
	if fCustomCharAdd then
		fCustomCharAdd(nodeItem);
	end
end

local fCustomCharRemove = nil;
function setCustomCharRemove(fCharRemove)
	fCustomCharRemove = fCharRemove;
end
function onCharRemoveEvent(nodeItem)
	if fCustomCharRemove then
		fCustomCharRemove(nodeItem);
	end
end

--
-- ACTIONS
--

function handleTransfer(msgOOB)
	addItemToList(msgOOB.sTarget, msgOOB.sClass, msgOOB.sSource);
end

function isItemClass(sClass)
	if sClass == "item" then
		return true;
	elseif ItemManager2 and ItemManager2.isItemClass then
		return ItemManager2.isItemClass(sClass);
	end
	
	return false;
end

function getIDState(nodeRecord, bIgnoreHost)
	local bID = true;
	local bOptionID = OptionsManager.isOption("MIID", "on");
	if bOptionID and (bIgnoreHost or not User.isHost()) then
		bID = (DB.getValue(nodeRecord, "isidentified", 0) == 1);
	end
	
	return bID, bOptionID;
end

function getDisplayName(nodeItem, bIgnoreHost)
	local bID = getIDState(nodeItem, bIgnoreHost);
	if bID then
		return DB.getValue(nodeItem, "name", "");
	end
	
	local sName = DB.getValue(nodeItem, "nonid_name", "");
	if sName == "" then
		sName = "Unidentified Item";
	end
	return sName;
end

function getSortName(nodeItem)
	local sName = getDisplayName(nodeItem);
	return sName:lower();
end

function handleDrop(nodeList, draginfo)
	if draginfo.isType("shortcut") then
		local sClass,sRecord = draginfo.getShortcutData();
		if isItemClass(sClass) then
			notifyTransfer(nodeList.getNodeName(), sClass, sRecord);
			return true;
		end
	end
	
	return nil;
end

function getItemSourceType(vNode)
	local sType = "";
	local nodeTemp = nil;
	if type(vNode) == "databasenode" then
		nodeTemp = vNode;
	elseif type(vNode) == "string" then
		nodeTemp = DB.findNode(vNode);
	end
	while nodeTemp do
		sType = nodeTemp.getName();
		nodeTemp = nodeTemp.getParent();
	end
	return sType;
end

function compareFields(node1, node2, bTop)
	if node1 == node2 then
		return false;
	end
	
	local bOptionID = OptionsManager.isOption("MIID", "on");
	
	for _,vChild1 in pairs(node1.getChildren()) do
		local sName = vChild1.getName();
		if bTop and StringManager.contains({"count", "location", "assign", "locked", "carried", "showonminisheet"}, sName) then
			-- SKIP
		elseif bTop and not bOptionID and sName == "isidentified" then
			-- SKIP
		else
			local sType = vChild1.getType();
			local vChild2 = node2.getChild(sName);
			if vChild2 then
				if sType ~= vChild2.getType() then
					return false;
				end
				
				if sType == "node" then
					if not compareFields(vChild1, vChild2, false) then
						return false;
					end
				else
					if vChild1.getValue() ~= vChild2.getValue() then
						return false;
					end
				end
			else
				if sType == "number" and vChild1.getValue() == 0 then
					-- DEFAULT MATCH
				elseif sType == "string" and vChild1.getValue() == "" then
					-- DEFAULT MATCH
				else
					return false;
				end
			end
			
		end
	end
	
	return true;
end

-- NOTE: Assumed target and source base nodes 
-- (item = campaign, charsheet = char inventory, partysheet = party inventory, treasureparcels = parcel inventory)
function addItemToList(sListNode, sClass, vSource)
	-- Get the source item database node object
	local nodeSource = nil;
	if type(vSource) == "databasenode" then
		nodeSource = vSource;
	elseif type(vSource) == "string" then
		nodeSource = DB.findNode(vSource);
	end
	if not nodeSource then
		return nil;
	end
	
	-- Determine the source and target item location type
	local sSourceRecordType = getItemSourceType(nodeSource);
	local sTargetRecordType = getItemSourceType(sListNode);
	
	-- Make sure that the source and target locations are not the same character
	if sSourceRecordType == "charsheet" and sTargetRecordType == "charsheet" then
		if nodeSource.getNodeName():sub(1, string.len(sListNode)) == sListNode then
			return nil;
		end
	end
	
	-- Use a temporary location to create an item copy for manipulation, if the item type is supported
	DB.deleteNode("temp.item");
	local nodeTemp = DB.createNode("temp.item");
	local bCopy = false;
	if sClass == "item" then
		local bID = getIDState(nodeSource, true);
		DB.copyNode(nodeSource, nodeTemp);
		if bID then
			DB.setValue(nodeTemp, "isidentified", "number", 1);
		end
		bCopy = true;
	elseif ItemManager2 and ItemManager2.addItemToList2 then
		bCopy = ItemManager2.addItemToList2(sClass, nodeSource, nodeTemp);
	end
	
	local nodeNew = nil;
	if bCopy then
		-- Remove fields specific to the source item location that shouldn't be transferred
		if sSourceRecordType == "charsheet" then
			DB.deleteChild(nodeTemp, "location");
			DB.deleteChild(nodeTemp, "carried");
			DB.deleteChild(nodeTemp, "showonminisheet");
		elseif sSourceRecordType == "partysheet" then
			DB.deleteChild(nodeTemp, "assign");
		end
		
		-- Determine target node for source item data.  
		-- If we already have an item with the same fields, then just append the item count.  
		-- Otherwise, create a new item and copy from the source item.
		local bAppend = false;
		if sTargetRecordType ~= "item" then
			for _,vItem in pairs(DB.getChildren(sListNode)) do
				if compareFields(vItem, nodeTemp, true) then
					nodeNew = vItem;
					bAppend = true;
					break;
				end
			end
		end
		if not nodeNew then
			nodeNew = DB.createChild(sListNode);
			DB.copyNode(nodeTemp, nodeNew);
		end
		
		-- Determine the source, target and item names
		local sSrcName, sTrgtName;
		if sSourceRecordType == "charsheet" then
			sSrcName = DB.getValue(nodeSource, "...name", "");
		elseif sSourceRecordType == "partysheet" then
			sSrcName = "PARTY";
		else
			sSrcName = "";
		end
		if sTargetRecordType == "charsheet" then
			sTrgtName = DB.getValue(nodeNew, "...name", "");
		elseif sTargetRecordType == "partysheet" then
			sTrgtName = "PARTY";
		else
			sTrgtName = "";
		end
		local sItemName = getDisplayName(nodeNew, true);
		
		-- Determine whether to copy all items at once or just one item at a time (based on source and target)
		local bCountN = false;
		if (sSourceRecordType == "treasureparcels" and sTargetRecordType == "partysheet") or
				(sSourceRecordType == "partysheet" and sTargetRecordType == "treasureparcels") or 
				(sSourceRecordType == "treasureparcels" and sTargetRecordType == "treasureparcels") then
			bCountN = true;
		end
		if bCountN or sTargetRecordType ~= "item" then
			local nCount = 1;
			if bCountN then
				nCount = DB.getValue(nodeSource, "count", 1);
			end
			if bAppend then
				local nAppendCount = math.max(DB.getValue(nodeNew, "count", 1), 1);
				nCount = nCount + nAppendCount;
			end
			DB.setValue(nodeNew, "count", "number", nCount);
		end
		
		-- If not adding to an existing record, then lock the new record and generate events
		if not bAppend then
			DB.setValue(nodeNew, "locked", "number", 1);
			if sTargetRecordType == "charsheet" then
				onCharAddEvent(nodeNew);
			end
		end

		-- Generate output message if transferring between characters or between party sheet and character
		if sSourceRecordType == "charsheet" and (sTargetRecordType == "partysheet" or sTargetRecordType == "charsheet") then
			local msg = {font = "msgfont", icon = "coins"};
			msg.text = "[" .. sSrcName .. "] -> [" .. sTrgtName .. "] : " .. sItemName;
			Comm.deliverChatMessage(msg);

			local nCharCount = DB.getValue(nodeSource, "count", 0);
			if nCharCount <= 1 then
				onCharRemoveEvent(nodeSource);
				nodeSource.delete();
			else
				DB.setValue(nodeSource, "count", "number", nCharCount - 1);
			end
		elseif sSourceRecordType == "partysheet" and sTargetRecordType == "charsheet" then
			local msg = {font = "msgfont", icon = "coins"};
			msg.text = "[" .. sSrcName .. "] -> [" .. sTrgtName .. "] : " .. sItemName;
			Comm.deliverChatMessage(msg);

			local nPartyCount = DB.getValue(nodeSource, "count", 0);
			if nPartyCount <= 1 then
				nodeSource.delete();
			else
				DB.setValue(nodeSource, "count", "number", nPartyCount - 1);
			end
		end
	end
	
	-- Clean up
	DB.deleteNode("temp.item");

	return nodeNew;
end

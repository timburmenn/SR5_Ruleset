-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_TRANSFERITEM = "transferitem";
OOB_MSGTYPE_TRANSFERCURRENCY = "transfercurrency";
OOB_MSGTYPE_TRANSFERPARCEL = "transferparcel";
OOB_MSGTYPE_TRANSFERITEMSTRING = "transferitemstring";

local aDeleteCopyFields = { "count", "locked", "location", "carried", "showonminisheet", "assign" };

--
-- INITIALIZATION
--

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_TRANSFERITEM, handleItemTransfer);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_TRANSFERCURRENCY, handleCurrencyTransfer);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_TRANSFERPARCEL, handleParcelTransfer);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_TRANSFERITEMSTRING, handleItemStringTransfer);
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

function addFieldToIgnore (sIgnore)
	if type(sIgnore) == "string" and sIgnore ~= "" then
		table.insert(aDeleteCopyFields, sIgnore);
	end
end

local aCustomTransferNotifyHandlers = {};
function addTransferNotificationHandler(f)
	table.insert(aCustomTransferNotifyHandlers, f);
end

--
-- ACTIONS
--

function isItemClass(sClass)
	if sClass == "item" then
		return true;
	elseif ItemManager2 and ItemManager2.isItemClass then
		return ItemManager2.isItemClass(sClass);
	end
	
	return false;
end

function getIDState(nodeRecord, bIgnoreHost)
	if ItemManager2 and ItemManager2.getIDState then
		return ItemManager2.getIDState(nodeRecord, bIgnoreHost);
	end
	
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
		sName = Interface.getString("item_unidentified");
	end
	return sName;
end

function getSortName(nodeItem)
	local sName = getDisplayName(nodeItem);
	return sName:lower();
end

function handleAnyDrop(vTarget, draginfo)
	local sDragType = draginfo.getType();
	
	if not User.isHost() then
		local sTargetType = getItemSourceType(vTarget);
		if sTargetType == "item" then
			return false;
		elseif sTargetType == "treasureparcels" then
			return false;
		elseif sTargetType == "partysheet" then
			if sDragType ~= "shortcut" then
				return false;
			end
			local sClass, sRecord = draginfo.getShortcutData();
			if sClass ~= "item" then
				return false;
			end
			local sSourceType = getItemSourceType(sRecord);
			if sSourceType ~= "charsheet" then
				return false;
			end
		elseif sTargetType == "charsheet" then
			if not DB.isOwner(vTarget) then
				return false;
			end
		end
	end
	
	if sDragType == "number" then
		handleString(vTarget, draginfo.getDescription(), draginfo.getNumberData());
		return true;

	elseif sDragType == "string" then
		handleString(vTarget, draginfo.getStringData());
		return true;

	elseif sDragType == "shortcut" then
		local sClass,sRecord = draginfo.getShortcutData();
		if isItemClass(sClass) then
			local bTransferAll = false;
			local sSourceType = getItemSourceType(sRecord);
			local sTargetType = getItemSourceType(vTarget);
			if StringManager.contains({"charsheet", "partysheet"}, sSourceType) and StringManager.contains({"charsheet", "partysheet"}, sTargetType) then
				bTransferAll = Input.isShiftPressed();
			end
			
			handleItem(vTarget, nil, sClass, sRecord, bTransferAll);
			return true;
		elseif sClass == "treasureparcel" then
			handleParcel(vTarget, sRecord);
			return true;
		end
	end
	
	return false;
end

-- Deprecated
function handleDrop(nodeList, draginfo, bTransferAll)
	if draginfo.isType("shortcut") then
		local sClass,sRecord = draginfo.getShortcutData();
		if isItemClass(sClass) then
			handleItemTransfer(nodeList.getParent(), nodeList.getName(), sClass, sRecord, bTransferAll);
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
		if bTop and StringManager.contains(aDeleteCopyFields, sName) then
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

--
-- HIGH-LEVEL ACTIONS
--

function handleItem(vTargetRecord, sTargetList, sClass, sRecord, bTransferAll)
	local nodeTargetRecord = nil;
	if type(vTargetRecord) == "databasenode" then
		nodeTargetRecord = vTargetRecord;
	elseif type(vTargetRecord) == "string" then
		nodeTargetRecord = DB.findNode(vTargetRecord);
	end
	if not nodeTargetRecord then
		return;
	end
	
	if not sTargetList then
		local sTargetRecordType = getItemSourceType(nodeTargetRecord);
		if sTargetRecordType == "charsheet" then
			sTargetList = "inventorylist";
		elseif sTargetRecordType == "treasureparcels" then
			sTargetList = "itemlist";
		elseif sTargetRecordType == "partysheet" then
			sTargetList = "treasureparcelitemlist";
		elseif sTargetRecordType == "item" then
			sTargetList = "";
		end
		
		if not sTargetList then
			return;
		end
	end
	
	ItemManager.sendItemTransfer(nodeTargetRecord.getPath(), sTargetList, sClass, sRecord, bTransferAll);
end

function handleCurrency(vTargetRecord, sCurrency, nCurrency)
	local sTargetRecord = nil;
	if type(vTargetRecord) == "databasenode" then
		sTargetRecord = vTargetRecord.getPath();
	elseif type(vTargetRecord) == "string" then
		sTargetRecord = vTargetRecord;
	end
	if not sTargetRecord then
		return;
	end

	sendCurrencyTransfer(sTargetRecord, sCurrency, nCurrency);
end

function handleParcel(vTargetRecord, sRecord)
	local sTargetRecord = nil;
	if type(vTargetRecord) == "databasenode" then
		sTargetRecord = vTargetRecord.getPath();
	elseif type(vTargetRecord) == "string" then
		sTargetRecord = vTargetRecord;
	end
	if not sTargetRecord then
		return;
	end
	
	local sTargetRecordType = getItemSourceType(vTargetRecord);
	if sTargetRecordType == "item" then
		return;
	end

	sendParcelTransfer(sTargetRecord, sRecord);
end

function handleString(vTargetRecord, s, n)
	local sTargetRecord = nil;
	if type(vTargetRecord) == "databasenode" then
		sTargetRecord = vTargetRecord.getPath();
	elseif type(vTargetRecord) == "string" then
		sTargetRecord = vTargetRecord;
	end
	if not sTargetRecord then
		return;
	end

	local sText = StringManager.trim(s);
	if sText == "" or sText == "-" then
		return;
	end
	
	local nCurrency = nil;
	local sCurrency = nil;
	if n then
		nCurrency = n;
		sCurrencyMatch = StringManager.trim(s):upper();
		if GameSystem.currencies then
			for i = 1, #(GameSystem.currencies) do
				if GameSystem.currencies[i]:upper() == sCurrencyMatch then
					sCurrency = GameSystem.currencies[i];
				end
			end
		end
	else
		local nCurrencyMatch, sCurrencyMatch = sText:match("^(%d+)%s+(.+)$");
		if nCurrencyMatch then
			local sCurrencyMatch2 = StringManager.trim(sCurrencyMatch);
			-- DEBUG - Remove when 5E DMG fixed
			if sCurrencyMatch2:match("^%([0-9,]+%)") then
				sCurrencyMatch2 = sCurrencyMatch2:gsub("^%([0-9,]+%)", "");
				sCurrencyMatch2 = StringManager.trim(sCurrencyMatch2);
			end
			sCurrencyMatch2 = sCurrencyMatch2:upper();
			if GameSystem.currencies then
				for i = 1, #(GameSystem.currencies) do
					if GameSystem.currencies[i]:upper() == sCurrencyMatch2 then
						sCurrency = GameSystem.currencies[i];
						nCurrency = nCurrencyMatch;
					end
				end
			end
			if not sCurrency then
				sText = sCurrencyMatch;
				n = nCurrencyMatch;
			end
		end
	end
		
	if sCurrency then
		sendCurrencyTransfer(sTargetRecord, sCurrency, nCurrency);
	else
		sendItemStringTransfer(sTargetRecord, sText, n);
	end
end

--
-- ADD/TRANSFER ITEM
--

-- DEPRECATED
function notifyTransfer(sTargetInvRecord, sClass, sRecord, bTransferAll)
	local aSplit = StringManager.split(sTargetInvRecord, ".");
	if #aSplit < 2 then
		return;
	end
	local sTargetList = aSplit[#aSplit];
	table.remove(aSplit, #aSplit);
	
	handleItem(table.concat(aSplit, "."), sTargetList, sClass, sRecord, bTransferAll);
end

function sendItemTransfer (sTargetRecord, sTargetList, sClass, sRecord, bTransferAll)
	for _,fHandler in ipairs(aCustomTransferNotifyHandlers) do
		if fHandler(DB.getPath(sTargetRecord, sTargetList), sClass, sRecord, bTransferAll) then
			return;
		end
	end
	
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_TRANSFERITEM;
	
	msgOOB.sTarget = sTargetRecord;
	msgOOB.sTargetList = sTargetList;
	msgOOB.sClass = sClass;
	msgOOB.sRecord = sRecord;
	if bTransferAll then
		msgOOB.sTransferAll = "true";
	end

	if not User.isHost() then
		local sSourceRecordType = getItemSourceType(sRecord);
		local sTargetRecordType = getItemSourceType(nodeTargetRecord);
		if not StringManager.contains({"partysheet", "charsheet"}, sSourceRecordType) and StringManager.contains({"charsheet"}, sTargetRecordType) then
			handleItemTransfer(msgOOB);
			return;
		end
	end

	Comm.deliverOOBMessage(msgOOB, "");
end

function handleItemTransfer(msgOOB)
	addItemToList(DB.getPath(msgOOB.sTarget, msgOOB.sTargetList), msgOOB.sClass, msgOOB.sRecord, ((msgOOB.sTransferAll or "") == "true"));
end

-- NOTE: Assumed target and source base nodes 
-- (item = campaign, charsheet = char inventory, partysheet = party inventory, treasureparcels = parcel inventory)
function addItemToList(vList, sClass, vSource, bTransferAll, nTransferCount)
	-- Get the source item database node object
	local nodeSource = nil;
	if type(vSource) == "databasenode" then
		nodeSource = vSource;
	elseif type(vSource) == "string" then
		nodeSource = DB.findNode(vSource);
	end
	local nodeList = nil;
	if type(vList) == "databasenode" then
		nodeList = vList;
	elseif type(vList) == "string" then
		nodeList = DB.createNode(vList);
	end
	if not nodeSource or not nodeList then
		return nil;
	end
	
	-- Determine the source and target item location type
	local sSourceRecordType = getItemSourceType(nodeSource);
	local sTargetRecordType = getItemSourceType(nodeList);
	
	-- Make sure that the source and target locations are not the same character
	if sSourceRecordType == "charsheet" and sTargetRecordType == "charsheet" then
		if nodeSource.getParent().getNodeName() == nodeList.getNodeName() then
			return nil;
		end
	end
	
	-- Use a temporary location to create an item copy for manipulation, if the item type is supported
	local sTempPath;
	if nodeList.getParent() then
		sTempPath = nodeList.getParent().getPath("temp.item");
	else
		sTempPath = "temp.item";
	end
	DB.deleteNode(sTempPath);
	local nodeTemp = DB.createNode(sTempPath);
	local bCopy = false;
	if sClass == "item" then
		local bID = getIDState(nodeSource, true);
		DB.copyNode(nodeSource, nodeTemp);
		if bID then
			DB.setValue(nodeTemp, "isidentified", "number", 1);
		end
		bCopy = true;
	elseif ItemManager2 and ItemManager2.addItemToList2 then
		bCopy = ItemManager2.addItemToList2(sClass, nodeSource, nodeTemp, nodeList);
	end
	
	local nodeNew = nil;
	if bCopy then
		-- Remove fields that shouldn't be transferred
		for _,sField in ipairs(aDeleteCopyFields) do
			DB.deleteChild(nodeTemp, sField);
		end
		
		-- Determine target node for source item data.  
		-- If we already have an item with the same fields, then just append the item count.  
		-- Otherwise, create a new item and copy from the source item.
		local bAppend = false;
		if sTargetRecordType ~= "item" then
			for _,vItem in pairs(DB.getChildren(nodeList, "")) do
				if compareFields(vItem, nodeTemp, true) then
					nodeNew = vItem;
					bAppend = true;
					break;
				end
			end
		end
		if not nodeNew then
			nodeNew = DB.createChild(nodeList);
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
				(sSourceRecordType == "treasureparcels" and sTargetRecordType == "charsheet") or 
				(sSourceRecordType == "partysheet" and sTargetRecordType == "treasureparcels") or 
				(sSourceRecordType == "treasureparcels" and sTargetRecordType == "treasureparcels") then
			bCountN = true;
		elseif (sSourceRecordType == "partysheet" and sTargetRecordType == "charsheet") or
				(sSourceRecordType == "charsheet" and sTargetRecordType == "charsheet") or
				(sSourceRecordType == "charsheet" and sTargetRecordType == "partysheet") then
			if bTransferAll then
				bCountN = true;
			end
		elseif (sSourceRecordType == "temp" and sTargetRecordType == "charsheet") or
				(sSourceRecordType == "temp" and sTargetRecordType == "treasureparcels") or 
				(sSourceRecordType == "temp" and sTargetRecordType == "partysheet") then
			bCountN = true;
		end
		local nCount = 1;
		if bCountN or sTargetRecordType ~= "item" then
			if bCountN then
				nCount = DB.getValue(nodeSource, "count", 1);
			elseif nTransferCount then
				nCount = math.min(DB.getValue(nodeSource, "count", 1), nTransferCount);
			end
			if bAppend then
				local nAppendCount = math.max(DB.getValue(nodeNew, "count", 1), 1);
				DB.setValue(nodeNew, "count", "number", nCount + nAppendCount);
			else
				DB.setValue(nodeNew, "count", "number", nCount);
			end
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
			if nCount > 1 then
				msg.text = msg.text .. " (" .. nCount .. "x)";
			end
			Comm.deliverChatMessage(msg);

			local nCharCount = DB.getValue(nodeSource, "count", 0);
			if nCharCount <= nCount then
				onCharRemoveEvent(nodeSource);
				nodeSource.delete();
			else
				DB.setValue(nodeSource, "count", "number", nCharCount - nCount);
			end
		elseif sSourceRecordType == "partysheet" and sTargetRecordType == "charsheet" then
			local msg = {font = "msgfont", icon = "coins"};
			msg.text = "[" .. sSrcName .. "] -> [" .. sTrgtName .. "] : " .. sItemName;
			if nCount > 1 then
				msg.text = msg.text .. " (" .. nCount .. "x)";
			end
			Comm.deliverChatMessage(msg);

			local nPartyCount = DB.getValue(nodeSource, "count", 0);
			if nPartyCount <= nCount then
				nodeSource.delete();
			else
				DB.setValue(nodeSource, "count", "number", nPartyCount - nCount);
			end
		end
	end
	
	-- Clean up
	DB.deleteNode(sTempPath);

	return nodeNew;
end

--
-- ADD/TRANSFER CURRENCY
--

function sendCurrencyTransfer (sTargetRecord, sCurrency, nCurrency)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_TRANSFERCURRENCY;
	
	msgOOB.sTarget = sTargetRecord;
	msgOOB.sCurrency = sCurrency;
	msgOOB.nCurrency = nCurrency;

	Comm.deliverOOBMessage(msgOOB, "");
end

-- NOTE: Assume that we are running on host
function handleCurrencyTransfer (msgOOB)
	local nodeTargetRecord = DB.findNode(msgOOB.sTarget);
	if not nodeTargetRecord then
		return;
	end
	
	local nCurrency = tonumber(msgOOB.nCurrency) or 0;
	if nCurrency <= 0 then
		return;
	end
	local sCurrency = msgOOB.sCurrency;
	local sCurrencyUpper = sCurrency:upper();
	
	local sTargetRecordType = getItemSourceType(nodeTargetRecord);
	if sTargetRecordType == "charsheet" then
		local nodeTargetCoinSlot = nil;
		
		-- Check for existing coin match, or find first empty slot
		for i = 1,6 do
			if DB.getValue(nodeTargetRecord, "coins.slot" .. i .. ".name", ""):upper() == sCurrencyUpper then
				nodeTargetCoinSlot = DB.getChild(nodeTargetRecord, "coins.slot" .. i);
				break;
			end
		end
		if not nodeTargetCoinSlot then
			for i = 1,6 do
				local sCharCoin = StringManager.trim(DB.getValue(nodeTargetRecord, "coins.slot" .. i .. ".name", ""));
				if sCharCoin == "" and (DB.getValue(nodeTargetRecord, "coins.slot" .. i .. ".amount", 0) == 0) then
					nodeTargetCoinSlot = DB.getChild(nodeTargetRecord, "coins.slot" .. i);
					break;
				end
			end
		end
		
		-- If we have a match or an empty slot, then add the currency; otherwise, add to the other area
		if nodeTargetCoinSlot then
			DB.setValue(nodeTargetCoinSlot, "amount", "number", DB.getValue(nodeTargetCoinSlot, "amount", 0) + nCurrency);
			DB.setValue(nodeTargetCoinSlot, "name", "string", sCurrency);
		else
			local aCoinOther = { DB.getValue(nodeTargetRecord, "coinother", "") };
			table.insert(aCoinOther, "" .. nCurrency .. " " .. sCurrency);
			DB.setValue(nodeTargetRecord, "coinother", "string", table.concat(aCoinOther, ", "));
		end
	elseif sTargetRecordType == "treasureparcels" then
		local nodeTargetCoin = nil;
		for _,vParcelCoin in pairs(DB.getChildren(nodeTargetRecord, "coinlist")) do
			if sCurrency:upper() == DB.getValue(vParcelCoin, "description", ""):upper() then
				nodeTargetCoin = vParcelCoin;
			end
		end
		if not nodeTargetCoin  then
			nodeTargetCoin = DB.createChild(nodeTarget, "coinlist");
			DB.setValue(nodeTargetCoin, "description", "string", sCurrency);
		end
		DB.setValue(nodeTargetCoin, "amount", "number", nCurrency + DB.getValue(nodeTargetCoin, "amount", 0));
	elseif sTargetRecordType == "partysheet" then
		local nodeCurrency = nil;
		for _,vPSCurrency in pairs(DB.getChildren("partysheet.treasureparcelcoinlist")) do
			if DB.getValue(vPSCurrency, "description", ""):upper() == sCurrencyUpper then
				nodeCurrency = vPSCurrency;
				break;
			end
		end
		
		if nodeCurrency then
			DB.setValue(nodeCurrency, "amount", "number",  DB.getValue(nodeCurrency, "amount", 0) + nCurrency);
		else
			nodeCurrency = DB.createChild("partysheet.treasureparcelcoinlist");
			DB.setValue(nodeCurrency, "description", "string", sCurrency);
			DB.setValue(nodeCurrency, "amount", "number", nCurrency);
		end
	end
end

--
-- ADD/TRANSFER PARCEL
--

function sendParcelTransfer (sTargetRecord, sSource)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_TRANSFERPARCEL;
	
	msgOOB.sTarget = sTargetRecord;
	msgOOB.sSource = sSource;

	Comm.deliverOOBMessage(msgOOB, "");
end

-- NOTE: Assume that we are running on host
function handleParcelTransfer (msgOOB)
	local nodeTargetRecord = DB.findNode(msgOOB.sTarget);
	if not nodeTargetRecord then
		return;
	end
	
	local nodeParcel = DB.findNode(msgOOB.sSource);
	if not nodeParcel then
		return;
	end
	
	for _,vParcelItem in pairs(DB.getChildren(nodeParcel, "itemlist")) do
		handleItem(nodeTargetRecord, nil, "item", vParcelItem.getNodeName(), true);
	end
								
	for _,vParcelCoin in pairs(DB.getChildren(nodeParcel, "coinlist")) do
		local sCurrency = DB.getValue(vParcelCoin, "description", "");
		local nCurrency = DB.getValue(vParcelCoin, "amount", 0);
		handleCurrency(nodeTargetRecord, sCurrency, nCurrency);
	end

	local sTargetRecordType = getItemSourceType(nodeTargetRecord);
	if sTargetRecordType == "charsheet" then
		local msg = {font = "msgfont", icon = "coins"};
		msg.text = "Parcel [" .. DB.getValue(DB.getPath(nodeParcel, "name"), "") .. "] -> [" .. DB.getValue(DB.getPath(nodeTargetRecord, "name"), "") .. "]";
		Comm.deliverChatMessage(msg);
	end
end

--
-- ADD/TRANSFER STRING
--

function sendItemStringTransfer (sTargetRecord, sItemName, nItemCount)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_TRANSFERITEMSTRING;
	
	msgOOB.sTarget = sTargetRecord;
	msgOOB.sName = sItemName;
	msgOOB.nCount = nItemCount;

	Comm.deliverOOBMessage(msgOOB, "");
end

-- NOTE: Assume that we are running on host
function handleItemStringTransfer (msgOOB)
	local nodeTargetRecord = DB.findNode(msgOOB.sTarget);
	if not nodeTargetRecord then
		return;
	end
	
	local sText = StringManager.trim(msgOOB.sName);
	if sText == "" or sText == "-" then
		return;
	end
	
	local nCount = tonumber(msgOOB.nCount) or 1;
	
	local sTempPath = "temp.stringasitem";
	DB.deleteNode(sTempPath);
	local nodeTemp = DB.createNode(sTempPath);
	DB.setValue(nodeTemp, "name", "string", sText);
	DB.setValue(nodeTemp, "count", "number", nCount);
	DB.setValue(nodeTemp, "isidentified", "number", 1);
	
	handleItem(nodeTargetRecord, nil, "item", sTempPath, true);
	
	DB.deleteNode(sTempPath);
end


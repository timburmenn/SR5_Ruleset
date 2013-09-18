-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- NOTE: Assumes field is a child of each item record, and is a string data type.
local sItemCostField = "cost";
function setItemCostField(sField)
	sItemCostField = sField;
end
local sItemCostCurrency = "";
function setDefaultCurrency(s)
	sItemCostCurrency = s;
end

--
-- DROP HANDLING
--

function addParcel(nodeParcel)
	if not User.isHost() then
		return;
	end
	
	if not nodeParcel then
		return;
	end
	
	for _,v in pairs(DB.getChildren(nodeParcel, "itemlist")) do
		addItem("item", v);
	end
								
	for _,vParcelCoin in pairs(DB.getChildren(nodeParcel, "coinlist")) do
		local sCoin = DB.getValue(vParcelCoin, "description", "");
		local nCoin = DB.getValue(vParcelCoin, "amount", 0);
		addCoins(sCoin, nCoin);
	end
end

function addItem(sClass, nodeRecord)
	ItemManager.notifyTransfer("partysheet.treasureparcelitemlist", sClass, nodeRecord.getNodeName())
end

function addCoins(sCoin, nCoin)
	local sCoinList = "partysheet.treasureparcelcoinlist";
	
	local nodeCoin = nil;
	for _,vPSCoin in pairs(DB.getChildren(sCoinList)) do
		if DB.getValue(vPSCoin, "description", ""):upper() == sCoin:upper() then
			nodeCoin = vPSCoin;
			break;
		end
	end
	
	if nodeCoin then
		nCoin = nCoin + DB.getValue(nodeCoin, "amount", 0);
		DB.setValue(nodeCoin, "amount", "number", nCoin);
	else
		nodeCoin = DB.createChild(sCoinList);
		DB.setValue(nodeCoin, "description", "string", sCoin);
		DB.setValue(nodeCoin, "amount", "number", nCoin);
	end
end

--
-- DISTRIBUTION
--

function distribute()
	distributeParcelAssignments();
	distributeParcelCoins();
end

function distributeParcelAssignments()
	-- Determine members of party
	local aParty = {};
	for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
		local sClass, sRecord = DB.getValue(v, "link");
		if sClass == "charsheet" and sRecord then
			local nodePC = DB.findNode(sRecord);
			if nodePC then
				local rMember = {};
				rMember.name = DB.getValue(v, "name", "");
				rMember.node = nodePC;
				rMember.given = {};
				
				table.insert(aParty, rMember);
			end
		end
	end
	if #aParty == 0 then
		return;
	end

	-- Add assigned items to party members
	local nItems = 0;
	local aItemsAssigned = {};
	for _,vItem in pairs(DB.getChildren("partysheet.treasureparcelitemlist")) do
		local sItem = DB.getValue(vItem, "name", "");
		local nCount = DB.getValue(vItem, "count", 0);
		if sItem ~= "" and nCount > 0 then
			nItems = nItems + 1;

			local sAssign = DB.getValue(vItem, "assign", "");
			if sAssign ~= "" then
				local rMember = nil;
				for _,v in ipairs(aParty) do
					if sAssign == v.name then
						rMember = v;
						break;
					end
				end
				
				local sError = nil;
				if rMember then
					nodeItem = ItemManager.addItemToList(rMember.node.getNodeName() .. ".inventorylist", "item", vItem);
					if nodeItem then
						table.insert(aItemsAssigned, { item = ItemManager.getDisplayName(nodeItem), name = rMember.name });
					else
						sError = "Unable to create character inventory entry (" .. sAssign .. ") for item assignment.";
					end
				else
					sError = "Unable to locate character (" .. sAssign .. ") for item assignment.";
				end
				
				if sError then
					local msg = {font = "msgfont"};
					msg.text = "[WARNING] " .. sError;
					Comm.addChatMessage(msg);
				else
					DB.setValue(vItem, "assign", "string", "");
				end
			end
		end
	end
	if nItems == 0 then
		return;
	end
	
	-- Output item assignments and rebuild party inventory
	local msg = {font = "msgfont", icon = "portrait_gm_token"};
	if #aItemsAssigned > 0 then
		msg.text = "Distributed assigned items to the Party";
		Comm.deliverChatMessage(msg);

		buildPartyInventory();
	else
		msg.text = "No items assigned for distribution to the Party";
		Comm.addChatMessage(msg);
	end
end

function distributeParcelCoins() 
	-- Determine coins in parcel
	local aParcelCoins = {};
	local nCoinEntries = 0;
	for _,vCoin in pairs(DB.getChildren("partysheet.treasureparcelcoinlist")) do
		local sCoin = DB.getValue(vCoin, "description", ""):upper();
		local nCount = DB.getValue(vCoin, "amount", 0);
		if sCoin ~= "" and nCount > 0 then
			aParcelCoins[sCoin] = (aParcelCoins[sCoin] or 0) + nCount;
			nCoinEntries = nCoinEntries + 1;
		end
	end
	if nCoinEntries == 0 then
		return;
	end
	
	-- Determine members of party
	local aParty = {};
	for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
		local sClass, sRecord = DB.getValue(v, "link");
		if sClass == "charsheet" and sRecord then
			local nodePC = DB.findNode(sRecord);
			if nodePC then
				local rMember = {};
				
				rMember.name = DB.getValue(v, "name", "");
				rMember.node = nodePC;
				rMember.coins = {};
				rMember.given = {};
				
				for _,nodeCoin in pairs(DB.getChildren(nodePC, "coins")) do
					local sCoin = string.upper(DB.getValue(nodeCoin, "name", ""));
					if sCoin ~= "" then
						rMember.coins[sCoin] = nodeCoin;
					end
				end
				
				table.insert(aParty, rMember);
			end
		end
	end
	if #aParty == 0 then
		return;
	end
	
	-- Add party member split to their character sheet
	for sCoin, nCoin in pairs(aParcelCoins) do
		local nAverageSplit;
		if nCoin >= #aParty then
			nAverageSplit = math.floor(nCoin / #aParty);
		else
			nAverageSplit = 0;
		end
		local nFinalSplit = math.max((nCoin - ((#aParty - 1) * nAverageSplit)), 0);
		
		for k,v in ipairs(aParty) do
			local nAmount;
			if k == #aParty then
				nAmount = nFinalSplit;
			else
				nAmount = nAverageSplit;
			end
			
			if nAmount > 0 then
				-- Add distribution amount to character
				local sTarget = nil;
				if v.coins[sCoin] then
					sTarget = "coins." .. v.coins[sCoin].getName();
				else
					for i = 1,6 do
						local sNodeCoin = "coins.slot" .. i;
						local sCharCoin = DB.getValue(v.node, sNodeCoin .. ".name", ""); 
						local nCharAmt = DB.getValue(v.node, sNodeCoin .. ".amount", 0);
						if sCharCoin == "" and nCharAmt == 0 then
							sTarget = sNodeCoin;
							break;
						end
					end
				end
				if sTarget then
					local nNewAmount = DB.getValue(v.node, sTarget .. ".amount", 0) + nAmount;
					DB.setValue(v.node, sTarget .. ".amount", "number", nNewAmount);
					DB.setValue(v.node, sTarget .. ".name", "string", sCoin);
				else
					local sCoinOther = DB.getValue(v.node, "coinother", "");
					if sCoinOther ~= "" then
						sCoinOther = sCoinOther .. ", ";
					end
					sCoinOther = sCoinOther .. nAmount .. " " .. sCoin;
					DB.setValue(v.node, "coinother", "string", sCoinOther);
				end
				
				-- Track distribution amount for output message
				v.given[sCoin] = nAmount;
			end
		end
	end
	
	-- Output coin assignments
	local aPartyAmount = {};
	for sCoin, nCoin in pairs(aParcelCoins) do
		table.insert(aPartyAmount, tostring(nCoin) .. " " .. sCoin);
	end

	local msg = {font = "msgfont"};
	
	msg.icon = "coins";
	for _,v in ipairs(aParty) do
		local aMemberAmount = {};
		for sCoin, nCoin in pairs(v.given) do
			table.insert(aMemberAmount, tostring(nCoin) .. " " .. sCoin);
		end
		msg.text = "[" .. table.concat(aMemberAmount, ", ") .. "] -> " .. v.name;
		Comm.deliverChatMessage(msg);
	end
	
	msg.icon = "portrait_gm_token";
	msg.text = "Distributed [" .. table.concat(aPartyAmount, ", ") .. "] across the Party";
	Comm.deliverChatMessage(msg);

	-- Reset parcel and party coin amounts
	for _,vCoin in pairs(DB.getChildren("partysheet.treasureparcelcoinlist")) do
		vCoin.delete();
	end
	buildPartyCoins();
end

--
-- PARTY INVENTORY VIEWING
--

function rebuild()
	buildPartyInventory();
	buildPartyCoins();
end

function buildPartyInventory()
	for _,vItem in pairs(DB.getChildren("partysheet.inventorylist")) do
		vItem.delete();
	end

	-- Determine members of party
	local aParty = {};
	for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
		local sClass, sRecord = DB.getValue(v, "link");
		if sClass == "charsheet" and sRecord then
			local nodePC = DB.findNode(sRecord);
			if nodePC then
				local sName = DB.getValue(v, "name", "");
				table.insert(aParty, { name = sName, node = nodePC } );
			end
		end
	end
	
	-- Build a database of party inventory items
	local aInvDB = {};
	for _,v in ipairs(aParty) do
		for _,nodeItem in pairs(DB.getChildren(v.node, "inventorylist")) do
			local sItem = ItemManager.getDisplayName(nodeItem);
			if sItem ~= "" then
				local nCount = math.max(DB.getValue(nodeItem, "count", 0), 1)
				if aInvDB[sItem] then
					aInvDB[sItem].count = aInvDB[sItem].count + nCount;
				else
					local aItem = {};
					aItem.count = nCount;
					aInvDB[sItem] = aItem;
				end
				
				if not aInvDB[sItem].carriedby then
					aInvDB[sItem].carriedby = {};
				end
				aInvDB[sItem].carriedby[v.name] = ((aInvDB[sItem].carriedby[v.name]) or 0) + nCount;
			end
		end
	end
	
	-- Create party sheet inventory entries
	for sItem, rItem in pairs(aInvDB) do
		local vGroupItem = DB.createChild("partysheet.inventorylist");
		DB.setValue(vGroupItem, "count", "number", rItem.count);
		DB.setValue(vGroupItem, "name", "string", sItem);
		
		local aCarriedBy = {};
		for k,v in pairs(rItem.carriedby) do
			table.insert(aCarriedBy, string.format("%s [%d]", k, math.floor(v)));
		end
		DB.setValue(vGroupItem, "carriedby", "string", table.concat(aCarriedBy, ", "));
	end
end

function buildPartyCoins()
	for _,vCoin in pairs(DB.getChildren("partysheet.coinlist")) do
		vCoin.delete();
	end

	-- Determine members of party
	local aParty = {};
	for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
		local sClass, sRecord = DB.getValue(v, "link");
		if sClass == "charsheet" and sRecord then
			local nodePC = DB.findNode(sRecord);
			if nodePC then
				local sName = DB.getValue(v, "name", "");
				table.insert(aParty, { name = sName, node = nodePC } );
			end
		end
	end
	
	-- Build a database of party coins
	local aCoinDB = {};
	for _,v in ipairs(aParty) do
		for _,nodeCoin in pairs(DB.getChildren(v.node, "coins")) do
			local sCoin = DB.getValue(nodeCoin, "name", ""):upper();
			if sCoin ~= "" then
				local nCount = DB.getValue(nodeCoin, "amount", 0);
				if nCount > 0 then
					if aCoinDB[sCoin] then
						aCoinDB[sCoin].count = aCoinDB[sCoin].count + nCount;
						aCoinDB[sCoin].carriedby = string.format("%s, %s [%d]", aCoinDB[sCoin].carriedby, v.name, math.floor(nCount));
					else
						local aCoin = {};
						aCoin.count = nCount;
						aCoin.carriedby = string.format("%s [%d]", v.name, math.floor(nCount));
						aCoinDB[sCoin] = aCoin;
					end
				end
			end
		end
	end
	
	-- Create party sheet coin entries
	for sCoin, rCoin in pairs(aCoinDB) do
		local vGroupItem = DB.createChild("partysheet.coinlist");
		DB.setValue(vGroupItem, "amount", "number", rCoin.count);
		DB.setValue(vGroupItem, "name", "string", sCoin);
		DB.setValue(vGroupItem, "carriedby", "string", rCoin.carriedby);
	end
end

--
-- SELL ITEMS
--

function sellItems()
	local nItemTotal = 0;
	local aSellTotal = {};
	local nSellPercentage = DB.getValue("partysheet.sellpercentage");
	
	for _,vItem in pairs(DB.getChildren("partysheet.treasureparcelitemlist")) do
		local sItem = DB.getValue(vItem, "name", "");
		local sCost = DB.getValue(vItem, sItemCostField, "");
		local sCoinValue, sCoin = string.match(sCost, "^%s*([%d,]+)%s*([%w%s]+%w)%s*$");
		local nCoin = 0;
		if sCoinValue then
			sCoinValue = string.gsub(sCoinValue, ",", "");
			nCoin = tonumber(sCoinValue) or 0;
		elseif sItemCostCurrency ~= "" then
			sCoin = sItemCostCurrency;
			nCoin = tonumber(sCost) or 0;
		end
		if nCoin == 0 then
			local msg = {font = "systemfont"};
			msg.text = "Unable to determine cost for [" .. sItem .. "] or zero cost";
			Comm.addChatMessage(msg);
		else
			local nCount = math.max(DB.getValue(vItem, "count", 1), 1);
			local nItemSellTotal = math.floor(nCount * nCoin * nSellPercentage / 100);
			if nItemSellTotal <= 0 then
				local msg = {font = "systemfont"};
				msg.text = "Sell total is less than one currency unit for [" .. sItem .. "]";
				Comm.addChatMessage(msg);
			else
				addCoins(sCoin, nItemSellTotal);
				aSellTotal[sCoin] = (aSellTotal[sCoin] or 0) + nItemSellTotal;
				nItemTotal = nItemTotal + nCount;
				
				vItem.delete();

				local msg = {font = "msgfont"};
				msg.text = "Selling [";
				if nCount > 1 then
					msg.text = msg.text .. "(" .. nCount .. "x) ";
				end
				msg.text = msg.text .. sItem .. "] -> [" .. nItemSellTotal .. " " .. sCoin .. "]";
				Comm.deliverChatMessage(msg);
			end
		end
	end

	if nItemTotal > 0 then
		local aTotalOutput = {};
		for k,v in pairs(aSellTotal) do
			table.insert(aTotalOutput, tostring(v) .. " " .. k);
		end
		local msg = {font = "msgfont"};
		msg.icon = "portrait_gm_token";
		msg.text = tostring(nItemTotal) .. " item(s) sold for [" .. table.concat(aTotalOutput, ", ") .. "]";
		Comm.deliverChatMessage(msg);
	end
end

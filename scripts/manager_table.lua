-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	Comm.registerSlashHandler("rollon", processTableRoll);
	ActionsManager.registerResultHandler("table", onTableRoll);
end

function performRoll(draginfo, rActor, nodeTable, nColumn, bUseModStack, aDice, nMod)
	-- If dice or modifier not provided, then use the right one for this table
	if not aDice or #aDice == 0 then
		aDice = getTableDice(nodeTable);
	end
	if not nMod then
		nMod = 0;
	end

	local rRoll = {};
	rRoll.sType = "table";
	rRoll.sDesc = "[TABLE] " .. DB.getValue(nodeTable, "name", "");
	if nColumn > 0 then
		rRoll.sDesc = rRoll.sDesc .. " (" .. nColumn .. " - " .. DB.getValue(nodeTable, "labelcol" .. nColumn) .. ")";
	end
	rRoll.aDice = aDice;
	rRoll.nMod = nMod;
	
	-- Add modifier stack
	if bUseModStack and not ModifierStack.isEmpty() then
		local sStackDesc, nStackMod = ModifierStack.getStack(true);
		rRoll.sDesc = rRoll.sDesc .. " (" .. sStackDesc .. ")";
		rRoll.nMod = rRoll.nMod + nStackMod;
	end
	
	rRoll.bSecret = (DB.getValue(nodeTable, "hiderollresults", 0) ~= 0);
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

-- Determine die to roll for this table
function getTableDice(nodeTable)
	local nMax = 0;
	for _,v in pairs(DB.getChildren(nodeTable, "tablerows")) do
		local nEnd = DB.getValue(v, "torange", 0);
		if nEnd == 0 then
			nEnd = DB.getValue(v, "fromrange", 0);
		end
		nMax = math.max(nEnd, nMax);
	end
	
	local aDice = {};
	if nMax <= 2 then
		table.insert(aDice, "d2");
	elseif nMax <= 3 then
		table.insert(aDice, "d3");
	elseif nMax <= 4 then
		table.insert(aDice, "d4");
	elseif nMax <= 6 then
		table.insert(aDice, "d6");
	elseif nMax <= 8 then
		table.insert(aDice, "d8");
	elseif nMax <= 10 then
		table.insert(aDice, "d10");
	elseif nMax <= 12 then
		table.insert(aDice, "d12");
	elseif nMax <= 20 then
		table.insert(aDice, "d20");
	else
		table.insert(aDice, "d100");
		table.insert(aDice, "d10");
	end
	
	return aDice;
end

function findTableInDB(nodeRoot, sTable)
	for _,v in pairs(DB.getChildren(nodeRoot, "tables")) do
		if StringManager.trim(DB.getValue(v, "name", "")) == sTable then
			return v;
		end
	end
	
	return nil;
end

function findTable(sTable)
	local sFind = StringManager.trim(sTable);
	
	local nodeTable = findTableInDB(DB.getRoot(), sFind);
	if not nodeTable then
		local aModules = Module.getModules();
		for _,v in ipairs(aModules) do
			nodeTable = findTableInDB(DB.getRoot(v), sFind);
			if nodeTable then
				break;
			end
		end
	end
	
	return nodeTable;
end

function findColumn(nodeTable, sColumn)
	local nResultColumn = 0;

	if sColumn and sColumn ~= "" then
		local sFind = StringManager.trim(sColumn);
		local nColumns = DB.getValue(nodeTable, "resultscols", 0);
		for i = 1, nColumns do
			if StringManager.trim(DB.getValue(nodeTable, "labelcol" .. i, "")) == sFind then
				nResultColumn = i;
				break;
			end
		end
	end
	
	return nResultColumn;
end

function getResult(nodeTable, nTotal, nColumn)
	local nodeResults = nil;
	for _,v in pairs(DB.getChildren(nodeTable, "tablerows")) do
		local nFrom = DB.getValue(v, "fromrange", 0);
		local nTo = DB.getValue(v, "torange", 0);
		if nTo == 0 then
			nTo = nFrom;
		end
		if (nTotal >= nFrom) and (nTotal <= nTo) then
			nodeResults = v.getChild("results");
			break;
		end
	end
	if not nodeResults then
		return nil;
	end
	
	local aChildren = nodeResults.getChildren();
	local aKeys = {};
	for k,_ in pairs(aChildren) do
		table.insert(aKeys, k);
	end
	table.sort(aKeys);
	
	if nColumn > 0 then
		if not aKeys[nColumn] then
			return nil;
		end
		return DB.getValue(aChildren[aKeys[nColumn]], "result", "");
	end
	
	local aResult = {};
	for k = 1, #aKeys do
		table.insert(aResult, DB.getValue(aChildren[aKeys[k]], "result", ""));
	end
	return table.concat(aResult, " ");
end

function onTableRoll(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	local nTotal = ActionsManager.total(rRoll);
	
	local nodeTable = nil;
	local sTable = string.match(rRoll.sDesc, "%[TABLE%] ([^([]+)");
	if sTable then
		nodeTable = findTable(sTable);
	end
	if not nodeTable then
		rMessage.text = rMessage.text .. " = [Unable to find matching table]";
		Comm.addChatMessage(rMessage);
		return;
	end
	
	local nColumn = 0;
	local sColumn = string.match(rRoll.sDesc, "%[TABLE%] [^([]+%((%d) %- ([^)]+)%)")
	if sColumn then
		nColumn = tonumber(sColumn) or 0;
	end
	
	local sResult = getResult(nodeTable, nTotal, nColumn);
	if not sResult then
		rMessage.text = rMessage.text .. " = [Unable to find result row or column]";
		Comm.addChatMessage(rMessage);
		return;
	end
	
	rMessage.text = rMessage.text .. " = " .. sResult;
	
	if bHideRoll then
		Comm.addChatMessage(rMessage);
	else
		Comm.deliverChatMessage(rMessage);
	end

	local sTable;
	for sTable in string.gmatch(sResult, "%[([^]]+)%]") do
		local nodeTable = findTable(sTable);
		if nodeTable then
			performRoll(nil, rSource, nodeTable, 0, false);
		else
			ChatManager.SystemMessage("[ERROR] Unable to find table (" .. sTable .. ")");
		end
	end
end

function processTableRoll(sCommand, sParams)
	local bError = false;
	local sFlag = "";
	local aTableName = {};
	local aColumnName = {};
	local aDiceString = {};
	local bHide = false;

	local aWords = StringManager.parseWords(sParams);
	for k = 1, #aWords do
		if aWords[k] == "-c" or aWords[k] == "-d" then
			sFlag = aWords[k];
		elseif aWords[k] == "-hide" then
			sFlag = aWords[k];
			bHide = true;
		elseif aWords[k]:sub(1,1) == "-" then
			bError = true;
			break;
		else
			if sFlag == "" then
				table.insert(aTableName, aWords[k]);
			elseif sFlag == "-c" then
				table.insert(aColumnName, aWords[k]);
			elseif sFlag == "-d" then
				table.insert(aDiceString, aWords[k]);
			elseif sFlag == "-hide" then
				bError = true;
				break;
			end
		end
	end
	
	local sTable = table.concat(aTableName, " ");
	
	if bError or not sTable or sTable == "" then
		ChatManager.SystemMessage("Usage: /rollon tablename -c [column name] [-d dice] [-hide]");
		return;
	end

	local nodeTable = findTable(sTable);
	if not nodeTable then
		ChatManager.SystemMessage("[ERROR] Unable to find table (" .. sTable .. ")");
		return;
	end
	
	local sColumn = table.concat(aColumnName, " ");
	local nColumn = findColumn(nodeTable, sColumn);
	
	local sDice = table.concat(aDiceString, "");
	local aDice, nMod = StringManager.convertStringToDice(sDice);
	
	performRoll(nil, nil, nodeTable, nColumn, false, aDice, nMod, bHide);
end

function createTable(nRows, nStep, bSpecial)
	local nodeTables = DB.createNode("tables");
	local nodeNewTable = nodeTables.createChild();
	local nodeTableRows = nodeNewTable.createChild("tablerows");
	
	if bSpecial then
		local nFrom = 0;
		local nTo = 0;
		
		for i = 1, nRows do
			local nodeRow = nodeTableRows.createChild();

			if i == 1 then
				nFrom = 1;
				nTo = 1;
			elseif i == nRows then
				nFrom = nTo + 1;
				nTo = nFrom;
			else
				if i == 2 then
					nFrom = (i * tonumber(nStep));
				else
					nFrom = nTo + 1;
				end
				nTo = nFrom + 1;
			end
			
			DB.setValue(nodeRow, "fromrange", "number", nFrom);
			DB.setValue(nodeRow, "torange", "number", nTo);
		end
	else
		for i = 1, nRows do
			local nodeRow = nodeTableRows.createChild();
			
			local nFrom = i;
			if nFrom ~= 1 then
				nFrom = (i * tonumber(nStep) + 1) - tonumber(nStep);
			end
			local nTo = i * tonumber(nStep);

			DB.setValue(nodeRow, "fromrange", "number", nFrom);
			DB.setValue(nodeRow, "torange", "number", nTo);
		end
	end
	
	Interface.openWindow("table", nodeNewTable);
end

function lookup(sTable, nValue, sColumn)
	local nodeTable = findTable(sTable);
	if not nodeTable then
		return nil;
	end

	local nColumn = findColumn(nodeTable, sColumn);
	
	return getResult(nodeTable, nValue, nColumn);
end

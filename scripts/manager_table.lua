-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	Comm.registerSlashHandler("rollon", processTableRoll);
	ActionsManager.registerResultHandler("table", onTableRoll);
end

function prepareTableDice(rRoll)
	local aFinalDice = {};
	
	local nOriginalMod = rRoll.nMod;
	
	local aNonStandardResults = {};
	for _,v in ipairs(rRoll.aDice) do
		if StringManager.contains(Interface.getDice(), v) then
			table.insert(aFinalDice, v);
		else
			local sDieSides = v:match("^[dD]([%dF]+)");
			if sDieSides then
				local nResult;
				if sDieSides == "F" then
					local nRandom = math.random(3);
					if nRandom == 1 then
						nResult = -1;
					elseif nRandom == 3 then
						nResult = 1;
					end
				else
					local nDieSides = tonumber(sDieSides) or 0;
					nResult = math.random(nDieSides);
				end
				rRoll.nMod = rRoll.nMod + nResult;
				table.insert(aNonStandardResults, string.format(" [%s=%d]", v, nResult));
			end
		end
	end
	
	if (nOriginalMod or 0) ~= 0 then
		table.insert(aNonStandardResults, string.format(" [%+d]", nOriginalMod));
	end
	
	rRoll.aDice = aFinalDice;
	if #aNonStandardResults > 0 then
		rRoll.sDesc = rRoll.sDesc .. table.concat(aNonStandardResults, "");
	end
end

function performRoll(draginfo, rActor, rTableRoll, bUseModStack)
	-- If dice or modifier not provided, then use the right one for this table
	if (not rTableRoll.aDice or #rTableRoll.aDice == 0) and not rTableRoll.nMod then
		rTableRoll.aDice, rTableRoll.nMod = getTableDice(rTableRoll.nodeTable);
	end

	local rRoll = {};
	rRoll.sType = "table";
	rRoll.sDesc = "[" .. Interface.getString("table_tag") .. "] " .. DB.getValue(rTableRoll.nodeTable, "name", "");
	if rTableRoll.nColumn and rTableRoll.nColumn > 0 then
		rRoll.sDesc = rRoll.sDesc .. " [" .. rTableRoll.nColumn .. " - " .. DB.getValue(rTableRoll.nodeTable, "labelcol" .. rTableRoll.nColumn) .. "]";
	end
	rRoll.sNodeTable = rTableRoll.nodeTable.getNodeName();

	rRoll.aDice = rTableRoll.aDice;
	rRoll.nMod = rTableRoll.nMod;
	prepareTableDice(rRoll);
	
	local bHost = User.isHost();
	if rTableRoll.bSecret then
		rRoll.bSecret = rTableRoll.bSecret;
	elseif bHost then
		rRoll.bSecret = (DB.getValue(rTableRoll.nodeTable, "hiderollresults", 0) == 1);
	end
	if rTableRoll.sOutput then
		rRoll.sOutput = rTableRoll.sOutput;
		if rTableRoll.nodeOutput then
			rRoll.sOutputNode = rTableRoll.nodeOutput.getNodeName();
		end
	elseif bHost then
		rRoll.sOutput = DB.getValue(rTableRoll.nodeTable, "output", "");
	end
	
	-- Add modifier stack
	if bUseModStack and not ModifierStack.isEmpty() then
		local sStackDesc, nStackMod = ModifierStack.getStack(true);
		rRoll.sDesc = rRoll.sDesc .. " [" .. sStackDesc .. "]";
		rRoll.nMod = rRoll.nMod + nStackMod;
	end
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

-- Determine die to roll for this table
function getTableDice(nodeTable)
	local aDice = DB.getValue(nodeTable, "dice", {});
	local nMod = 0;
	
	if #aDice == 0 then
		local nMin = nil;
		local nMax = nil;
		for _,v in pairs(DB.getChildren(nodeTable, "tablerows")) do
			local nFrom = DB.getValue(v, "fromrange", 0);
			local nTo = DB.getValue(v, "torange", 0);
			
			if nTo == 0 then
				nMax = math.max(nFrom, nMax or nFrom);
			else
				nMax = math.max(nTo, nMax or nTo);
			end
			nMin = math.min(nFrom, nMin or nFrom);
		end
		
		local nRange = 0;
		if nMin and nMin == 0 then
			nMin = 1;
		end
		if nMin and nMax then
			nRange = math.max(nMax - nMin + 1, 0);
		end
			
		if nRange == 2 then
			table.insert(aDice, "d2");
		elseif nRange == 3 then
			table.insert(aDice, "d3");
		elseif nRange == 4 then
			table.insert(aDice, "d4");
		elseif nRange == 6 then
			table.insert(aDice, "d6");
		elseif nRange == 8 then
			table.insert(aDice, "d8");
		elseif nRange == 10 then
			table.insert(aDice, "d10");
		elseif nRange == 12 then
			table.insert(aDice, "d12");
		elseif nRange == 20 then
			table.insert(aDice, "d20");
		elseif nRange == 100 then
			table.insert(aDice, "d100");
			table.insert(aDice, "d10");
		elseif nRange > 0 then
			table.insert(aDice, "d" .. nRange);
		end
		
		if nMin then
			nMod = nMod + (nMin - 1);
		end
		
		nMod = nMod + DB.getValue(nodeTable, "mod", 0);
	else
		nMod = DB.getValue(nodeTable, "mod", 0);
	end
	
	return aDice, nMod;
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

function getResults(nodeTable, nTotal, nColumn)
	local nodeResults = nil;
	local nMin, nMax; 
	local nodeMin, nodeMax;
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
		if not nMin or nFrom < nMin then 
			nMin = nFrom;
			nodeMin = v.getChild("results");
		end
		if not nMax or nTo > nMax then
			nMax = nFrom;
			nodeMax = v.getChild("results");
		end
	end
	if not nodeResults then
		if nMin and nTotal < nMin then
			nodeResults = nodeMin;
		elseif nMax and nTotal > nMax then
			nodeResults = nodeMax;
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
	
	local aResults = {};
	if nColumn > 0 then
		if not aKeys[nColumn] then
			return nil;
		end
		local rResult = {};
		rResult.sText = StringManager.trim(DB.getValue(aChildren[aKeys[nColumn]], "result", ""));
		rResult.sClass, rResult.sRecord = DB.getValue(aChildren[aKeys[nColumn]], "resultlink");
		rResult.sLabel = DB.getValue(nodeTable, "labelcol" .. nColumn);
		table.insert(aResults, rResult);
	else
		for k = 1, #aKeys do
			local rResult = {};
			rResult.sText = StringManager.trim(DB.getValue(aChildren[aKeys[k]], "result", ""));
			rResult.sClass, rResult.sRecord = DB.getValue(aChildren[aKeys[k]], "resultlink");
			rResult.sLabel = DB.getValue(nodeTable, "labelcol" .. k);
			table.insert(aResults, rResult);
		end
	end
	
	return aResults;
end

function onTableRoll(rSource, rTarget, rRoll)
	local nodeTable = DB.findNode(rRoll.sNodeTable);
	if not nodeTable then
		local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
		rMessage.text = rMessage.text .. " = [" .. Interface.getString("table_error_tablematch") .. "]";
		Comm.addChatMessage(rMessage);
		return;
	end
	
	local nTotal = ActionsManager.total(rRoll);
	local nColumn = 0;
	local sPattern2 = "%[" .. Interface.getString("table_tag") .. "%] [^[]+%[(%d) %- ([^)]*)%]";
	local sColumn = string.match(rRoll.sDesc, sPattern2)
	if sColumn then
		nColumn = tonumber(sColumn) or 0;
	end
	
	local aResults = getResults(nodeTable, nTotal, nColumn);
	if not aResults then
		local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
		rMessage.text = rMessage.text .. " = [" .. Interface.getString("table_error_columnmatch") .. "]";
		Comm.addChatMessage(rMessage);
		return;
	end
	
	for _,v in ipairs(aResults) do
		v.aMult = {};
		
		v.aTableLinks = {};
		v.aOtherLink = nil;
		
		if (v.sClass or "") ~= "" then
			if v.sClass == "table" then
				table.insert(v.aTableLinks, { sClass = v.sClass, sRecord = v.sRecord });
			else
				v.aOtherLink = { sClass = v.sClass, sRecord = v.sRecord };
			end
		end

		if v.sText ~= "" then
			local sResult = v.sText;
			
			local sTag;
			local aMathResults = {};
			for nStartTag, sTag, nEndTag in v.sText:gmatch("()%[([^%]]+)%]()") do
				local bMult = false;
				local sPotentialRoll = sTag;
				if sPotentialRoll:match("x$") then
					sPotentialRoll = sPotentialRoll:sub(1, -2);
					bMult = true;
				end
				if StringManager.isDiceMathString(sPotentialRoll) then
					local nMathResult = StringManager.evalDiceMathExpression(sPotentialRoll);
					if bMult then
						table.insert(v.aMult, nMathResult);
						table.insert(aMathResults, { nStart = nStartTag, nEnd = nEndTag, vResult = "[" .. nMathResult .. "x]" });
					else
						table.insert(aMathResults, { nStart = nStartTag, nEnd = nEndTag, vResult = nMathResult });
					end
				else
					local nodeTable = findTable(sTag);
					if nodeTable then
						table.insert(v.aTableLinks, { sClass = "table", sRecord = nodeTable.getPath() });
					end
				end
			end
			for i = #aMathResults,1,-1 do
				sResult = sResult:sub(1, aMathResults[i].nStart - 1) .. aMathResults[i].vResult .. sResult:sub(aMathResults[i].nEnd);
			end
			
			v.sText = sResult;
		end
	end

	local sOutput = rRoll.sOutput or "";
	local nodeTarget = nil;
	local bTopTable = true;
	if sOutput ~= "" and rRoll.sOutputNode then
		nodeTarget = DB.findNode(rRoll.sOutputNode);
		if nodeTarget then
			bTopTable = false; -- Only relevant for parcel and story output
		end
	end
	
	local sResultName = "[" .. Interface.getString("table_result_tag") .. "] " .. DB.getValue(nodeTable, "name", "");
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	-- Build chat messages with links as needed
	local aAddChatMessages = {};
	rMessage.shortcuts = {};
	if sOutput == "story" then
		if not nodeTarget then
			nodeTarget = DB.createChild("encounter");
			if nodeTarget then
				DB.setValue(nodeTarget, "name", "string", sResultName);
				DB.setValue(nodeTarget, "text", "formattedtext", "<h>" .. Interface.getString("table_result_tag") .. "</h>");
				Interface.openWindow("encounter", nodeTarget);
			else
				sOutput = "";
			end
		end

		if bTopTable then
			table.insert(rMessage.shortcuts, { description = sResultName, class = "encounter", recordname = nodeTarget.getPath() });
		end
		
		local sAddDesc = "";
		for _,v in ipairs(aResults) do
			local sText = v.sText;
			sText = sText:gsub("%[[^%]]*%]", "");
			sText = StringManager.trim(sText);
			if sText:match("^%([%d]*%)$") then
				sText = "";
			end
			
			if sText ~= "" and sText ~= "-" then
				if v.aOtherLink and v.aOtherLink ~= "reference_tableresult" then
					sAddDesc = sAddDesc .. "<linklist><link class=\"" .. UtilityManager.encodeXML(v.aOtherLink.sClass) .. "\" recordname=\"" .. UtilityManager.encodeXML(v.aOtherLink.sRecord) .. "\">" .. UtilityManager.encodeXML(sText) .. "</link></linklist>";
				elseif (bTopTable or (#v.aTableLinks == 0)) then
					if sText:match("^<[biu]>") then
						sAddDesc = sAddDesc .. "<p>" .. UtilityManager.encodeXML(sText):gsub("&lt;(/?[phbiu])&gt;", "<%1>") .. "</p>";
					elseif sText:match("^<[ph]>") then
						sAddDesc = sAddDesc .. UtilityManager.encodeXML(sText):gsub("&lt;(/?[phbiu])&gt;", "<%1>");
					else
						sAddDesc = sAddDesc .. "<list><li>" .. UtilityManager.encodeXML(sText) .. "</li></list>";
					end
				end
			end
		end
		
		if sAddDesc ~= "" then
			DB.setValue(nodeTarget, "text", "formattedtext", DB.getValue(nodeTarget, "text", "") .. sAddDesc);
		end
		
	elseif sOutput == "parcel" then
		if not nodeTarget then
			nodeTarget = DB.createChild("treasureparcels");
			if nodeTarget then
				DB.setValue(nodeTarget, "name", "string", sResultName);
				Interface.openWindow("treasureparcel", nodeTarget);
			else
				sOutput = "";
			end
		end

		if bTopTable then
			table.insert(rMessage.shortcuts, { description = sResultName, class = "treasureparcel", recordname = nodeTarget.getPath() });
		end
		
		for _,v in ipairs(aResults) do
			local bHandled = false;
			if v.aOtherLink then
				if v.aOtherLink.sClass == "treasureparcel" then
					bHandled = true;
					for i = 1, (v.aMult[1] or 1) do
						ItemManager.handleParcel(nodeTarget, v.aOtherLink.sRecord);
					end
				elseif ItemManager.isItemClass(v.aOtherLink.sClass) then
					bHandled = true;
					for i = 1, (v.aMult[1] or 1) do
						ItemManager.handleItem(nodeTarget, nil, v.aOtherLink.sClass, v.aOtherLink.sRecord);
					end
				end
			end
			if not bHandled and (#v.aTableLinks == 0) then
				ItemManager.handleString(nodeTarget, v.sText);
			end
		end

	else -- Chat output
		rMessage.text = rMessage.text .. " = ";
		
		local bResultLinks = false;
		for _,v in ipairs(aResults) do
			if v.aOtherLink then
				bResultLinks = true;
			end
		end
		
		for _,v in ipairs(aResults) do
			local sResult = v.sText;
			if (v.sLabel or "") ~= "" and #aResults > 1 then
				sResult = v.sLabel .. " = " .. sResult;
			end
			
			local rResultMsg = { font = "systemfont", secret = rMessage.secret };
			if bResultLinks then
				rResultMsg.text = "[" .. Interface.getString("table_result_tag") .. "] " .. sResult;
				
				if v.aOtherLink then
					rResultMsg.shortcuts = {};
					table.insert(rResultMsg.shortcuts, { class = v.aOtherLink.sClass, recordname = v.aOtherLink.sRecord });
				end
			else
				rResultMsg.text = sResult;
			end
			table.insert(aAddChatMessages, rResultMsg);
		end
	end
	
	-- Output any chat messages
	if rMessage.secret then
		Comm.addChatMessage(rMessage);
		for _,vMsg in ipairs(aAddChatMessages) do
			Comm.addChatMessage(vMsg);
		end
	else
		Comm.deliverChatMessage(rMessage);
		for _,vMsg in ipairs(aAddChatMessages) do
			Comm.deliverChatMessage(vMsg);
		end
	end
	
	-- Follow cascading table links
	for _,v in ipairs(aResults) do
		for kLink,vLink in ipairs(v.aTableLinks) do
			local nMult = v.aMult[kLink] or 1;
			
			for i = 1, nMult do
				local rTableRoll = {};
				rTableRoll.nodeTable = DB.findNode(vLink.sRecord);
				rTableRoll.bSecret = rRoll.bSecret;
				rTableRoll.sOutput = rRoll.sOutput;
				rTableRoll.nodeOutput = nodeTarget;
				
				performRoll(nil, rSource, rTableRoll, false);
			end
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

	local aWords = StringManager.parseWords(sParams, "%(%)%[%]:");
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
		ChatManager.SystemMessage(Interface.getString("table_error_lookupfail") .. " (" .. sTable .. ")");
		return;
	end
	
	local rTableRoll = {};
	rTableRoll.nodeTable = nodeTable;
	if bHide then
		rTableRoll.bSecret = true;
	end
	
	rTableRoll.nColumn = findColumn(nodeTable, table.concat(aColumnName, " "));
	
	if #aDiceString > 0 then
		local sDice = table.concat(aDiceString, "");
		rTableRoll.aDice, rTableRoll.nMod = StringManager.convertStringToDice(sDice);
	else
		rTableRoll.aDice, rTableRoll.nMod = getTableDice(nodeTable);
	end
	
	performRoll(nil, nil, rTableRoll, false);
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

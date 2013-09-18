-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Export structures
local aNodes = {};
local aTokens = {};

local aProperties = {};

local bHasIndex = false;

function getIndexState(window)
	if window and window.index and window.index.getValue() == 1 then
		return true;
	else
		return false;
	end
end

function addExportNode(node)
	-- Create node entry
	local nodeentrytable = {};
	
	nodeentrytable.import = node.getNodeName();
	if node.getCategory() then
		nodeentrytable.category = node.getCategory();
		nodeentrytable.category.mergeid = aProperties.mergeid;
	end
	
	aNodes[node.getNodeName()] = nodeentrytable;
end

function performExport()
	-- Reset data
	aHostNodes = {};
	aCommonNodes = {};
	aClientNodes = {};
	aTokens = {};
	aProperties = {};
	bHasIndex = false;

	-- Global properties
	aProperties.name = name.getValue();
	aProperties.category = category.getValue();
	aProperties.file = file.getValue();
	aProperties.author = author.getValue();
	aProperties.thumbnail = thumbnail.getValue();
	aProperties.mergeid = mergeid.getValue();

	-- Pre checks
	if aProperties.name == "" then
		ChatManager.SystemMessage("Module name not specified");
		name.setFocus(true);
		return;
	end
	if aProperties.file == "" then
		ChatManager.SystemMessage("Module file not specified");
		file.setFocus(true);
		return;
	end
	
	-- Loop through categories
	for _, cw in ipairs(list.getWindows()) do
		-- Construct export lists
		if cw.all.getValue() == 1 then
			-- Add all child nodes
			local sourcenode = DB.findNode(cw.exportsource);
			if sourcenode then
				for _, nv in pairs(sourcenode.getChildren()) do
					if nv.getType() == "node" then
						addExportNode(nv);
					end
				end
			end
		else
			-- Loop through entries in category
			for _, ew in ipairs(cw.entries.getWindows()) do
				addExportNode(ew.getDatabaseNode());
			end
		end
	end
	
	-- Tokens
	for _, tw in ipairs(tokens.getWindows()) do
		table.insert(aTokens, tw.token.getPrototype());
	end
	
	-- Export
	local bRet = Module.export(aProperties.name, aProperties.category, aProperties.author, aProperties.file, aProperties.thumbnail,	aNodes, aTokens);
	
	if bRet then
		ChatManager.SystemMessage("Module exported successfully");
	else
		ChatManager.SystemMessage("Module export failed!");
	end
end

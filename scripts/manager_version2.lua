-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local rsname = "CoreRPG";

function onInit()
	if User.isHost() or User.isLocal() then
		updateCampaign();
	end

	DB.onAuxCharLoad = onCharImport;
	DB.onImport = onImport;
end

function onCharImport(nodePC)
	local _, _, aMajor, _ = DB.getImportRulesetVersion();
	updateChar(nodePC, aMajor[rsname]);
end

function onImport(node)
	local aPath = StringManager.split(node.getNodeName(), ".");
	if #aPath == 2 and aPath[1] == "charsheet" then
		local _, _, aMajor, _ = DB.getImportRulesetVersion();
		updateChar(node, aMajor[rsname]);
	end
end

function updateChar(nodePC, nVersion)
	if not nVersion then
		nVersion = 0;
	end
	
	if nVersion < 3 then
		if nVersion < 3 then
			migrateChar3(nodePC);
		end
	end
end

function updateCampaign()
	local _, _, aMajor, aMinor = DB.getRulesetVersion();
	local major = aMajor[rsname];
	if not major then
		return;
	end
	
	if major > 0 and major < 3 then
		print("Migrating campaign database to latest data version. (" .. rsname ..")");
		DB.backup();
		
		if major < 3 then
			convertChars3();
		end
	end
end

function migrateChar3(nodeChar)
	if DB.getChildCount(nodeChar, "skilllist") > 0 then
		local nodeCategories = DB.createChild(nodeChar, "maincategorylist");
		local nodeCategory = DB.createChild(nodeCategories);
		local nodeAttributeList = DB.createChild(nodeCategory, "attributelist");
		if nodeAttributeList then
			for _,vSkill in pairs(DB.getChildren(nodeChar, "skilllist")) do
				local vNewSkill = nodeAttributeList.createChild();
				if vNewSkill then
					DB.copyNode(vSkill, vNewSkill);
					vSkill.delete();
				end
			end
		end
	end
	if DB.getChildCount(nodeChar, "skilllist") == 0 then
		DB.deleteChild(nodeChar, "skilllist");
	end
end

function convertChars3()
	for _,nodeChar in pairs(DB.getChildren("charsheet")) do
		migrateChar3(nodeChar);
	end
end

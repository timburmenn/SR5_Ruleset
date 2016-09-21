-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local rsname = "CoreRPG";

function onInit()
	if User.isHost() then
		updateDatabase();
	end
end

function updateDatabase()
	local _, _, aMajor, aMinor = DB.getRulesetVersion();
	local major = aMajor[rsname];
	if not major then
		return;
	end
	
	if major > 0 and major < 2 then
		print("Migrating campaign database to latest data version. (" .. rsname ..")");
		DB.backup();
		
		if major < 2 then
			convertNotes2();
		end
	end
end

function convertNotes2()
	for _,vNote in pairs(DB.getChildren("notes")) do
		local vText = DB.getChild(vNote, "text");
		if DB.getType(vText) == "string" then
			local sText = vText.getValue();
			sText = "<p>" .. sText:gsub("\n", "</p><p>") .. "</p>";
			DB.deleteChild(vNote, "text");
			DB.setValue(vNote, "text", "formattedtext", sText);
		end
	end
end


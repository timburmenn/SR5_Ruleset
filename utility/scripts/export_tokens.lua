-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onDrop(x, y, draginfo)
	if draginfo.isType("token") then
		local sPrototype = draginfo.getTokenData();
		
		-- Check for module tokens
		if sPrototype and sPrototype:find("@") then
			ChatManager.SystemMessage("Only non-module tokens can be exported.");
			return true;
		end
		
		-- Check for duplicates
		for _,v in ipairs(getWindows()) do
			if v.token.getPrototype() == sPrototype then
				return true;
			end
		end
		
		-- If no duplicates, create new list entry
		local w = createWindow();
		w.token.setPrototype(sPrototype);
		
		return true;
	end
end
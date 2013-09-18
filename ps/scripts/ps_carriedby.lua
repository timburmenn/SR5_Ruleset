-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aAutoFill = {};

function getCompletion(s)
	for _,v in ipairs(aAutoFill) do
		if string.lower(s) == string.lower(string.sub(v, 1, #s)) then
			return string.sub(v, #s + 1);
		end
	end
	return "";
end

function onChar()
	local nCursor = getCursorPosition();
	local sValue = getValue();
	
	if nCursor == #sValue + 1 then
		local sCompletion = getCompletion(sValue);
		if sCompletion ~= "" then
			setValue(sValue .. sCompletion);
			setSelectionPosition(nCursor + #sCompletion);
		end
	end
end

function onGainFocus()
	aAutoFill = {};
	
	for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
		local s = DB.getValue(v, "name", "");
		if s ~= "" then
			table.insert(aAutoFill, s);
		end
	end
end

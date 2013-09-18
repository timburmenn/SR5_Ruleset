-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerMenuItem("Remove Note", "deletepointer", 3);
	registerMenuItem("Confirm Remove", "delete", 3, 3);
end

function onMenuSelection(selection, subselection)
	if selection == 3 and subselection == 3 then
		windowlist.deleteChild(self, true);
	end
end

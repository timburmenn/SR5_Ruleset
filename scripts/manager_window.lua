-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function getReadOnlyState(nodeRecord)
	local bLocked = (DB.getValue(nodeRecord, "locked", 0) ~= 0);
	local bReadOnly = true;
	if nodeRecord.isOwner() and not nodeRecord.isReadOnly() and not bLocked then
		bReadOnly = false;
	end
	
	return bReadOnly;
end

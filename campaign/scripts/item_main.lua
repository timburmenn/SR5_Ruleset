-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	update();
end

function VisDataCleared()
	update();
end

function InvisDataAdded()
	update();
end

function updateControl(sControl, bReadOnly, bID)
	if not self[sControl] then
		return false;
	end
		
	if not bID then
		return self[sControl].update(bReadOnly, true);
	end
	
	return self[sControl].update(bReadOnly);
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID, bOptionID = ItemManager.getIDState(nodeRecord);
	
	local bSection1 = false;
	if bOptionID and User.isHost() then
		if updateControl("nonid_name", bReadOnly, true) then bSection1 = true; end;
	else
		updateControl("nonid_name", bReadOnly, false);
	end
	if bOptionID and (User.isHost() or not bID) then
		if updateControl("nonid_notes", bReadOnly, true) then bSection1 = true; end;
	else
		updateControl("nonid_notes", bReadOnly, false);
	end
	
	local bSection2 = false;
	if updateControl("cost", bReadOnly, bID) then bSection2 = true; end
	if updateControl("weight", bReadOnly, bID) then bSection2 = true; end

	local bSection3 = bID;
	notes.setVisible(bID);
	notes.setReadOnly(bReadOnly);
		
	divider.setVisible(bSection1 and bSection2);
	divider2.setVisible((bSection1 or bSection2) and bSection3);
end

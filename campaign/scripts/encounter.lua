-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local sNode = getDatabaseNode().getNodeName();
	DB.addHandler(sNode .. ".locked", "onUpdate", onLockChanged);
	onLockChanged();
end

function onClose()
	local sNode = getDatabaseNode().getNodeName();
	DB.removeHandler(sNode .. ".locked", "onUpdate", onLockChanged);
end

function onLockChanged()
	if header.subwindow then
		header.subwindow.update();
	end
	
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	
	if bReadOnly then
		npcs_iedit.setValue(0);
	end
	npcs_iedit.setVisible(not bReadOnly);

	npcs.setReadOnly(bReadOnly);
	for _,w in pairs(npcs.getWindows()) do
		w.count.setReadOnly(bReadOnly);
		w.token.setReadOnly(bReadOnly);
		w.name.setReadOnly(bReadOnly);
	end
end

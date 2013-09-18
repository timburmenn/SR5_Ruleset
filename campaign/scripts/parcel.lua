-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	OptionsManager.registerCallback("MIID", StateChanged);

	local sNode = getDatabaseNode().getNodeName();
	DB.addHandler(sNode .. ".locked", "onUpdate", onLockChanged);
	onLockChanged();
end

function onClose()
	OptionsManager.unregisterCallback("MIID", StateChanged);

	local sNode = getDatabaseNode().getNodeName();
	DB.removeHandler(sNode .. ".locked", "onUpdate", onLockChanged);
end

function StateChanged()
	for _,w in ipairs(items.getWindows()) do
		w.onIDChanged();
	end
	items.applySort();
end

function onDrop(x, y, draginfo)
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	if bReadOnly then
		return;
	end
	
	if draginfo.isType("number") then
		local w = coins.addEntry(true);
		if w then
			w.description.setValue(draginfo.getDescription());
			w.amount.setValue(draginfo.getNumberData());
			onLockChanged();
		end
		return true;

	elseif draginfo.isType("shortcut") then
		if ItemManager.handleDrop(items.getDatabaseNode(), draginfo) then
			onLockChanged();
		end
		return true;
	end
end

function onLockChanged()
	if header.subwindow then
		header.subwindow.update();
	end

	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	
	if bReadOnly then
		coins_iedit.setValue(0);
		items_iedit.setValue(0);
	end
	coins_iedit.setVisible(not bReadOnly);
	items_iedit.setVisible(not bReadOnly);

	coins.setReadOnly(bReadOnly);
	for _,w in pairs(coins.getWindows()) do
		w.amount.setReadOnly(bReadOnly);
		w.description.setReadOnly(bReadOnly);
	end

	items.setReadOnly(bReadOnly);
	for _,w in pairs(items.getWindows()) do
		w.count.setReadOnly(bReadOnly);
		w.name.setReadOnly(bReadOnly);
		w.nonid_name.setReadOnly(bReadOnly);
	end
end

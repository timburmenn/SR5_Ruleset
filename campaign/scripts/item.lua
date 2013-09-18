-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	OptionsManager.registerCallback("MIID", StateChanged);

	local sNode = getDatabaseNode().getNodeName();
	DB.addHandler(sNode .. ".locked", "onUpdate", onLockChanged);
	DB.addHandler(sNode .. ".isidentified", "onUpdate", onIDChanged);
	onLockChanged();
end

function onClose()
	OptionsManager.unregisterCallback("MIID", StateChanged);
	
	local sNode = getDatabaseNode().getNodeName();
	DB.removeHandler(sNode .. ".locked", "onUpdate", onLockChanged);
	DB.removeHandler(sNode .. ".isidentified", "onUpdate", onIDChanged);
end

function onLockChanged()
	StateChanged();
end

function onIDChanged()
	StateChanged();
end

function StateChanged()
	if header.subwindow then
		header.subwindow.update();
	end
	if main.subwindow then
		main.subwindow.update();
	end
end

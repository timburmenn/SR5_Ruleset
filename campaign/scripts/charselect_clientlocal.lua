-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	activeidentities = User.getAllActiveIdentities();

	localIdentities = User.getLocalIdentities();
	for _, v in ipairs(localIdentities) do
		local aLabels = {};
		addIdentity(v.id, aLabels, v.databasenode);
	end
end

function addIdentity(id, aLabels, nodeLocal)
	for _, v in ipairs(activeidentities) do
		if v == id then
			return;
		end
	end

	local w = createWindow();
	if w then
		w.setId(id);
		w.setLocalNode(nodeLocal);

		local sName, sDetails = GameSystem.getCharSelectDetailLocal(nodeLocal);
		w.name.setValue(sName);
		w.details.setValue(sDetails);

		if id then
			w.portrait.setIcon("portrait_" .. id .. "_charlist", true);
		end
	end
end

function onListChanged()
	update();
end

function update()
	local bEditMode = (window.button_localedit.getValue() == 1);
	for _,w in pairs(getWindows()) do
		w.idelete.setVisible(bEditMode);
		w.iexport.setVisible(bEditMode);
	end
end

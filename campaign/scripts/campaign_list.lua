-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onListChanged()
	update();
end

function update()
	local bEditMode = (window[getName() .. "_iedit"].getValue() == 1);
	
	for _,w in pairs(getWindows()) do
		if w.getDatabaseNode().isOwner() then
			w.idelete.setVisible(bEditMode);
		else
			w.idelete.setVisible(false);
		end
	end
end


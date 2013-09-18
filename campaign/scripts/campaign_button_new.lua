-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onButtonPress()
	if User.isHost() then
		local node = window.getDatabaseNode().createChild();
		if node then
			local w = Interface.openWindow(class[1], node.getNodeName());
			if w and w.name then
				w.name.setFocus();
			end
		end
	else
		local nodeWin = window.getDatabaseNode();
		if nodeWin then
			Interface.requestNewClientWindow(class[1], nodeWin.getNodeName());
		end
	end
	
	window.list_iedit.setValue(0);
end

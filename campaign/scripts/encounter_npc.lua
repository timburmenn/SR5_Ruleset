-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	synchToCount();
	synchTokenView();
end

function synchToCount()
	if User.isHost() then
		local nodeList = maplinks.getDatabaseNode();
		local nFieldCount = count.getValue();
		local nListCount = nodeList.getChildCount();
		
		if nListCount < nFieldCount then
			local i;
			for i = nListCount + 1, nFieldCount do
				nodeList.createChild();
			end
			synchTokenView();

		elseif nListCount > nFieldCount then
			local i = 1;
			for k, v in pairs(maplinks.getWindows()) do
				if i > nFieldCount then
					local nodeWin = v.getDatabaseNode();
					v.close();
					nodeWin.delete();
				end
				i = i + 1;
			end
		end
	end
end

function synchTokenView()
	local sToken = token.getPrototype();
	if sToken == "" or not User.isHost() then
		maplinks.setVisible(false);
		maplinks_label.setVisible(false);
	else
		maplinks.setVisible(true);
		maplinks_label.setVisible(true);
	end

	for _, v in pairs(maplinks.getWindows()) do
		v.token.setPrototype(sToken);
	end
end

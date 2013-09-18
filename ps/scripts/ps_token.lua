-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

local scaleWidget = nil;

function onDragStart(button, x, y, draginfo)
	if not User.isHost() then
		return false;
	end
end

function onDrop(x, y, draginfo)
	if draginfo.isType("token") then
		local prototype, dropref = draginfo.getTokenData();
		setPrototype(prototype);
		replace(dropref);
		return true;
	end
end

function onDragEnd(draginfo)
	local prototype, dropref = draginfo.getTokenData();
	if dropref then
		replace(dropref);
	end
	return true;
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	-- Left click to toggle activation outline for linked token
	if button == 1 then
		if User.isHost() then
			window.link.activate();
		end
	
	-- Middle click to reset linked token scale
	else
		local tokeninstance = CombatManager.getTokenFromCT(window.getDatabaseNode());
		if tokeninstance then
			tokeninstance.setScale(1.0);
		end
	end

	return true;
end

function onWheel(notches)
	TokenManager.onWheelCT(window.getDatabaseNode(), notches);
	return true;
end

function onScaleChanged()
	local scale = window.tokenscale.getValue();
	
	if scale == 1 then
		if scaleWidget then
			scaleWidget.setVisible(false);
		end
	else
		if not scaleWidget then		
			scaleWidget = addTextWidget("sheetlabel", "0");
			scaleWidget.setFrame("tempmodmini", 4, 1, 6, 3);
			scaleWidget.setPosition("topright", -2, 2);
		end
		scaleWidget.setVisible(true);
		scaleWidget.setText(string.format("%.1f", scale));
	end
end

function replace(newTokenInstance)
	local nodePS = window.getDatabaseNode();
	
	local oldTokenInstance = CombatManager.getTokenFromCT(nodePS);
	if oldTokenInstance and oldTokenInstance ~= newTokenInstance then
		if not newTokenInstance then
			local nodeContainerOld = oldTokenInstance.getContainerNode();
			if nodeContainerOld then
				local x,y = oldTokenInstance.getPosition();
				newTokenInstance = Token.addToken(nodeContainerOld.getNodeName(), getPrototype(), x, y);
			end
		end
		oldTokenInstance.delete();
	end

	PartyManager.linkToken(window.getDatabaseNode(), newTokenInstance);
end

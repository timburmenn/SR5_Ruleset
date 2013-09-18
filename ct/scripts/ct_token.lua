-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local scaleWidget = nil;

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
		local tokeninstance = CombatManager.getTokenFromCT(window.getDatabaseNode());
		if tokeninstance then
			tokeninstance.setActive(not tokeninstance.isActive());
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

function onDoubleClick(x, y)
	CombatManager.openMap(window.getDatabaseNode());
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
			scaleWidget = addTextWidget("sheetlabelmini", "0");
			scaleWidget.setFrame("tempmodmini", 4, 1, 6, 3);
			scaleWidget.setPosition("topright", -2, 2);
		end
		scaleWidget.setVisible(true);
		scaleWidget.setText(string.format("%.1f", scale));
	end
end

function replace(newTokenInstance)
	local oldTokenInstance = CombatManager.getTokenFromCT(window.getDatabaseNode());
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

	TokenManager.linkToken(window.getDatabaseNode(), newTokenInstance);
	TokenManager.updateVisibility(window.getDatabaseNode());
end

function deleteReference()
	local tokeninstance = CombatManager.getTokenFromCT(window.getDatabaseNode());
	if tokeninstance then
		tokeninstance.delete();
	end
end


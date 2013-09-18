-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sIdentity = nil;

function setActiveState(sUserState)
	if sUserState == "idle" then
		statewidget.setBitmap("charlist_idling");
	elseif sUserState == "typing" then
		statewidget.setBitmap("charlist_typing");
	elseif sUserState == "afk" then
		statewidget.setBitmap("charlist_afk");
	else
		statewidget.setBitmap();
	end
end

function setCurrent(nCurrentState, sUserState)
	if nCurrentState then
		namewidget.setFont("mini_name_selected");
		setActiveState(sUserState);
	else
		namewidget.setFont("mini_name");
		setActiveState("active");
	end
end

function setName(sName)
	if sName ~= "" then
		namewidget.setText(sName);
	else
		namewidget.setText("- Unnamed -");
	end
end

function updateColor()
	colorwidget.setColor(User.getIdentityColor(sIdentity));
	colorwidget.setVisible(true);
end

function createWidgets(name)
	sIdentity = name;

	portraitwidget = addBitmapWidget("portrait_" .. name .. "_charlist");

	namewidget = addTextWidget("mini_name", "- Unnamed -");
	namewidget.setPosition("center", 0, 36);
	namewidget.setFrame("mini_name", 5, 2, 5, 2);
	namewidget.setMaxWidth(70);
	
	statewidget = addBitmapWidget();
	statewidget.setPosition("center", -23, -23);
	
	colorwidget = addBitmapWidget("charlist_pointer");
	colorwidget.setPosition("center", 36, 16);
	colorwidget.setVisible(false);

	resetMenuItems();
	if User.isHost() then
		registerMenuItem("Ring Bell", "bell", 5);
		registerMenuItem("Kick", "kick", 3);
		registerMenuItem("Kick Confirm", "kickconfirm", 3, 5);
	elseif User.isOwnedIdentity(name) then
		registerMenuItem("Toggle AFK", "hand", 3);
		registerMenuItem("Release", "erase", 5);
	end
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if User.isHost() then
		bringCharacterToTop();
	else
		if User.isOwnedIdentity(sIdentity) then
			setCurrentIdentity(sIdentity);

			local aOwned = User.getOwnedIdentities();
			if #aOwned == 1 then
				bringCharacterToTop();
			end
		end
	end
	return true;
end

function onDoubleClick(x, y)
	if User.isHost() or User.isOwnedIdentity(sIdentity) then
		bringCharacterToTop();
	end
	return true;
end

function onDragStart(button, x, y, draginfo)
	if User.isHost() or User.isOwnedIdentity(sIdentity) then
		draginfo.setType("shortcut");
		draginfo.setIcon("portrait_" .. sIdentity .. "_charlist");
		draginfo.setTokenData("portrait_" .. sIdentity .. "_token");
		draginfo.setShortcutData("charsheet", "charsheet." .. sIdentity);

		local base = draginfo.createBaseData();
		base.setType("token");
		base.setTokenData("portrait_" .. sIdentity .. "_token");
	
		return true;
	end
end

function onDrop(x, y, draginfo)
	local sDragType = draginfo.getType();
	
	if User.isHost() then
		if CombatManager.onDrop("pc", "charsheet." .. sIdentity, draginfo) then
			return true;
		end
		
		-- Default number drop behavior
		if sDragType == "number" then
			local msg = {};
			msg.text = draginfo.getDescription() .. " [to " .. User.getIdentityLabel(sIdentity) .."]";
			msg.font = "systemfont";
			msg.icon = "portrait_" .. sIdentity .. "_targetportrait";
			msg.dice = {};
			msg.diemodifier = draginfo.getNumberData();
			msg.secret = false;
			
			Comm.deliverChatMessage(msg);
			return true;
		end

		-- Shortcut: party item transfer to character (if relevant) or share record to single client
		if sDragType == "shortcut" then
			local sClass, sRecord = draginfo.getShortcutData();
			local nodeSource = draginfo.getDatabaseNode();
			if sClass == "item" and StringManager.contains({"partysheet", "charsheet"}, ItemManager.getItemSourceType(nodeSource)) then
				ItemManager.notifyTransfer("charsheet." .. sIdentity .. ".inventorylist", sClass, sRecord);
			else
				local w = Interface.openWindow(sClass, sRecord);
				if w then
					w.share(User.getIdentityOwner(sIdentity));
				end
			end
		
			return true;
		end
	else
		if sDragType == "shortcut" then
			local sClass, sRecord = draginfo.getShortcutData();
			local nodeSource = draginfo.getDatabaseNode();
			if sClass == "item" and StringManager.contains({"partysheet", "charsheet"}, ItemManager.getItemSourceType(nodeSource)) then
				ItemManager.notifyTransfer("charsheet." .. sIdentity .. ".inventorylist", sClass, sRecord);
			end
		end
	end

	-- String: send as whisper
	if draginfo.isType("string") then
		ChatManager.processWhisperHelper(User.getIdentityLabel(sIdentity), draginfo.getStringData());
		return true;
	end
	
	-- Portrait: set as portrait for identity
	if User.isHost() or User.isOwnedIdentity(sIdentity) then
		if draginfo.isType("portraitselection") then
			User.setPortrait(sIdentity, draginfo.getStringData());
			return true;
		end
	end
end

function onMenuSelection(selection, subselection)
	if User.isHost() then
		if selection == 5 then
			User.ringBell(User.getIdentityOwner(sIdentity));
		elseif selection == 3 and subselection == 5 then
			User.kick(User.getIdentityOwner(sIdentity));
		end
	elseif User.isOwnedIdentity(sIdentity) then
		if selection == 3 then
			window.toggleAFK();
		elseif selection == 5 then
			User.releaseIdentity(sIdentity);

			local aOwned = User.getOwnedIdentities();
			for _,v in pairs(aOwned) do
				if v ~= sIdentity then
					setCurrentIdentity(v);
					break;
				end
			end
		end
	end
end

function setCurrentIdentity(sCurrentIdentity)
	User.setCurrentIdentity(sCurrentIdentity);

	if CampaignRegistry and CampaignRegistry.colortables and CampaignRegistry.colortables[sCurrentIdentity] then
		local colortable = CampaignRegistry.colortables[sCurrentIdentity];
		User.setCurrentIdentityColors(colortable.color or "000000", colortable.blacktext or false);
	end
end

function bringCharacterToTop()
	local wndMain = Interface.findWindow("charsheet", "charsheet." .. sIdentity);
	local wndMini = Interface.findWindow("charsheetmini", "charsheet." .. sIdentity);
	if wndMain then
		wndMain.bringToFront();
	elseif wndMini then
		wndMini.bringToFront();
	else
		Interface.openWindow("charsheet", "charsheet." .. sIdentity);
	end
end

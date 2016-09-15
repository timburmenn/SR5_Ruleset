-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onFactionChanged();
end

function updateDisplay()
	if active.getValue() == 1 then
		name.setFont("sheetlabel");

		active_spacer_top.setVisible(true);
		active_spacer_bottom.setVisible(true);
		
		local sFaction = friendfoe.getStringValue();
		if sFaction == "friend" then
			setFrame("ctentrybox_friend_active");
		elseif sFaction == "neutral" then
			setFrame("ctentrybox_neutral_active");
		elseif sFaction == "foe" then
			setFrame("ctentrybox_foe_active");
		else
			setFrame("ctentrybox_active");
		end
		
		windowlist.scrollToWindow(self);
	else
		name.setFont("sheettext");

		active_spacer_top.setVisible(false);
		active_spacer_bottom.setVisible(false);
		
		local sFaction = friendfoe.getStringValue();
		if sFaction == "friend" then
			setFrame("ctentrybox_friend");
		elseif sFaction == "neutral" then
			setFrame("ctentrybox_neutral");
		elseif sFaction == "foe" then
			setFrame("ctentrybox_foe");
		else
			setFrame("ctentrybox");
		end
	end
end

function onActiveChanged()
	updateDisplay();
end

function onFactionChanged()
	updateDisplay();
end

function onLinkChanged()
end

-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onFactionChanged();
	
	DB.addHandler(getDatabaseNode().getNodeName() .. ".effects", "onChildUpdate", onEffectsChanged);
	onEffectsChanged();
end

function onClose()
	DB.removeHandler(getDatabaseNode().getNodeName() .. ".effects", "onChildUpdate", onEffectsChanged);
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

function onEffectsChanged()
	local affectedby = EffectManager.getEffectsString(getDatabaseNode());
	if affectedby == "" then
		effects_label.setVisible(false);
		effects_str.setVisible(false);
	else
		effects_label.setVisible(true);
		effects_str.setVisible(true);
	end
	effects_str.setValue(affectedby);
end

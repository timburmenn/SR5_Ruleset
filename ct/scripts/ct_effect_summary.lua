-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onEffectsChanged();
	DB.addHandler(DB.getPath(window.getDatabaseNode(), "effects"), "onChildUpdate", onEffectsChanged);
end

function onClose()
	DB.removeHandler(DB.getPath(window.getDatabaseNode(), "effects"), "onChildUpdate", onEffectsChanged);
end

function onEffectsChanged()
	-- Set the effect summary string
	local sEffects = EffectManager.getEffectsString(window.getDatabaseNode());
	if sEffects ~= "" then
		setValue(Interface.getString("ct_label_effects") .. " " .. sEffects);
	else
		setValue(nil);
	end
	
	-- Update visibility
	if sEffects == "" or (window.effecticon and window.effecticon.isVisible()) then
		setVisible(false);
	else
		setVisible(true);
	end
end


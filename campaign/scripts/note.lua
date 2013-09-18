-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bUpdating = false;

function onInit()
	getDatabaseNode().onObserverUpdate = onObserverUpdated;
	onObserverUpdated();
	
	onLockChanged();
end

function onObserverUpdated()
	local node = getDatabaseNode();
	
	local sOwner = node.getOwner();
	if sOwner then
		owner.setValue(sOwner);
	else
		owner.setValue("");
	end
	
	if not bUpdating then
		bUpdating = true;

		if node.isPublic() then
			ispublic.setValue(1);
		else
			ispublic.setValue(0);
		end
		
		bUpdating = false;
	end
end

function onPublicChanged()
	if not bUpdating then
		bUpdating = true;
		
		if ispublic.getValue() == 1 then
			getDatabaseNode().setPublic(true);
		else
			getDatabaseNode().setPublic(false);
		end
		
		bUpdating = false;
	end
end

function onLockChanged()
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	
	name.setReadOnly(bReadOnly);
	ispublic.setReadOnly(bReadOnly);
	text.setReadOnly(bReadOnly);
end

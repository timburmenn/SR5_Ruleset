-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Active identities are stored in the list as keys, the value indicating 
-- whether they are NPCs (false) or the GM identity (true)
identities = {};

-- The currently active identity, key into the list table
currentidentity = nil;

function onInit()
	Comm.registerSlashHandler("identity", slashCommandHandlerId);
	Comm.registerSlashHandler("gmid", slashCommandHandlerGmId);
end

function slashCommandHandlerId(sCommand, sParams)
	if not User.isHost() then
		return;
	end
	
	addIdentity(sParams, false);
end

function slashCommandHandlerGmId(sCommand, sParams)
	if not User.isHost() then
		return;
	end
	
	for k,v in pairs(identities) do
		if v then
			identities[k] = nil;
		end
	end

	identities[sParams] = true;
	if identitylist then
		identitylist.renameGmIdentity(sParams);
	end
	
	setCurrent(sParams);

	CampaignRegistry.gmidentity = sParams;
end

function registerIdentityList(list)
	-- Store a reference to the list window
	identitylist = list;
	
	activateGMIdentity();
end

function setCurrent(name)
	if identitylist then
		identitylist.setCurrent(name);
	end
	
	currentidentity = name;
end

function getCurrent()
	if currentidentity then
		return currentidentity, identities[currentidentity];
	end

	return nil, nil;
end

function activateGMIdentity()
	local gmidname = CampaignRegistry.gmidentity or "GM";
	
	addIdentity(gmidname, true);
end

function existsIdentity(name)
	if identities[name] then
		return true;
	end
	
	return false;
end

function addIdentity(name, isgm)
	if not identities[name] and identitylist then
		identitylist.addIdentity(name, isgm);
	end
	
	identities[name] = isgm;

	setCurrent(name);
end

function removeIdentity(name)
	-- Preserve the first entry
	if identities[name] then
		return;
	end

	-- In case the identity being deleted is active, activate the root identity
	if currentidentity == name then
		setCurrent(next(identities));
	end

	-- Remove from list	
	if identitylist then
		identitylist.removeIdentity(name);
	end

	-- Remove from table
	identities[name] = nil;
end

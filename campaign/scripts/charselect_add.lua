-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function requestResponse(result, identity)
	if result and identity then
		--window.close();
	end
end

function openCharacter()
	if User.isLocal() then
		Interface.openWindow("charsheet", User.createLocalIdentity());
	else
		if not bRequested then
			User.requestIdentity(nil, "charsheet", "name", nil, requestResponse);
			bRequested = true;
		end
	end
	window.close();
end

function onButtonPress()
	openCharacter();
end

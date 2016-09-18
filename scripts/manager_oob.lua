-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	Comm.onReceiveOOBMessage = processOOBMessage;
end

--
--
-- FRAMEWORK
--
--

aOOBMsgHandlers = {};

function registerOOBMsgHandler(sMessageType, fCallback)
	aOOBMsgHandlers[sMessageType] = fCallback;
end

function processOOBMessage(msg)
	if not msg.type then
		return;
	end
	
	-- Handle the special message
	for kHandlerType, fHandler in pairs(aOOBMsgHandlers) do
		if msg.type == kHandlerType then
			fHandler(msg);
			return true;
		end
	end
	
	ChatManager.SystemMessage(Interface.getString("error_oobunknown") .. " (" .. msg.type .. ")");
	return true;
end

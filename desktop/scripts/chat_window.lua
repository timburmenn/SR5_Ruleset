-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	deliverLaunchMessage()
end

function deliverLaunchMessage()
    local launchmsg = ChatManager.retrieveLaunchMessages();
    for keyMessage, rMessage in ipairs(launchmsg) do
    	Comm.addChatMessage(rMessage);
    end
end

function onDiceLanded(draginfo)
 	return ActionsManager.onDiceLanded(draginfo);
end

function onDrop(x, y, draginfo)
	ActionsManager.actionDrop(draginfo, nil, false);
end

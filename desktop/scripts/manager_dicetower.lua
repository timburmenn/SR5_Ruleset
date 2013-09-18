-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local control = nil;
OOB_MSGTYPE_DICETOWER = "dicetower";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_DICETOWER, handleDiceTower);
end

function registerControl(ctrl)
	control = ctrl;
	activate();
end

function activate()
	OptionsManager.registerCallback("TBOX", update);
	OptionsManager.registerCallback("REVL", update);

	update();
end

function update()
	if control then
		if OptionsManager.isOption("TBOX", "on") then
			if User.isHost() and OptionsManager.isOption("REVL", "off") then
				control.setVisible(false);
			else
				control.setVisible(true);
			end
		else
			control.setVisible(false);
		end
	end
end

function encodeOOBFromDrag(draginfo, i, rSource)
	local msgOOB = ActionsManager.decodeRollFromDrag(draginfo, i);
	
	msgOOB.type = OOB_MSGTYPE_DICETOWER;
	if rSource then
		msgOOB.sender = rSource.sCreatureNode;
	end

	msgOOB.sDice = StringManager.convertDiceToString(msgOOB.aDice, msgOOB.nMod);
	msgOOB.aDice = nil;
	msgOOB.nMod = nil;
	
	return msgOOB;
end

function decodeRollFromOOB(msgOOB)
	msgOOB.aDice, msgOOB.nMod = StringManager.convertStringToDice(msgOOB.sDice);
	msgOOB.sDice = nil;
	
	msgOOB.type = nil;
	msgOOB.sender = nil;
	
	msgOOB.bSecret = true;
	
	return msgOOB;
end

function onDrop(draginfo)
	if control then
		if OptionsManager.isOption("TBOX", "on") then
			if GameSystem.actions[draginfo.getType()] then
				local rSource = ActionsManager.actionDropHelper(draginfo, false);
				
				for i = 1, draginfo.getSlotCount() do
					local msgOOB = encodeOOBFromDrag(draginfo, i, rSource);
					Comm.deliverOOBMessage(msgOOB, "");

					if not User.isHost() then
						local msg = {font = "chatfont", icon = "dicetower_icon", text = ""};
						if rSource then
							msg.sender = rSource.sName;
						end
						if msgOOB.sDesc ~= "" then
							msg.text = msgOOB.sDesc .. " ";
						end
						msg.text = msg.text .. "[" .. msgOOB.sDice .. "]";
						
						Comm.addChatMessage(msg);
					end
				end
			end
		end
	end

	return true;
end

function handleDiceTower(msgOOB)
	local sRoll = "[TOWER] ";

	msgOOB.type = nil;
	
	local rActor = nil;
	if msgOOB.sender then
		rActor = ActorManager.getActor(nil, msgOOB.sender);
	end
	msgOOB.sender = nil;

	if msgOOB.sDesc then
		sRoll = sRoll .. msgOOB.sDesc;
	end
	
	msgOOB.aDice, msgOOB.nMod = StringManager.convertStringToDice(msgOOB.sDice);
	msgOOB.sDice = nil;
	
	msgOOB.bSecret = true;

	ActionsManager.roll(rActor, nil, msgOOB);
end

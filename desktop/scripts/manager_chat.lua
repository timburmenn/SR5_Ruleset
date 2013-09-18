-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_WHISPER = "whisper";

-- Initialization
function onInit()
	if User.isHost() then
		Module.onActivationRequested = moduleActivationRequested;
	end
	Module.onUnloadedReference = moduleUnloadedReference;

	Comm.registerSlashHandler("whisper", processWhisper);
	Comm.registerSlashHandler("w", processWhisper);
	Comm.registerSlashHandler("reply", processReply);
	Comm.registerSlashHandler("r", processReply);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_WHISPER, handleWhisper);
	
	Comm.registerSlashHandler("die", processDie);
	Comm.registerSlashHandler("mod", processMod);

	if User.isHost() then
		Comm.registerSlashHandler("importchar", processImport);
		Comm.registerSlashHandler("exportchar", processExport);
	end
end

--
-- MODULE NOTIFICATIONS
--

function moduleActivationRequested(sModule)
	local msg = {};
	msg.text = "Players have requested permission to load '" .. sModule .. "'";
	msg.font = "systemfont";
	msg.icon = "module_loaded";
	Comm.addChatMessage(msg);
end

function moduleUnloadedReference(sModule)
	local msg = {};
	msg.text = "Could not open sheet with data from unloaded module '" .. sModule .. "'";
	msg.font = "systemfont";
	Comm.addChatMessage(msg);
end

--
-- LAUNCH MESSAGES
--

launchmsg = {};

function registerLaunchMessage(msg)
	table.insert(launchmsg, msg);
end

function retrieveLaunchMessages()
	return launchmsg;
end

--
-- SLASH COMMAND HANDLER
--

function onSlashCommand(command, parameters)
	SystemMessage("SLASH COMMANDS [required] <optional>");
	SystemMessage("----------------");
	if User.isHost() then
		SystemMessage("/clear");
		SystemMessage("/console");
		SystemMessage("/day");
		SystemMessage("/die [NdN+N] <message>");
		SystemMessage("/emote [message]");
		SystemMessage("/export");
		SystemMessage("/exportchar");
		SystemMessage("/exportchar [name]");
		SystemMessage("/flushdb");
		SystemMessage("/gmid [name]");
		SystemMessage("/identity [name]");
		SystemMessage("/importchar");
		SystemMessage("/lighting [RGB hex value]");
		SystemMessage("/mod [N] <message>");
		SystemMessage("/mood [mood] <message>");
		SystemMessage("/mood ([multiword mood]) <message>");
		SystemMessage("/ooc [message]");
		SystemMessage("/night");
		SystemMessage("/reload");
		SystemMessage("/reply [message]");
		SystemMessage("/save");
		SystemMessage("/scaleui [50-200]");
		SystemMessage("/story [message]");
		SystemMessage("/vote <message>");
		SystemMessage("/whisper [character] [message]");
	else
		SystemMessage("/action [message]");
		SystemMessage("/console");
		SystemMessage("/die [NdN+N] <message>");
		SystemMessage("/emote [message]");
		SystemMessage("/mod [N] <message>");
		SystemMessage("/mood [mood] <message>");
		SystemMessage("/mood ([multiword mood]) <message>");
		SystemMessage("/ooc [message]");
		SystemMessage("/reply [message]");
		SystemMessage("/save");
		SystemMessage("/scaleui [50-200]");
		SystemMessage("/vote <message>");
		SystemMessage("/whisper GM [message]");
		SystemMessage("/whisper [character] [message]");
	end
end

--
-- AUTO-COMPLETE
--

function searchForIdentity(sSearch)
	for _,sIdentity in ipairs(User.getAllActiveIdentities()) do
		local sLabel = User.getIdentityLabel(sIdentity);
		if string.find(string.lower(sLabel), string.lower(sSearch), 1, true) == 1 then
			if User.getIdentityOwner(sIdentity) then
				return sIdentity;
			end
		end
	end

	return nil;
end

function doUserAutoComplete(ctrl)
	local buffer = ctrl.getValue();
	if buffer == "" then 
		return ;
	end

	-- Parse the string, adding one chunk at a time, looking for the maximum possible match
	local sReplacement = nil;
	local nStart = 2;
	while not sReplacement do
		local nSpace = string.find(string.reverse(buffer), " ", nStart, true);

		if nSpace then
			local sSearch = string.sub(buffer, #buffer - nSpace + 2);

			if not string.match(sSearch, "^%s$") then
				local sIdentity = searchForIdentity(sSearch);
				if sIdentity then
					local sRemainder = string.sub(buffer, 1, #buffer - nSpace + 1);
					sReplacement = sRemainder .. User.getIdentityLabel(sIdentity) .. " ";
					break;
				end
			end
		else
			local sIdentity = searchForIdentity(buffer);
			if sIdentity then
				sReplacement = User.getIdentityLabel(sIdentity) .. " ";
				break;
			end
			
			return;
		end

		nStart = nSpace + 1;
	end

	if sReplacement then
		ctrl.setValue(sReplacement);
		ctrl.setCursorPosition(#sReplacement + 1);
		ctrl.setSelectionPosition(#sReplacement + 1);
	end
end

--
-- DICE AND MOD SLASH HANDLERS
--

function processDie(sCommand, sParams)
	if User.isHost() then
		if sParams == "reveal" then
			OptionsManager.setOption("REVL", "on");
			SystemMessage("Revealing all die rolls");
			return;
		end
		if sParams == "hide" then
			OptionsManager.setOption("REVL", "off");
			SystemMessage("Hiding all die rolls");
			return;
		end
	end

	local sDice, sDesc = string.match(sParams, "%s*(%S+)%s*(.*)");
	
	if not StringManager.isDiceString(sDice) then
		SystemMessage("Usage: /die [dice] [description]");
		return;
	end
	
	local aDice, nMod = StringManager.convertStringToDice(sDice);
	
	local rRoll = { sType = "dice", sDesc = sDesc, aDice = aDice, nMod = nMod };
	ActionsManager.actionDirect(nil, "dice", { rRoll });
end

function processMod(sCommand, sParams)
	local sMod, sDesc = string.match(sParams, "%s*(%S+)%s*(.*)");
	
	local nMod = tonumber(sMod);
	if not nMod then
		SystemMessage("Usage: /mod [number] [description]");
		return;
	end
	
	ModifierStack.addSlot(sDesc, nMod);
end

function processImport(sCommand, sParams)
	UtilityManager.importChar();
end

function processExport(sCommand, sParams)
	local nodeChar = nil;
	
	local sFind = StringManager.trim(sParams);
	if string.len(sFind) > 0 then
		for _,vChar in pairs(DB.getChildren("charsheet")) do
			local sChar = DB.getValue(vChar, "name", "");
			if string.len(sChar) > 0 then
				if string.lower(sFind) == string.lower(string.sub(sChar, 1, string.len(sFind))) then
					nodeChar = vChar;
					break;
				end
			end
		end
		if not nodeChar then
			SystemMessage("Unable to find character requested for export. (" .. sParams .. ")");
			return;
		end
	end
	
	UtilityManager.exportChar(nodeChar);
end

--
--
-- MESSAGES
--
--

function createBaseMessage(rSource)
	-- Set up the basic message components
	local msg = {font = "systemfont", text = "", secret = false};

	local bShowUser = true;
	
	-- Use portrait chat?
	if OptionsManager.isOption("PCHT", "on") then
		if User.isHost() then
			msg.icon = "portrait_gm_token";
		else
			if rSource and rSource.sType == "pc" and rSource.nodeCreature then
				msg.icon = "portrait_" .. rSource.nodeCreature.getName() .. "_chat";
			else
				local sIdentity = User.getCurrentIdentity();
				if sIdentity then
					msg.icon = "portrait_" .. User.getCurrentIdentity() .. "_chat";
				end
			end
		end
		bShowUser = false;
	end

	-- If actor specified, then use the specified actor
	if rSource then
		msg.sender = rSource.sName;
		bShowUser = false;
		
	-- If actor not specified, user is host, and alternate ID specified, use that instead
	elseif User.isHost() then
		local gmid, isgm = GmIdentityManager.getCurrent();
		if not isgm then
			msg.sender = gmid;
			bShowUser = false;
		end
	end
	
	-- If portrait and/or actor name not used, then use active identity.
	if bShowUser then
		if User.isHost() then
			msg.sender = GmIdentityManager.getCurrent();
		else
			msg.sender = User.getIdentityLabel();
		end
	end
	
	-- RESULTS
	return msg;
end

-- Message: prints a message in the Chatwindow
function Message(msgtxt, broadcast, rActor)
	local msg = createBaseMessage(rActor);
	msg.text = msg.text .. msgtxt;

	if broadcast then
		Comm.deliverChatMessage(msg);
	else
		msg.secret = true;
		Comm.addChatMessage(msg);
	end
end

-- SystemMessage: prints a message in the Chatwindow
function SystemMessage(msgtxt)
	local msg = {font = "systemfont"};
	msg.text = msgtxt;
	Comm.addChatMessage(msg);
end

-----------------------
-- WHISPERS
-----------------------

function processWhisper(sCommand, sParams)
	-- Find the target user for the whisper
	local sLowerParams = string.lower(sParams);
	local sGMIdentity = "gm ";

	local sRecipient = nil;
	if string.sub(sLowerParams, 1, string.len(sGMIdentity)) == sGMIdentity then
		sRecipient = "GM";
	else
		for _,vID in ipairs(User.getAllActiveIdentities()) do
			local sIdentity = User.getIdentityLabel(vID);

			local sIdentityMatch = string.lower(sIdentity) .. " ";
			if string.sub(sLowerParams, 1, string.len(sIdentityMatch)) == sIdentityMatch then
				if sRecipient then
					if #sRecipient < #sIdentity then
						sRecipient = sIdentity;
					end
				else
					sRecipient = sIdentity;
				end
			end
		end
	end
	
	local sMessage;
	if sRecipient then
		sMessage = string.sub(sParams, #sRecipient + 2)
	else
		sMessage = sParams;
	end
	
	processWhisperHelper(sRecipient, sMessage);
end

sLastWhisperer = nil;

function processReply(sCommand, sParams)
	if not sLastWhisperer then
		ChatManager.SystemMessage("Reply target not available.");
		return;
	end
	processWhisperHelper(sLastWhisperer, sParams);
end

function processWhisperHelper(sRecipient, sMessage)
	-- Make sure we have a valid identity and valid user owning the identity
	local sUser = nil;
	local sRecipientID = nil;
	if sRecipient then
		if sRecipient == "GM" then
			sRecipientID = "";
			sUser = "";
		else
			for _,vID in ipairs(User.getAllActiveIdentities()) do
				local sIdentity = User.getIdentityLabel(vID);
				if sIdentity == sRecipient then
					sRecipientID = vID;
					sUser = User.getIdentityOwner(vID);
				end
			end
		end
	end
	if not sRecipientID or not sUser then
		ChatManager.SystemMessage("Whisper recipient not found \rUsage: /w GM [message]\rUsage: /w [recipient] [message]");
		return;
	end
	
	-- Check for empty message
	if sMessage == "" then
		ChatManager.SystemMessage("No whisper message found \rUsage: /w GM [message]\rUsage /w [recipient] [message]");
		return;
	end
	
	-- Make sure we have a user identity
	local sSender;
	if User.isHost() then
		sSender = "";
	else
		sSender = User.getCurrentIdentity();
		if not sSender then
			ChatManager.SystemMessage("Please select an identity before whispering.");
			return;
		end
	end
	
	-- Send the whisper
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_WHISPER;
	msgOOB.sender = sSender;
	msgOOB.receiver = sRecipientID;
	msgOOB.text = sMessage;

	if User.isHost() then
		Comm.deliverOOBMessage(msgOOB, { sUser, "" });
	else
		Comm.deliverOOBMessage(msgOOB);
	end
	
	-- Show what the user whispered
	local msg = { font = "whisperfont", sender="[w]" };
	if OptionsManager.isOption("PCHT", "on") then
		if User.isHost() then
			msg.icon = "portrait_gm_token";
		else
			msg.icon = "portrait_" .. msgOOB.sender .. "_chat";
		end
	else
		if #(User.getOwnedIdentities()) > 1 then
			msg.sender = "[w] " .. User.getIdentityLabel(sSender);
		end
	end
	
	msg.sender = msg.sender .. " -> " .. sRecipient;
	msg.text = sMessage;
	
	Comm.addChatMessage(msg);
end

function handleWhisper(msgOOB)
	-- Validate
	if not msgOOB.sender or not msgOOB.receiver or not msgOOB.text then
		return;
	end

	-- Check to see if GM has asked to see whispers
	if User.isHost() then
		if msgOOB.sender == "" then
			return;
		end
		if msgOOB.receiver ~= "" and OptionsManager.isOption("SHPW", "off") then
			return;
		end
		
	-- Ignore messages not targeted to this user
	else
		if msgOOB.receiver == "" then
			return;
		end
		if not User.isOwnedIdentity(msgOOB.receiver) then
			return;
		end
	end
	
	-- Get the send and receiver labels
	local sSender, sReceiver;
	if msgOOB.sender == "" then
		sSender = "GM";
	else
		sSender = User.getIdentityLabel(msgOOB.sender) or "<unknown>";
	end
	if msgOOB.receiver == "" then
		sReceiver = "GM";
	else
		sReceiver = User.getIdentityLabel(msgOOB.receiver) or "<unknown>";
	end
	
	-- Remember last whisperer
	sLastWhisperer = sSender;
	
	-- Build the message to display
	local msg = { font = "whisperfont", text = "", sender="[w]" };
	if OptionsManager.isOption("PCHT", "on") then
		if msgOOB.sender == "" then
			msg.icon = "portrait_gm_token";
		else
			msg.icon = "portrait_" .. msgOOB.sender .. "_chat";
		end
	else
		msg.sender = "[w] " .. sSender;
	end
	if User.isHost() then
		if msgOOB.receiver ~= "" then
			msg.sender = msg.sender .. " -> " .. sReceiver;
		end
	else
		if #(User.getOwnedIdentities()) > 1 then
			msg.sender = msg.sender .. " -> " .. sReceiver;
		end
	end
	msg.text = msg.text .. msgOOB.text;
	
	-- Show whisper message
	Comm.addChatMessage(msg);
end

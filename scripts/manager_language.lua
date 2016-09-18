--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

OOB_MSGTYPE_LANGCHAT = "languagechat"

CAMPAIGN_LANGUAGE_LIST = "languages"
CAMPAIGN_LANGUAGE_LIST_NAME = "name"
CAMPAIGN_LANGUAGE_FONT_NAME = "font"

CHAR_LANGUAGE_LIST = "languagelist"
CHAR_LANGUAGE_LIST_NAME = "name"

local aCampaignLang = {};
local aCampaignLangLower = {};

local sActiveIdentity = ""
local bCampaignHandlers = false
local bNewCampaign = false

aLanguageSpeaksAll = {}
aLanguagesUnderstandsAll = {}
aLanguagesTongues = {}

function onInit()
	aLanguageSpeaksAll[Interface.getString("lang_val_speaksall"):lower()] = true
	aLanguagesUnderstandsAll[Interface.getString("lang_val_understandsall"):lower()] = true
	aLanguagesUnderstandsAll[Interface.getString("lang_val_comprehendlanguages"):lower()] = true
	aLanguagesTongues[Interface.getString("lang_val_polyglot"):lower()] = true
	aLanguagesTongues[Interface.getString("lang_val_tongues"):lower()] = true

	if User.isHost() then
		if not DB.findNode("languages") then
			bNewCampaign = true
		end
		DB.createNode("languages").setPublic(true);

		Interface.onDesktopInit = onDesktopInit
		OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_LANGCHAT, handleLangChat)
	else
		User.onIdentityActivation = onIdentityActivation
		User.onIdentityStateChange = onIdentityStateChange
	end
end

function onDesktopInit()
	if GameSystem.languages then
		if bNewCampaign then
			-- If new campaign, set up language records
			for kLang,vLang in pairs(GameSystem.languages) do
				local nodeLang = DB.createChild("languages")
				DB.setValue(nodeLang, "name", "string", kLang)
				DB.setValue(nodeLang, "font", "string", vLang)
			end
		else
			-- If existing campaign and records partially set up (from beta), then fill in record with font data
			for kLang,vLang in pairs(GameSystem.languages) do
				for _,vNode in pairs(DB.getChildren("languages")) do
					if DB.getValue(vNode, "name", "") == kLang then
						if not DB.getChild(vNode, "font") then
							DB.setValue(vNode, "font", "string", vLang);
						end
					end
				end
			end
		end
	end
	
	addCampaignLanguageHandlers()
end

function addCampaignLanguageHandlers()
	bCampaignHandlers = true
	refreshCampaignLanguages()
	DB.addHandler(CAMPAIGN_LANGUAGE_LIST, "onChildDeleted", refreshCampaignLanguages)
	DB.addHandler(CAMPAIGN_LANGUAGE_LIST .. ".*." .. CAMPAIGN_LANGUAGE_LIST_NAME, "onUpdate", refreshCampaignLanguages)
	DB.addHandler(CAMPAIGN_LANGUAGE_LIST .. ".*." .. CAMPAIGN_LANGUAGE_FONT_NAME, "onUpdate", refreshCampaignLanguages)	
end

function setSpeakerIdentity(sIdentity)
	if not bCampaignHandlers then
		addCampaignLanguageHandlers()
	end
	
	if (sActiveIdentity or "") == (sIdentity or "") then
		return
	end
	
	if (sActiveIdentity or "") ~= "" then
		DB.removeHandler("charsheet." .. sActiveIdentity .. "." .. CHAR_LANGUAGE_LIST, "onChildDeleted", refreshChatLanguages);
		DB.removeHandler("charsheet." .. sActiveIdentity .. "." .. CHAR_LANGUAGE_LIST .. ".*." .. CHAR_LANGUAGE_LIST_NAME, "onUpdate", refreshChatLanguages);
	end
	
	if (sIdentity or "") ~= "" then
		DB.addHandler("charsheet." .. sIdentity .. "." .. CHAR_LANGUAGE_LIST, "onChildDeleted", refreshChatLanguages);
		DB.addHandler("charsheet." .. sIdentity .. "." .. CHAR_LANGUAGE_LIST .. ".*." .. CHAR_LANGUAGE_LIST_NAME, "onUpdate", refreshChatLanguages);
	end
	
	sActiveIdentity = sIdentity or ""
	
	refreshChatLanguages()
end

function onIdentityActivation(sIdentity, sUser, bActive)
	if User.getUsername() == sUser and not bActive then
		if sActiveIdentity == sIdentity then
			setSpeakerIdentity("")
		end
	end
end

function onIdentityStateChange(sIdentity, sUser, sState, bState)
	if User.getUsername() == sUser and sState == 'current' and bState then
		setSpeakerIdentity(sIdentity)
	end
end

function refreshCampaignLanguages()
	-- Rebuild the campaign language dictionary for fast lookup
	aCampaignLang = {}
	aCampaignLangLower = {}
	for _,v in pairs(DB.getChildren(CAMPAIGN_LANGUAGE_LIST)) do
		local sLang = DB.getValue(v, CAMPAIGN_LANGUAGE_LIST_NAME, "")
		sLang = StringManager.trim(sLang)
		if (sLang or "") ~= "" then
			local sFont = DB.getValue(v, CAMPAIGN_LANGUAGE_FONT_NAME, "")
			sFont = StringManager.trim(sFont)
			
			aCampaignLang[sLang] = sFont
			aCampaignLangLower[sLang:lower()] = sFont
		end
	end
	
	-- Refresh the chat window, since the campaign languages have changed
	refreshChatLanguages()
end

function getKnownLanguages(sIdentity, bHost)
	local aSpokenLang = {}
	local aUnderstoodLang = {}
	local bSpeaksAll = false
	local bUnderstandsAll = false
	
	if bHost then
		bSpeaksAll = true;
		bUnderstandsAll = true;
	else
		local nodeChar = DB.findNode("charsheet." .. sIdentity)
		if nodeChar then
			for _,v in pairs(DB.getChildren(nodeChar, CHAR_LANGUAGE_LIST)) do
				local sLang = DB.getValue(v, CHAR_LANGUAGE_LIST_NAME, "")
				sLang = StringManager.trim(sLang)
				sLangLower = sLang:lower()
				if (sLang or "") ~= "" then
					if aLanguagesTongues[sLangLower] then
						bSpeaksAll = true;
						bUnderstandsAll = true;
					elseif aLanguageSpeaksAll[sLangLower] then
						bSpeaksAll = true;
					elseif aLanguagesUnderstandsAll[sLangLower] then
						bUnderstandsAll = true;
					elseif aCampaignLangLower[sLangLower] then
						table.insert(aSpokenLang, sLang)
						table.insert(aUnderstoodLang, sLang)
					end
				end
			end
			
		end
	end
	
	if bSpeaksAll then
		aSpokenLang = {}
		for kLang,_ in pairs(aCampaignLang) do
			table.insert(aSpokenLang, kLang)
		end
	end
	if bUnderstandsAll then
		aUnderstoodLang = {}
		for kLang,_ in pairs(aCampaignLang) do
			table.insert(aUnderstoodLang, kLang)
		end
	end
	
	return aSpokenLang, aUnderstoodLang
end

function refreshChatLanguages()
	-- If no chat window, then we don't need to refresh anything
	local w = Interface.findWindow("chat", "")
	if not w then
		return
	end
	
	-- Determine which languages are valid for the active identity/user
	local aSpokenLang = getKnownLanguages(sActiveIdentity, User.isHost())
	table.sort(aSpokenLang)
	
	-- If the current chat window language selection is not in the list, then clear the chat window language field
	local sChatWindowLanguage = w.language.getValue()
	if not StringManager.contains(aSpokenLang, sChatWindowLanguage) then
		w.language.setValue("")
	end
	
	-- Set the current language value options in the drop down control
	w.language.clear()
	w.language.add("")
	w.language.addItems(aSpokenLang)
end

function checkLangChat(msg, sLang)
	if (sLang or "") ~= "" then
		msg.type = LanguageManager.OOB_MSGTYPE_LANGCHAT
		msg.mode = mode
		msg.language = sLang
		Comm.deliverOOBMessage(msg, "")
		return true
	end
	return false
end

function handleLangChat(msgOOB)
	-- Validation
	local sLang = msgOOB.language
	if (sLang or "") == "" then
		return
	end
	if not aCampaignLang[sLang] then
		local sError = string.format(Interface.getString("error_chathandlelang_unavailable"), sLang, msgOOB.text)
		ChatManager.SystemMessage(sError)
		return
	end
	
	-- Deliver customized message to each player
	local aUnderstood = {}
	for _,vUser in ipairs(User.getActiveUsers()) do
		local bLanguageMiss
		local aUserPCKnownLanguage = {}
		local aUserPCUnknownLanguage = {}
		for _,vIdentity in ipairs(User.getActiveIdentities(vUser)) do
			local sName = DB.getValue("charsheet." .. vIdentity .. ".name", "")
			local _,aUnderstoodLang = getKnownLanguages(vIdentity)
			if StringManager.contains(aUnderstoodLang, sLang) then
				table.insert(aUserPCKnownLanguage, sName)
				table.insert(aUnderstood, sName)
			else
				table.insert(aUserPCUnknownLanguage, sName)
			end
		end
		
		deliverLanguageMessagesToUser(vUser, msgOOB, sLang, aUserPCKnownLanguage, aUserPCUnknownLanguage)
	end
	
	-- Deliver translated message to GM
	deliverLanguageMessagesToUser("", msgOOB, sLang, aUnderstood)
end

function deliverLanguageMessagesToUser(sUser, msg, sLang, aPCKnownLanguage, aPCUnknownLanguage)
	-- Make a copy of the message object, so we can change it
	local msgCopy = UtilityManager.copyDeep(msg)
	
	-- Determine the alternate font to use, if any
	local sFont = aCampaignLang[sLang]
	
	-- If user understands language, then send them the translated message
	if (sUser == "") or (#aPCKnownLanguage > 0) then
		if (sFont or "") ~= "" then
			msgCopy.sender = (msg.sender or "") .. " [" .. sLang .. "]"
			msgCopy.text = Interface.getString("tag_chathandlelang_translation") .. " " .. msgCopy.text
			Comm.deliverChatMessage(msgCopy, sUser)

			msgCopy.mode = "chat"
			msgCopy.sender = nil
			msgCopy.icon = nil
			msgCopy.font = sFont
			msgCopy.text = msg.text
			Comm.deliverChatMessage(msgCopy, sUser)
		else
			msgCopy.mode = "chat"
			msgCopy.sender = (msgCopy.sender or "") .. " [" .. sLang .. "]"
			Comm.deliverChatMessage(msgCopy, sUser)
		end
		
		if (sUser == "") or (#aPCUnknownLanguage > 0) then
			local msgUnderstood = {font = "systemfont"};
			msgUnderstood.text = "[" .. Interface.getString("message_chathandlelang_understood") .. ": " .. table.concat(aPCKnownLanguage, ", ") .. "]";
			Comm.deliverChatMessage(msgUnderstood, sUser)
		end
	-- Otherwise, send them gibberish message
	else
		local sGibberish = convertStringToGibberish(msgCopy.text, sLang)
		if (sFont or "") ~= "" then
			msgCopy.sender = (msg.sender or "") .. " " .. Interface.getString("tag_chathandlelang_unknown")
			msgCopy.text = ""
			Comm.deliverChatMessage(msgCopy, sUser)
			
			msgCopy.mode = "chat"
			msgCopy.sender = nil
			msgCopy.icon = nil
			msgCopy.font = sFont
			msgCopy.text = sGibberish
			Comm.deliverChatMessage(msgCopy, sUser)
		else
			msgCopy.mode = "chat"
			msgCopy.sender = (msgCopy.sender or "") .. " " .. Interface.getString("tag_chathandlelang_unknown")
			msgCopy.text = sGibberish
			Comm.deliverChatMessage(msgCopy, sUser)
		end
	end
end

function setCurrentLanguage(sLang)
	if (sLang or "") == "" then
		return
	end
	
	-- If no chat window, then we don't need to refresh anything
	local w = Interface.findWindow("chat", "")
	if not w then
		return
	end

	-- Make sure the language activated is in the list
	if w.language.hasValue(sLang) then
		if w.language.getValue() ~= sLang then
			w.language.setValue(sLang)
		end
	else
		ChatManager.SystemMessage(Interface.getString("message_chatsetlang_unavailable"))
	end
end

function convertStringToGibberish(sInput, sLang)
	local sOutput = ""
	
	local nAsciiCode
	local nRandom
	
	local aWords = StringManager.split(sInput, " ")
	for _,v in ipairs(aWords) do
		-- Set random seed based off the current word and the language name 
		-- Note: This returns the same gibberish for the same text in the same language
		calcRandomSeedFromString(v, sLang)

		-- nRandomLength will be added to the current length of the word - gives a different number of letters to original word.
		local nRandomLength = math.random(0,2)

		-- Create a string of random characters a-z, A-Z, 0-9 of the same length as the original string
		local sRandom = ""
		for nCharCount=1,(string.len(v) + nRandomLength - 1) do
			-- Get a random number 1 to 62 - this is the total number of possible unique characters
			nRandom = math.random(62)
			if nRandom < 27 then 
				nAsciiCode = nRandom + 64
			elseif nRandom < 53 then 
				nAsciiCode = nRandom + 70
			else 
				nAsciiCode = nRandom - 5
			end
			sRandom = sRandom .. string.char(nAsciiCode)
		end	
		sOutput = sOutput .. " " .. sRandom
	end	

	return sOutput
end

function calcRandomSeedFromString(sText, sLang)
	-- Calculate random seed based off text and language
	local nSeed = 0
	local sLangAndText = (sLang or "") .. (sText or "")
	for i = 1,#sLangAndText do
		nSeed = nSeed + sLangAndText:byte(i)
	end
	
	-- Set the random seed
	math.randomseed(nSeed)
	
	-- Pull the first random number to prevent corner cases
	math.random(10)
end

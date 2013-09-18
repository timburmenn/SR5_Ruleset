-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
    local msg = {font = "emotefont", icon="portrait_ruleset_token"};
    msg.text = "CoreRPG v3.0 ruleset for Fantasy Grounds.\rCopyright 2013 Smiteworks USA, LLC."
 	ChatManager.registerLaunchMessage(msg);
	
	Interface.onDesktopInit = onDesktopInit;

	registerPublicNodes();
	
	buildDesktop();
end

function onDesktopInit()
	if not User.isLocal() and not User.isHost() then
		Interface.openWindow("charselect_client", "", true);
	end
end

function registerPublicNodes()
	if User.isHost() then
		DB.createNode("options").setPublic(true);
		DB.createNode("partysheet").setPublic(true);
		DB.createNode("calendar").setPublic(true);
		DB.createNode("combattracker").setPublic(true);
		DB.createNode("modifiers").setPublic(true);
	end
end

function buildDesktop()
	-- Local mode
	if User.isLocal() then
		DesktopManager.registerStackShortcut("button_color", "button_color_down", "Colors", "pointerselection");

		DesktopManager.registerDockShortcut("button_characters", "button_characters_down", "Characters", "charselect_client");
		DesktopManager.registerDockShortcut("button_library", "button_library_down", "Library", "library");
		
	-- GM mode
	elseif User.isHost() then
		DesktopManager.registerStackShortcut("button_ct", "button_ct_down", "Combat Tracker", "combattracker_host", "combattracker");
		DesktopManager.registerStackShortcut("button_partysheet", "button_partysheet_down", "Party Sheet", "partysheet_host", "partysheet");

		DesktopManager.registerStackShortcut("button_tables", "button_tables_down", "Tables", "tablelist", "tables");
		DesktopManager.registerStackShortcut("button_calendar", "button_calendar_down", "Calendar", "calendar", "calendar");

		DesktopManager.registerStackShortcut("button_light", "button_light_down", "Lighting", "lightingselection");
		DesktopManager.registerStackShortcut("button_color", "button_color_down", "Colors", "pointerselection");

		DesktopManager.registerStackShortcut("button_modifiers", "button_modifiers_down", "Modifiers", "modifiers", "modifiers");
		DesktopManager.registerStackShortcut("button_options", "button_options_down", "Options", "options");
		
		DesktopManager.registerDockShortcut("button_characters", "button_characters_down", "Characters", "charselect_host", "charsheet");
		DesktopManager.registerDockShortcut("button_book", "button_book_down", "Story", "encounterlist", "encounter");
		DesktopManager.registerDockShortcut("button_maps", "button_maps_down", "Maps &\rImages", "imagelist", "image");
		DesktopManager.registerDockShortcut("button_people", "button_people_down", "Personalities", "npclist", "npc");
		DesktopManager.registerDockShortcut("button_items", "button_items_down", "Items", "itemlist", "item");
		DesktopManager.registerDockShortcut("button_notes", "button_notes_down", "Notes", "notelist", "notes");
		DesktopManager.registerDockShortcut("button_library", "button_library_down", "Library", "library");
		
		DesktopManager.registerDockShortcut("button_tokencase", "button_tokencase_down", "Tokens", "tokenbag", nil, true);
		
	-- Player mode
	else
		DesktopManager.registerStackShortcut("button_ct", "button_ct_down", "Combat tracker", "combattracker_client", "combattracker");
		DesktopManager.registerStackShortcut("button_partysheet", "button_partysheet_down", "Party Sheet", "partysheet_client", "partysheet");

		DesktopManager.registerStackShortcut("button_tables", "button_tables_down", "Tables", "tablelist", "tables");
		DesktopManager.registerStackShortcut("button_calendar", "button_calendar_down", "Calendar", "calendar", "calendar");

		DesktopManager.registerStackShortcut("button_color", "button_color_down", "Colors", "pointerselection");
		DesktopManager.registerStackShortcut("button_options", "button_options_down", "Options", "options");

		DesktopManager.registerStackShortcut("button_modifiers", "button_modifiers_down", "Modifiers", "modifiers", "modifiers");

		DesktopManager.registerDockShortcut("button_characters", "button_characters_down", "Characters", "charselect_client");
		DesktopManager.registerDockShortcut("button_book", "button_book_down", "Story", "encounterlist", "encounter");
		DesktopManager.registerDockShortcut("button_maps", "button_maps_down", "Maps &\rImages", "imagelist", "image");
		DesktopManager.registerDockShortcut("button_people", "button_people_down", "Personalities", "npclist", "npc");
		DesktopManager.registerDockShortcut("button_items", "button_items_down", "Items", "itemlist", "item");
		DesktopManager.registerDockShortcut("button_notes", "button_notes_down", "Notes", "notelist", "notes");
		DesktopManager.registerDockShortcut("button_library", "button_library_down", "Library", "library");
		
		DesktopManager.registerDockShortcut("button_tokencase", "button_tokencase_down", "Tokens", "tokenbag", nil, true);
	end
end

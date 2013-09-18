-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if User.isHost() then
		registerMenuItem("Turn Order", "turn", 7);
		registerMenuItem("Reset Turn Order", "pointer_circle", 7, 4);

		registerMenuItem("Delete From Tracker", "delete", 3);
		registerMenuItem("Delete All Non-Friendly", "delete", 3, 1);
		registerMenuItem("Delete Only Foes", "delete", 3, 3);
	end
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if button == 1 then
		Interface.openRadialMenu();
		return true;
	end
end

function onMenuSelection(selection, subselection, subsubselection)
	if User.isHost() then
		if selection == 7 then
			if subselection == 4 then
				CombatManager.resetInit();
			end
		elseif selection == 3 then
			if subselection == 1 then
				clearNPCs();
			elseif subselection == 3 then
				clearNPCs(true);
			end
		end
	end
end

function clearNPCs(bDeleteOnlyFoe)
	for _, vChild in pairs(window.list.getWindows()) do
		local sFaction = vChild.friendfoe.getStringValue();
		if bDeleteOnlyFoe then
			if sFaction == "foe" then
				vChild.delete();
			end
		else
			if sFaction ~= "friend" then
				vChild.delete();
			end
		end
	end
end

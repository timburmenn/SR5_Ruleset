-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	CalendarManager.registerChangeCallback(onCalendarChanged);
	
	if CalendarManager.getMonthsInYear() == 0 then
		if User.isHost() then
			sub_select.setVisible(true);
		else
			sub_empty.setVisible(true);
		end
	else
		sub_main.setVisible(true);
	end
	
	if User.isHost() then
		registerMenuItem("Reset Calendar", "delete", 3);
		registerMenuItem("Confirm Reset", "delete", 3, 1);
	end
end

function onClose()
	CalendarManager.unregisterChangeCallback(onCalendarChanged);
end

function onMenuSelection(selection, subselection)
	if selection == 3 and subselection == 1 then
		CalendarManager.reset();
	end
end

function onCalendarChanged()
	if CalendarManager.getMonthsInYear() == 0 then
		if User.isHost() then
			sub_select.setVisible(true);
		else
			sub_empty.setVisible(true);
		end
		sub_main.setVisible(false);
	else
		if User.isHost() then
			sub_select.setVisible(false);
		else
			sub_empty.setVisible(false);
		end
		sub_main.setVisible(true);
	end
	if sub_main.subwindow then
		sub_main.subwindow.onCalendarChanged();
	end
end

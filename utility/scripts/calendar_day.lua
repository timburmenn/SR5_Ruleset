-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function setState(bCurrDay, bSelDay, bHoliday, nodeEvent)
	if bCurrDay then
		setBackColor("000000");
		label_day.setColor("FFFFFF");
	else
		setBackColor();
		if bHoliday then
			label_day.setColor("333399");
		else
			label_day.setColor("000000");
		end
	end
	if bSelDay then
		setFrame("calendarhighlight");
	else
		setFrame(nil);
	end
	if bHoliday then
		label_day.setFont("calendarday-bi");
		label_day.setUnderline(true);
	else
		label_day.setFont("calendarday");
		label_day.setUnderline(false);
	end
	if nodeEvent then
		local sText = DB.getText(nodeEvent, "logentry");
		local bText = (sText ~= "");
		local sGMText = DB.getText(nodeEvent, "gmlogentry");
		local bGMText = (sGMText ~= "");
		
		if User.isHost() then
			icon_event.setVisible(bText);
			if bText then
				icon_gmevent.setVisible(bGMText);
			else
				icon_gmevent.setVisible(true);
			end
		else
			icon_event.setVisible(bText);
		end

		if User.isHost() then
			resetMenuItems();
			registerMenuItem("Delete Event", "delete", 6);
			registerMenuItem("Confirm Delete", "delete", 6, 7);
		end
	else
		icon_gmevent.setVisible(false);
		icon_event.setVisible(false);
		resetMenuItems();
	end
end

function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		local nDay = day.getValue();
		if nDay > 0 then
			local nMonth = windowlist.window.month.getValue();
			windowlist.window.windowlist.window.removeLogEntry(nMonth, nDay);
		end
	end
end

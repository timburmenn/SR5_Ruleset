-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if isEmpty() then
		local sName = "";
		
		if not skiplocal then
			sName = DB.getValue(window.getDatabaseNode(), "name", "");
		end
		
		if sName == "" and linktarget then
			sName = DB.getValue(window[linktarget[1]].getTargetDatabaseNode(), "name", "")
		end
		
		setValue(sName);
	end
end

function onHover(bOnControl)
	setUnderline(bOnControl);
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if linktarget then
		window[linktarget[1]].activate();
	end
	return true;
end

function onDragStart(button, x, y, draginfo)
	if linktarget and window[linktarget[1]].onDragStart then
		window[linktarget[1]].onDragStart(button, x, y, draginfo);
		return true;
	end
end

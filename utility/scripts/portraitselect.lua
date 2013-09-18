-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aPath = {};

function onInit()
	buildWindows();
end

function buildWindows()
	closeAll();
	
	if #aPath > 0 then
		local w = createWindowWithClass("portraitselection_up");
		w.icon.setIcon("tokenbagup");
	end
	
	local sPath = table.concat(aPath, "/");
	
	for _, v in ipairs(User.getPortraitDirectoryList(sPath)) do
		local w = createWindowWithClass("portraitselection_dir");
		w.icon.setIcon("tokenbag");
		w.icon.setTooltipText(v);
	end
	
	for _, v in ipairs(User.getPortraitFileList(sPath)) do
		local w = createWindow();
		w.portrait.setFile(v);
	end
end

function addPath(sPath)
	table.insert(aPath, sPath);
	buildWindows();
end

function popPath()
	table.remove(aPath);
	buildWindows();
end

function onClickRelease(button, x, y)
	if button == 4 and #aPath > 0 then
		popPath();
		return true;
	end
end

-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if (User.isHost()) then
		toggle_toolbars.setVisible(true);
	else
		toggle_toolbars.setVisible(false);
	end
	
	updateDisplay();

	registerMenuItem("Resize", "imagesize", 3);
	registerMenuItem("Original Size", "imagesizeoriginal", 3, 2);
	registerMenuItem("Adjust Vertical", "imagesizevertical", 3, 4);
	registerMenuItem("Adjust Horizontal", "imagesizehorizontal", 3, 5);
end

function onMenuSelection(item, subitem)
	if item == 3 then
		if subitem == 2 then
			local iw, ih = image.getImageSize();
			local w = iw + image.marginx[1];
			local h = ih + image.marginy[1];
			setSize(w, h);
			image.setViewpoint(0,0,1);
		elseif subitem == 4 then
			local iw, ih = image.getImageSize();
			local cw, ch = image.getSize();
			local w = cw + image.marginx[1];
			local h = ((ih/iw)*cw) + image.marginy[1];
			setSize(w, h);
			image.setViewpoint(0,0,0.1);
		elseif subitem == 5 then
			local iw, ih = image.getImageSize();
			local cw, ch = image.getSize();
			local w = ((iw/ih)*ch) + image.marginx[1];
			local h = ch + image.marginy[1];
			setSize(w, h);
			image.setViewpoint(0,0,0.1);
		end
	end
end
			
function updateDisplay()
	local bShowToolbar = false
	if (toolbars.getValue() > 0) then
		bShowToolbar = true;
	end

	if (User.isHost()) then
		h1.setVisible(bShowToolbar);
		if (bShowToolbar) then
			toggle_toolbars.setColor("ffffffff");
		else
			toggle_toolbars.setColor("60a0a0a0");
		end

		toolbar_draw.setVisibility(bShowToolbar);
		h2.setVisible(bShowToolbar);
		
		local bShowGridToggle = false;
		if (image.hasGrid()) then
			bShowGridToggle = bShowToolbar;
		end
		toggle_grid.setVisible(bShowGridToggle);
		
		local bShowGridToolbar = false;
		if (toggle_grid.getValue() > 0) then
			bShowGridToolbar = bShowGridToggle;
		end
		toolbar_grid.setVisibility(bShowGridToolbar);

		h3.setVisible(bShowGridToggle);
	end

	toggle_select.setVisible(bShowToolbar);
	toggle_targetselect.setVisible(bShowToolbar);
	toolbar_targeting.setVisibility(bShowToolbar);
end

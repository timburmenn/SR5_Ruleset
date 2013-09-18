-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if User.isHost() then
		addMenuChoices();
	end
end

function onButtonPress()
	Interface.openRadialMenu();
end

function addMenuChoices()
	resetMenuItems();

	registerMenuItem("2 Rows", "num2", 8);
	registerMenuItem("4 Rows", "num4", 7);
	registerMenuItem("6 Rows", "num6", 6);
	registerMenuItem("More", "radial_plus", 5);
	registerMenuItem("8 Rows", "num8", 5, 8);
	registerMenuItem("10 Rows", "num10", 5, 7);
	registerMenuItem("20 Rows", "num20", 5, 6);
	registerMenuItem("100 Rows", "percent", 5, 5);
	
	registerMenuItem("Step 1", "equals", 8, 8);
	registerMenuItem("Step 2", "num2", 8, 7);
	registerMenuItem("Step 4", "num4", 8, 6);
	registerMenuItem("More", "radial_plus", 8, 5);
	registerMenuItem("Step 5", "num5", 8, 5, 8);
	registerMenuItem("Step 10", "num10", 8, 5, 7);
	registerMenuItem("Step 20", "num20", 8, 5, 6);
	registerMenuItem("Step 100", "percent", 8, 5, 5);
	
	registerMenuItem("Step 1", "equals", 7, 8);
	registerMenuItem("Step 2", "num2", 7, 7);
	registerMenuItem("Step 4", "num4", 7, 6);
	registerMenuItem("More", "radial_plus", 7, 5);
	registerMenuItem("Step 5", "num5", 7, 5, 8);
	registerMenuItem("Step 10", "num10", 7, 5, 7);
	registerMenuItem("Step 20", "num20", 7, 5, 6);
	registerMenuItem("Step 100", "percent", 7, 5, 5);
	
	registerMenuItem("Step 1", "equals", 6, 8);
	registerMenuItem("Step 2", "num2", 6, 7);
	registerMenuItem("Step 4", "num4", 6, 6);
	registerMenuItem("More", "radial_plus", 6, 5);
	registerMenuItem("Step 5", "num5", 6, 5, 8);
	registerMenuItem("Step 10", "num10", 6, 5, 7);
	registerMenuItem("Step 20", "num20", 6, 5, 6);
	registerMenuItem("Step 100", "percent", 6, 5, 5);
	
	registerMenuItem("Step 1", "equals", 5, 8, 8);
	registerMenuItem("Step 2", "num2", 5, 8, 7);
	registerMenuItem("Step 4", "num4", 5, 8, 6);
	registerMenuItem("More", "radial_plus", 5, 8, 5);
	registerMenuItem("Step 5", "num5", 5, 8, 5, 8);
	registerMenuItem("Step 10", "num10", 5, 8, 5, 7);
	registerMenuItem("Step 20", "num20", 5, 8, 5, 6);
	registerMenuItem("Step 100", "percent", 5, 8, 5, 5);
	
	registerMenuItem("Step 1", "equals", 5, 7, 8);
	registerMenuItem("Step 2", "num2", 5, 7, 7);
	registerMenuItem("Step 4", "num4", 5, 7, 6);
	registerMenuItem("More", "radial_plus", 5, 7, 5);
	registerMenuItem("Step 5", "num5", 5, 7, 5, 8);
	registerMenuItem("Step 10", "num10", 5, 7, 5, 7);
	registerMenuItem("Step 20", "num20", 5, 7, 5, 6);
	registerMenuItem("Step 100", "percent", 5, 7, 5, 5);
	
	registerMenuItem("Step 1", "equals", 5, 6, 8);
	registerMenuItem("Step 2", "num2", 5, 6, 7);
	registerMenuItem("Step 4", "num4", 5, 6, 6);
	registerMenuItem("More", "radial_plus", 5, 6, 5);
	registerMenuItem("Step 5", "num5", 5, 6, 5, 8);
	registerMenuItem("Step 10", "num10", 5, 6, 5, 7);
	registerMenuItem("Step 20", "num20", 5, 6, 5, 6);
	registerMenuItem("Step 100", "percent", 5, 6, 5, 5);

	registerMenuItem("Step 1", "equals", 5, 5, 8);
	registerMenuItem("Step 2", "num2", 5, 5, 7);
	registerMenuItem("Step 4", "num4", 5, 5, 6);
	registerMenuItem("More", "radial_plus", 5, 5, 5);
	registerMenuItem("Step 5", "num5", 5, 5, 5, 8);
	registerMenuItem("Step 10", "num10", 5, 5, 5, 7);
	registerMenuItem("Step 20", "num20", 5, 5, 5, 6);
end

function onMenuSelection(subselection, subsubselection, subsubsubselection, subsubsubsubselection)
	if subselection == 8 then
		if subsubselection == 8 then
			TableManager.createTable(2, 1);
		elseif subsubselection == 7 then
			if Input.isControlPressed() then
				TableManager.createTable(3, 1, true);
			else
				TableManager.createTable(2, 2);
			end
		elseif subsubselection == 6 then
			TableManager.createTable(2, 4);
		elseif subsubselection == 5 then
			if subsubsubselection == 8 then
				TableManager.createTable(2, 5);
			elseif subsubsubselection == 7 then
				TableManager.createTable(2, 10);
			elseif subsubsubselection == 6 then
				TableManager.createTable(2, 20);
			elseif subsubsubselection == 5 then
				TableManager.createTable(2, 100);
			end
		end
	elseif subselection == 7 then
		if subsubselection == 8 then
			TableManager.createTable(4, 1);
		elseif subsubselection == 7 then
			if Input.isControlPressed() then
				TableManager.createTable(5, 1, true);
			else
				TableManager.createTable(4, 2);
			end
		elseif subsubselection == 6 then
			TableManager.createTable(4, 4);
		elseif subsubselection == 5 then
			if subsubsubselection == 8 then
				TableManager.createTable(4, 5);
			elseif subsubsubselection == 7 then
				TableManager.createTable(4, 10);
			elseif subsubsubselection == 6 then
				TableManager.createTable(4, 20);
			elseif subsubsubselection == 5 then
				TableManager.createTable(4, 100);
			end
		end
	elseif subselection == 6 then
		if subsubselection == 8 then
			TableManager.createTable(6, 1);
		elseif subsubselection == 7 then
			if Input.isControlPressed() then
				TableManager.createTable(7, 1, true);
			else
				TableManager.createTable(6, 2);
			end
		elseif subsubselection == 6 then
			TableManager.createTable(6, 4);
		elseif subsubselection == 5 then
			if subsubsubselection == 8 then
				TableManager.createTable(6, 5);
			elseif subsubsubselection == 7 then
				TableManager.createTable(6, 10);
			elseif subsubsubselection == 6 then
				TableManager.createTable(6, 20);
			elseif subsubsubselection == 5 then
				TableManager.createTable(6, 100);
			end
		end
	elseif subselection == 5 then
		if subsubselection == 8 then
			if subsubsubselection == 8 then
				TableManager.createTable(8, 1);
			elseif subsubsubselection == 7 then
				TableManager.createTable(8, 2);
			elseif subsubsubselection == 6 then
				TableManager.createTable(8, 4);
			elseif subsubsubselection == 5 then
				if subsubsubsubselection == 8 then
					TableManager.createTable(8, 5);
				elseif subsubsubsubselection == 7 then
					TableManager.createTable(8, 10);
				elseif subsubsubsubselection == 6 then
					TableManager.createTable(8, 20);
				elseif subsubsubsubselection == 5 then
					TableManager.createTable(8, 100);
				end
			end
		elseif subsubselection == 7 then
			if subsubsubselection == 8 then
				TableManager.createTable(10, 1);
			elseif subsubsubselection == 7 then
				if Input.isControlPressed() then
					TableManager.createTable(11, 1, true);
				else
					TableManager.createTable(10, 2);
				end
			elseif subsubsubselection == 6 then
				TableManager.createTable(10, 4);
			elseif subsubsubselection == 5 then
				if subsubsubsubselection == 8 then
					TableManager.createTable(10, 5);
				elseif subsubsubsubselection == 7 then
					TableManager.createTable(10, 10);
				elseif subsubsubsubselection == 6 then
					TableManager.createTable(10, 20);
				elseif subsubsubsubselection == 5 then
					TableManager.createTable(10, 100);
				end
			end
		elseif subsubselection == 6 then
			if subsubsubselection == 8 then
				TableManager.createTable(20, 1);
			elseif subsubsubselection == 7 then
				if Input.isControlPressed() then
					TableManager.createTable(21, 1, true);
				else
					TableManager.createTable(20, 2);
				end
			elseif subsubsubselection == 6 then
				TableManager.createTable(20, 4);
			elseif subsubsubselection == 5 then
				if subsubsubsubselection == 8 then
					TableManager.createTable(20, 5);
				elseif subsubsubsubselection == 7 then
					TableManager.createTable(20, 10);
				elseif subsubsubsubselection == 6 then
					TableManager.createTable(20, 20);
				elseif subsubsubsubselection == 5 then
					TableManager.createTable(20, 100);
				end
			end
		elseif subsubselection == 5 then
			if subsubsubselection == 8 then
				TableManager.createTable(100, 1);
			elseif subsubsubselection == 7 then
				if Input.isControlPressed() then
					TableManager.createTable(101, 1, true);
				else
					TableManager.createTable(100, 2);
				end
			elseif subsubsubselection == 6 then
				TableManager.createTable(100, 4);
			elseif subsubsubselection == 5 then
				if subsubsubsubselection == 8 then
					TableManager.createTable(100, 5);
				elseif subsubsubsubselection == 7 then
					TableManager.createTable(100, 10);
				elseif subsubsubsubselection == 6 then
					TableManager.createTable(100, 20);
				elseif subsubsubsubselection == 5 then
					TableManager.createTable(100, 100);
				end
			end
		end
	end
end

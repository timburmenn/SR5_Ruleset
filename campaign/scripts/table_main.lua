-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aTableColumnLabels = {};
local nColumnsLeftMargin = 70;
local nColumnsRightMargin = 10;
local nLabelLeftMargin = 5;
local nLabelRightMargin = 5;
local bInitPhase = true;

function onInit()
	if User.isHost() then
		if not tablerows.getNextWindow(nil) then
			addRow();
			addRow();
		end
		
		resetMenuItems();
		registerMenuItem("Add Row", "insert", 5);
		registerMenuItem("Add Column", "insert", 3);
		registerMenuItem("Delete Column", "delete", 4);
	end

	self.onSizeChanged = handleSizeChanged;
	onColumnsChanged();
	
	updateDieHeader();
	update();
	
	bInitPhase = false;
end

function update()
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	
	if bReadOnly then
		table_iedit.setValue(0);
	end
	table_iedit.setVisible(not bReadOnly);

	description.setReadOnly(bReadOnly);
	
	for _,ctrlLabel in pairs(aTableColumnLabels) do
		ctrlLabel.setReadOnly(bReadOnly);
	end
	
	tablerows.setReadOnly(bReadOnly);
	for _,w in ipairs(tablerows.getWindows()) do
		w.fromrange.setReadOnly(bReadOnly);
		w.torange.setReadOnly(bReadOnly);
		for _,w2 in ipairs(w.results.getWindows()) do
			w2.result.setReadOnly(bReadOnly);
		end
	end
end

function handleSizeChanged()
	updateColumns();
end

function onMenuSelection(selection, subselection, subsubselection, subsubsubselection, subsubsubsubselection)
	if selection == 3 then
		setColumns(getColumns() + 1);
	elseif selection == 4 then
		setColumns(getColumns() - 1);
	elseif selection == 5 then
		addRow();
	end					
end

function updateDieHeader()
	local aDice = TableManager.getTableDice(getDatabaseNode());
	header_die.setValue(aDice[1]);
end

function getColumns()
	return resultscols.getValue();
end

function setColumns(nColumns)
	local nCurrentColumns = getColumns();
	if nColumns < 1 then
		nColumns = 1;
	elseif nColumns > 20 then
		nColumns = 20;
	end
	if nColumns ~= nCurrentColumns then
		resultscols.setValue(nColumns);
	end
end

function calcColumnWidths()
	local w,h = tablerows.getSize();
	return math.floor(((w - nColumnsLeftMargin - nColumnsRightMargin) / getColumns()) + 0.5) - 1;
end

function onColumnsChanged()
	local nColumns = getColumns();
	for i = 1, nColumns do
		addColumnLabel(i);
	end
	for i = nColumns + 1, 20 do
		removeColumnLabel(i);
	end

	if User.isHost() then
		for _,v in ipairs(tablerows.getWindows()) do
			setRowColumns(v, nColumns);
		end
	end
	
	updateColumns();
end

function addRow()
	local winRow = tablerows.createWindow();
	
	setRowColumns(winRow, getColumns());
	winRow.results.setColumnWidth(calcColumnWidths());

	return winRow;
end

function setRowColumns(winRow, nColumns)
	local nCount = 0;
	
	for _,v in ipairs(winRow.results.getWindows()) do
		nCount = nCount + 1;
		if nCount > nColumns then
			v.getDatabaseNode().delete();
		end
	end
	
	while nCount < nColumns do
		nCount = nCount + 1;
		winRow.results.createWindow();
	end
end

function addColumnLabel(index)
	local ctrlLabel = self["labelcol" .. index];
	if not ctrlLabel then
		ctrlLabel = createControl("label_tablecolumn", "labelcol" .. index);
		if ctrlLabel then
			table.insert(aTableColumnLabels, index, ctrlLabel);
		end
	end
end

function removeColumnLabel(index)
	local ctrlLabel = self["labelcol" .. index];
	if ctrlLabel then
		ctrlLabel.destroy();
		table.remove(aTableColumnLabels, index);
	end
end

function updateColumns()
	local nColumns = getColumns();
	local nWidth = calcColumnWidths();
	
	for _,v in ipairs(tablerows.getWindows()) do
		v.results.setColumnWidth(nWidth);
	end

	local nHeaderOffset = 0;
	local x = nColumnsLeftMargin + 10;
	local w,h;
	local nLabelWidth = nWidth - nLabelLeftMargin - nLabelRightMargin;
	
	for k,v in pairs(aTableColumnLabels) do
		if k <= nColumns then
			v.setAnchor("left", "", "left", "absolute", x + nLabelLeftMargin);
			v.setVisible(true);
			x = x + nWidth;
			v.setAnchoredWidth(nLabelWidth);

			w,h = v.getSize();
			if h > nHeaderOffset then	
				nHeaderOffset = h - 15;
			end
		elseif k > nColumns then
			v.setVisible(false);
		end
	end
	
	if bInitPhase then
		nHeaderOffset = table_positionoffset.getValue();
	else
		table_positionoffset.setValue(nHeaderOffset);
	end
	
	frame_header.setAnchoredHeight(nHeaderOffset + 15);
end

function onDrop(x, y, draginfo)
	-- If no dice, then nothing to do
	if not draginfo.isType("dice") then
		return false;
	end
	local aDropDiceList = draginfo.getDieList();
	if not aDropDiceList then
		return false;
	end
	
	-- Get dice and mod
	local aDice = {};
	for _,v in ipairs(aDropDiceList) do
		table.insert(aDice, v.type);
	end
	local nMod = draginfo.getNumberData();

	-- Determine column dropped on (if any)
	local nodeWin = getDatabaseNode();
	local nDropColumn = 0;
	local nColumns = getColumns();
	local sColumn = "";
	if nColumns > 1 then
		local nWidth = calcColumnWidths();
		if x > nColumnsLeftMargin then
			nDropColumn = math.floor((x - nColumnsLeftMargin) / nWidth) + 1;
			if (nDropColumn < 1) or (nDropColumn > nColumns) then
				nDropColumn = 0;
			end
		end
	end
	
	-- Perform the roll
	TableManager.performRoll(nil, nil, nodeWin, nDropColumn, true, aDice, nMod);
	return true;
end

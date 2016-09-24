function onSourceUpdate()
    local nodeWin = window.getDatabaseNode();
    local nScoreOne = DB.getValue(nodeWin, "attributes." .. source_one[1] .. ".score",1);
    local nScoreTwo = DB.getValue(nodeWin, "attributes." .. source_two[1] .. ".score",0);
    local nMod = DB.getValue(nodeWin, "npcinitiative." .. target[1] .. ".temp",0);
    local nAugs = DB.getValue(nodeWin, "npcinitiative." .. target[1] .. ".augs",0);
    local nCurrent = (nScoreOne + nScoreTwo) + nMod + nAugs;
    setValue(nCurrent);
end

function onInit()
    addSource("attributes." .. source_one[1] .. ".score");
    addSource("attributes." .. source_two[1] .. ".score");
    addSource("npcinitiative." .. target[1] .. ".augs");
    addSource("npcinitiative." .. target[1] .. ".temp");

    super.onInit();
end

function action(draginfo)
    local nodeWin = window.getDatabaseNode();
    if nodeWin then
print("NodeWin OK");
        local nTotal = DB.getValue(nodeWin,
                "npcinitiative." .. target[1] .. ".score");
        local nMult = DB.getValue(nodeWin, "npcinitiative." .. target[1] .. ".mult");
        local iLabel = self.alabel[1];
        local msg = "[INIT] " .. iLabel;
        local nWoundPen = DB.getValue(nodeWin, "damage.penalty");
        local rActor = ActorManager.getActor("npc", window.getDatabaseNode());

        local tDice = {};
if nWoundPen &lt; 0 then
msg = msg .. " (Wound Penalty: "..nWoundPen..") ";
nTotal = nTotal + nWoundPen;
end

for i = 1, nMult do
table.insert (tDice, "d6");
end

        local rRoll = {sType = "init", sDesc = msg, aDice=tDice, nMod = nTotal, bSecret=true};
        ActionInit.performRoll(nil, rActor, rRoll);
    end
end

function onDragStart(button, x, y,  draginfo)
local nodeWin = window.getDatabaseNode();
    if nodeWin then
print("NodeWin OK");
        local nTotal = DB.getValue(nodeWin,
                "npcinitiative." .. target[1] .. ".score");
        local nMult = DB.getValue(nodeWin, "npcinitiative." .. target[1] .. ".mult");
        local iLabel = self.alabel[1];
        local msg = "[INIT] " .. iLabel;
        local nWoundPen = DB.getValue(nodeWin, "damage.penalty");
        local rActor = ActorManager.getActor("npc", window.getDatabaseNode());
local msg = "[INIT] " .. iLabel;

        local tDice = {};
if nWoundPen &lt; 0 then
msg = msg .. " (Wound Penalty: "..nWoundPen..") ";
nTotal = nTotal + nWoundPen;
end

for i = 1, nMult do
table.insert (tDice, "d6");
end

        local rRoll = {sType = "init", sDesc = msg, aDice=tDice, nMod = nTotal, bSecret=true};
        ActionInit.performRoll(draginfo, rActor, rRoll);
    end
return true;
end

function onDrop(x, y, draginfo)
return windowlist.onDrop(x, y, draginfo);
end

function onDoubleClick(x,y)
    return action();
end

						function onDragStart(button, x, y, draginfo)
							local nodeWin = window.getDatabaseNode();
							print("DB");
							print(nWoundPenalty);
							local nDice = window.getDatabaseNode().getChild("dice_pool").getValue();
							local modDesc, modStack = ModifierStack.getStack(true);
							nDice = nDice + modStack + nWoundPenalty;
							nDice = math.max(nDice,0);
							local label = window.getDatabaseNode().getChild("label").getValue()
							tDice = {};
							if nDice > 0 then
								print("ALA");
								for i = 1, nDice do
									table.insert (tDice, "d6");
								end
								local msg = "[Skill] ".. label;
								print("ALA");
								if modDesc ~= "" then
									msg = msg .. " (" .. modDesc .. ")";
								end
								print("ALA");
								if nWoundPenalty < 0 then
									msg = msg .. " (Wounds: " .. nWoundPenalty .. ") ";
								end
								local rRoll = { sType = "dice", sDesc = msg, aDice = tDice, nMod = 0 };
								ActionsManager.performAction(draginfo, nil, rRoll);
							else
								local rRoll = { sType = "dice", sDesc = label, aDice = tDice, nMod = 0 };
								ActionsManager.performAction(draginfo, nil, rRoll);
							end
							return true;						
						end
						
						function onDoubleClick(x, y)
							local nDice = window.getDatabaseNode().getChild("dice_pool").getValue()
							local modDesc, modStack = ModifierStack.getStack(true)
							nDice = nDice + modStack
							local label = window.getDatabaseNode().getChild("label").getValue()
							tDice = {};
							if nDice > 0 then
								for i = 1, nDice do
									table.insert (tDice, "d6");
								end
								local msg = "[Skill] ".. label
								if modDesc ~= "" then
									msg = msg .. " (" .. modDesc .. ")"
								end
								local rRoll = { sType = "dice", sDesc = msg, aDice = tDice, nMod = 0 };
								ActionsManager.performAction(nil, nil, rRoll);
							else
								local rRoll = { sType = "dice", sDesc = label, aDice = tDice, nMod = 0 };
								ActionsManager.performAction(nil, nil, rRoll);
							end
							return true;
						end
					
						function onDrop(x, y, draginfo)
							return windowlist.onDrop(x, y, draginfo);
						end
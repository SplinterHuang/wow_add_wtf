local L = LibStub("AceLocale-3.0"):NewLocale("AutoFollow", "ptBR");
if (not L) then
	return;
end

L["Drink"] = "Bebida";
L["Food"] = "Comida";
L["Refreshment"] = "Refeição";

L["pauseDrinkEatTitle"] = "Pause while drink/eat";
L["pauseDrinkEatDesc"] = "Pause follow while eating or drinking.";

L["pauseCastingTitle"] = "Pause while casting";
L["pauseCastingDesc"] = "Pause follow while casting or channeling spells.";

L["pauseControlledTitle"] = "Pause while moving manually";
L["pauseControlledDesc"] = "Pause follow while manually moving this character with movement keybinds.";

L["pauseShiftTitle"] = "Pause while shift down";
L["pauseShiftDesc"] = "Pause follow while holding down the shift key.";

L["intervalTitle"] = "Seconds between refollow";
L["intervalDesc"] = "How many second between each refollow try.";

L["stayWhileDrinkEatTitle"] = "Stay if lead moves";
L["stayWhileDrinkEatDesc"] = "When drinking/eating should we stay still until we've finished completely? (Untick this to follow leader if they move off before we're finished eating).";
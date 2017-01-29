local m4xArtifactData = LibStub("LibDataBroker-1.1"):NewDataObject("m4xArtifactBroker", {
	type = "data source",
	icon = "Interface\\Icons\\archaeology_5_0_mogucoin",
	label = "AP",
})

local akMulti = {
	25, 50, 90, 140, 200,
	275, 375, 500, 650, 850,
	1100, 1400, 1775, 2250, 2850,
	3600, 4550, 5700, 7200, 9000,
	11300, 14200, 17800, 22300, 24900,
};

local frame = CreateFrame("Frame", "m4xArtifactBrokerFrame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD");
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
frame:RegisterEvent("ARTIFACT_CLOSE");
frame:RegisterEvent("ARTIFACT_RESPEC_PROMPT");
frame:RegisterEvent("ARTIFACT_XP_UPDATE");

frame:SetScript("OnEvent", function(self, event, ...)
    local itemID, _, _, _, totalXP, pointsSpent = C_ArtifactUI.GetEquippedArtifactInfo()
    
	if itemID then
        local pointsFree, xpToNextPoint = 0, C_ArtifactUI.GetCostForPointAtRank(pointsSpent);
        
		while totalXP >= xpToNextPoint do
			totalXP, pointsSpent, pointsFree, xpToNextPoint = totalXP - xpToNextPoint, pointsSpent + 1, pointsFree + 1, C_ArtifactUI.GetCostForPointAtRank(pointsSpent + 1);
		end

		m4xArtifactData.text = string.format("|cff00ff00%d/%d (%.1f%%)|r" .. (pointsFree > 0 and " (+%d)" or ""), totalXP, xpToNextPoint, 100 * totalXP / xpToNextPoint, pointsFree);
		m4xArtifactData.value = string.format("|cff00ff00%.1f%%|r" .. (pointsFree > 0 and " (+%d)" or ""), 100 * totalXP / xpToNextPoint, pointsFree);
    end
 
end);

m4xArtifactData.OnTooltipShow = function(tooltip)
	local _, akLevel = GetCurrencyInfo(1171);
	local _, _, itemName, itemIcon, _, pointsSpent = C_ArtifactUI.GetEquippedArtifactInfo()
	local _, effectiveStat = UnitStat("player", 3);

	if HasArtifactEquipped() then
		tooltip:SetText(string.format("|T%d:0|t %s", itemIcon, itemName));
		tooltip:AddLine(" ");
		tooltip:AddLine(string.format("Artifact Knowledge Level: |cff00ff00%d (+%d%%)|r", akLevel, akMulti[akLevel] or 0));

		if akLevel < 25 then
			tooltip:AddLine(string.format("Next Artifact Knowledge: |cff00ff00%d (+%d%%)|r", akLevel + 1, akMulti[akLevel + 1]));
		end
		
		tooltip:AddLine(" ");
		tooltip:AddLine(string.format("Stamina from points: |cff00ff00+%g%% (+%d)|r", pointsSpent > 34 and 34 * 0.75 or pointsSpent * 0.75, effectiveStat - (effectiveStat / ((pointsSpent > 34 and 34 * 0.75 / 100 or pointsSpent * 0.75 / 100) + 1))));
	else
		tooltip:SetText("No Artifact Weapon Equipped");
	end
end

m4xArtifactData.OnClick = function(frame, button)
	if button == "LeftButton" then
		ArtifactFrame_LoadUI();
		if ( ArtifactFrame:IsVisible() ) then
			HideUIPanel(ArtifactFrame);
		else
			SocketInventoryItem(16);
		end
	end
end
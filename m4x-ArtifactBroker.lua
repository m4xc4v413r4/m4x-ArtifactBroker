local dropData = {}
m4xArtifactBrokerDB = m4xArtifactBrokerDB or {}

local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local dataobj = ldb:NewDataObject("m4xArtifactBroker", {
	type = "data source",
	icon = "Interface\\Icons\\archaeology_5_0_mogucoin",
	label = "AP"
})

local frame = CreateFrame("Frame")
local dropdown = CreateFrame("Button")

dropdown.displayMode = "MENU"

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterEvent("ARTIFACT_UPDATE")
frame:RegisterEvent("ARTIFACT_CLOSE")
frame:RegisterEvent("ARTIFACT_RESPEC_PROMPT")
frame:RegisterEvent("ARTIFACT_XP_UPDATE")

local function FormatText(arg)
	local formatedText = "|cff00ff00%.2f|r|cffff7f00%s|r"
	if arg >= 1000000000 then
		arg = string.format(formatedText, arg / 1000000000, "B")
	elseif arg >= 1000000 then
		arg = string.format(formatedText, arg / 1000000, "M")
	elseif arg >= 1000 then
		arg = string.format(formatedText, arg / 1000, "K")
	end
	return arg
end

local function ColorText(arg)
	local cR, cG
	if arg > 0.5 then
		cR = 255 * (1 - arg) * 2
		cG = 255
	elseif arg <= 0.5 then
		cR = 255
		cG = 255 * arg * 2
	end
	arg = string.format("|cff%02x%02x00", cR, cG)
	return arg
end


local function UpdateValues()
	local itemID, _, _, itemIcon, totalXP, pointsSpent, _, _, _, _, _, _, artifactTier = C_ArtifactUI.GetEquippedArtifactInfo()
	if itemID then
		dataobj.icon = itemIcon
		local pointsFree, xpToNextPoint = 0, C_ArtifactUI.GetCostForPointAtRank(pointsSpent, artifactTier)
		while totalXP >= xpToNextPoint and xpToNextPoint > 0 do
			totalXP, pointsSpent, pointsFree, xpToNextPoint = totalXP - xpToNextPoint, pointsSpent + 1, pointsFree + 1, C_ArtifactUI.GetCostForPointAtRank(pointsSpent + 1, artifactTier)
		end
		if xpToNextPoint < 1 then
			dataobj.text = string.format("Use %d ranks to calculate", pointsFree - 88)
		elseif m4xArtifactBrokerDB["view"] == "full" then
			dataobj.text = string.format("%s/%s (%s%.1f%%|r)" .. (pointsFree > 0 and " (+%d)" or ""), FormatText(totalXP), FormatText(xpToNextPoint), ColorText(totalXP / xpToNextPoint), 100 * totalXP / xpToNextPoint, pointsFree)
		elseif m4xArtifactBrokerDB["view"] == "partial" then
			dataobj.text = string.format("%s%.1f%%|r" .. (pointsFree > 0 and " (+%d)" or ""),ColorText(totalXP / xpToNextPoint), 100 * totalXP / xpToNextPoint, pointsFree)
		end
		return totalXP, xpToNextPoint, pointsFree
	end
end

frame:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		if not m4xArtifactBrokerDB["view"] then
			m4xArtifactBrokerDB["view"] = "partial"
		end
	end
	UpdateValues()
end)

dataobj.OnTooltipShow = function(tooltip)
	local _, _, itemName, itemIcon, _, pointsSpent = C_ArtifactUI.GetEquippedArtifactInfo()
	local totalXP, xpToNextPoint = UpdateValues()

	if HasArtifactEquipped() then
		tooltip:SetText(string.format("|T%d:0|t %s", itemIcon, itemName))
		tooltip:AddLine(" ")
		tooltip:AddDoubleLine("Artifact Weapon Rank:", string.format("|cff00ff00%d|r", pointsSpent))
		if xpToNextPoint > 0 then
			tooltip:AddDoubleLine("AP left for next Rank:", string.format("%s", FormatText(xpToNextPoint - totalXP)))
		end
	else
		tooltip:SetText("No Artifact Weapon Equipped")
	end
end

dropdown.initialize = function(self, dropLevel)
	if not dropLevel then return end
	wipe(dropData)

	if dropLevel == 1 then
		dropData.isTitle = 1
		dropData.notCheckable = 1

		dropData.text = "m4x ArtifactBroker"
		UIDropDownMenu_AddButton(dropData, dropLevel)

		dropData.isTitle = nil
		dropData.disabled = nil
		dropData.keepShownOnClick = 1
		dropData.hasArrow = 1
		dropData.notCheckable = 1

		dropData.text = "View"
		UIDropDownMenu_AddButton(dropData, dropLevel)

		dropData.value = nil
		dropData.hasArrow = nil
		dropData.keepShownOnClick = nil

		dropData.text = CLOSE
		dropData.func = function() CloseDropDownMenus() end
		dropData.checked = nil
		UIDropDownMenu_AddButton(dropData, dropLevel)

	elseif dropLevel == 2 then
		local totalXP, xpToNextPoint, pointsFree = UpdateValues()
		dropData.keepShownOnClick = 1
		dropData.notCheckable = 1

		if xpToNextPoint > 0 then
			dropData.text = string.format("%s/%s (%s%.1f%%|r)", FormatText(totalXP), FormatText(xpToNextPoint), ColorText(totalXP / xpToNextPoint), 100 * totalXP / xpToNextPoint, pointsFree)
			dropData.func = function() m4xArtifactBrokerDB["view"] = "full" UpdateValues() end
			UIDropDownMenu_AddButton(dropData, dropLevel)

			dropData.text = string.format("%s%.1f%%|r", ColorText(totalXP / xpToNextPoint), 100 * totalXP / xpToNextPoint, pointsFree)
			dropData.func = function() m4xArtifactBrokerDB["view"] = "partial" UpdateValues() end
			UIDropDownMenu_AddButton(dropData, dropLevel)
		end
	end
end

dataobj.OnClick = function(self, button)
	if button == "LeftButton" then
		ArtifactFrame_LoadUI()
		if ( ArtifactFrame:IsVisible() ) then
			HideUIPanel(ArtifactFrame)
		else
			SocketInventoryItem(16)
		end
	elseif button == "RightButton" then
		itemID = C_ArtifactUI.GetEquippedArtifactInfo()
		if itemID then
			ToggleDropDownMenu(1, nil, dropdown, self:GetName(), 0, 0)
		end
	end
end
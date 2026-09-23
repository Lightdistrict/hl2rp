
ITEM.name = "Identification Card"
ITEM.category = "Important"
ITEM.noDrop = true
ITEM.width = 1
ITEM.height = 1

-- Overridden per faction: the card's own title, and whether it should
-- show the holder's civic points (Conscripts/MPF use civic points; OTA
-- promotion is memory replacement, not points, so their card skips it).
ITEM.cardTitle = "Identification Card"
ITEM.showCivicPoints = false

-- The name always reflects whatever the owning character is currently
-- named (which itself updates automatically on rank/faction changes),
-- rather than a name snapshotted when the card was issued.
function ITEM:GetCardDetails()
	local owner = self:GetOwner()
	local character = IsValid(owner) and owner:GetCharacter()
	local name = (character and character:GetName()) or self:GetData("name", "Unknown")
	local text = string.format("ID #%s, assigned to %s.", self:GetData("id", "00000"), name)

	if (self.showCivicPoints and character) then
		text = text.." Civic Points: "..character:GetData("civicPoints", 0).."."
	end

	return text
end

function ITEM:GetDescription()
	return self.cardTitle..". "..self:GetCardDetails()
end

ITEM.functions.Show = {
	name = "show",
	tip = "showIDTip",
	icon = "icon16/comments.png",
	OnRun = function(item)
		local client = item.player

		if (!IsValid(client)) then
			return false
		end

		ix.chat.Send(client, "me", "shows their "..item.cardTitle..". It reads: \""..item:GetCardDetails().."\"")

		return false
	end,
	OnCanRun = function(item)
		return IsValid(item.player) and !IsValid(item.entity)
	end
}

CLASS.name = "Combine Elite"
CLASS.faction = FACTION_OTA

function CLASS:CanSwitchTo(client)
	return false
end

function CLASS:OnSet(client)
	local character = client:GetCharacter()

	if (character) then
		character:SetModel("models/combine_super_soldier.mdl")
	end
end

CLASS_OTA_ELITE = CLASS.index

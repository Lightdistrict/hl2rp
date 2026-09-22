CLASS.name = "Combine Suppressor"
CLASS.faction = FACTION_OTA

function CLASS:CanSwitchTo(client)
	return false
end

function CLASS:OnSet(client)
	local character = client:GetCharacter()

	if (character) then
		character:SetModel("models/synapse/combine/combine_supressor.mdl")
	end
end

CLASS_OTA_SUPPRESSOR = CLASS.index

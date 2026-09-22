CLASS.name = "Combine Ordinal"
CLASS.faction = FACTION_OTA

function CLASS:CanSwitchTo(client)
	return false
end

function CLASS:OnSet(client)
	local character = client:GetCharacter()

	if (character) then
		character:SetModel("models/synapse/combine/combine_soldier_elite_h.mdl")
	end
end

CLASS_OTA_ORDINAL = CLASS.index

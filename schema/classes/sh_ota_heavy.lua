CLASS.name = "Combine Heavy"
CLASS.faction = FACTION_OTA

function CLASS:CanSwitchTo(client)
	return false
end

function CLASS:OnSet(client)
	local character = client:GetCharacter()

	if (character) then
		character:SetModel("models/combine_soldier_prisonguard.mdl")
	end
end

CLASS_OTA_HEAVY = CLASS.index

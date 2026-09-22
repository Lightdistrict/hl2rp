CLASS.name = "Grunt"
CLASS.faction = FACTION_OTA
CLASS.isDefault = true

function CLASS:OnSet(client)
	local character = client:GetCharacter()

	if (character) then
		character:SetModel("models/combine_soldier.mdl")
	end
end

CLASS_OTA_GRUNT = CLASS.index

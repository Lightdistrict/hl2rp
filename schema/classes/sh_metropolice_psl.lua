CLASS.name = "Protection Shift Leader"
CLASS.faction = FACTION_MPF

function CLASS:CanSwitchTo(client)
	return false
end

function CLASS:OnSet(client)
	local character = client:GetCharacter()

	if (character) then
		character:SetModel("models/leet_police2.mdl")
	end
end

CLASS_PSL = CLASS.index

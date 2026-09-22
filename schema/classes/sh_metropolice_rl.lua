CLASS.name = "Rank Leader"
CLASS.faction = FACTION_MPF

function CLASS:CanSwitchTo(client)
	return false
end

function CLASS:OnSet(client)
	local character = client:GetCharacter()

	if (character) then
		character:SetModel("models/eliteghostcp.mdl")
	end
end

CLASS_RL = CLASS.index

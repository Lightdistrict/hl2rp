CLASS.name = "Combine Shotgunner"
CLASS.faction = FACTION_OTA

function CLASS:CanSwitchTo(client)
	return false
end

function CLASS:OnSet(client)
	local character = client:GetCharacter()

	if (character) then
		character:SetModel("models/jq/hlvr/characters/combine/grunt/combine_grunt_hlvr_npc.mdl")
		character:SetData("skin", 1)
		client:SetSkin(1)
	end
end

CLASS_OTA_SHOTGUNNER = CLASS.index

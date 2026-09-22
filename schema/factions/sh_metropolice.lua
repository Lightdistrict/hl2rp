
FACTION.name = "Metropolice Force"
FACTION.description = "A metropolice unit working as Civil Protection."
FACTION.color = Color(50, 100, 150)
FACTION.pay = 10
FACTION.models = {"models/police.mdl"}
FACTION.weapons = {"ix_stunstick"}
FACTION.isDefault = false
FACTION.isGloballyRecognized = true
FACTION.runSounds = {[0] = "NPC_MetroPolice.RunFootstepLeft", [1] = "NPC_MetroPolice.RunFootstepRight"}

function FACTION:OnCharacterCreated(client, character)
	local inventory = character:GetInventory()

	inventory:Add("pistol", 1)
	inventory:Add("pistolammo", 2)

	character:SetData("civicPoints", 0)
end

function FACTION:OnTransferred(character)
	character:SetData("callsign", Schema.mpfCallsignWords[math.random(#Schema.mpfCallsignWords)])
	character:SetData("callsignNumber", math.random(100, 999))
	character:SetModel(self.models[1])
end

FACTION_MPF = FACTION.index

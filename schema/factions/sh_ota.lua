
FACTION.name = "Stabilization Forces"
FACTION.description = "The Overwatch Transhuman Arm, a transhuman soldier produced by the Combine."
FACTION.color = Color(150, 50, 50, 255)
FACTION.pay = 40
FACTION.models = {"models/combine_soldier.mdl"}
FACTION.isDefault = false
FACTION.isGloballyRecognized = true
FACTION.runSounds = {[0] = "NPC_CombineS.RunFootstepLeft", [1] = "NPC_CombineS.RunFootstepRight"}

function FACTION:OnCharacterCreated(client, character)
	local inventory = character:GetInventory()

	inventory:Add("pistol", 1)
	inventory:Add("pistolammo", 2)

	inventory:Add("ar2", 1)
	inventory:Add("ar2ammo", 2)

	character:SetData("civicPoints", 0)
end

function FACTION:OnTransferred(character)
	character:SetData("callsignNumber", math.random(100, 999))
	character:SetModel(self.models[1])
end

FACTION_OTA = FACTION.index

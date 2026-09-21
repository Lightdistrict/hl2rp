CLASS.name = "Overwatch Elite"
CLASS.description = "A Combine Overwatch Transhuman Arm soldier, physically and cybernetically enhanced far beyond a human officer."
CLASS.faction = FACTION_CIVILPROTECTION
CLASS.isDefault = false
CLASS.limit = 2
CLASS.color = Color(180, 60, 60)
CLASS.health = 150
CLASS.armor = 80
CLASS.weapons = {"weapon_stunstick", "weapon_smg1", "weapon_ar2"}
CLASS.model = {
	"models/player/combine_soldier.mdl"
}

CLASS.OnCanBe = function(self, client)
	local character = client:getChar()
	return character ~= nil and character:hasClassWhitelist(self.index)
end

CLASS_OVERWATCHELITE = CLASS.index

CLASS.name = "Corporal"
CLASS.description = "A junior non-commissioned officer trusted with an SMG and light patrol authority."
CLASS.faction = FACTION_CIVILPROTECTION
CLASS.isDefault = false
CLASS.color = Color(70, 115, 175)
CLASS.health = 120
CLASS.armor = 40
CLASS.weapons = {"weapon_stunstick", "weapon_pistol", "weapon_smg1"}
CLASS.model = {
	"models/player/police.mdl",
	"models/player/police_fem.mdl"
}

CLASS.OnCanBe = function(self, client)
	local character = client:getChar()
	return character ~= nil and character:hasClassWhitelist(self.index)
end

CLASS_CORPORAL = CLASS.index

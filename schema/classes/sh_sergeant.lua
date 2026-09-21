CLASS.name = "Sergeant"
CLASS.description = "A senior non-commissioned officer responsible for supervising Conscripts, Privates, and Corporals in the field."
CLASS.faction = FACTION_CIVILPROTECTION
CLASS.isDefault = false
CLASS.limit = 3
CLASS.color = Color(55, 100, 165)
CLASS.health = 130
CLASS.armor = 55
CLASS.weapons = {"weapon_stunstick", "weapon_pistol", "weapon_smg1"}
CLASS.model = {
	"models/player/police.mdl",
	"models/player/police_fem.mdl"
}

CLASS.OnCanBe = function(self, client)
	local character = client:getChar()
	return character ~= nil and character:hasClassWhitelist(self.index)
end

CLASS_SERGEANT = CLASS.index

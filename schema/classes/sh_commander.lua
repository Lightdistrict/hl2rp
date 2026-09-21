CLASS.name = "Elite Commander"
CLASS.description = "The ranking Combine officer on-site, answerable only to the Civil Authority itself. Commands every rank below it."
CLASS.faction = FACTION_CIVILPROTECTION
CLASS.isDefault = false
CLASS.limit = 1
CLASS.color = Color(210, 40, 40)
CLASS.health = 175
CLASS.armor = 100
CLASS.weapons = {"weapon_stunstick", "weapon_smg1", "weapon_ar2"}
CLASS.model = {
	"models/player/combine_super_soldier.mdl"
}

CLASS.OnCanBe = function(self, client)
	local character = client:getChar()
	return character ~= nil and character:hasClassWhitelist(self.index)
end

CLASS_ELITECOMMANDER = CLASS.index

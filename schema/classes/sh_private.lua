CLASS.name = "Private"
CLASS.description = "A Conscript who has proven basic reliability and been issued a sidearm."
CLASS.faction = FACTION_CIVILPROTECTION
CLASS.isDefault = false
CLASS.color = Color(90, 130, 180)
CLASS.health = 110
CLASS.armor = 25
CLASS.weapons = {"weapon_stunstick", "weapon_pistol"}
CLASS.model = {
	"models/player/police.mdl",
	"models/player/police_fem.mdl"
}

-- Requires an admin to whitelist this rank onto the character (see schema/sh_commands.lua).
CLASS.OnCanBe = function(self, client)
	local character = client:getChar()
	return character ~= nil and character:hasClassWhitelist(self.index)
end

CLASS_PRIVATE = CLASS.index

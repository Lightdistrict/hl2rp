--[[
	Per-class Stabilization Forces (OTA) voice lines.

	The base "Combine" voice class (schema/sh_voices.lua) is shared by both
	MPF and OTA and stays as-is - generic radio codes any Combine unit can
	use. These classes sit on top of it: a character only gets a given
	class's lines while they currently hold that exact OTA class, so a
	Grunt can't use Ordinal-only phrases, etc. A player who qualifies for
	multiple classes (shouldn't normally happen here, since a character
	only has one class at a time) would get all of them - Schema.voices.
	GetClass returns every match, checked in order until one has the typed
	phrase.

	Schema.voices.Add calls with the actual phrase/sound data for each
	class go in this file too, once that data is available.
]]

Schema.voices.AddClass("OTA_Grunt", function(client)
	return Schema.voices.CharacterHasClass(client:GetCharacter(), "ota_grunt")
end)

Schema.voices.AddClass("OTA_Soldier", function(client)
	return Schema.voices.CharacterHasClass(client:GetCharacter(), "ota_soldier")
end)

Schema.voices.AddClass("OTA_Shotgunner", function(client)
	return Schema.voices.CharacterHasClass(client:GetCharacter(), "ota_shotgunner")
end)

Schema.voices.AddClass("OTA_Suppressor", function(client)
	return Schema.voices.CharacterHasClass(client:GetCharacter(), "ota_suppressor")
end)

Schema.voices.AddClass("OTA_Heavy", function(client)
	return Schema.voices.CharacterHasClass(client:GetCharacter(), "ota_heavy")
end)

Schema.voices.AddClass("OTA_Ordinal", function(client)
	return Schema.voices.CharacterHasClass(client:GetCharacter(), "ota_ordinal")
end)

Schema.voices.AddClass("OTA_Elite", function(client)
	return Schema.voices.CharacterHasClass(client:GetCharacter(), "ota_elite")
end)

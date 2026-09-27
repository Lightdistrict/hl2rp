Schema.voices = {}
Schema.voices.stored = {}
Schema.voices.classes = {}

function Schema.voices.Add(class, key, text, sound, global)
	class = string.lower(class)
	key = string.lower(key)

	Schema.voices.stored[class] = Schema.voices.stored[class] or {}
	Schema.voices.stored[class][key] = {
		text = text,
		sound = sound,
		global = global
	}
end

function Schema.voices.Get(class, key)
	class = string.lower(class)
	key = string.lower(key)

	if (Schema.voices.stored[class]) then
		return Schema.voices.stored[class][key]
	end
end

function Schema.voices.AddClass(class, condition)
	class = string.lower(class)

	Schema.voices.classes[class] = {
		condition = condition
	}
end

function Schema.voices.GetClass(client)
	local classes = {}

	for k, v in pairs(Schema.voices.classes) do
		if (v.condition(client)) then
			classes[#classes + 1] = k
		end
	end

	return classes
end

-- Compares a character's class by its stable uniqueID (the class file's
-- name) instead of its numeric index, since that index is just the class's
-- position in an alphabetical file list and silently shifts for every class
-- that loads after it whenever a class file is added or removed.
function Schema.voices.CharacterHasClass(character, uniqueID)
	if (!character) then return false end

	local info = ix.class.Get(character:GetClass())

	return info != nil and info.uniqueID == uniqueID
end
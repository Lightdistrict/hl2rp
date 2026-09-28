
function Schema:CanPlayerUseBusiness(client, uniqueID)
	if (client:Team() == FACTION_CITIZEN) then
		local itemTable = ix.item.list[uniqueID]

		if (itemTable) then
			if (itemTable.permit) then
				local character = client:GetCharacter()
				local inventory = character:GetInventory()

				if (!inventory:HasItem("permit_"..itemTable.permit)) then
					return false
				end
			elseif (itemTable.base ~= "base_permit") then
				return false
			end
		end
	end
end

-- called when the client wants to view the combine data for the given target
function Schema:CanPlayerViewData(client, target)
	return client:IsCombine() and (!target:IsCombine() and target:Team() != FACTION_ADMIN)
end

-- called when the client wants to edit the combine data for the given target
function Schema:CanPlayerEditData(client, target)
	return client:IsCombine() and (!target:IsCombine() and target:Team() != FACTION_ADMIN)
end

function Schema:CanPlayerViewObjectives(client)
	return client:IsCombine()
end

function Schema:CanPlayerEditObjectives(client)
	if (!client:IsCombine() or !client:GetCharacter()) then
		return false
	end

	local bCanEdit = false
	local name = client:GetCharacter():GetName()

	for k, v in ipairs({"OfC", "EpU", "DvL", "SeC"}) do
		if (self:IsCombineRank(name, v)) then
			bCanEdit = true
			break
		end
	end

	return bCanEdit
end

function Schema:CanDrive()
	return false
end

-- Per-faction folder under sound/footsteps/<folder>/ - shared so both the
-- server (which picks and emits the actual sound) and the client (which
-- needs to suppress its own locally-predicted default footstep sound) know
-- which factions have a custom footstep pack registered.
Schema.footstepFactionFolders = Schema.footstepFactionFolders or {}

function Schema:RegisterFootstepFaction(factionID, folder)
	self.footstepFactionFolders[factionID] = folder
end

-- Per-faction cycling run-footstep pack under sound/foley/<folder>/ - files
-- are named <prefix><1..count>.wav. Factions without one registered keep
-- using the faction's runSounds GameSound table (see sv_hooks.lua).
Schema.footstepRunPacks = Schema.footstepRunPacks or {}

function Schema:RegisterRunFootstepFaction(factionID, folder, prefix, count)
	self.footstepRunPacks[factionID] = {folder = folder, prefix = prefix, count = count}
end

Schema:RegisterRunFootstepFaction(FACTION_MPF, "metrocop", "metrocop_foley_step_", 9)

-- Per-class WALKING footstep override, keyed by the class's uniqueID (not
-- its numeric index, which shifts if classes are added/removed) - takes
-- priority over the material system entirely, so this class always uses
-- this fixed cycling set regardless of surface. Files are <prefix><NN>.wav,
-- zero-padded to 2 digits. Running is unaffected (see footstepRunPacks).
Schema.footstepClassOverrides = Schema.footstepClassOverrides or {}

function Schema:RegisterFootstepClass(classUniqueID, folder, prefix, count, ext)
	self.footstepClassOverrides[classUniqueID] = {folder = folder, prefix = prefix, count = count, ext = ext or "wav"}
end

Schema:RegisterFootstepClass("ota_heavy", "charger", "charger_step_", 5, "mp3")

-- The 4-channel combine radio (schema/items/sh_combine_radio.lua). "factions"
-- nil means everyone can send/hear it; otherwise it's a whitelist. Names are
-- just what's shown in chat ("<name> radios in <name>: ...") - rename freely.
Schema.radioChannels = {
	[1] = {name = "Tac 1", factions = nil},
	[2] = {name = "Tac 2", factions = {FACTION_MPF, FACTION_OVERWATCH, FACTION_OTA}},
	[3] = {name = "Tac 3", factions = {FACTION_OTA, FACTION_OVERWATCH}},
	[4] = {name = "Tac 4", factions = {FACTION_OVERWATCH}}
}

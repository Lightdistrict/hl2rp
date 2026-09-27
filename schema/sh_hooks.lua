
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

Schema:RegisterFootstepFaction(FACTION_CONSCRIPT, "conscripts")

-- Per-faction cycling run-footstep pack under sound/foley/<folder>/ - files
-- are named <prefix><1..count>.wav. Factions without one registered keep
-- using the faction's runSounds GameSound table (see sv_hooks.lua).
Schema.footstepRunPacks = Schema.footstepRunPacks or {}

function Schema:RegisterRunFootstepFaction(factionID, folder, prefix, count)
	self.footstepRunPacks[factionID] = {folder = folder, prefix = prefix, count = count}
end

Schema:RegisterRunFootstepFaction(FACTION_MPF, "metrocop", "metrocop_foley_step_", 9)

-- The 4-channel combine radio (schema/items/sh_combine_radio.lua). "factions"
-- nil means everyone can send/hear it; otherwise it's a whitelist. Names are
-- just what's shown in chat ("<name> radios in <name>: ...") - rename freely.
Schema.radioChannels = {
	[1] = {name = "tac", factions = nil},
	[2] = {name = "command", factions = {FACTION_MPF, FACTION_OVERWATCH, FACTION_OTA}},
	[3] = {name = "field", factions = {FACTION_OTA, FACTION_OVERWATCH}},
	[4] = {name = "overwatch", factions = {FACTION_OVERWATCH}}
}

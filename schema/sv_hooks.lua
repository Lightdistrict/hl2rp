
function Schema:LoadData()
	self:LoadRationDispensers()
	self:LoadVendingMachines()
	self:LoadCombineLocks()
	self:LoadForceFields()

	Schema.CombineObjectives = ix.data.Get("combineObjectives", {}, false, true)
end

function Schema:SaveData()
	self:SaveRationDispensers()
	self:SaveVendingMachines()
	self:SaveCombineLocks()
	self:SaveForceFields()
end

function Schema:PlayerSwitchFlashlight(client, enabled)
	if (client:IsCombine()) then
		return true
	end
end

function Schema:PlayerUse(client, entity)
	if (IsValid(client.ixScanner)) then
		return false
	end

	if ((client:IsCombine() or client:Team() == FACTION_ADMIN) and entity:IsDoor() and IsValid(entity.ixLock) and client:KeyDown(IN_SPEED)) then
		entity.ixLock:Toggle(client)
		return false
	end

	if (!client:IsRestricted() and entity:IsPlayer() and entity:IsRestricted() and !entity:GetNetVar("untying")) then
		entity:SetAction("@beingUntied", 5)
		entity:SetNetVar("untying", true)

		client:SetAction("@unTying", 5)

		client:DoStaredAction(entity, function()
			entity:SetRestricted(false)
			entity:SetNetVar("untying")
		end, 5, function()
			if (IsValid(entity)) then
				entity:SetNetVar("untying")
				entity:SetAction()
			end

			if (IsValid(client)) then
				client:SetAction()
			end
		end)
	end
end

function Schema:PlayerUseDoor(client, door)
	if (client:IsCombine()) then
		if (!door:HasSpawnFlags(256) and !door:HasSpawnFlags(1024)) then
			door:Fire("open")
		end
	end
end

function Schema:PlayerLoadout(client)
	client:SetNetVar("restricted")
end

function Schema:PostPlayerLoadout(client)
	-- outfit items' bodygroups only ever get applied at the moment they're
	-- equipped (AddOutfit) - bodygroups reset to 0 on every fresh player
	-- entity (respawn, or rejoining/loading a character), so an item that
	-- was left equipped from a previous life stays marked as equipped in
	-- its own data but visually disappears until manually unequipped and
	-- re-equipped. Recompute bodygroup state from currently-equipped items
	-- on every loadout to fix that.
	Schema:ReapplyOutfitBodygroups(client)

	if (client:IsCombine()) then
		if (client:Team() == FACTION_OTA) then
			client:SetMaxHealth(150)
			client:SetHealth(150)
			client:SetArmor(150)
		elseif (client:IsScanner()) then
			if (client.ixScanner:GetClass() == "npc_clawscanner") then
				client:SetHealth(200)
				client:SetMaxHealth(200)
			end

			client.ixScanner:SetHealth(client:Health())
			client.ixScanner:SetMaxHealth(client:GetMaxHealth())
			client:StripWeapons()
		else
			client:SetArmor(self:IsCombineRank(client:Name(), "RCT") and 50 or 100)
		end

		local factionTable = ix.faction.Get(client:Team())

		if (factionTable.OnNameChanged) then
			factionTable:OnNameChanged(client, "", client:GetCharacter():GetName())
		end
	end
end

function Schema:PrePlayerLoadedCharacter(client, character, oldCharacter)
	if (IsValid(client.ixScanner)) then
		client.ixScanner:Remove()
	end

	-- stop any gas mask breathing loop from the character being switched
	-- away from (deleted, or just swapped) - the timer's own character-ID
	-- check (sh_conscript_gasmask.lua) would eventually catch this too,
	-- but only after its next 3-5s cycle, so stop it immediately here
	timer.Remove("ixhl2rpGasmaskBreath" .. client:EntIndex())
end

function Schema:PlayerLoadedCharacter(client, character, oldCharacter)
	local faction = character:GetFaction()

	if (faction == FACTION_CITIZEN) then
		self:AddCombineDisplayMessage("@cCitizenLoaded", Color(255, 100, 255, 255))
	elseif (client:IsCombine()) then
		client:AddCombineDisplayMessage("@cCombineLoaded")
	end

	-- Force the Conscript/MPF/OTA display name for this character. This runs before Helix's own
	-- GM:PlayerLoadedCharacter assigns a fresh character's default class (Schema hooks run before
	-- the core gamemode hook of the same name), so assign it ourselves first if it isn't valid yet.
	-- Also catches a leftover class from a PREVIOUS faction (e.g. a promotion that got interrupted
	-- because the target faction had no isDefault class set) - not just a missing class entirely.
	local currentClass = ix.class.list[character:GetClass()]

	if (!currentClass or currentClass.faction != faction) then
		for _, v in pairs(ix.class.list) do
			if (v.faction == faction and v.isDefault) then
				character:SetClass(v.index)
				break
			end
		end
	end

	if (faction == FACTION_CONSCRIPT) then
		if (!character:GetData("baseName")) then
			character:SetData("baseName", character:GetName())
		end

		self:UpdateConscriptName(character)
	elseif (faction == FACTION_MPF) then
		if (!character:GetData("callsign")) then
			character:SetData("callsign", self.mpfCallsignWords[math.random(#self.mpfCallsignWords)])
			character:SetData("callsignNumber", math.random(100, 999))
		end

		self:UpdateMPFName(character)
	elseif (faction == FACTION_OTA) then
		if (!character:GetData("callsignNumber")) then
			character:SetData("callsignNumber", math.random(100, 999))
		end

		self:UpdateOTAName(character)
	elseif (faction == FACTION_OVERWATCH and character:GetClass() == CLASS_OVERWATCH_SCANNER) then
		if (!character:GetData("scannerCallsign")) then
			character:SetData("scannerCallsign", self:ZeroNumber(math.random(0, 999), 3))
		end

		self:UpdateScannerName(character)
	end
end

function Schema:CharacterVarChanged(character, key, oldValue, value)
	local client = character:GetPlayer()
	if (key == "name") then
		local factionTable = ix.faction.Get(client:Team())

		if (factionTable.OnNameChanged) then
			factionTable:OnNameChanged(client, oldValue, value)
		end
	end
end

-- The dropped world-model entity for an item (gamemode/entities/entities/
-- ix_item.lua) never applies any bodygroups - it only sets the item's
-- model and skin - so a dropped/picked-up-by-someone-else outfit item
-- always shows its base/default bodygroup state instead of the value the
-- item is actually meant to represent. Call this from ITEM:OnEntityCreated
-- to fix that up.
--
-- Deliberately reads ITEM.worldBodyGroups, NOT ITEM.bodyGroups - the two
-- can be (and for the berets, ARE) completely different bodygroups on
-- completely different meshes: ITEM.bodyGroups is applied to the PLAYER's
-- own model via base_outfit (e.g. the "headwear" bodygroup on the
-- thomask_110 player models, which swaps in a different head mesh per
-- hat), while the world/inventory appearance comes from ITEM.model - a
-- separate standalone prop (e.g. head_beret.mdl) that isn't guaranteed to
-- share any bodygroup names, or even a bodygroup at all, with the player
-- model. The beret prop, for instance, has its own "colour" bodygroup
-- (confirmed via an in-game dump: id 0, name "colour", 2 values) that has
-- nothing to do with "headwear" on the player model.
function Schema:ApplyItemBodyGroups(entity, itemTable)
	if (!istable(itemTable.worldBodyGroups)) then
		return
	end

	for name, value in pairs(itemTable.worldBodyGroups) do
		local index = entity:FindBodygroupByName(name)

		if (index > -1) then
			entity:SetBodygroup(index, value)
		end
	end
end

-- base_outfit's own AddOutfit/RemoveOutfit (gamemode/items/base/sh_outfit.lua)
-- keep a single, non-namespaced character:GetData("groups") snapshot plus a
-- per-category character:GetData("oldGroups"<category>) snapshot, meant for
-- ONE outfit piece being worn at a time. With several independent
-- single-bodygroup accessories (helmet/vest/cap/beret) worn together, that
-- bookkeeping gets cross-contaminated - RemoveOutfit's own
-- client:ResetBodygroups() call zeroes EVERY bodygroup on the model, not
-- just the one being removed, and the old-groups snapshot it restores from
-- can end up holding a stale mix of whatever bodygroups happened to be set
-- at some earlier equip, corrupting even the EQUIP path (a second item's
-- ResetBodygroups() firing when it shouldn't).
--
-- Rather than trying to keep that bookkeeping consistent, this treats the
-- character's bodygroup state as fully DERIVED from which outfit items are
-- currently equipped: reset everything, wipe out base_outfit's own stale
-- character data so it can't reset anything again later, then reapply only
-- what every currently-equipped item's own ITEM.bodyGroups says. Call this
-- after any outfit item's own equip/unequip logic.
function Schema:ReapplyOutfitBodygroups(client)
	local character = client:GetCharacter()
	local inventory = character and character:GetInventory()

	if (!character or !inventory) then
		return
	end

	character:SetData("groups", nil)

	for _, item in pairs(ix.item.list) do
		if (item.outfitCategory) then
			character:SetData("oldGroups" .. item.outfitCategory, nil)
		end
	end

	client:ResetBodygroups()

	-- rank-based bodygroups (e.g. Conscript epaulettes, Schema.conscriptEpaulettes
	-- in sh_civicpoints.lua) aren't tied to an inventory item, so they have to be
	-- reapplied here too - otherwise equipping/unequipping any outfit item would
	-- wipe them back to 0 via the ResetBodygroups() call just above
	local epaulettes = self.conscriptEpaulettes and self.conscriptEpaulettes[character:GetClass()]

	if (epaulettes) then
		local index = client:FindBodygroupByName("epaulettes")

		if (index > -1) then
			client:SetBodygroup(index, epaulettes)
		end
	end

	for item in inventory:Iter() do
		if (item:GetData("equip") and istable(item.bodyGroups)) then
			for name, value in pairs(item.bodyGroups) do
				local index = client:FindBodygroupByName(name)

				if (index > -1) then
					client:SetBodygroup(index, value)
				end
			end
		end
	end
end

-- Plays an MP3 (which Source's classic EmitSound can't decode - see
-- Schema:EmitFootstepSound above) to everyone standing near the given
-- player, for positional equip/unequip-style sounds others should hear
-- happen nearby. For a sound meant for the player alone (no one else),
-- just call netstream.Start(client, "PlaySound", path) directly instead.
function Schema:EmitNearbyMP3(client, path, range)
	range = range or ix.config.Get("chatRange", 280)

	local recipients = {}

	for _, ply in ipairs(player.GetAll()) do
		if ((ply:GetPos() - client:GetPos()):LengthSqr() <= (range * range)) then
			recipients[#recipients + 1] = ply
		end
	end

	netstream.Start(recipients, "PlaySound", path)
end

-- Maps a traced surfaceprop name to one of our footstep sound categories.
-- Source surfaceprops vary a lot by content pack (e.g. "wood.plank" vs
-- "wood"), so this matches by substring rather than requiring an exact
-- name - tune if a material isn't picking the right category in-game.
local FOOTSTEP_MATERIAL_ALIASES = {
	{"metalgrate", "metalgrate"},
	{"grate", "metalgrate"},
	{"concrete", "concrete"},
	{"gravel", "gravel"},
	{"ladder", "ladder"},
	{"rubber", "rubber"},
	{"wade", "wade"},
	{"slosh", "slosh"},
	{"water", "slosh"},
	{"grass", "grass"},
	{"metal", "metal"},
	{"snow", "snow"},
	{"tile", "tile"},
	{"sand", "sand"},
	{"wood", "wood"},
	{"woodpanel", "woodpanel"},
	{"mud", "mud"},
	{"dirt", "dirt"},
	{"duct", "duct"},
	{"vent", "duct"}
}

-- How many numbered variants each category has (most are 1-4, but not all).
local FOOTSTEP_MATERIAL_COUNTS = {
	concrete = 4,
	dirt = 4,
	duct = 4,
	grass = 4,
	gravel = 4,
	ladder = 4,
	metal = 4,
	metalgrate = 4,
	mud = 4,
	rubber = 1,
	sand = 4,
	slosh = 4,
	snow = 6,
	tile = 4,
	wade = 8,
	wood = 4,
	woodpanel = 4
}

function Schema:GetFootstepMaterial(position)
	local data = {}
		data.start = position + Vector(0, 0, 4)
		data.endpos = position - Vector(0, 0, 24)
	local trace = util.TraceLine(data)
	local propName = string.lower(util.GetSurfacePropName(trace.SurfaceProps) or "")

	for _, pair in ipairs(FOOTSTEP_MATERIAL_ALIASES) do
		if (propName:find(pair[1], 1, true)) then
			return pair[2]
		end
	end
end

-- Down-maps our custom categories to the (smaller) set of stock HL2
-- footstep materials, for factions without their own registered pack -
-- stock content doesn't have distinct duct/metalgrate/mud/rubber/woodpanel
-- files, so those fall back to their closest stock equivalent.
local FOOTSTEP_STOCK_MATERIAL = {
	duct = "metal",
	metalgrate = "metal",
	mud = "dirt",
	rubber = "metal",
	woodpanel = "wood"
}

-- Some footstep packs (like OTA Heavy's) are real MP3 files, which
-- Source's classic EmitSound can't decode - route those through the
-- netstream/sound.PlayFile system instead, same as MP3 voice lines,
-- audible to anyone near the walker. Genuine WAV files are unaffected.
local FOOTSTEP_MP3_RANGE = 350

function Schema:EmitFootstepSound(client, path)
	if (path:lower():find("%.mp3$")) then
		local recipients = {}

		for _, ply in ipairs(player.GetAll()) do
			if ((ply:GetPos() - client:GetPos()):LengthSqr() <= (FOOTSTEP_MP3_RANGE * FOOTSTEP_MP3_RANGE)) then
				recipients[#recipients + 1] = ply
			end
		end

		netstream.Start(recipients, "PlaySound", path)
	else
		client:EmitSound(path)
	end
end

function Schema:PlayerFootstep(client, position, foot, soundName, volume)
	local factionTable = ix.faction.Get(client:Team())

	if (client:IsRunning()) then
		local runPack = self.footstepRunPacks[client:Team()]

		if (runPack) then
			local index = (client.ixRunFootstepIndex or 0) % runPack.count + 1
			client.ixRunFootstepIndex = index

			self:EmitFootstepSound(client, string.format("foley/%s/%s%d.wav", runPack.folder, runPack.prefix, index))
			return true
		elseif (factionTable.runSounds) then
			self:EmitFootstepSound(client, factionTable.runSounds[foot])
			return true
		end
	end

	-- walking - a per-class override (if registered) always wins, regardless
	-- of surface material
	local character = client:GetCharacter()
	local classInfo = character and ix.class.Get(character:GetClass())
	local classOverride = classInfo and self.footstepClassOverrides[classInfo.uniqueID]

	if (classOverride) then
		local index = (client.ixClassFootstepIndex or 0) % classOverride.count + 1
		client.ixClassFootstepIndex = index

		self:EmitFootstepSound(client, string.format("footsteps/%s/%s%02d.%s", classOverride.folder, classOverride.prefix, index, classOverride.ext))
		return true
	end

	local material = self:GetFootstepMaterial(position)

	if (!material) then
		self:EmitFootstepSound(client, soundName)
		return true
	end

	local folder = self.footstepFactionFolders[client:Team()]

	client.ixFootstepIndex = client.ixFootstepIndex or {}

	local path

	if (folder and FOOTSTEP_MATERIAL_COUNTS[material] and client:IsRunning()) then
		local count = FOOTSTEP_MATERIAL_COUNTS[material]
		local index = (client.ixFootstepIndex[material] or 0) % count + 1
		client.ixFootstepIndex[material] = index

		local fileName = count == 1 and material or (material..index)

		path = string.format("footsteps/%s/%s.wav", folder, fileName)
	else
		-- walking (or no custom pack for this faction/material) - fall back to
		-- the stock HL2 footstep files instead of the named GameSound, since
		-- those are muted client-side to stop the engine's own local-prediction
		-- footstep sound from doubling up with ours (see cl_hooks.lua)
		local stockMaterial = FOOTSTEP_STOCK_MATERIAL[material] or material
		local index = (client.ixFootstepIndex[stockMaterial] or 0) % 4 + 1
		client.ixFootstepIndex[stockMaterial] = index

		path = string.format("player/footsteps/%s%d.wav", stockMaterial, index)
	end

	client:EmitSound(path)
	return true
end

function Schema:PlayerSpawn(client)
	client:SetCanZoom(client:IsCombine())
end

function Schema:PlayerDeath(client, inflicter, attacker)
	if (client:IsCombine()) then
		local location = client:GetArea() or "unknown location"

		self:AddCombineDisplayMessage("@cLostBiosignal")
		self:AddCombineDisplayMessage("@cLostBiosignalLocation", Color(255, 0, 0, 255), location)

		if (IsValid(client.ixScanner) and client.ixScanner:Health() > 0) then
			client.ixScanner:TakeDamage(999)
		end

		local sounds = {"npc/overwatch/radiovoice/on1.wav", "npc/overwatch/radiovoice/lostbiosignalforunit.wav"}
		local chance = math.random(1, 7)

		if (chance == 2) then
			sounds[#sounds + 1] = "npc/overwatch/radiovoice/remainingunitscontain.wav"
		elseif (chance == 3) then
			sounds[#sounds + 1] = "npc/overwatch/radiovoice/reinforcementteamscode3.wav"
		end

		sounds[#sounds + 1] = "npc/overwatch/radiovoice/off4.wav"

		for k, v in ipairs(player.GetAll()) do
			if (v:IsCombine()) then
				ix.util.EmitQueuedSounds(v, sounds, 2, nil, v == client and 100 or 80)
			end
		end
	end
end

function Schema:PlayerNoClip(client)
	if (IsValid(client.ixScanner)) then
		return false
	end
end

function Schema:EntityTakeDamage(entity, dmgInfo)
	if (IsValid(entity.ixPlayer) and entity.ixPlayer:IsScanner()) then
		entity.ixPlayer:SetHealth( math.max(entity:Health(), 0) )

		hook.Run("PlayerHurt", entity.ixPlayer, dmgInfo:GetAttacker(), entity.ixPlayer:Health(), dmgInfo:GetDamage())
	end
end

function Schema:PlayerHurt(client, attacker, health, damage)
	if (health <= 0) then
		return
	end

	if (client:IsCombine() and (client.ixTraumaCooldown or 0) < CurTime()) then
		local text = "External"

		if (damage > 50) then
			text = "Severe"
		end

		client:AddCombineDisplayMessage("@cTrauma", Color(255, 0, 0, 255), text)

		if (health < 25) then
			client:AddCombineDisplayMessage("@cDroppingVitals", Color(255, 0, 0, 255))
		end

		client.ixTraumaCooldown = CurTime() + 15
	end
end

function Schema:PlayerStaminaLost(client)
	client:AddCombineDisplayMessage("@cStaminaLost", Color(255, 255, 0, 255))
end

function Schema:PlayerStaminaGained(client)
	client:AddCombineDisplayMessage("@cStaminaGained", Color(0, 255, 0, 255))
end

function Schema:GetPlayerPainSound(client)
	if (client:IsCombine()) then
		local sound = "NPC_MetroPolice.Pain"

		if (Schema:IsCombineRank(client:Name(), "SCN")) then
			sound = "NPC_CScanner.Pain"
		elseif (Schema:IsCombineRank(client:Name(), "SHIELD")) then
			sound = "NPC_SScanner.Pain"
		end

		return sound
	end
end

function Schema:GetPlayerDeathSound(client)
	if (client:IsCombine()) then
		local sound = "NPC_MetroPolice.Die"

		if (Schema:IsCombineRank(client:Name(), "SCN")) then
			sound = "NPC_CScanner.Die"
		elseif (Schema:IsCombineRank(client:Name(), "SHIELD")) then
			sound = "NPC_SScanner.Die"
		end

		for k, v in ipairs(player.GetAll()) do
			if (v:IsCombine()) then
				v:EmitSound(sound)
			end
		end

		return sound
	end
end

function Schema:OnNPCKilled(npc, attacker, inflictor)
	if (IsValid(npc.ixPlayer)) then
		hook.Run("PlayerDeath", npc.ixPlayer, inflictor, attacker)
	end
end

function Schema:PlayVoiceInfo(speaker, chatType, info, data)
	if (!info.sound) then
		return
	end

	local volume = 80

	if (chatType == "w") then
		volume = 60
	elseif (chatType == "y") then
		volume = 150
	end

	-- info.sound can be a single path, or a table of paths to pick a random one from
	-- each time (e.g. several taunt/reload/idle variants registered under one key)
	local sound = istable(info.sound) and info.sound[math.random(#info.sound)] or info.sound

	-- Some voice packs are real MP3 files (or, previously, MP3 data saved
	-- with a .wav extension) - Source's classic sound system (EmitSound/
	-- surface.PlaySound) only decodes real WAV/PCM and silently plays
	-- nothing for those, so any .mp3 has to go through GMod's BASS-based
	-- client audio system (sound.PlayFile) instead, which can decode MP3.
	local isMP3 = sound:lower():find("%.mp3$") != nil

	if (info.global) then
		-- citywide - everyone hears it
		if (isMP3) then
			netstream.Start(nil, "PlaySound", sound)
		else
			for _, ply in ipairs(player.GetAll()) do
				ply:EmitSound(sound)
			end
		end
	elseif (chatType == "dispatchchannel") then
		-- /dispatchN's audio should only reach the same audience as its chat
		-- text - whichever faction whitelist that Tac channel has (or
		-- everyone, for the everyone-channel)
		local channelInfo = Schema.radioChannels[data and data.channel]
		local recipients = {}

		for _, ply in ipairs(player.GetAll()) do
			if (!channelInfo or !channelInfo.factions or table.HasValue(channelInfo.factions, ply:Team())) then
				recipients[#recipients + 1] = ply
			end
		end

		if (isMP3) then
			netstream.Start(recipients, "PlaySound", sound)
		else
			for _, ply in ipairs(recipients) do
				ply:EmitSound(sound)
			end
		end
	elseif (isMP3) then
		-- normal ic/w/y - sound.PlayFile has no distance falloff, so
		-- approximate "nearby" using the same range the chat text itself uses
		local range = ix.config.Get("chatRange", 280)

		if (chatType == "w") then
			range = range * 0.25
		elseif (chatType == "y") then
			range = range * 2
		end

		local recipients = {}

		for _, ply in ipairs(player.GetAll()) do
			if ((ply:GetPos() - speaker:GetPos()):LengthSqr() <= (range * range)) then
				recipients[#recipients + 1] = ply
			end
		end

		netstream.Start(recipients, "PlaySound", sound)
	else
		local sounds = {sound}

		if (speaker:IsCombine()) then
			speaker.bTypingBeep = nil
			sounds[#sounds + 1] = "NPC_MetroPolice.Radio.Off"
		end

		ix.util.EmitQueuedSounds(speaker, sounds, nil, nil, volume)
	end
end

function Schema:PlayerMessageSend(speaker, chatType, text, anonymous, receivers, rawText, data)
	if (chatType == "ic" or chatType == "w" or chatType == "y" or chatType == "dispatchchannel" or chatType == "dispatchbroadcast") then
		local class = self.voices.GetClass(speaker)

		-- exact match: the whole message is a voice command (e.g. "10-4"), which
		-- replaces the sent text with the phrase's own formatted line
		for k, v in ipairs(class) do
			local info = self.voices.Get(v, rawText)

			if (info) then
				self:PlayVoiceInfo(speaker, chatType, info, data)

				if (speaker:IsCombine()) then
					return string.format("<:: %s ::>", info.text)
				else
					return info.text
				end
			end
		end

		-- /dispatchN only: "<key> <free text>" - the key's own phrase is
		-- prefixed onto whatever the speaker typed after it, e.g.
		-- "radio_escort all administrators to zone" plays the "radio_escort"
		-- line's sound and sends "Escort all administrators to zone"
		if (chatType == "dispatchchannel") then
			local firstWord, rest = rawText:match("^(%S+)%s+(.+)$")

			if (firstWord) then
				for k, v in ipairs(class) do
					local info = self.voices.Get(v, firstWord)

					if (info) then
						self:PlayVoiceInfo(speaker, chatType, info, data)

						local combined = string.format("%s %s", info.text, rest)

						if (speaker:IsCombine()) then
							return string.format("<:: %s ::>", combined)
						else
							return combined
						end
					end
				end
			end
		end

		-- no exact command - if any word in the message matches one of the speaker's
		-- voice keys, still play that line, but leave the sent message exactly as
		-- typed (e.g. "Safeman, move up!" plays the "safeman" callout without
		-- replacing the chat text)
		for k, v in ipairs(class) do
			local stored = self.voices.stored[v]

			if (stored) then
				for word in rawText:lower():gmatch("%a+") do
					local info = stored[word]

					if (info) then
						self:PlayVoiceInfo(speaker, chatType, info, data)

						if (speaker:IsCombine()) then
							return string.format("<:: %s ::>", text)
						end

						return
					end
				end
			end
		end

		if (speaker:IsCombine()) then
			return string.format("<:: %s ::>", text)
		end
	end
end

function Schema:CanPlayerJoinClass(client, class, info)
	if (client:IsRestricted()) then
		client:Notify("You cannot change classes when you are restrained!")

		return false
	end
end

local SCANNER_SOUNDS = {
	"npc/scanner/scanner_blip1.wav",
	"npc/scanner/scanner_scan1.wav",
	"npc/scanner/scanner_scan2.wav",
	"npc/scanner/scanner_scan4.wav",
	"npc/scanner/scanner_scan5.wav",
	"npc/scanner/combat_scan1.wav",
	"npc/scanner/combat_scan2.wav",
	"npc/scanner/combat_scan3.wav",
	"npc/scanner/combat_scan4.wav",
	"npc/scanner/combat_scan5.wav",
	"npc/scanner/cbot_servoscared.wav",
	"npc/scanner/cbot_servochatter.wav"
}

function Schema:KeyPress(client, key)
	if (IsValid(client.ixScanner) and (client.ixScannerDelay or 0) < CurTime()) then
		local source

		if (key == IN_USE) then
			source = SCANNER_SOUNDS[math.random(1, #SCANNER_SOUNDS)]
			client.ixScannerDelay = CurTime() + 1.75
		elseif (key == IN_RELOAD) then
			source = "npc/scanner/scanner_talk"..math.random(1, 2)..".wav"
			client.ixScannerDelay = CurTime() + 10
		elseif (key == IN_WALK) then
			if (client:GetViewEntity() == client.ixScanner) then
				client:SetViewEntity(NULL)
			else
				client:SetViewEntity(client.ixScanner)
			end
		end

		if (source) then
			client.ixScanner:EmitSound(source)
		end
	end
end

function Schema:PlayerSpawnObject(client)
	if (client:IsRestricted() or IsValid(client.ixScanner)) then
		return false
	end
end

function Schema:PlayerSpray(client)
	return true
end

-- IsCombine() only covers MPF/OTA (it's used in ~30 other places for
-- things like door access, restraints, and water/supplement
-- restrictions, so it's not something to broaden lightly) - Overwatch was
-- already special-cased here alongside it for the same reason Conscripts
-- need to be: neither is "combine" by that definition, but both should
-- still get the radio typing beep like MPF/OTA do.
local function CanHearRadioBeep(client)
	return client:IsCombine() or client:Team() == FACTION_OVERWATCH or client:Team() == FACTION_CONSCRIPT
end

netstream.Hook("PlayerChatTextChanged", function(client, key)
	if (CanHearRadioBeep(client) and !client.bTypingBeep
	and (key == "y" or key == "w" or key == "r" or key == "t")) then
		client:EmitSound("NPC_MetroPolice.Radio.On")
		client.bTypingBeep = true
	end
end)

netstream.Hook("PlayerFinishChat", function(client)
	if (CanHearRadioBeep(client) and client.bTypingBeep) then
		client:EmitSound("NPC_MetroPolice.Radio.Off")
		client.bTypingBeep = nil
	end
end)

netstream.Hook("ViewDataUpdate", function(client, target, text)
	if (IsValid(target) and hook.Run("CanPlayerEditData", client, target) and client:GetCharacter() and target:GetCharacter()) then
		local data = {
			text = string.Trim(text:sub(1, 1000)),
			editor = client:GetCharacter():GetName()
		}

		target:GetCharacter():SetData("combineData", data)
		Schema:AddCombineDisplayMessage("@cViewDataFiller", nil, client)
	end
end)

netstream.Hook("ViewObjectivesUpdate", function(client, text)
	if (client:GetCharacter() and hook.Run("CanPlayerEditObjectives", client)) then
		local date = ix.date.Get()
		local data = {
			text = text:sub(1, 1000),
			lastEditPlayer = client:GetCharacter():GetName(),
			lastEditDate = ix.date.GetSerialized(date)
		}

		ix.data.Set("combineObjectives", data, false, true)
		Schema.CombineObjectives = data
		Schema:AddCombineDisplayMessage("@cViewObjectivesFiller", nil, client, date:spanseconds())
	end
end)

--[[
	Civic Points progression system.

	Civic points are the whitelist/promotion currency for the Combine Civil
	Authority career track (Conscripts -> Metropolice Force -> Stabilization
	Forces). Overwatch personnel award them via /awardcivicpoints. Points
	reset to 0 each time a character is promoted into the next faction -
	each stage of the career is earned fresh.

	Point thresholds below are starting defaults, not tuned numbers - adjust
	freely, they only live in this one table.

	IMPORTANT: files under schema/libs/ are auto-included before
	schema/factions/ and schema/classes/ even exist (Helix loads libs,
	then factions, then classes, then the schema's own root files). So the
	FACTION_*/CLASS_* globals below can only be touched lazily - inside a
	function - never in a top-level table built when this file first
	loads. That's why the tables are built by BuildCivicLadders(), called
	from Schema:OnLoaded() once everything actually exists.
]]

function Schema:BuildCivicLadders()
	self.civicLadders = {
		[FACTION_CONSCRIPT] = {
			ranks = {
				{class = CLASS_CONSCRIPT_PFC, points = 10},
				{class = CLASS_CONSCRIPT_SPC, points = 20},
				{class = CLASS_CONSCRIPT_CPL, points = 30},
				{class = CLASS_CONSCRIPT_SGT, points = 40},
				{class = CLASS_CONSCRIPT_SSGT, points = 50},
				{class = CLASS_CONSCRIPT_MSGT, points = 60},
				{class = CLASS_CONSCRIPT_LT, points = 70},
				{class = CLASS_CONSCRIPT_CPT, points = 80},
				{class = CLASS_CONSCRIPT_MAJ, points = 90},
				{class = CLASS_CONSCRIPT_COL, points = 100},
				{class = CLASS_CONSCRIPT_GEN, points = 110},
				{class = CLASS_CONSCRIPT_GOCCF, points = 120}
			},
			nextFaction = FACTION_MPF,
			-- was 60 (Lieutenant's old threshold) - shifted +10 to 70 to
			-- keep "unlocks MPF at Lieutenant" true now that Specialist
			-- pushed every rank after it up by one 10-point step; flag if
			-- you actually wanted this to stay a flat 60
			nextFactionPoints = 70
		},
		[FACTION_MPF] = {
			ranks = {
				{class = CLASS_MPR, points = 0},
				{class = CLASS_MPO, points = 25},
				{class = CLASS_PTL, points = 50},
				{class = CLASS_PSL, points = 75},
				{class = CLASS_RL, points = 100}
			},
			nextFaction = FACTION_OTA,
			nextFactionPoints = 110
		}
	}

	-- Stabilization Forces (OTA) don't use civic points - promotion there is
	-- memory replacement, a deliberate procedure Overwatch orders on a
	-- character rather than something earned. /resleeve advances a
	-- character exactly one step through this order per use.
	self.otaResleeveOrder = {
		CLASS_OTA_GRUNT,
		CLASS_OTA_SOLDIER,
		CLASS_OTA_SHOTGUNNER,
		CLASS_OTA_SUPPRESSOR,
		CLASS_OTA_HEAVY,
		CLASS_OTA_ORDINAL,
		CLASS_OTA_ELITE
	}

	-- Forced naming per faction:
	-- - Conscripts keep their chosen name, prefixed with their current rank
	--   title (e.g. "Captain Max Desmond"). The rank title is just the
	--   class's own name, so no separate table is needed there.
	-- - Metropolice Force drop their chosen name entirely for a callsign:
	--   "[<rank points>] <WORD> <###>", e.g. "[50] JURY 587". The word and
	--   number are picked once at faction transfer and stay fixed; only
	--   the bracketed point count updates as they earn more.
	-- - Stabilization Forces use "<WORD> <###>", e.g. "ECHO 584", where the
	--   word is tied to their current rank (updates on each /resleeve) and
	--   the number is picked once at faction transfer and stays fixed.
	-- These word lists are starting placeholders - rename freely.
	self.mpfCallsignWords = {
		"VICTOR", "PATROL", "JURY", "DEFENDER", "SENTINEL", "WARDEN", "MARSHAL", "ENFORCER", "VANGUARD", "BASTION"
	}

	self.otaCallsignWords = {
		[CLASS_OTA_GRUNT] = "ECHO",
		[CLASS_OTA_SOLDIER] = "SWORD",
		[CLASS_OTA_SHOTGUNNER] = "DELTA",
		[CLASS_OTA_SUPPRESSOR] = "DAGGER",
		[CLASS_OTA_HEAVY] = "WALLHAMMER",
		[CLASS_OTA_ORDINAL] = "ORDINAL",
		[CLASS_OTA_ELITE] = "KING"
	}

	-- Conscript player models have an "epaulettes" bodygroup that visually
	-- tracks rank - starts at 1 for the default Private class, going up by
	-- 1 each rank, capping at 13 for the top rank (General of the Combine
	-- Conscript Forces) with nothing beyond that, same as civic points
	-- themselves just stop mattering once you're at the top of the ladder.
	-- Keyed by class rather than incremented step-by-step so it can't get
	-- out of sync if a promotion ever skips ranks (e.g. a big points
	-- award landing a Private straight at a much higher rank in one go).
	-- This same table also doubles as a general "rank position" lookup for
	-- Schema:GrantConscriptRankItems below.
	self.conscriptEpaulettes = {
		[CLASS_CONSCRIPT_PVT] = 1,
		[CLASS_CONSCRIPT_PFC] = 2,
		[CLASS_CONSCRIPT_SPC] = 3,
		[CLASS_CONSCRIPT_CPL] = 4,
		[CLASS_CONSCRIPT_SGT] = 5,
		[CLASS_CONSCRIPT_SSGT] = 6,
		[CLASS_CONSCRIPT_MSGT] = 7,
		[CLASS_CONSCRIPT_LT] = 8,
		[CLASS_CONSCRIPT_CPT] = 9,
		[CLASS_CONSCRIPT_MAJ] = 10,
		[CLASS_CONSCRIPT_COL] = 11,
		[CLASS_CONSCRIPT_GEN] = 12,
		[CLASS_CONSCRIPT_GOCCF] = 13
	}
end

function Schema:OnLoaded()
	self:BuildCivicLadders()
end

if (SERVER) then
	--- Sets a Conscript character's display name to "<rank title> <chosen name>".
	-- @realm server
	function Schema:UpdateConscriptName(character)
		local class = ix.class.list[character:GetClass()]
		local baseName = character:GetData("baseName")

		if (!class or !baseName) then
			return
		end

		character:SetName(class.name .. " " .. baseName)
	end

	--- Sets a Metropolice Force character's display name to "[<rank points>] <callsign> <number>".
	-- @realm server
	function Schema:UpdateMPFName(character)
		local callsign = character:GetData("callsign")
		local number = character:GetData("callsignNumber")

		if (!callsign or !number) then
			return
		end

		character:SetName("[" .. character:GetData("civicPoints", 0) .. "] " .. callsign .. " " .. number)
	end

	--- Sets a Stabilization Forces character's display name to "<rank word> <number>".
	-- @realm server
	function Schema:UpdateOTAName(character)
		local word = self.otaCallsignWords[character:GetClass()]
		local number = character:GetData("callsignNumber")

		if (!word or !number) then
			return
		end

		character:SetName(word .. " " .. number)
	end

	--- Sets an Overwatch Scanner character's display name to "AW:SCN:<number>".
	-- @realm server
	function Schema:UpdateScannerName(character)
		local number = character:GetData("scannerCallsign")

		if (!number) then
			return
		end

		character:SetName("AW:SCN:" .. number)
	end

	--- Grants a one-time item reward the first time a Conscript character reaches (or, via a big
	-- points jump, passes straight over) a given rank - flagKey guards against granting it again on
	-- a later promotion or character load. Uses the character's current rank POSITION
	-- (Schema.conscriptEpaulettes) rather than an exact class match, so a promotion that skips
	-- ranks in one jump still grants it. Drops the item on the ground if the inventory is full.
	-- @realm server
	function Schema:GrantRankItem(character, flagKey, requiredClass, itemUniqueID)
		if (character:GetData(flagKey)) then
			return
		end

		local rankValue = self.conscriptEpaulettes[character:GetClass()]
		local requiredValue = self.conscriptEpaulettes[requiredClass]

		if (!rankValue or !requiredValue or rankValue < requiredValue) then
			return
		end

		character:SetData(flagKey, true)

		local client = character:GetPlayer()

		if (IsValid(client) and !character:GetInventory():Add(itemUniqueID)) then
			ix.item.Spawn(itemUniqueID, client)
		end
	end

	--- Checks all of the Conscript rank-reward items a character might now qualify for. Safe to call
	-- repeatedly (on every promotion AND on every character load) since GrantRankItem's own flag
	-- stops any of them from being granted twice.
	-- @realm server
	function Schema:GrantConscriptRankItems(character)
		self:GrantRankItem(character, "grantedBlackBeret", CLASS_CONSCRIPT_CPL, "conscript_beret_black")
		self:GrantRankItem(character, "grantedRedBeret", CLASS_CONSCRIPT_LT, "conscript_beret_red")
	end

	--- Adds (or removes, with a negative amount) civic points on a character, then checks for a promotion.
	-- @realm server
	function Schema:AddCivicPoints(character, amount)
		local client = character:GetPlayer()

		if (!IsValid(client)) then
			return
		end

		local points = math.max(0, character:GetData("civicPoints", 0) + amount)
		character:SetData("civicPoints", points)

		client:Notify("You now have " .. points .. " civic points.")

		self:CheckCivicPromotion(character)
	end

	--- Checks a character's civic points against their faction's rank ladder, promoting them (and
	-- transferring them into the next faction, if eligible) as far as their points allow.
	-- @realm server
	function Schema:CheckCivicPromotion(character)
		local client = character:GetPlayer()

		if (!IsValid(client)) then
			return
		end

		local ladder = self.civicLadders[character:GetFaction()]

		if (!ladder) then
			return
		end

		local points = character:GetData("civicPoints", 0)
		local target

		for _, rank in ipairs(ladder.ranks) do
			if (points >= rank.points) then
				target = rank.class
			end
		end

		if (target and target != character:GetClass()) then
			local oldClass = character:GetClass()

			character:SetClass(target)
			hook.Run("PlayerJoinedClass", client, target, oldClass)

			-- refreshes the Conscript "epaulettes" bodygroup (see
			-- Schema.conscriptEpaulettes above) to match the new rank
			-- immediately, rather than waiting for the next respawn
			self:ReapplyOutfitBodygroups(client)

			if (character:GetFaction() == FACTION_CONSCRIPT) then
				self:GrantConscriptRankItems(character)
			end

			client:Notify("You have been promoted!")
		end

		local faction = character:GetFaction()

		if (faction == FACTION_CONSCRIPT) then
			self:UpdateConscriptName(character)
		elseif (faction == FACTION_MPF) then
			self:UpdateMPFName(character)
		end

		if (ladder.nextFaction and points >= ladder.nextFactionPoints) then
			self:GrantFactionWhitelist(client, ladder.nextFaction)
		end
	end

	--- Whitelists a player into a new faction once one of their characters has earned enough
	-- points to graduate. Does NOT transfer their current character - that character stays exactly
	-- as it is (e.g. permanently a Colonel), and the player makes a separate, brand new character in
	-- the newly unlocked faction through the normal character creation menu whenever they want to.
	-- @realm server
	function Schema:GrantFactionWhitelist(client, factionID)
		if (!IsValid(client)) then
			return
		end

		local faction = ix.faction.indices[factionID]

		if (!faction) then
			return
		end

		if (client:HasWhitelist(factionID)) then
			return
		end

		client:SetWhitelisted(factionID, true)

		client:Notify("You have proven yourself worthy of " .. faction.name .. ". You may now create a character in that faction from the character menu.")
	end

	-- NOTE: the actual PlayerLoadedCharacter hook that applies forced names lives in
	-- schema/sv_hooks.lua, not here - this schema already defines Schema:PlayerLoadedCharacter
	-- there, and a second definition here would silently overwrite/be overwritten by it
	-- (function Schema:X() is just Schema.X = function() - last one loaded wins). Always
	-- check for an existing Schema:<hookname> definition elsewhere before adding a new one.

	--- Advances a Stabilization Forces character exactly one step through the memory replacement
	-- order (see Schema.otaResleeveOrder). Returns false with a reason string if the character isn't
	-- in Stabilization Forces or is already at the final stage.
	-- @realm server
	function Schema:ResleeveCharacter(character)
		local client = character:GetPlayer()

		if (!IsValid(client)) then
			return false, "invalid"
		end

		if (character:GetFaction() != FACTION_OTA) then
			return false, "notOTA"
		end

		local order = self.otaResleeveOrder
		local currentIndex

		for i, class in ipairs(order) do
			if (class == character:GetClass()) then
				currentIndex = i
				break
			end
		end

		if (!currentIndex or currentIndex >= #order) then
			return false, "maxStage"
		end

		local target = order[currentIndex + 1]
		local oldClass = character:GetClass()

		character:SetClass(target)
		hook.Run("PlayerJoinedClass", client, target, oldClass)
		self:UpdateOTAName(character)

		client:Notify("You have undergone memory replacement.")

		return true
	end
end

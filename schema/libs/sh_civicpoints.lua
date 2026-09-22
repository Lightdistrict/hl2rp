--[[
	Civic Points progression system.

	Civic points are the whitelist/promotion currency for the Combine Civil
	Authority career track (Conscripts -> Metropolice Force -> Stabilization
	Forces). Overwatch personnel award them via /awardcivicpoints. Points
	reset to 0 each time a character is promoted into the next faction -
	each stage of the career is earned fresh.

	Point thresholds below are starting defaults, not tuned numbers - adjust
	freely, they only live in this one table.
]]

Schema.civicLadders = {
	[FACTION_CONSCRIPT] = {
		ranks = {
			{class = CLASS_CONSCRIPT_PVT, points = 10},
			{class = CLASS_CONSCRIPT_PFC, points = 25},
			{class = CLASS_CONSCRIPT_CPL, points = 45},
			{class = CLASS_CONSCRIPT_SGT, points = 70},
			{class = CLASS_CONSCRIPT_SSGT, points = 100},
			{class = CLASS_CONSCRIPT_MSGT, points = 135},
			{class = CLASS_CONSCRIPT_LT, points = 175},
			{class = CLASS_CONSCRIPT_CPT, points = 220},
			{class = CLASS_CONSCRIPT_MAJ, points = 270},
			{class = CLASS_CONSCRIPT_COL, points = 325}
		},
		nextFaction = FACTION_MPF,
		nextFactionPoints = 400
	},
	[FACTION_MPF] = {
		ranks = {
			{class = CLASS_MPU, points = 50},
			{class = CLASS_EMP, points = 120},
			{class = CLASS_MPF_LEADER, points = 220}
		},
		nextFaction = FACTION_OTA,
		nextFactionPoints = 300
	}
}

--[[
	Stabilization Forces (OTA) don't use civic points - promotion there is
	memory replacement, a deliberate procedure Overwatch orders on a
	character rather than something earned. /resleeve advances a character
	exactly one step through this order per use.
]]
Schema.otaResleeveOrder = {
	CLASS_OWS,
	CLASS_OTA_SOLDIER,
	CLASS_OTA_SHOTGUNNER,
	CLASS_OTA_SUPPRESSOR,
	CLASS_OTA_HEAVY,
	CLASS_OTA_ORDINAL,
	CLASS_EOW
}

if (SERVER) then
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

			client:Notify("You have been promoted!")
		end

		local lastRank = ladder.ranks[#ladder.ranks]

		if (ladder.nextFaction and lastRank and character:GetClass() == lastRank.class
		and points >= ladder.nextFactionPoints) then
			self:PromoteToFaction(character, ladder.nextFaction)
		end
	end

	--- Transfers a character into a new faction, resetting their civic points and assigning them
	-- the new faction's default class.
	-- @realm server
	function Schema:PromoteToFaction(character, factionID)
		local client = character:GetPlayer()

		if (!IsValid(client)) then
			return
		end

		local faction = ix.faction.indices[factionID]

		if (!faction) then
			return
		end

		client:SetWhitelisted(factionID, true)
		character:SetFaction(factionID)
		character:SetData("civicPoints", 0)

		if (faction.OnTransferred) then
			faction:OnTransferred(character)
		end

		character:KickClass()

		client:Notify("You have been promoted into " .. faction.name .. "!")
	end

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

		client:Notify("You have undergone memory replacement.")

		return true
	end
end

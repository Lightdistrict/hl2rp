
ITEM.name = "Radio Set"
ITEM.description = "A large standing radio set. Tap E on it to turn it on or off - hold E to pick it up instead."
ITEM.model = Model("models/alyxintprops/radioset_1_0.mdl")
ITEM.category = "Misc"
ITEM.width = 2
ITEM.height = 2

local SOUND_ON = "music_radio/radio_on.mp3"
local SOUND_OFF = "music_radio/radio_off.mp3"
local FALLBACK_CLIP_LENGTH = 15

local BREEN_SOUNDS = {}

for i = 1, 13 do
	BREEN_SOUNDS[i] = "music_radio/breen/breen_radio_"..i..".mp3"
end

-- keyed by item:GetID() (stable across drop/pickup, unlike entity:EntIndex())
-- so only one loop can ever be running per item instance
local activeLoops = {}

local function NearbyPlayers(pos, range)
	local recipients = {}

	for _, ply in ipairs(player.GetAll()) do
		if ((ply:GetPos() - pos):LengthSqr() <= (range * range)) then
			recipients[#recipients + 1] = ply
		end
	end

	return recipients
end

-- the client that actually hears a clip reports its real length back (see
-- "ixRadioSetPlay"/"ixRadioSetReportLength" in cl_hooks.lua/sv_hooks.lua)
-- so the next clip starts right as this one ends - this fallback only
-- covers the case where nobody was in range to report back at all
local function PlayNextBreenClip(itemID)
	local state = activeLoops[itemID]

	if (!state or !IsValid(state.entity)) then
		activeLoops[itemID] = nil

		return
	end

	local itemTable = state.entity:GetItemTable()

	if (!itemTable or !itemTable:GetData("enabled", false)) then
		activeLoops[itemID] = nil

		return
	end

	local range = ix.config.Get("chatRange", 280)
	local recipients = NearbyPlayers(state.entity:GetPos(), range)

	netstream.Start(recipients, "ixRadioSetPlay", itemID, BREEN_SOUNDS[math.random(#BREEN_SOUNDS)])

	state.reported = false

	timer.Create("ixhl2rpRadioSetFallback"..itemID, FALLBACK_CLIP_LENGTH, 1, function()
		if (!activeLoops[itemID] or activeLoops[itemID].reported) then
			return
		end

		PlayNextBreenClip(itemID)
	end)
end

netstream.Hook("ixRadioSetReportLength", function(client, itemID, length)
	local state = activeLoops[itemID]

	if (!state or state.reported) then
		return
	end

	state.reported = true

	timer.Remove("ixhl2rpRadioSetFallback"..itemID)
	timer.Create("ixhl2rpRadioSetNext"..itemID, math.Clamp(length or FALLBACK_CLIP_LENGTH, 1, 120), 1, function()
		PlayNextBreenClip(itemID)
	end)
end)

local function StartBreenLoop(entity, itemTable)
	local itemID = itemTable:GetID()

	activeLoops[itemID] = {entity = entity}

	PlayNextBreenClip(itemID)
end

local function StopBreenLoop(itemTable)
	local itemID = itemTable:GetID()

	activeLoops[itemID] = nil

	timer.Remove("ixhl2rpRadioSetFallback"..itemID)
	timer.Remove("ixhl2rpRadioSetNext"..itemID)
end

local function ToggleRadioSet(entity, caller)
	local itemTable = entity:GetItemTable()

	if (!itemTable) then
		return
	end

	local enabled = !itemTable:GetData("enabled", false)

	itemTable:SetData("enabled", enabled)

	local range = ix.config.Get("chatRange", 280)
	local recipients = NearbyPlayers(entity:GetPos(), range)

	if (enabled) then
		netstream.Start(recipients, "PlaySound", SOUND_ON)
		StartBreenLoop(entity, itemTable)
	else
		netstream.Start(recipients, "PlaySound", SOUND_OFF)
		StopBreenLoop(itemTable)
	end
end

-- the stock ix_item pickup (ENT:Use in Helix core) is driven by holding E
-- for ix.config.Get("itemPickupTime", 0.5) seconds - the engine calls
-- Use() every tick the key is held, so a press still generating Use()
-- calls once that time elapses is a hold (let the stock pickup above
-- finish); anything shorter means E was tapped and released early -
-- treat that as the on/off toggle instead
function ITEM:OnEntityCreated(entity)
	local baseUse = entity.Use

	function entity:Use(activator, caller)
		local pickupTime = ix.config.Get("itemPickupTime", 0.5)

		if (!self.ixRadioUseStart) then
			self.ixRadioUseStart = CurTime()
			self.ixRadioUseCaller = caller

			timer.Simple(pickupTime, function()
				if (!IsValid(self) or !self.ixRadioUseStart) then
					return
				end

				local heldRecently = (CurTime() - (self.ixRadioLastUse or 0)) < 0.15

				self.ixRadioUseStart = nil

				if (!heldRecently and IsValid(self.ixRadioUseCaller)) then
					ToggleRadioSet(self, self.ixRadioUseCaller)
				end
			end)
		end

		self.ixRadioLastUse = CurTime()

		return baseUse(self, activator, caller)
	end

	-- covers a radio restored still "on" after a server restart, same
	-- class of bug as the gas mask not resuming its breathing loop on load
	if (self:GetData("enabled", false)) then
		StartBreenLoop(entity, self)
	end
end

function ITEM.postHooks.take(item, result)
	if (result == false) then
		return
	end

	item:SetData("enabled", false)
	StopBreenLoop(item)
end

function ITEM:OnRemoved()
	StopBreenLoop(self)
end

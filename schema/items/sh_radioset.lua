
ITEM.name = "Radio Set"
ITEM.description = "A large standing radio set. Tap E on it for the option to turn it on or off - hold E to pick it up instead."
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
-- so only one loop can ever be running per item instance. "what's playing"
-- (this table) and "where it's anchored" (ixRadioSetTrack, sent whenever
-- the item changes hands) are handled separately - that's what lets
-- picking the radio up or dropping it again retarget the sound live,
-- without interrupting whatever clip is currently playing.
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

-- entIndex 0 doesn't exist as a real entity (worldspawn is 0 but is never a
-- valid anchor here), so it's used as "no anchor" instead of -1/nil, which
-- the thirdparty netstream/pon encoder may not round-trip faithfully
local function BroadcastTrack(itemID, trackEntity)
	netstream.Start(player.GetAll(), "ixRadioSetTrack", itemID, IsValid(trackEntity) and trackEntity:EntIndex() or 0)
end

-- broadcasts to everyone, not just players currently nearby - clips are
-- played as real 3D positional audio anchored to whatever ixRadioSetTrack
-- last pointed at (see cl_hooks.lua), so BASS itself continuously
-- attenuates it based on each listener's live distance to that anchor.
-- A nearby-only send-time gate would miss anyone who walks into range
-- after the clip already started, and wouldn't make walking away fade it
-- out either.
local function PlayNextBreenClip(itemID)
	local state = activeLoops[itemID]

	if (!state or !state.item:GetData("enabled", false)) then
		activeLoops[itemID] = nil

		return
	end

	netstream.Start(player.GetAll(), "ixRadioSetPlay", itemID, BREEN_SOUNDS[math.random(#BREEN_SOUNDS)])

	state.reported = false

	timer.Create("ixhl2rpRadioSetFallback"..itemID, FALLBACK_CLIP_LENGTH, 1, function()
		if (!activeLoops[itemID] or activeLoops[itemID].reported) then
			return
		end

		PlayNextBreenClip(itemID)
	end)
end

-- called from schema/sv_hooks.lua's "ixRadioSetReportLength" netstream.Hook -
-- registering that netstream.Hook here directly would run at item-load time
-- (via ix.item.Register), which happens before the thirdparty netstream lib
-- is even included, so the hook has to live in sv_hooks.lua instead
function Schema:HandleRadioSetReportLength(client, itemID, length)
	local state = activeLoops[itemID]

	if (!state or state.reported) then
		return
	end

	state.reported = true

	timer.Remove("ixhl2rpRadioSetFallback"..itemID)
	timer.Create("ixhl2rpRadioSetNext"..itemID, math.Clamp(length or FALLBACK_CLIP_LENGTH, 1, 120), 1, function()
		PlayNextBreenClip(itemID)
	end)
end

-- itemTable.entity must be valid when this is called (true both at the
-- moment it's turned on - CanRun requires a dropped entity - and when
-- resuming after a restart, where OnEntityCreated sets it first)
local function StartBreenLoop(itemTable)
	local itemID = itemTable:GetID()

	if (activeLoops[itemID]) then
		return
	end

	activeLoops[itemID] = {item = itemTable}

	BroadcastTrack(itemID, itemTable.entity)
	PlayNextBreenClip(itemID)
end

-- moves an ALREADY-playing radio's sound to follow a new anchor (the
-- player who just picked it up, or the new entity it was just dropped
-- as) without interrupting whatever clip is currently playing. A no-op if
-- the radio isn't actually on.
local function UpdateBreenLoopTarget(itemTable, trackEntity)
	local itemID = itemTable:GetID()

	if (!activeLoops[itemID]) then
		return
	end

	BroadcastTrack(itemID, trackEntity)
end

local function StopBreenLoop(itemTable)
	local itemID = itemTable:GetID()

	activeLoops[itemID] = nil

	timer.Remove("ixhl2rpRadioSetFallback"..itemID)
	timer.Remove("ixhl2rpRadioSetNext"..itemID)

	-- stopping the loop above only stops scheduling FUTURE clips - the one
	-- already playing on each client's own audio channel keeps going on its
	-- own otherwise, so explicitly tell everyone to cut it off too (clips
	-- are broadcast to everyone now - see PlayNextBreenClip above - so the
	-- stop has to be too, regardless of where the radio currently is)
	netstream.Start(player.GetAll(), "ixRadioSetStop", itemID)
end

-- itemTable must be the REAL, live item instance (e.g. what the dispatcher
-- hands OnRun/postHooks as "item") - entity:GetItemTable() looks tempting
-- but actually returns ix.item.list[...], the STATIC item class definition
-- shared by every Radio Set in the game (used for things like icons), not
-- this specific dropped instance. Calling :GetID() on that always reads 0,
-- which silently filed the breen loop under the wrong activeLoops key and
-- is why turning it off/picking it up couldn't find the loop to stop.
local function ToggleRadioSet(itemTable, caller)
	local entity = itemTable.entity
	local enabled = !itemTable:GetData("enabled", false)

	itemTable:SetData("enabled", enabled)

	-- a dropped item's own SetData isn't networked to clients that don't
	-- own it (nobody owns an unowned world item), so the entity menu's
	-- OnCanRun below - which runs CLIENT-SIDE - would always see the
	-- default/false value no matter what. A plain networked entity var
	-- actually replicates to everyone nearby, so that's what OnCanRun
	-- checks instead; item data is still what's kept/restored on reload.
	entity:SetNWBool("ixRadioEnabled", enabled)

	local range = ix.config.Get("chatRange", 280)
	local recipients = NearbyPlayers(entity:GetPos(), range)

	if (enabled) then
		netstream.Start(recipients, "PlaySound", SOUND_ON)
		StartBreenLoop(itemTable)
	else
		netstream.Start(recipients, "PlaySound", SOUND_OFF)
		StopBreenLoop(itemTable)
	end
end

-- tapping E on a dropped item (releasing +use before the hold-to-pick-up
-- duration elapses) is already handled by stock Helix - it opens a small
-- menu of the item's own functions (anything other than take/combine).
-- Gating these on IsValid(item.entity) means they only ever show up in
-- that ground menu, never in the normal inventory right-click menu, since
-- there's nothing to toggle on/off while it's just sitting in a bag.
--
-- (an earlier version of this item tried to tell a tap and a hold apart
-- itself by overriding the entity's Use() directly - that turned out to be
-- unreliable in practice and broke both the toggle and the stock pickup,
-- so this sticks to the same mechanism the working Combine Radio item
-- already uses for its own Turn On/Turn Off)
ITEM.functions.TurnOn = {
	name = "Turn On",
	OnCanRun = function(item)
		return IsValid(item.entity) and !item.entity:GetNWBool("ixRadioEnabled", false)
	end,
	OnRun = function(item)
		ToggleRadioSet(item, item.player)

		return false
	end
}

ITEM.functions.TurnOff = {
	name = "Turn Off",
	OnCanRun = function(item)
		return IsValid(item.entity) and item.entity:GetNWBool("ixRadioEnabled", false) == true
	end,
	OnRun = function(item)
		ToggleRadioSet(item, item.player)

		return false
	end
}

-- fires both for a fresh drop (possibly re-anchoring an already-playing
-- radio to this new entity) and for a radio restored still "on" after a
-- server restart (same class of bug as the gas mask not resuming its
-- breathing loop on load)
function ITEM:OnEntityCreated(entity)
	self.entity = entity

	if (activeLoops[self:GetID()]) then
		entity:SetNWBool("ixRadioEnabled", true)
		UpdateBreenLoopTarget(self, entity)
	elseif (self:GetData("enabled", false)) then
		entity:SetNWBool("ixRadioEnabled", true)
		StartBreenLoop(self)
	end
end

-- picking it up no longer turns it off - it keeps playing and follows
-- whoever's carrying it until they turn it off or drop it somewhere else
function ITEM.postHooks.take(item, result)
	if (result == false) then
		return
	end

	UpdateBreenLoopTarget(item, item.player)
end

function ITEM:OnRemoved()
	StopBreenLoop(self)
end


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

local function StartBreenLoop(entity, itemTable)
	local itemID = itemTable:GetID()

	if (activeLoops[itemID]) then
		return
	end

	activeLoops[itemID] = {entity = entity}

	PlayNextBreenClip(itemID)
end

local function StopBreenLoop(itemTable)
	local itemID = itemTable:GetID()
	local state = activeLoops[itemID]

	activeLoops[itemID] = nil

	timer.Remove("ixhl2rpRadioSetFallback"..itemID)
	timer.Remove("ixhl2rpRadioSetNext"..itemID)

	-- stopping the loop above only stops scheduling FUTURE clips - the one
	-- already playing on each nearby client's own audio channel keeps going
	-- on its own otherwise, so explicitly tell them to cut it off too
	if (state and IsValid(state.entity)) then
		local range = ix.config.Get("chatRange", 280)
		local recipients = NearbyPlayers(state.entity:GetPos(), range)

		print("[RADIOSET DEBUG] StopBreenLoop itemID="..itemID.." sending stop to "..#recipients.." nearby players")
		netstream.Start(recipients, "ixRadioSetStop", itemID)
	else
		print("[RADIOSET DEBUG] StopBreenLoop itemID="..itemID.." entity gone, broadcasting stop to everyone")
		netstream.Start(player.GetAll(), "ixRadioSetStop", itemID)
	end
end

local function ToggleRadioSet(entity, caller)
	local itemTable = entity:GetItemTable()

	if (!itemTable) then
		return
	end

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
		StartBreenLoop(entity, itemTable)
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
		ToggleRadioSet(item.entity, item.player)

		return false
	end
}

ITEM.functions.TurnOff = {
	name = "Turn Off",
	OnCanRun = function(item)
		return IsValid(item.entity) and item.entity:GetNWBool("ixRadioEnabled", false) == true
	end,
	OnRun = function(item)
		ToggleRadioSet(item.entity, item.player)

		return false
	end
}

-- covers a radio restored still "on" after a server restart, same class
-- of bug as the gas mask not resuming its breathing loop on load
function ITEM:OnEntityCreated(entity)
	if (self:GetData("enabled", false)) then
		entity:SetNWBool("ixRadioEnabled", true)
		StartBreenLoop(entity, self)
	end
end

function ITEM.postHooks.take(item, result)
	print("[RADIOSET DEBUG] postHooks.take fired, result="..tostring(result)..", entity valid="..tostring(IsValid(item.entity)))

	if (result == false) then
		return
	end

	item:SetData("enabled", false)
	StopBreenLoop(item)
end

function ITEM:OnRemoved()
	StopBreenLoop(self)
end

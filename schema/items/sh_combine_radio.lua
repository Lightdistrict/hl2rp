
ITEM.name = "Combine Radio"
ITEM.model = Model("models/gibs/shield_scanner_gib1.mdl")
ITEM.description = "A radio with 4 fixed channels.\nIt is currently turned %s, set to channel %d (%s)."
ITEM.cost = 50

-- shows on the Conscript playermodel's "radio" bodygroup while equipped -
-- separate from being turned on/off (below), same distinction as wearing
-- a helmet vs it having power: you can carry/wear the radio equipped
-- without it being on, or have it on while it's not physically shown
ITEM.bodyGroups = {
	["radio"] = 1
}

-- Inventory drawing
if (CLIENT) then
	function ITEM:PaintOver(item, w, h)
		if (item:GetData("enabled")) then
			surface.SetDrawColor(110, 255, 110, 100)
			surface.DrawRect(w - 14, h - 14, 8, 8)
		end
	end
end

function ITEM:GetDescription()
	local enabled = self:GetData("enabled")
	local channel = self:GetData("channel", 1)
	local info = Schema.radioChannels[channel]

	return string.format(self.description, enabled and "on" or "off", channel, info and info.name or "unknown")
end

function ITEM.postHooks.drop(item, status)
	item:SetData("enabled", false)

	-- dropping it while worn shouldn't leave the bodygroup showing on a
	-- player who no longer has the item at all
	if (item:GetData("equip") and IsValid(item.player)) then
		item:SetData("equip", false)
		Schema:ReapplyOutfitBodygroups(item.player)
	end
end

-- these are MP3 files, which Source's classic EmitSound can't decode, so
-- broadcast them the same way PlayVoiceInfo does for local MP3 voice lines -
-- a netstream to nearby players, played client-side via sound.PlayFile
local function PlayRadioChirp(client, sound)
	local range = ix.config.Get("chatRange", 280)
	local recipients = {}

	for _, ply in ipairs(player.GetAll()) do
		if ((ply:GetPos() - client:GetPos()):LengthSqr() <= (range * range)) then
			recipients[#recipients + 1] = ply
		end
	end

	netstream.Start(recipients, "PlaySound", sound)
end

-- Equipping is what makes the radio show on the player's own model (the
-- "radio" bodygroup above) - split the same way base_outfit splits
-- Equip/EquipUn, and using the same tip/icon keys so it fits right in
-- alongside a clothing item's own equip/unequip options.
ITEM.functions.Equip = {
	name = "equip",
	tip = "equipTip",
	icon = "icon16/tick.png",
	OnCanRun = function(item)
		return !item:GetData("equip", false)
	end,
	OnRun = function(itemTable)
		itemTable:SetData("equip", true)
		Schema:ReapplyOutfitBodygroups(itemTable.player)

		return false
	end
}

ITEM.functions.EquipUn = {
	name = "unequip",
	tip = "unequipTip",
	icon = "icon16/cross.png",
	OnCanRun = function(item)
		return item:GetData("equip", false) == true
	end,
	OnRun = function(itemTable)
		itemTable:SetData("equip", false)
		Schema:ReapplyOutfitBodygroups(itemTable.player)

		return false
	end
}

-- Turning it on/off is a SEPARATE state from being equipped/worn - it
-- controls whether the radio can send/receive on a channel at all, not
-- whether it's visible on the player's model.
ITEM.functions.TurnOn = {
	name = "Turn On",
	OnCanRun = function(item)
		return !item:GetData("enabled", false)
	end,
	OnRun = function(itemTable)
		local client = itemTable.player

		itemTable:SetData("enabled", true)

		-- always comes on tuned to the everyone-channel, regardless of
		-- what it was last left on
		itemTable:SetData("channel", 1)

		PlayRadioChirp(client, "foley/handheld_radio/choreo_radiochirp_start.mp3")

		return false
	end
}

ITEM.functions.TurnOff = {
	name = "Turn Off",
	OnCanRun = function(item)
		return item:GetData("enabled", false) == true
	end,
	OnRun = function(itemTable)
		itemTable:SetData("enabled", false)

		PlayRadioChirp(itemTable.player, "foley/handheld_radio/choreo_radiochirp_end.mp3")

		return false
	end
}

local function SwitchChannel(itemTable, nextChannel)
	local client = itemTable.player

	if (!itemTable:GetData("enabled", false)) then
		client:Notify("Turn your radio on first.")

		return false
	end

	local info = Schema.radioChannels[nextChannel]

	if (info and info.factions and !table.HasValue(info.factions, client:Team())) then
		client:Notify("You cannot switch to this channel.")

		return false
	end

	itemTable:SetData("channel", nextChannel)
	client:Notify(string.format("Radio set to channel %d (%s).", nextChannel, info and info.name or "unknown"))

	return false
end

ITEM.functions.ChannelUp = {
	name = "Channel Up",
	OnCanRun = function(item)
		return item:GetData("enabled", false)
	end,
	OnRun = function(itemTable)
		return SwitchChannel(itemTable, (itemTable:GetData("channel", 1) % 4) + 1)
	end
}

ITEM.functions.ChannelDown = {
	name = "Channel Down",
	OnCanRun = function(item)
		return item:GetData("enabled", false)
	end,
	OnRun = function(itemTable)
		return SwitchChannel(itemTable, ((itemTable:GetData("channel", 1) + 2) % 4) + 1)
	end
}

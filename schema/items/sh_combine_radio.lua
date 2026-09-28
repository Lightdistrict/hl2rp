
ITEM.name = "Combine Radio"
ITEM.model = Model("models/gibs/shield_scanner_gib1.mdl")
ITEM.description = "A radio with 4 fixed channels.\nIt is currently turned %s, set to channel %d (%s)."
ITEM.cost = 50

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

ITEM.functions.Toggle = {
	OnRun = function(itemTable)
		local enabled = !itemTable:GetData("enabled", false)
		local client = itemTable.player

		itemTable:SetData("enabled", enabled)

		-- always come on tuned to the everyone-channel, regardless of what
		-- it was last left on
		if (enabled) then
			itemTable:SetData("channel", 1)
		end

		PlayRadioChirp(client, enabled and "foley/handheld_radio/choreo_radiochirp_start.mp3"
			or "foley/handheld_radio/choreo_radiochirp_end.mp3")

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

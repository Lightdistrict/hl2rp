
ITEM.name = "Combine Radio"
ITEM.model = Model("models/deadbodies/dead_male_civilian_radio.mdl")
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

ITEM.functions.Toggle = {
	OnRun = function(itemTable)
		itemTable:SetData("enabled", !itemTable:GetData("enabled", false))
		itemTable.player:EmitSound("buttons/lever7.wav", 50, math.random(170, 180), 0.25)

		return false
	end
}

ITEM.functions.Channel = {
	OnRun = function(itemTable)
		local channel = (itemTable:GetData("channel", 1) % 4) + 1
		local info = Schema.radioChannels[channel]

		itemTable:SetData("channel", channel)
		itemTable.player:Notify(string.format("Radio set to channel %d (%s).", channel, info and info.name or "unknown"))

		return false
	end
}

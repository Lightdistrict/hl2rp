-- Adds a skin selector to character creation, shown right after the model
-- grid, with a live-updating preview. Currently only shown for Conscripts,
-- since that's the faction that asked for it - Schema.charCreateSkinFactions
-- lists which factions get this control.
Schema.charCreateSkinFactions = Schema.charCreateSkinFactions or {FACTION_CONSCRIPT}

ix.char.RegisterVar("skin", {
	index = 3.5, -- right after "model" (3), before "attributes" (4)
	default = 0,

	OnDisplay = function(self, container, payload)
		local panel = container:Add("DPanel")
		panel:Dock(TOP)
		panel:SetTall(150)
		panel.Paint = function(this, w, h)
			derma.SkinFunc("DrawImportantBackground", 0, 0, w, h, Color(255, 255, 255, 25))
		end

		local label = panel:Add("DLabel")
		label:Dock(BOTTOM)
		label:SetTall(24)
		label:SetContentAlignment(5)
		label:SetFont("ixMenuButtonFont")
		label:SetText("Skin")

		local left = panel:Add("DButton")
		left:Dock(LEFT)
		left:SetWide(36)
		left:SetText("<")

		local right = panel:Add("DButton")
		right:Dock(RIGHT)
		right:SetWide(36)
		right:SetText(">")

		local preview = panel:Add("ixModelPanel")
		preview:Dock(FILL)
		preview:SetFOV(35)

		payload.skin = 0

		local function GetModelPath()
			local faction = ix.faction.indices[payload.faction]

			if (!faction) then
				return
			end

			local model = faction:GetModels(LocalPlayer())[payload.model]

			if (!model) then
				return
			end

			return isstring(model) and model or model[1]
		end

		local function Refresh()
			local path = GetModelPath()

			if (!path) then
				label:SetText("Skin")
				return
			end

			preview:SetModel(path, payload.skin)

			local count = IsValid(preview.Entity) and preview.Entity:SkinCount() or 1
			label:SetText(string.format("Skin %d / %d", payload.skin + 1, math.max(count, 1)))
		end

		left.DoClick = function()
			local count = IsValid(preview.Entity) and preview.Entity:SkinCount() or 1

			payload.skin = (payload.skin - 1) % math.max(count, 1)
			payload:Set("skin", payload.skin)
			Refresh()
		end

		right.DoClick = function()
			local count = IsValid(preview.Entity) and preview.Entity:SkinCount() or 1

			payload.skin = (payload.skin + 1) % math.max(count, 1)
			payload:Set("skin", payload.skin)
			Refresh()
		end

		-- re-sync when the player picks a different model
		payload:AddHook("model", function(value)
			payload.skin = 0
			Refresh()
		end)

		Refresh()

		return panel
	end,

	OnAdjust = function(self, client, data, value, newData)
		if (!table.HasValue(Schema.charCreateSkinFactions, data.faction)) then
			return
		end

		newData.data = newData.data or {}
		newData.data.skin = tonumber(value) or 0
	end,

	ShouldDisplay = function(self, container, payload)
		return table.HasValue(Schema.charCreateSkinFactions, payload.faction)
	end
})

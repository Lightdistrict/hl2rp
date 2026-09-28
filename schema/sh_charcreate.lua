-- Adds a skin selector to character creation, shown right after the model
-- grid. Currently only for Conscripts, since that's the faction that asked
-- for it - Schema.charCreateSkinFactions lists which factions get this.
-- Reuses the existing model preview panels (factionModel/descriptionModel/
-- attributesModel) already on screen - no separate preview of its own.
Schema.charCreateSkinFactions = Schema.charCreateSkinFactions or {FACTION_CONSCRIPT}

ix.char.RegisterVar("skin", {
	index = 3.5, -- right after "model" (3), before "attributes" (4)
	default = 0,

	OnDisplay = function(self, container, payload)
		local panel = container:Add("DPanel")
		panel:Dock(TOP)
		panel:DockMargin(0, 4, 0, 4)
		panel:SetTall(30)
		panel.Paint = nil

		local left = panel:Add("DButton")
		left:Dock(LEFT)
		left:SetWide(30)
		left:SetText("<")

		local right = panel:Add("DButton")
		right:Dock(RIGHT)
		right:SetWide(30)
		right:SetText(">")

		local label = panel:Add("DLabel")
		label:Dock(FILL)
		label:SetContentAlignment(5)
		label:SetFont("ixMenuButtonLabelFont")
		label:SetText("Skin")

		payload.skin = 0

		-- the char creation panel (ixCharMenuNew) is two levels up from this
		-- var's container: container == charMenu.descriptionPanel, whose
		-- parent is charMenu.description, whose parent is charMenu itself
		local function GetCharMenu()
			local description = container:GetParent()
			return IsValid(description) and description:GetParent() or nil
		end

		local function Refresh()
			-- this panel gets torn down and rebuilt every time the character
			-- creation menu repopulates (e.g. navigating between steps), but
			-- the payload hook below is never removed - once that happens,
			-- this closure's own label/panel are stale, so bail out quietly
			-- instead of erroring on a destroyed panel
			if (!IsValid(label)) then
				return
			end

			local charMenu = GetCharMenu()
			local reference = IsValid(charMenu) and charMenu.descriptionModel

			if (!IsValid(reference) or !IsValid(reference.Entity)) then
				label:SetText("Skin")
				return
			end

			local count = math.max(reference.Entity:SkinCount(), 1)
			payload.skin = payload.skin % count

			for _, key in ipairs({"factionModel", "descriptionModel", "attributesModel"}) do
				local modelPanel = charMenu[key]

				if (IsValid(modelPanel) and IsValid(modelPanel.Entity)) then
					modelPanel.Entity:SetSkin(payload.skin)
				end
			end

			label:SetText(string.format("Skin %d / %d", payload.skin + 1, count))
		end

		left.DoClick = function()
			payload.skin = payload.skin - 1
			Refresh()
			payload:Set("skin", payload.skin)
		end

		right.DoClick = function()
			payload.skin = payload.skin + 1
			Refresh()
			payload:Set("skin", payload.skin)
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


-- The walking player's own footstep sound comes from a client-side movement
-- prediction path the engine handles internally - it isn't actually gated
-- by the PlayerFootstep Lua hook's return value (that hook only reliably
-- controls what OTHER players hear about you). Since Schema:PlayerFootstep
-- (sv_hooks.lua) now always networks an explicit raw footstep sound to
-- everyone, including the walker, the only way to stop the engine's own
-- local copy from playing alongside it is to mute the underlying stock
-- GameSound scripts directly. If a surface still plays a default sound on
-- top of ours, the material's stock name is probably missing from this
-- list - tell me which surface and I'll add it.
local FOOTSTEP_MUTE_NAMES = {
	"Player.FootstepConcrete",
	"Player.FootstepDirt",
	"Player.FootstepGrass",
	"Player.FootstepGravel",
	"Player.FootstepLadder",
	"Player.FootstepMetal",
	"Player.FootstepSand",
	"Player.FootstepSlosh",
	"Player.FootstepSnow",
	"Player.FootstepTile",
	"Player.FootstepWade",
	"Player.FootstepWood",
	-- MPF's running sound overlap isn't the material-based prediction above -
	-- these are baked into the metrocop model's own footstep animation
	-- events, which fire independently of the PlayerFootstep hook entirely,
	-- so they play alongside our custom run pack unless muted the same way.
	"NPC_MetroPolice.RunFootstepLeft",
	"NPC_MetroPolice.RunFootstepRight"
}

for _, name in ipairs(FOOTSTEP_MUTE_NAMES) do
	sound.Add({
		name = name,
		channel = CHAN_STATIC,
		volume = 0,
		level = 20,
		pitch = 100,
		sound = "common/null.wav"
	})
end

function Schema:PopulateCharacterInfo(client, character, tooltip)
	if (client:IsRestricted()) then
		local panel = tooltip:AddRowAfter("name", "ziptie")
		panel:SetBackgroundColor(derma.GetColor("Warning", tooltip))
		panel:SetText(L("tiedUp"))
		panel:SizeToContents()
	elseif (client:GetNetVar("tying")) then
		local panel = tooltip:AddRowAfter("name", "ziptie")
		panel:SetBackgroundColor(derma.GetColor("Warning", tooltip))
		panel:SetText(L("beingTied"))
		panel:SizeToContents()
	elseif (client:GetNetVar("untying")) then
		local panel = tooltip:AddRowAfter("name", "ziptie")
		panel:SetBackgroundColor(derma.GetColor("Warning", tooltip))
		panel:SetText(L("beingUntied"))
		panel:SizeToContents()
	end
end

local COMMAND_PREFIX = "/"

function Schema:ChatTextChanged(text)
	if (LocalPlayer():IsCombine() or LocalPlayer():Team() == FACTION_OVERWATCH) then
		local key = nil

		if (text == COMMAND_PREFIX .. "radio " or text == COMMAND_PREFIX .. "r ") then
			key = "r"
		elseif (text == COMMAND_PREFIX .. "w ") then
			key = "w"
		elseif (text == COMMAND_PREFIX .. "y ") then
			key = "y"
		elseif (text:sub(1, 1):match("%w")) then
			key = "t"
		end

		if (key) then
			netstream.Start("PlayerChatTextChanged", key)
		end
	end
end

function Schema:FinishChat()
	netstream.Start("PlayerFinishChat")
end

function Schema:CanPlayerJoinClass(client, class, info)
	return false
end

function Schema:CharacterLoaded(character)
	if (character:IsCombine()) then
		vgui.Create("ixCombineDisplay")
	elseif (IsValid(ix.gui.combine)) then
		ix.gui.combine:Remove()
	end
end

function Schema:PlayerFootstep(client, position, foot, soundName, volume)
	return true
end

local COLOR_BLACK_WHITE = {
	["$pp_colour_addr"] = 0,
	["$pp_colour_addg"] = 0,
	["$pp_colour_addb"] = 0,
	["$pp_colour_brightness"] = 0,
	["$pp_colour_contrast"] = 1.5,
	["$pp_colour_colour"] = 0,
	["$pp_colour_mulr"] = 0,
	["$pp_colour_mulg"] = 0,
	["$pp_colour_mulb"] = 0
}

local combineOverlay = ix.util.GetMaterial("effects/combine_binocoverlay")
local scannerFirstPerson = false

function Schema:RenderScreenspaceEffects()
	local colorModify = {}
	colorModify["$pp_colour_colour"] = 0.77

	if (system.IsWindows()) then
		colorModify["$pp_colour_brightness"] = -0.02
		colorModify["$pp_colour_contrast"] = 1.2
	else
		colorModify["$pp_colour_brightness"] = 0
		colorModify["$pp_colour_contrast"] = 1
	end

	if (scannerFirstPerson) then
		COLOR_BLACK_WHITE["$pp_colour_brightness"] = 0.05 + math.sin(RealTime() * 10) * 0.01
		colorModify = COLOR_BLACK_WHITE
	end

	DrawColorModify(colorModify)

	if (LocalPlayer():IsCombine()) then
		render.UpdateScreenEffectTexture()

		combineOverlay:SetFloat("$alpha", 0.5)
		combineOverlay:SetInt("$ignorez", 1)

		render.SetMaterial(combineOverlay)
		render.DrawScreenQuad()
	end
end

function Schema:PreDrawOpaqueRenderables()
	local viewEntity = LocalPlayer():GetViewEntity()

	if (IsValid(viewEntity) and viewEntity:GetClass():find("scanner")) then
		self.LastViewEntity = viewEntity
		self.LastViewEntity:SetNoDraw(true)

		scannerFirstPerson = true
		return
	end

	if (self.LastViewEntity != viewEntity) then
		if (IsValid(self.LastViewEntity)) then
			self.LastViewEntity:SetNoDraw(false)
		end

		self.LastViewEntity = nil
		scannerFirstPerson = false
	end
end

function Schema:ShouldDrawCrosshair()
	if (scannerFirstPerson) then
		return false
	end
end

function Schema:AdjustMouseSensitivity()
	if (scannerFirstPerson) then
		return 0.3
	end
end

-- creates labels in the status screen
function Schema:CreateCharacterInfo(panel)
	if (LocalPlayer():Team() == FACTION_CITIZEN) then
		panel.cid = panel:Add("ixListRow")
		panel.cid:SetList(panel.list)
		panel.cid:Dock(TOP)
		panel.cid:DockMargin(0, 0, 0, 8)
	end

	if (Schema.civicLadders[LocalPlayer():Team()]) then
		panel.civicPoints = panel:Add("ixListRow")
		panel.civicPoints:SetList(panel.list)
		panel.civicPoints:Dock(TOP)
		panel.civicPoints:DockMargin(0, 0, 0, 8)
	end
end

-- populates labels in the status screen
function Schema:UpdateCharacterInfo(panel, character)
	if (LocalPlayer():Team() == FACTION_CITIZEN) then
		panel.cid:SetLabelText(L("citizenid"))
		panel.cid:SetText(string.format("##%s", LocalPlayer():GetCharacter():GetData("cid") or "UNKNOWN"))
		panel.cid:SizeToContents()
	end

	if (IsValid(panel.civicPoints)) then
		character = character or LocalPlayer():GetCharacter()

		local label = LocalPlayer():Team() == FACTION_MPF and "Rank Points" or "Civic Points"

		panel.civicPoints:SetLabelText(label)
		panel.civicPoints:SetText(tostring(character:GetData("civicPoints", 0)))
		panel.civicPoints:SizeToContents()
	end
end

function Schema:BuildBusinessMenu(panel)
	local bHasItems = false

	for k, _ in pairs(ix.item.list) do
		if (hook.Run("CanPlayerUseBusiness", LocalPlayer(), k) != false) then
			bHasItems = true

			break
		end
	end

	return bHasItems
end

function Schema:PopulateHelpMenu(tabs)
	tabs["voices"] = function(container)
		local classes = {}

		for k, v in pairs(Schema.voices.classes) do
			if (v.condition(LocalPlayer())) then
				classes[#classes + 1] = k
			end
		end

		if (#classes < 1) then
			local info = container:Add("DLabel")
			info:SetFont("ixSmallFont")
			info:SetText("You do not have access to any voice lines!")
			info:SetContentAlignment(5)
			info:SetTextColor(color_white)
			info:SetExpensiveShadow(1, color_black)
			info:Dock(TOP)
			info:DockMargin(0, 0, 0, 8)
			info:SizeToContents()
			info:SetTall(info:GetTall() + 16)

			info.Paint = function(_, width, height)
				surface.SetDrawColor(ColorAlpha(derma.GetColor("Error", info), 160))
				surface.DrawRect(0, 0, width, height)
			end

			return
		end

		table.sort(classes, function(a, b)
			return a < b
		end)

		for _, class in ipairs(classes) do
			local category = container:Add("Panel")
			category:Dock(TOP)
			category:DockMargin(0, 0, 0, 8)
			category:DockPadding(8, 8, 8, 8)
			category.Paint = function(_, width, height)
				surface.SetDrawColor(Color(0, 0, 0, 66))
				surface.DrawRect(0, 0, width, height)
			end

			local categoryLabel = category:Add("DLabel")
			categoryLabel:SetFont("ixMediumLightFont")
			categoryLabel:SetText(class:upper())
			categoryLabel:Dock(FILL)
			categoryLabel:SetTextColor(color_white)
			categoryLabel:SetExpensiveShadow(1, color_black)
			categoryLabel:SizeToContents()
			category:SizeToChildren(true, true)

			for command, info in SortedPairs(self.voices.stored[class] or {}) do
				local title = container:Add("DLabel")
				title:SetFont("ixMediumLightFont")
				title:SetText(command:upper())
				title:Dock(TOP)
				title:SetTextColor(ix.config.Get("color"))
				title:SetExpensiveShadow(1, color_black)
				title:SizeToContents()

				local description = container:Add("DLabel")
				description:SetFont("ixSmallFont")
				description:SetText(info.text)
				description:Dock(TOP)
				description:SetTextColor(color_white)
				description:SetExpensiveShadow(1, color_black)
				description:SetWrap(true)
				description:SetAutoStretchVertical(true)
				description:SizeToContents()
				description:DockMargin(0, 0, 0, 8)
			end
		end
	end
end

netstream.Hook("CombineDisplayMessage", function(text, color, arguments)
	if (IsValid(ix.gui.combine)) then
		ix.gui.combine:AddLine(text, color, nil, unpack(arguments))
	end
end)

-- some voice packs are actually MP3 data saved with a .wav extension, which
-- EmitSound/surface.PlaySound can't decode - sound.PlayFile uses GMod's
-- BASS-based audio system instead, which handles MP3 fine. The parameter is
-- deliberately not named "sound" - that would shadow the sound.* library.
netstream.Hook("PlaySound", function(soundPath)
	sound.PlayFile("sound/"..soundPath, "noplay", function(station, errorID, errorName)
		if (IsValid(station)) then
			station:Play()
		end
	end)
end)

netstream.Hook("Frequency", function(oldFrequency)
	Derma_StringRequest("Frequency", "What would you like to set the frequency to?", oldFrequency, function(text)
		ix.command.Send("SetFreq", text)
	end)
end)

netstream.Hook("ViewData", function(target, cid, data)
	Schema:AddCombineDisplayMessage("@cViewData")
	vgui.Create("ixViewData"):Populate(target, cid, data)
end)

-- Helix's own inventory grid icon (vgui "ixInventory", core/derma/
-- cl_inventory.lua - the uirework_inventory plugin ships an unmodified
-- copy of the same file) calls its icon panel's :SetModel(model, skin)
-- with only two arguments, even though SpawnIcon's real :SetModel signature
-- is (model, skin, bodygroups). That means an item's own bodygroups never
-- reach its inventory icon - it always renders with the model's default
-- bodygroup state, even for items (like our recolored berets) whose whole
-- visual identity IS a bodygroup change.
--
-- Reads ITEM.worldBodyGroups, not ITEM.bodyGroups - same reasoning as
-- Schema:ApplyItemBodyGroups in sv_hooks.lua: the icon renders ITEM.model,
-- a standalone prop that can have entirely different bodygroups (or none)
-- from the player model ITEM.bodyGroups targets.
--
-- SpawnIcon:SetModel's bodygroups table is keyed by numeric bodygroup
-- index, but ours is keyed by name (to match FindBodygroupByName elsewhere
-- and survive the model being re-exported with different indices) - spin
-- up a throwaway clientside model just to resolve names to indices, then
-- call the icon panel's own public :SetModel again with all three
-- arguments so it rebuilds its preview correctly the first time.
local function ResolveBodyGroupIndices(model, groups)
	local scratch = ClientsideModel(model, RENDERGROUP_OTHER)

	if (!IsValid(scratch)) then
		return nil
	end

	local resolved = {}

	for name, value in pairs(groups) do
		local index = scratch:FindBodygroupByName(name)

		if (index > -1) then
			resolved[index] = value
		end
	end

	scratch:Remove()

	return resolved
end

-- PostGamemodeLoaded had already fired by the time this file loaded (no
-- debug output at all showed up, even with the item visible in the
-- inventory) - schema client files load after that point, not before it -
-- so patch immediately instead. Schema files load after core Helix and
-- any UI plugins (uirework_inventory included) have already registered
-- their vgui panels, so "ixInventory" should already exist here.
local inventoryTable = vgui.GetControlTable("ixInventory")

print("[ixhl2rp icon debug] ixInventory table found=", tostring(inventoryTable != nil),
	"has AddIcon=", tostring(inventoryTable != nil and inventoryTable.AddIcon != nil))

if (inventoryTable and inventoryTable.AddIcon) then
	local BaseAddIcon = inventoryTable.AddIcon

	function inventoryTable:AddIcon(model, x, y, w, h, skin)
		local panel = BaseAddIcon(self, model, x, y, w, h, skin)

		local itemTable = IsValid(panel) and panel.GetItemTable and panel:GetItemTable()

		if (itemTable and istable(itemTable.worldBodyGroups)) then
			local resolved = ResolveBodyGroupIndices(model, itemTable.worldBodyGroups)

			-- TEMPORARY debug output - two attempts at this fix haven't
			-- worked, so print exactly what's happening instead of guessing
			-- a third time. Tell me what this prints in the client console
			-- (~ key) after opening your inventory with the item visible.
			print("[ixhl2rp icon debug]", itemTable.uniqueID,
				"resolved=", resolved and table.ToString(resolved) or "NIL",
				"panel.Icon valid=", tostring(IsValid(panel.Icon)),
				"panel.Icon has RebuildSpawnIconEx=", tostring(IsValid(panel.Icon) and panel.Icon.RebuildSpawnIconEx != nil))

			if (resolved and !table.IsEmpty(resolved)) then
				panel:SetModel(model, skin, resolved)

				if (IsValid(panel.Icon) and panel.Icon.RebuildSpawnIconEx) then
					local ok, err = pcall(function() panel.Icon:RebuildSpawnIconEx({}) end)
					print("[ixhl2rp icon debug] RebuildSpawnIconEx ok=", ok, "err=", err)
				end
			end
		end

		return panel
	end
end

netstream.Hook("ViewObjectives", function(data)
	Schema:AddCombineDisplayMessage("@cViewObjectives")
	vgui.Create("ixViewObjectives"):Populate(data)
end)

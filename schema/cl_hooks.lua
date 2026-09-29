
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
	-- IsCombine() only covers MPF/OTA - Overwatch was already special-cased
	-- here alongside it, same reason Conscript needs to be too (see the
	-- matching CanHearRadioBeep helper server-side in sv_hooks.lua, which
	-- this client-side gate has to mirror or the server never even gets a
	-- PlayerChatTextChanged netstream message to react to for Conscripts)
	local client = LocalPlayer()

	-- only /radio and /r should make the radio-typing noise - this used to
	-- also fire for /w, /y, and even plain IC talk (any message starting
	-- with a letter matched the old catch-all branch), which is why saying
	-- something as ordinary as "hi" was incorrectly beeping
	if ((client:IsCombine() or client:Team() == FACTION_OVERWATCH or client:Team() == FACTION_CONSCRIPT)
	and (text == COMMAND_PREFIX .. "radio " or text == COMMAND_PREFIX .. "r ")) then
		netstream.Start("PlayerChatTextChanged", "r")
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

-- ABANDONED: tried to make the inventory grid icon reflect an item's
-- worldBodyGroups (Helix's stock AddIcon never passes bodygroups through
-- to the icon panel, only model+skin). Every attempt either silently did
-- nothing, errored on a wrong argument type, or - calling the icon
-- panel's own :SetModel a second time with a bodygroup string, which by
-- itself doesn't error - visibly corrupted the icon's rendering/framing
-- entirely. panel.Icon is a native (C++-backed) panel with no inspectable
-- Lua-side state (pairs() on it errors with "table expected, got
-- userdata"), so there's no way to safely debug or fix this further
-- without hands-on access to the actual client. Reverted - the inventory
-- icon just shows the model's default bodygroup state, same as before any
-- of this was attempted. The dropped-world-item fix (sv_hooks.lua /
-- Schema:ApplyItemBodyGroups) is unaffected and confirmed working.

netstream.Hook("ViewObjectives", function(data)
	Schema:AddCombineDisplayMessage("@cViewObjectives")
	vgui.Create("ixViewObjectives"):Populate(data)
end)

-- Helix's stock ixModelPanel (core/derma/cl_modelpanel.lua) calls
-- hook.Run("DrawHelixModelView", self, self.Entity) / "PostDrawHelixModelView"
-- during its own DrawModel() - a real, built-in extension point for drawing
-- extra things onto a model preview, distinct from (and much safer than)
-- the icon panel patching attempted and abandoned above. The inventory
-- tab's character preview (uirework_inventory's cl_inventory.lua) already
-- copies the live player's bodygroups/submaterials onto its preview entity
-- every frame via its own LayoutEntity override - that's why clothing
-- shows correctly there - but nothing copies over a held weapon, since
-- weapons aren't bodygroups, they're a separate world model attached at a
-- hand bone/attachment point.
--
-- This attaches the local player's CURRENT weapon's world model to the
-- preview entity's right-hand attachment ("anim_attachment_RH", the
-- standard HL2/Source biped weapon-hold attachment - present on stock HL2
-- citizen/combine skeletons, which the Conscript models are built on).
--
-- Every weapon's world model has its own natural orientation/origin baked
-- in by whoever made it, so no single position/angle looks right sitting
-- directly on the attachment for every weapon - each one needs its own
-- small correction on top, same underlying problem as viewmodel
-- positioning. Schema.previewWeaponOffsets holds those corrections,
-- keyed by weapon class, as a LOCAL offset relative to the attachment
-- (not a world-space one) so it stays correct regardless of how the
-- player is angled. Tuned live via ix_tune_weapon_preview below as
-- weapons are found to look wrong.
Schema.previewWeaponOffsets = Schema.previewWeaponOffsets or {
	["tfa_suppressor"] = {pos = Vector(15.00, 0.00, 0.00), ang = Angle(0.00, 180.00, 360.00)},
	["tfa_heavyshotgun"] = {pos = Vector(13.00, 0.00, 1.00), ang = Angle(0.00, 180.00, 0.00)},
	["tfa_ocipr"] = {pos = Vector(15.00, 0.00, 0.00), ang = Angle(0.00, 180.00, 0.00)},
	["tfa_osips"] = {pos = Vector(12.00, 0.00, 0.00), ang = Angle(0.00, 180.00, 0.00)},
	["ix_stunstick"] = {pos = Vector(2.00, 0.00, 8.00), ang = Angle(90.00, 360.00, 180.00)},
	["tfa_hl2r_shotgun"] = {pos = Vector(14.00, 0.00, 0.00), ang = Angle(0.00, 180.00, 0.00)}
}

local PREVIEW_WEAPON_ATTACHMENT = "anim_attachment_RH"
local previewWeaponEntity

local function GetPreviewWeaponEntity(model)
	if (!IsValid(previewWeaponEntity) or previewWeaponEntity:GetModel() != model) then
		if (IsValid(previewWeaponEntity)) then
			previewWeaponEntity:Remove()
		end

		previewWeaponEntity = ClientsideModel(model, RENDERGROUP_OPAQUE)

		if (IsValid(previewWeaponEntity)) then
			previewWeaponEntity:SetNoDraw(true)
		end
	end

	return previewWeaponEntity
end

hook.Add("DrawHelixModelView", "ixhl2rpPreviewHeldWeapon", function(panel, entity)
	local weapon = LocalPlayer():GetActiveWeapon()

	if (!IsValid(weapon) or !IsValid(entity)) then
		return
	end

	-- enableHook (below) makes DrawHelixModelView fire on EVERY ixModelPanel,
	-- not just this one inventory preview (character creation, scoreboard,
	-- etc. all use the same panel class) - only draw a weapon on a preview
	-- that's actually showing the local player's own current model, so
	-- other previews (a different model being previewed, or someone else's)
	-- don't get a weapon that doesn't belong there
	if (entity:GetModel() != LocalPlayer():GetModel()) then
		return
	end

	-- GetWorldModel() isn't a real method on Weapon - the correct one is
	-- GetWeaponWorldModel() (confirmed via the GMod wiki after the wrong
	-- name errored live: "attempt to call method 'GetWorldModel' (a nil
	-- value)")
	local worldModel = weapon:GetWeaponWorldModel()

	if (!worldModel or worldModel == "") then
		return
	end

	local weaponEntity = GetPreviewWeaponEntity(worldModel)

	if (!IsValid(weaponEntity)) then
		return
	end

	local attachmentID = entity:LookupAttachment(PREVIEW_WEAPON_ATTACHMENT)
	local attachment = attachmentID > 0 and entity:GetAttachment(attachmentID)

	if (attachment) then
		local correction = Schema.previewWeaponOffsets[weapon:GetClass()]

		if (correction) then
			local pos, ang = LocalToWorld(correction.pos, correction.ang, attachment.Pos, attachment.Ang)
			weaponEntity:SetPos(pos)
			weaponEntity:SetAngles(ang)
		else
			weaponEntity:SetPos(attachment.Pos)
			weaponEntity:SetAngles(attachment.Ang)
		end
	end

	weaponEntity:DrawModel()
end)

-- Live tuning tool for the per-weapon corrections above - open your
-- inventory so you can see the preview, switch to the weapon that looks
-- wrong, then run e.g. "ix_tune_weapon_preview x 1" / "ix_tune_weapon_preview yaw 15"
-- to nudge it (negative numbers move the other way) while watching it
-- update live. Run with no arguments to print the current offset and a
-- ready-to-send line for that weapon - paste that back once it looks
-- right so it can be saved permanently (this command's changes are
-- client-only and runtime-only; they won't survive a reconnect on their
-- own).
concommand.Add("ix_tune_weapon_preview", function(client, cmd, args)
	local weapon = LocalPlayer():GetActiveWeapon()

	if (!IsValid(weapon)) then
		print("[ixhl2rp] You need an active weapon to tune.")
		return
	end

	local class = weapon:GetClass()
	local current = Schema.previewWeaponOffsets[class]

	if (!current) then
		current = {pos = Vector(0, 0, 0), ang = Angle(0, 0, 0)}
		Schema.previewWeaponOffsets[class] = current
	end

	local axis = args[1] and args[1]:lower()
	local amount = tonumber(args[2])

	if (axis and amount) then
		if (axis == "x") then
			current.pos.x = current.pos.x + amount
		elseif (axis == "y") then
			current.pos.y = current.pos.y + amount
		elseif (axis == "z") then
			current.pos.z = current.pos.z + amount
		elseif (axis == "pitch") then
			current.ang.p = current.ang.p + amount
		elseif (axis == "yaw") then
			current.ang.y = current.ang.y + amount
		elseif (axis == "roll") then
			current.ang.r = current.ang.r + amount
		else
			print("[ixhl2rp] Unknown axis '"..axis.."' - use x, y, z, pitch, yaw, or roll.")
			return
		end
	end

	print(string.format("[ixhl2rp] Offset for \"%s\":", class))
	print(string.format('Schema.previewWeaponOffsets["%s"] = {pos = Vector(%.2f, %.2f, %.2f), ang = Angle(%.2f, %.2f, %.2f)}',
		class, current.pos.x, current.pos.y, current.pos.z, current.ang.p, current.ang.y, current.ang.r))
end)

-- ixModelPanel's own DrawModel (core/derma/cl_modelpanel.lua) only calls
-- hook.Run("DrawHelixModelView"/"PostDrawHelixModelView", ...) when
-- self.enableHook is true - and nothing in this schema or the
-- uirework_inventory plugin ever sets that on the inventory preview panel,
-- so the hook above never actually ran. Rather than guess at re-
-- implementing DrawModel's rendering logic (the kind of blind panel
-- patching that broke the inventory icon earlier this session), just force
-- enableHook on before calling the real, unmodified method - the ONLY
-- thing this changes is whether that one already-designed extension point
-- fires, nothing about how any panel actually renders.
local modelPanelTable = vgui.GetControlTable("ixModelPanel")

if (modelPanelTable and modelPanelTable.DrawModel) then
	local BaseDrawModel = modelPanelTable.DrawModel

	function modelPanelTable:DrawModel()
		self.enableHook = true
		BaseDrawModel(self)
	end
end

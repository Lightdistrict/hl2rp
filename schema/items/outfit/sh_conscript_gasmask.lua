
ITEM.name = "Gas Mask"
ITEM.description = "An M40 field protective mask, standard issue for conscript forces."
ITEM.model = Model("models/willardnetworks/clothingitems/m40_item.mdl")
ITEM.category = "Clothing"
ITEM.outfitCategory = "mask"
ITEM.width = 1
ITEM.height = 1

ITEM.bodyGroups = {
	["face"] = 3
}

local EQUIP_SOUND = "equipment/gasmasks/gasmask_on.mp3"
local UNEQUIP_SOUND = "equipment/gasmasks/gasmask_off.mp3"

local BREATH_SOUNDS = {}

for i = 1, 6 do
	BREATH_SOUNDS[i] = "foley/gasmask/gasmask_breath" .. i .. ".mp3"
end

-- only equippable while on one of the current faction's actual models -
-- otherwise the face bodygroup change has nothing to apply to
function ITEM:CanEquipOutfit()
	local faction = ix.faction.Get(self.player:Team())
	local models = faction and faction:GetModels(self.player)

	return models != nil and table.HasValue(models, self.player:GetModel())
end

-- Reschedules itself with a fresh random delay each time for a more
-- natural, non-robotic breathing cadence instead of a fixed interval.
-- Sent straight to the wearer's own client only (not a nearby-players
-- broadcast like Schema:EmitNearbyMP3) - a personal immersion effect,
-- not something bystanders should hear.
--
-- item is a plain ITEM table, not an entity - IsValid() only ever returns
-- true for things with their own :IsValid() method (entities, panels),
-- so IsValid(item) was ALWAYS false here and made this bail out before
-- ever playing a sound. Just check it's non-nil instead.
local function ScheduleBreath(client, item)
	local timerName = "ixhl2rpGasmaskBreath" .. client:EntIndex()

	timer.Create(timerName, math.random(3, 5), 1, function()
		if (!IsValid(client) or !item or !item:GetData("equip")) then
			return
		end

		netstream.Start({client}, "PlaySound", BREATH_SOUNDS[math.random(#BREATH_SOUNDS)])
		ScheduleBreath(client, item)
	end)
end

function ITEM:OnEquipped()
	Schema:EmitNearbyMP3(self.player, EQUIP_SOUND)
	ScheduleBreath(self.player, self)

	-- base_outfit doesn't touch other equipped outfit items' bodygroups on
	-- equip, but this re-syncs them anyway in case that ever changes
	Schema:ReapplyOutfitBodygroups(self.player)
end

function ITEM:OnUnequipped()
	Schema:EmitNearbyMP3(self.player, UNEQUIP_SOUND)
	timer.Remove("ixhl2rpGasmaskBreath" .. self.player:EntIndex())

	-- base_outfit's RemoveOutfit just called client:ResetBodygroups(), which
	-- wipes every other currently-equipped outfit item's bodygroup too (see
	-- Schema:ReapplyOutfitBodygroups in sv_hooks.lua) - put them back
	Schema:ReapplyOutfitBodygroups(self.player)
end

-- the dropped world-model entity doesn't know about ITEM.bodyGroups on its
-- own (see Schema:ApplyItemBodyGroups in sv_hooks.lua) - without this it
-- always shows the default bodygroup state on the ground. Reads
-- worldBodyGroups specifically, which this item doesn't set - only here
-- as a no-op safeguard in case that's ever added later.
function ITEM:OnEntityCreated(entity)
	Schema:ApplyItemBodyGroups(entity, self)
end

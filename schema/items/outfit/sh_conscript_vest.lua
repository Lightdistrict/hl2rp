
ITEM.name = "Conscript Vest"
ITEM.description = "An outer tactical vest, standard issue for conscript forces."
ITEM.model = Model("models/thomask_110/props/otv.mdl")
ITEM.category = "Clothing"
ITEM.outfitCategory = "vest"
ITEM.width = 1
ITEM.height = 1
ITEM.maxArmor = 50

ITEM.bodyGroups = {
	["vest"] = 2
}

local EQUIP_SOUND = "foley/inventory/inv_move6.wav"

-- only equippable while on one of the current faction's actual models -
-- otherwise the vest bodygroup change has nothing to apply to
function ITEM:CanEquipOutfit()
	local faction = ix.faction.Get(self.player:Team())
	local models = faction and faction:GetModels(self.player)

	return models != nil and table.HasValue(models, self.player:GetModel())
end

-- Armor is recomputed from scratch (Schema:ReapplyOutfitArmor) rather than
-- added/subtracted here directly - see that function in sv_hooks.lua for
-- why a running total could stack past the intended amount across
-- multiple loadouts. Multiple armor pieces (helmet, vest, etc.) still
-- stack cleanly regardless of order, since the recompute sums every
-- currently-equipped item's own maxArmor every time.
function ITEM:OnEquipped()
	self.player:EmitSound(EQUIP_SOUND, 60, 100, 0.5)
	Schema:ReapplyOutfitArmor(self.player)

	-- base_outfit doesn't touch other equipped outfit items' bodygroups on
	-- equip, but this re-syncs them anyway in case that ever changes
	Schema:ReapplyOutfitBodygroups(self.player)
end

function ITEM:OnUnequipped()
	self.player:EmitSound(EQUIP_SOUND, 60, 100, 0.5)
	Schema:ReapplyOutfitArmor(self.player)

	-- base_outfit's RemoveOutfit just called client:ResetBodygroups(), which
	-- wipes every other currently-equipped outfit item's bodygroup too (see
	-- Schema:ReapplyOutfitBodygroups in sv_hooks.lua) - put them back
	Schema:ReapplyOutfitBodygroups(self.player)
end

-- the dropped world-model entity doesn't know about ITEM.bodyGroups on its
-- own (see Schema:ApplyItemBodyGroups in sv_hooks.lua) - without this it
-- always shows the default bodygroup state on the ground
function ITEM:OnEntityCreated(entity)
	Schema:ApplyItemBodyGroups(entity, self)
end


ITEM.name = "Red Conscript Beret"
ITEM.description = "A red beret, standard issue for conscript forces."
-- Deliberately a DIFFERENT model than the black beret (which uses
-- models/thomask_110/props/head_beret.mdl) - this willardnetworks one is
-- red by default on its own mesh/texture, no bodygroup needed. This only
-- affects the inventory icon and the dropped world prop (ITEM.model has
-- nothing to do with the actual equip visual, which is entirely the
-- "headwear" bodygroup on the PLAYER's own model below) - worked around
-- this way after several failed attempts to make Helix's stock inventory
-- icon renderer respect a bodygroup at all (it only ever forwards
-- model+skin, never bodygroups, and patching it from the schema side
-- broke the icon's rendering outright - see git history on cl_hooks.lua).
ITEM.model = Model("models/willardnetworks/clothingitems_conscripts/head_beret.mdl")
ITEM.category = "Clothing"
ITEM.outfitCategory = "hat"
ITEM.width = 1
ITEM.height = 1

ITEM.bodyGroups = {
	["headwear"] = 2
}

local EQUIP_SOUND = "foley/inventory/inv_move2.wav"

-- only equippable while on one of the current faction's actual models -
-- otherwise the headwear bodygroup change has nothing to apply to
function ITEM:CanEquipOutfit()
	local faction = ix.faction.Get(self.player:Team())
	local models = faction and faction:GetModels(self.player)

	return models != nil and table.HasValue(models, self.player:GetModel())
end

function ITEM:OnEquipped()
	self.player:EmitSound(EQUIP_SOUND, 60, 100, 0.5)

	-- base_outfit doesn't touch other equipped outfit items' bodygroups on
	-- equip, but this re-syncs them anyway in case that ever changes
	Schema:ReapplyOutfitBodygroups(self.player)
end

function ITEM:OnUnequipped()
	self.player:EmitSound(EQUIP_SOUND, 60, 100, 0.5)

	-- base_outfit's RemoveOutfit just called client:ResetBodygroups(), which
	-- wipes every other currently-equipped outfit item's bodygroup too (see
	-- Schema:ReapplyOutfitBodygroups in sv_hooks.lua) - put them back
	Schema:ReapplyOutfitBodygroups(self.player)
end

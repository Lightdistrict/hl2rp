
ITEM.name = "Conscript Glasses"
ITEM.description = "A pair of tactical glasses, standard issue for conscript forces."
ITEM.model = Model("models/willardnetworks/clothingitems/glasses.mdl")
ITEM.category = "Clothing"
ITEM.outfitCategory = "glasses"
ITEM.width = 1
ITEM.height = 1

ITEM.bodyGroups = {
	["glasses"] = 1
}

-- no equip/unequip sound was given for this one - reusing the same sound
-- as the other Conscript clothing items; tell me a different path if you
-- want something else
local EQUIP_SOUND = "foley/inventory/inv_move2.wav"

-- only equippable while on one of the current faction's actual models -
-- otherwise the glasses bodygroup change has nothing to apply to
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

-- the dropped world-model entity doesn't know about ITEM.bodyGroups on its
-- own (see Schema:ApplyItemBodyGroups in sv_hooks.lua) - without this it
-- always shows the default bodygroup state on the ground
function ITEM:OnEntityCreated(entity)
	Schema:ApplyItemBodyGroups(entity, self)
end


ITEM.name = "Conscript Vest"
ITEM.description = "An outer tactical vest, standard issue for conscript forces."
ITEM.model = Model("models/thomask_110/props/otv.mdl")
ITEM.category = "Clothing"
ITEM.outfitCategory = "vest"
ITEM.width = 1
ITEM.height = 1

ITEM.bodyGroups = {
	["vest"] = 2
}

local EQUIP_SOUND = "foley/inventory/inv_move2.wav"

-- only equippable while on one of the current faction's actual models -
-- otherwise the vest bodygroup change has nothing to apply to
function ITEM:CanEquipOutfit()
	local faction = ix.faction.Get(self.player:Team())
	local models = faction and faction:GetModels(self.player)

	return models != nil and table.HasValue(models, self.player:GetModel())
end

function ITEM:OnEquipped()
	self.player:EmitSound(EQUIP_SOUND, 60, 100, 0.5)
end

function ITEM:OnUnequipped()
	self.player:EmitSound(EQUIP_SOUND, 60, 100, 0.5)
end

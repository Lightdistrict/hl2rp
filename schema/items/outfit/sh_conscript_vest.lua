
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

-- Armor here is a flat add/remove-on-toggle bonus rather than a tracked,
-- degrading pool, so that multiple armor pieces (helmet, vest, etc.) stack
-- cleanly regardless of order - each equipped piece just contributes its
-- own maxArmor to the player's current total.
function ITEM:OnEquipped()
	self.player:SetArmor(self.player:Armor() + self.maxArmor)
	self.player:EmitSound(EQUIP_SOUND, 60, 100, 0.5)
end

function ITEM:OnUnequipped()
	self.player:SetArmor(math.max(self.player:Armor() - self.maxArmor, 0))
	self.player:EmitSound(EQUIP_SOUND, 60, 100, 0.5)
end

function ITEM:OnLoadout()
	if (self:GetData("equip")) then
		self.player:SetArmor(self.player:Armor() + self.maxArmor)
	end
end

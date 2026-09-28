
ITEM.name = "Conscript Helmet"
ITEM.description = "A PASGT combat helmet, standard issue for conscript forces."
ITEM.model = Model("models/thomask_110/props/pasgt_helmet.mdl")
ITEM.category = "Clothing"
ITEM.outfitCategory = "hat"
ITEM.width = 1
ITEM.height = 1
ITEM.maxArmor = 50

-- confirmed via in-game bodygroup listing on the current conscript models
ITEM.bodyGroups = {
	["headwear"] = 4
}

local EQUIP_SOUND = "foley/inventory/inv_move2.wav"

-- only equippable while on one of the current faction's actual models -
-- otherwise the headwear bodygroup change has nothing to apply to (wrong
-- model entirely), so someone could equip it purely for the free armor
-- with nothing showing on their playermodel
function ITEM:CanEquipOutfit()
	local faction = ix.faction.Get(self.player:Team())
	local models = faction and faction:GetModels(self.player)

	return models != nil and table.HasValue(models, self.player:GetModel())
end

function ITEM:OnEquipped()
	self.player:SetArmor(self:GetData("armor", self.maxArmor))
	self.player:EmitSound(EQUIP_SOUND, 60, 100, 0.5)
end

function ITEM:OnUnequipped()
	self:SetData("armor", math.Clamp(self.player:Armor(), 0, self.maxArmor))
	self.player:SetArmor(0)
	self.player:EmitSound(EQUIP_SOUND, 60, 100, 0.5)
end

function ITEM:OnLoadout()
	if (self:GetData("equip")) then
		self.player:SetArmor(self:GetData("armor", self.maxArmor))
	end
end

function ITEM:OnSave()
	if (self:GetData("equip")) then
		self:SetData("armor", math.Clamp(self.player:Armor(), 0, self.maxArmor))
	end
end

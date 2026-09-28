
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

-- Armor here is a flat add/remove-on-toggle bonus rather than a tracked,
-- degrading pool, so that multiple armor pieces (helmet, vest, etc.) stack
-- cleanly regardless of order - each equipped piece just contributes its
-- own maxArmor to the player's current total.
function ITEM:OnEquipped()
	self.player:SetArmor(self.player:Armor() + self.maxArmor)
	self.player:EmitSound(EQUIP_SOUND, 60, 100, 0.5)

	-- base_outfit doesn't touch other equipped outfit items' bodygroups on
	-- equip, but this re-syncs them anyway in case that ever changes
	Schema:ReapplyOutfitBodygroups(self.player)
end

function ITEM:OnUnequipped()
	self.player:SetArmor(math.max(self.player:Armor() - self.maxArmor, 0))
	self.player:EmitSound(EQUIP_SOUND, 60, 100, 0.5)

	-- base_outfit's RemoveOutfit just called client:ResetBodygroups(), which
	-- wipes every other currently-equipped outfit item's bodygroup too (see
	-- Schema:ReapplyOutfitBodygroups in sv_hooks.lua) - put them back
	Schema:ReapplyOutfitBodygroups(self.player)
end

function ITEM:OnLoadout()
	if (self:GetData("equip")) then
		self.player:SetArmor(self.player:Armor() + self.maxArmor)
	end
end

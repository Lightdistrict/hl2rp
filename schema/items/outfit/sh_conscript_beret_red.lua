
ITEM.name = "Red Conscript Beret"
ITEM.description = "A red beret, standard issue for conscript forces."
-- Deliberately a DIFFERENT model than the black beret's own
-- (models/thomask_110/props/head_beret.mdl) - this willardnetworks one is
-- red by default on its own mesh/texture, no bodygroup needed. ITEM.model
-- controls the inventory icon (Helix's stock icon renderer only ever
-- forwards model+skin, never bodygroups, and patching it to respect one
-- broke its rendering outright - see git history on cl_hooks.lua). The
-- actual equip visual is unaffected either way - it's entirely the
-- "headwear" bodygroup on the PLAYER's own model below.
ITEM.model = Model("models/willardnetworks/clothingitems_conscripts/head_beret.mdl")
ITEM.category = "Clothing"
ITEM.outfitCategory = "hat"
ITEM.width = 1
ITEM.height = 1

ITEM.bodyGroups = {
	["headwear"] = 2
}

-- The dropped world prop should look like the black beret's own model
-- (bodygroup-recolored red), not the willardnetworks stand-in used only
-- for the icon - swapped back in OnEntityCreated below.
local WORLD_MODEL = "models/thomask_110/props/head_beret.mdl"

ITEM.worldBodyGroups = {
	["colour"] = 1
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

-- ix_item.lua already set the entity's model to ITEM.model (the
-- willardnetworks icon stand-in) and initialized physics on it before
-- calling this hook - swap to the real world model and redo physics init
-- so the dropped prop's collision matches what's actually shown, then
-- apply the bodygroup that makes it red (see Schema:ApplyItemBodyGroups
-- in sv_hooks.lua)
function ITEM:OnEntityCreated(entity)
	entity:SetModel(WORLD_MODEL)
	entity:PhysicsInit(SOLID_VPHYSICS)
	entity:SetSolid(SOLID_VPHYSICS)

	local physObj = entity:GetPhysicsObject()

	if (IsValid(physObj)) then
		physObj:EnableMotion(true)
		physObj:Wake()
	end

	Schema:ApplyItemBodyGroups(entity, self)
end

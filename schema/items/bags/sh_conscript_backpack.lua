
ITEM.name = "Conscript Backpack"
ITEM.description = "A tactical backpack, standard issue for conscript forces. Grants extra storage while carried."
ITEM.model = Model("models/player/backpack_trizip/trizip.mdl")
ITEM.category = "Clothing"
ITEM.width = 1
ITEM.height = 1

-- size of the extra storage space this grants - adjust freely
ITEM.invWidth = 4
ITEM.invHeight = 3

-- shows on the Conscript playermodel's "backpack" bodygroup any time the
-- character owns this item at all - not gated by an equip/unequip action,
-- just plain ownership (see Schema:ReapplyOutfitBodygroups in sv_hooks.lua,
-- which reads alwaysShowBodyGroups instead of requiring GetData("equip"))
ITEM.bodyGroups = {
	["backpack"] = 1
}
ITEM.alwaysShowBodyGroups = true

--[[
	No Equip/EquipUn here on purpose - this item isn't equippable or
	unequippable, just droppable (its own base, base_bags, already
	provides View/combine/drop/OnInstanced/GetInventory/OnSendData/
	CanTransfer/OnRegistered/PaintOver for free via ITEM.base = "base_bags",
	set automatically by living in the items/bags/ folder - see
	gamemode/items/base/sh_bags.lua for all of that).

	Only two of that base's functions need touching here, since Helix's
	item inheritance is a one-time flat copy (not live fallback) - any
	function redefined in this file completely REPLACES the base's
	version, so both below re-implement the base's own logic and add the
	bodygroup update on top, rather than losing the base's behavior.
]]
function ITEM:OnTransferred(curInv, inventory)
	local bagInventory = self:GetInventory()

	if (isfunction(curInv.GetOwner)) then
		local owner = curInv:GetOwner()

		if (IsValid(owner)) then
			bagInventory:RemoveReceiver(owner)
			-- no longer in this player's inventory - drop the bodygroup
			Schema:ReapplyOutfitBodygroups(owner)
		end
	end

	if (isfunction(inventory.GetOwner)) then
		local owner = inventory:GetOwner()

		if (IsValid(owner)) then
			bagInventory:AddReceiver(owner)
			bagInventory:SetOwner(owner)
			-- now in this player's inventory - show the bodygroup
			Schema:ReapplyOutfitBodygroups(owner)
		end
	else
		bagInventory:SetOwner(nil)
	end
end

ITEM.postHooks.drop = function(item, status)
	local index = item:GetData("id")

	local query = mysql:Update("ix_inventories")
		query:Update("character_id", 0)
		query:Where("inventory_id", index)
	query:Execute()

	net.Start("ixBagDrop")
		net.WriteUInt(index, 32)
	net.Send(item.player)

	-- OnTransferred should also catch this (dropping moves the item out
	-- of the character's inventory), but this is a cheap, safe-to-repeat
	-- backstop in case it doesn't fire for a plain drop
	if (IsValid(item.player)) then
		Schema:ReapplyOutfitBodygroups(item.player)
	end
end

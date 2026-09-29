
ITEM.name = "Conscript Backpack"
ITEM.description = "A tactical backpack, standard issue for conscript forces. Grants extra storage while worn."
ITEM.model = Model("models/player/backpack_trizip/trizip.mdl")
ITEM.category = "Clothing"
ITEM.outfitCategory = "backpack"
ITEM.width = 1
ITEM.height = 1

ITEM.bodyGroups = {
	["backpack"] = 1
}

-- size of the extra storage space this grants while worn - adjust freely
ITEM.invWidth = 4
ITEM.invHeight = 3
ITEM.isBag = true

local EQUIP_SOUND = "foley/inventory/inv_move2.wav"

-- only equippable while on one of the current faction's actual models -
-- otherwise the backpack bodygroup change has nothing to apply to
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

	-- the storage is only supposed to be reachable while worn (see the
	-- View function below) - force-close it if it's currently open so it
	-- doesn't sit there showing contents you can no longer interact with.
	-- Nothing inside it is ever at risk either way: it lives in its own
	-- separate database-backed inventory (same as a stock Helix bag), not
	-- the main grid, so unequipping never displaces or loses items.
	local index = self:GetData("id")

	if (index and IsValid(self.player)) then
		net.Start("ixBagDrop")
			net.WriteUInt(index, 32)
		net.Send(self.player)
	end
end

-- the dropped world-model entity doesn't know about ITEM.bodyGroups on its
-- own (see Schema:ApplyItemBodyGroups in sv_hooks.lua) - without this it
-- always shows the default bodygroup state on the ground
function ITEM:OnEntityCreated(entity)
	Schema:ApplyItemBodyGroups(entity, self)
end

--[[
	Everything below is the standard Helix "bag" sub-inventory system
	(gamemode/items/base/sh_bags.lua), copied in rather than set via
	ITEM.base since this item already needs ITEM.base = "outfit" (for the
	equip/bodygroup mechanic above, via the items/outfit/ folder
	convention) and Helix items only support inheriting from ONE base.

	The only real change from stock: View's OnCanRun also requires
	self:GetData("equip") - the storage is only reachable while the
	backpack is actually worn, not just owned. Two places where
	base_outfit ALSO defines a function of the same name (OnRemoved,
	CanTransfer) merge both behaviors instead of one silently replacing
	the other. "ixBagDrop" is NOT re-registered with
	util.AddNetworkString - it's already registered once, unconditionally,
	by Helix's own sh_bags.lua (loaded as a base regardless of which items
	actually use it), and the CLIENT-side net.Receive("ixBagDrop", ...)
	handler already defined there works for this item's messages too.
]]
ITEM.functions.View = {
	icon = "icon16/briefcase.png",
	OnClick = function(item)
		local index = item:GetData("id", "")

		if (index) then
			local panel = ix.gui["inv"..index]
			local inventory = ix.item.inventories[index]
			local parent = IsValid(ix.gui.menuInventoryContainer) and ix.gui.menuInventoryContainer or ix.gui.openedStorage

			if (IsValid(panel)) then
				panel:Remove()
			end

			if (inventory and inventory.slots) then
				panel = vgui.Create("ixInventory", IsValid(parent) and parent or nil)
				panel:SetInventory(inventory)
				panel:ShowCloseButton(true)
				panel:SetTitle(item.GetName and item:GetName() or L(item.name))

				if (parent != ix.gui.menuInventoryContainer) then
					panel:Center()

					if (parent == ix.gui.openedStorage) then
						panel:MakePopup()
					end
				else
					panel:MoveToFront()
				end

				ix.gui["inv"..index] = panel
			else
				ErrorNoHalt("[Helix] Attempt to view an uninitialized inventory '"..index.."'\n")
			end
		end

		return false
	end,
	OnCanRun = function(item)
		return item:GetData("equip") == true and !IsValid(item.entity) and item:GetData("id")
			and !IsValid(ix.gui["inv" .. item:GetData("id", "")])
	end
}

ITEM.functions.combine = {
	OnRun = function(item, data)
		ix.item.instances[data[1]]:Transfer(item:GetData("id"), nil, nil, item.player)

		return false
	end,
	OnCanRun = function(item, data)
		local index = item:GetData("id", "")

		if (index) then
			local inventory = ix.item.inventories[index]

			if (inventory) then
				return true
			end
		end

		return false
	end
}

-- merges base_outfit's own PaintOver (the little green "equipped"
-- indicator square) with the bag's own PaintOver (highlights the open
-- storage window on hover) - defining this again would otherwise
-- silently replace base_outfit's version instead of adding to it
if (CLIENT) then
	function ITEM:PaintOver(item, width, height)
		if (item:GetData("equip")) then
			surface.SetDrawColor(110, 255, 110, 100)
			surface.DrawRect(width - 14, height - 14, 8, 8)
		end

		local panel = ix.gui["inv" .. item:GetData("id", "")]

		if (IsValid(panel)) then
			if (vgui.GetHoveredPanel() == self) then
				panel:SetHighlighted(true)
			else
				panel:SetHighlighted(false)
			end
		end
	end
end

function ITEM:OnInstanced(invID, x, y)
	local inventory = ix.item.inventories[invID]

	ix.inventory.New(inventory and inventory.owner or 0, self.uniqueID, function(inv)
		local client = inv:GetOwner()

		inv.vars.isBag = self.uniqueID
		self:SetData("id", inv:GetID())

		if (IsValid(client)) then
			inv:AddReceiver(client)
		end
	end)
end

function ITEM:GetInventory()
	local index = self:GetData("id")

	if (index) then
		return ix.item.inventories[index]
	end
end

ITEM.GetInv = ITEM.GetInventory

function ITEM:OnSendData()
	local index = self:GetData("id")

	if (index) then
		local inventory = ix.item.inventories[index]

		if (inventory) then
			inventory.vars.isBag = self.uniqueID
			inventory:Sync(self.player)
			inventory:AddReceiver(self.player)
		else
			local owner = self.player:GetCharacter():GetID()

			ix.inventory.Restore(self:GetData("id"), self.invWidth, self.invHeight, function(inv)
				inv.vars.isBag = self.uniqueID
				inv:SetOwner(owner, true)

				if (!inv.owner) then
					return
				end

				for client, character in ix.util.GetCharacters() do
					if (character:GetID() == inv.owner) then
						inv:AddReceiver(client)
						break
					end
				end
			end)
		end
	else
		ix.inventory.New(self.player:GetCharacter():GetID(), self.uniqueID, function(inv)
			self:SetData("id", inv:GetID())
		end)
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
end

-- merges base_outfit's own OnRemoved (unequips/restores bodygroups if this
-- was worn when it got destroyed) with the bag's own cleanup (deletes its
-- sub-inventory's rows) - defining OnRemoved again here would otherwise
-- silently replace base_outfit's version instead of adding to it
function ITEM:OnRemoved()
	if (self.invID != 0 and self:GetData("equip")) then
		self.player = self:GetOwner()
			self:RemoveOutfit(self.player)
		self.player = nil
	end

	local index = self:GetData("id")

	if (index) then
		local query = mysql:Delete("ix_items")
			query:Where("inventory_id", index)
		query:Execute()

		query = mysql:Delete("ix_inventories")
			query:Where("inventory_id", index)
		query:Execute()
	end
end

-- merges base_outfit's own CanTransfer (can't be moved to a different
-- inventory while equipped) with the bag's own rules (no nesting bags
-- inside each other or inside themselves)
function ITEM:CanTransfer(oldInventory, newInventory)
	if (newInventory and self:GetData("equip")) then
		return false
	end

	local index = self:GetData("id")

	if (newInventory) then
		if (newInventory.vars and newInventory.vars.isBag) then
			return false
		end

		local index2 = newInventory:GetID()

		if (index == index2) then
			return false
		end

		for k, _ in self:GetInventory():Iter() do
			if (k:GetData("id") == index2) then
				return false
			end
		end
	end

	return !newInventory or newInventory:GetID() != oldInventory:GetID() or newInventory.vars.isBag
end

function ITEM:OnTransferred(curInv, inventory)
	local bagInventory = self:GetInventory()

	if (isfunction(curInv.GetOwner)) then
		local owner = curInv:GetOwner()

		if (IsValid(owner)) then
			bagInventory:RemoveReceiver(owner)
		end
	end

	if (isfunction(inventory.GetOwner)) then
		local owner = inventory:GetOwner()

		if (IsValid(owner)) then
			bagInventory:AddReceiver(owner)
			bagInventory:SetOwner(owner)
		end
	else
		bagInventory:SetOwner(nil)
	end
end

function ITEM:OnRegistered()
	ix.inventory.Register(self.uniqueID, self.invWidth, self.invHeight, true)
end

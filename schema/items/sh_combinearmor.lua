ITEM.name = "Armor Repair Kit"
ITEM.description = "A field repair kit for Civil Protection armor plating. Restores 100 armor on use, then is consumed."
ITEM.model = "models/items/item_item_crate_key.mdl"
ITEM.category = "Utility"
ITEM.width = 1
ITEM.height = 1

ITEM.functions.Use = {
	name = "Use",
	tip = "useTip",
	OnRun = function(item)
		local client = item.player

		if (IsValid(client)) then
			client:SetArmor(100)
			client:notify("You repair your armor plating.")
		end

		return true
	end
}


ITEM.name = "Stim Dose"
ITEM.model = Model("models/genesis/props/w_stimdose.mdl")
ITEM.description = "A combat stimulant injector, used to quickly stabilize an injury."
ITEM.category = "Medical"
ITEM.price = 55

ITEM.functions.Apply = {
	sound = "items/medshot4.wav",
	OnRun = function(itemTable)
		local client = itemTable.player

		client:SetHealth(math.min(client:Health() + 35, client:GetMaxHealth()))
	end
}

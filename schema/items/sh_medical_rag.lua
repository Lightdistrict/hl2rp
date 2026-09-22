
ITEM.name = "Medical Rag"
ITEM.model = Model("models/genesis/props/w_medical_rag.mdl")
ITEM.description = "A cloth rag, used to clean and dress minor wounds."
ITEM.category = "Medical"
ITEM.price = 15

ITEM.functions.Apply = {
	sound = "items/medshot4.wav",
	OnRun = function(itemTable)
		local client = itemTable.player

		client:SetHealth(math.min(client:Health() + 15, client:GetMaxHealth()))
	end
}

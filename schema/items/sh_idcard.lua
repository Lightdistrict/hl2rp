ITEM.name = "CCA Identification Card"
ITEM.description = "An identification card marking its holder as a member of the Combine Civil Authority."
ITEM.model = "models/props_lab/binderblue.mdl"
ITEM.category = "Storage"
ITEM.width = 1
ITEM.height = 1

ITEM.functions.Use = {
	name = "Inspect",
	tip = "useTip",
	icon = "icon16/magnifier.png",
	OnRun = function(item)
		local client = item.player

		if (IsValid(client)) then
			local character = client:getChar()

			if (character) then
				client:notify("This ID belongs to " .. character:getName() .. ".")
			end
		end

		return false
	end
}

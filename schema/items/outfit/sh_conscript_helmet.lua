
ITEM.name = "Conscript Helmet"
ITEM.description = "A standard-issue conscript helmet."
ITEM.model = Model("models/props_c17/oildrum001.mdl") -- TODO: swap for the helmet's own world/inventory model
ITEM.category = "Clothing"
ITEM.outfitCategory = "hat"

-- TODO: "helmet" and 1 are placeholders - replace with the real bodygroup
-- name and value that shows the helmet on the conscript models (see the
-- diagnostic command to find them)
ITEM.bodyGroups = {
	["helmet"] = 1
}


ITEM.name = "Conscript Helmet"
ITEM.description = "A standard-issue conscript helmet."
ITEM.model = Model("models/props_c17/oildrum001.mdl") -- TODO: swap for the helmet's own world/inventory model
ITEM.category = "Clothing"
ITEM.outfitCategory = "hat"

-- "headwear" has 4 values (0-3) on the conscript models - 0 is bare-headed
-- (the default), so this assumes 1 is the helmet. If a different number
-- turns out to actually be the helmet, just change the 1 below to match.
ITEM.bodyGroups = {
	["headwear"] = 1
}

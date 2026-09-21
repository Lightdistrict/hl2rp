--[[
	/ccsetrank <target> <rank>

	Admin-only command that whitelists the given Civil Protection rank onto
	the target's character (if they don't already have it) and switches them
	into it immediately. Valid rank keywords: conscript, private, corporal,
	sergeant, elite, commander.
]]

local RANKS = {
	["conscript"] = "CLASS_CONSCRIPT",
	["private"] = "CLASS_PRIVATE",
	["corporal"] = "CLASS_CORPORAL",
	["sergeant"] = "CLASS_SERGEANT",
	["elite"] = "CLASS_OVERWATCHELITE",
	["commander"] = "CLASS_ELITECOMMANDER"
}

ix.command.Add("ccsetrank", {
	description = "Whitelists and switches a Civil Protection member into the given rank.",
	adminOnly = true,
	arguments = {
		ix.type.player,
		ix.type.text
	},
	OnRun = function(self, client, target, rankName)
		local classID = RANKS[string.lower(rankName)] and _G[RANKS[string.lower(rankName)]]

		if (not classID) then
			client:notify("'" .. rankName .. "' is not a valid Civil Protection rank. Try: conscript, private, corporal, sergeant, elite, commander.")
			return
		end

		local character = target:getChar()

		if (not character or character:getFaction() ~= FACTION_CIVILPROTECTION) then
			client:notify(target:Name() .. " is not currently a Civil Protection character.")
			return
		end

		character:classWhitelist(classID)
		character:setClass(classID)

		client:notify(target:Name() .. "'s Civil Protection rank has been updated.")
		target:notify("Your Civil Protection rank has been updated by an administrator.")
	end
})

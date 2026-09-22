do
	local COMMAND = {}
	COMMAND.arguments = ix.type.text

	function COMMAND:OnRun(client, message)
		if (!client:IsRestricted()) then
			ix.chat.Send(client, "dispatch", message)
		else
			return "@notNow"
		end
	end

	ix.command.Add("Dispatch", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.arguments = ix.type.text

	function COMMAND:OnRun(client, message)
		local character = client:GetCharacter()
		local radios = character:GetInventory():GetItemsByUniqueID("handheld_radio", true)
		local item

		for k, v in ipairs(radios) do
			if (v:GetData("enabled", false)) then
				item = v
				break
			end
		end

		if (item) then
			if (!client:IsRestricted()) then
				ix.chat.Send(client, "radio", message)
				ix.chat.Send(client, "radio_eavesdrop", message)
			else
				return "@notNow"
			end
		elseif (#radios > 0) then
			return "@radioNotOn"
		else
			return "@radioRequired"
		end
	end

	ix.command.Add("Radio", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.arguments = ix.type.number

	function COMMAND:OnRun(client, frequency)
		local character = client:GetCharacter()
		local inventory = character:GetInventory()
		local itemTable = inventory:HasItem("handheld_radio")

		if (itemTable) then
			if (string.find(frequency, "^%d%d%d%.%d$")) then
				character:SetData("frequency", frequency)
				itemTable:SetData("frequency", frequency)

				client:Notify(string.format("You have set your radio frequency to %s.", frequency))
			end
		end
	end

	ix.command.Add("SetFreq", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.arguments = ix.type.text

	function COMMAND:OnRun(client, message)
		local character = client:GetCharacter()
		local inventory = character:GetInventory()

		if (inventory:HasItem("request_device") or client:IsCombine() or client:Team() == FACTION_ADMIN) then
			if (!client:IsRestricted()) then
				Schema:AddCombineDisplayMessage("@cRequest")

				ix.chat.Send(client, "request", message)
				ix.chat.Send(client, "request_eavesdrop", message)
			else
				return "@notNow"
			end
		else
			return "@needRequestDevice"
		end
	end

	ix.command.Add("Request", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.arguments = ix.type.text

	function COMMAND:OnRun(client, message)
		if (!client:IsRestricted()) then
			ix.chat.Send(client, "broadcast", message)
		else
			return "@notNow"
		end
	end

	ix.command.Add("Broadcast", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.adminOnly = true
	COMMAND.arguments = {
		ix.type.character,
		ix.type.text
	}

	function COMMAND:OnRun(client, target, permit)
		local itemTable = ix.item.Get("permit_" .. permit:lower())

		if (itemTable) then
			target:GetInventory():Add(itemTable.uniqueID)
		end
	end

	ix.command.Add("PermitGive", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.adminOnly = true
	COMMAND.arguments = {
		ix.type.character,
		ix.type.text
	}
	COMMAND.syntax = "<string name> <string permit>"

	function COMMAND:OnRun(client, target, permit)
		local inventory = target:GetInventory()
		local itemTable = inventory:HasItem("permit_" .. permit:lower())

		if (itemTable) then
			inventory:Remove(itemTable.id)
		end
	end

	ix.command.Add("PermitTake", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.arguments = ix.type.character

	function COMMAND:OnRun(client, target)
		local targetClient = target:GetPlayer()

		if (!hook.Run("CanPlayerViewData", client, targetClient)) then
			return "@cantViewData"
		end

		netstream.Start(client, "ViewData", targetClient, target:GetData("cid") or false, target:GetData("combineData"))
	end

	ix.command.Add("ViewData", COMMAND)
end

do
	local COMMAND = {}

	function COMMAND:OnRun(client, arguments)
		if (!hook.Run("CanPlayerViewObjectives", client)) then
			return "@noPerm"
		end

		netstream.Start(client, "ViewObjectives", Schema.CombineObjectives)
	end

	ix.command.Add("ViewObjectives", COMMAND)
end

do
	local COMMAND = {}

	function COMMAND:OnRun(client, arguments)
		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector() * 96
			data.filter = client
		local target = util.TraceLine(data).Entity

		if (IsValid(target) and target:IsPlayer() and target:IsRestricted()) then
			if (!client:IsRestricted()) then
				Schema:SearchPlayer(client, target)
			else
				return "@notNow"
			end
		end
	end

	ix.command.Add("CharSearch", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.description = "Awards civic points to a character on behalf of Overwatch."
	COMMAND.arguments = {
		ix.type.character,
		ix.type.number
	}

	function COMMAND:OnRun(client, target, amount)
		local character = client:GetCharacter()
		local bAuthorized = client:IsAdmin() or client:Team() == FACTION_OVERWATCH
			or (character and character:HasFlags("o"))

		if (!bAuthorized) then
			return "@notNow"
		end

		amount = math.Round(amount)

		if (amount == 0) then
			return
		end

		Schema:AddCivicPoints(target, amount)

		client:Notify("Awarded " .. amount .. " civic points to " .. target:GetName() .. ".")
	end

	ix.command.Add("AwardCivicPoints", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.description = "Removes civic points from a character on behalf of Overwatch."
	COMMAND.arguments = {
		ix.type.character,
		ix.type.number
	}

	function COMMAND:OnRun(client, target, amount)
		local character = client:GetCharacter()
		local bAuthorized = client:IsAdmin() or client:Team() == FACTION_OVERWATCH
			or (character and character:HasFlags("o"))

		if (!bAuthorized) then
			return "@notNow"
		end

		amount = math.Round(amount)

		if (amount == 0) then
			return
		end

		Schema:AddCivicPoints(target, -amount)

		client:Notify("Removed " .. amount .. " civic points from " .. target:GetName() .. ".")
	end

	ix.command.Add("RemoveCivicPoints", COMMAND)
end

do
	local COMMAND = {}

	function COMMAND:OnRun(client)
		local character = client:GetCharacter()

		if (!character) then
			return
		end

		client:Notify("You have " .. character:GetData("civicPoints", 0) .. " civic points.")
	end

	ix.command.Add("CivicPoints", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.description = "Orders a Stabilization Forces character in for memory replacement, advancing them one rank."
	COMMAND.arguments = ix.type.character

	function COMMAND:OnRun(client, target)
		if (!client:IsAdmin() and client:Team() != FACTION_OVERWATCH) then
			return "@notNow"
		end

		local success, reason = Schema:ResleeveCharacter(target)

		if (!success) then
			if (reason == "notOTA") then
				client:Notify(target:GetName() .. " is not a member of Stabilization Forces.")
			elseif (reason == "maxStage") then
				client:Notify(target:GetName() .. " has already undergone full memory replacement.")
			end

			return
		end

		client:Notify("Ordered " .. target:GetName() .. " in for memory replacement.")
	end

	ix.command.Add("Resleeve", COMMAND)
end

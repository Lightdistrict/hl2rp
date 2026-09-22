CLASS.name = "Scanner"
CLASS.description = "A Combine scanner drone, an extension of Overwatch's surveillance network."
CLASS.faction = FACTION_OVERWATCH

function CLASS:CanSwitchTo(client)
	return client:IsSuperAdmin()
end

function CLASS:OnSpawn(client)
	if (IsValid(client.ixScanner) and !client.ixScanner.bPendingRemove) then
		client.ixScanner.position = client:GetPos()
		client.ixScanner.bPendingRemove = true
		client.ixScanner:Remove()
	else
		Schema:CreateScanner(client)
	end
end

function CLASS:OnLeave(client)
	if (IsValid(client.ixScanner)) then
		local data = {}
			data.start = client.ixScanner:GetPos()
			data.endpos = data.start - Vector(0, 0, 1024)
			data.filter = {client, client.ixScanner}
		local position = util.TraceLine(data).HitPos

		client.ixScanner.position = position
		client.ixScanner:Remove()
	end
end

CLASS_OVERWATCH_SCANNER = CLASS.index

CLASS.name = "Scanner"
CLASS.description = "A Combine scanner drone, an extension of Overwatch's surveillance network."
CLASS.faction = FACTION_OVERWATCH
CLASS.isDefault = true

function CLASS:CanSwitchTo(client)
	return client:IsSuperAdmin()
end

-- Scanners are anonymous - give them a callsign-style name (e.g. "AW:SCN:482")
-- instead of whatever their character was previously named, matching the
-- "SCN" rank-code IsDispatch() already looks for, which is how Scanner
-- qualifies for the global dispatch chat/voice-line channel. This is also
-- applied from Schema:PlayerLoadedCharacter (sv_hooks.lua), since a
-- freshly-loaded character that defaults into Scanner gets its class set
-- directly and never runs OnSet at all.
function CLASS:OnSet(client)
	local character = client:GetCharacter()

	if (character) then
		if (!character:GetData("scannerCallsign")) then
			character:SetData("scannerCallsign", Schema:ZeroNumber(math.random(0, 999), 3))
		end

		Schema:UpdateScannerName(character)
	end
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

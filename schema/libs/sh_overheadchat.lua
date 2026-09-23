--[[
	Overhead chat bubbles + voice indicator.

	Similar in spirit to the classic "Chat Bubbles" workshop addon, built
	as a small Helix-native feature instead of a standalone addon:

	- While a player is typing a chat message, a bubble above their head
	  shows a typing indicator ("Talking...", "Yelling...",
	  "Whispering...", "Performing..." for /me, etc). This reuses each
	  chat class's own `indicator` phrase from ix.chat.Register - Helix
	  already defines these on every stock chat class, but nothing in
	  core actually renders them anywhere.
	- When they actually send the message, the bubble swaps to the real
	  text for a few seconds, then fades out.
	- Only chat classes listed in Schema.overheadChatTypes show a bubble
	  at all (in-character speech, not OOC/LOOC/PMs/system messages).
	- Anyone currently transmitting voice gets a small speaker icon above
	  their head instead of the default bottom-right voice HUD box, which
	  this file hides.
]]

Schema.overheadChatTypes = Schema.overheadChatTypes or {
	ic = true,
	w = true,
	y = true,
	me = true,
	it = true
}

if (SERVER) then
	util.AddNetworkString("ixOverheadChat")
	util.AddNetworkString("ixOverheadTyping")

	-- Broadcasts the final message text to whoever ix.chat.Send already
	-- determined could hear it, right after the message goes out.
	hook.Add("PlayerMessageSend", "ixOverheadChatBroadcast", function(speaker, chatType, text, bAnonymous, receivers, rawText, data)
		if (!IsValid(speaker) or bAnonymous or !Schema.overheadChatTypes[chatType]) then
			return
		end

		local class = ix.chat.classes[chatType]

		if (!class or class.bNoIndicator or !receivers) then
			return
		end

		net.Start("ixOverheadChat")
			net.WriteEntity(speaker)
			net.WriteString(text)
		net.Send(receivers)
	end)

	-- Relays a player's "currently typing" state to whoever is close
	-- enough to plausibly notice, mirroring IC chat range instead of
	-- broadcasting it server-wide.
	net.Receive("ixOverheadTyping", function(length, client)
		if (!IsValid(client) or !client:GetCharacter()) then
			return
		end

		local indicator = net.ReadString()
		local range = ix.config.Get("chatRange", 280) * 2
		local receivers = {}

		for _, v in player.Iterator() do
			if (v != client and v:GetPos():DistToSqr(client:GetPos()) <= range * range) then
				receivers[#receivers + 1] = v
			end
		end

		if (#receivers == 0) then
			return
		end

		net.Start("ixOverheadTyping")
			net.WriteEntity(client)
			net.WriteString(indicator)
		net.Send(receivers)
	end)
end

if (CLIENT) then
	Schema.overheadChat = Schema.overheadChat or {}

	local OVERHEAD_MESSAGE_TIME = 6
	local OVERHEAD_FADE_TIME = 1
	local OVERHEAD_TYPING_TIME = 4
	local OVERHEAD_MAX_DISTANCE = 900
	local voiceIcon = Material("icon16/sound.png")

	net.Receive("ixOverheadChat", function()
		local speaker = net.ReadEntity()
		local text = net.ReadString()

		if (!IsValid(speaker)) then
			return
		end

		Schema.overheadChat[speaker] = {
			text = text,
			bTyping = false,
			expire = CurTime() + OVERHEAD_MESSAGE_TIME
		}
	end)

	net.Receive("ixOverheadTyping", function()
		local speaker = net.ReadEntity()
		local indicator = net.ReadString()

		if (!IsValid(speaker)) then
			return
		end

		if (indicator == "") then
			local existing = Schema.overheadChat[speaker]

			if (existing and existing.bTyping) then
				Schema.overheadChat[speaker] = nil
			end

			return
		end

		local existing = Schema.overheadChat[speaker]

		-- don't let a stale "is typing" packet clobber a message that just
		-- arrived for this player
		if (existing and !existing.bTyping and existing.expire > CurTime()) then
			return
		end

		Schema.overheadChat[speaker] = {
			text = L(indicator),
			bTyping = true,
			expire = CurTime() + OVERHEAD_TYPING_TIME
		}
	end)

	hook.Add("EntityRemoved", "ixOverheadChatCleanup", function(entity)
		Schema.overheadChat[entity] = nil
	end)

	-- Figures out which registered chat class the player's current chat
	-- box text would be sent as, matching prefixes the same way
	-- ix.chat.Parse does server-side.
	local function GetIntendedChatClass(text)
		for _, v in pairs(ix.chat.classes) do
			if (v.bNoIndicator or !v.prefix) then
				continue
			end

			local prefixes = istable(v.prefix) and v.prefix or {v.prefix}

			for _, prefix in ipairs(prefixes) do
				if (text:utf8sub(1, prefix:utf8len()):utf8lower() == prefix:utf8lower()) then
					return v
				end
			end
		end

		return ix.chat.classes.ic
	end

	local lastSentIndicator

	local function SendTypingState(indicator)
		if (indicator == lastSentIndicator) then
			return
		end

		net.Start("ixOverheadTyping")
			net.WriteString(indicator or "")
		net.Send()

		lastSentIndicator = indicator
	end

	hook.Add("ChatTextChanged", "ixOverheadTypingNotify", function(text)
		local client = LocalPlayer()

		if (!IsValid(client) or !client:GetCharacter()) then
			return
		end

		if (!text or text == "") then
			SendTypingState(nil)

			return
		end

		local class = GetIntendedChatClass(text)

		if (!class or class.bNoIndicator or !Schema.overheadChatTypes[class.uniqueID]) then
			SendTypingState(nil)

			return
		end

		SendTypingState(class.indicator or "chatTalking")
	end)

	hook.Add("FinishChat", "ixOverheadTypingStop", function()
		SendTypingState(nil)
	end)

	hook.Add("HUDPaint", "ixOverheadChatAndVoiceDraw", function()
		local client = LocalPlayer()

		if (!IsValid(client)) then
			return
		end

		for _, speaker in ipairs(player.GetAll()) do
			if (!IsValid(speaker) or !speaker:Alive()) then
				continue
			end

			local origin = speaker:GetPos()

			-- speaker icon, drawn for anyone actively transmitting voice
			if (speaker:IsSpeaking()) then
				local iconPos = origin + Vector(0, 0, (speaker:OBBMaxs().z or 72) + 26)
				local screen = iconPos:ToScreen()

				if (screen.visible) then
					surface.SetMaterial(voiceIcon)
					surface.SetDrawColor(255, 255, 255, 255)
					surface.DrawTexturedRect(screen.x - 8, screen.y - 8, 16, 16)
				end
			end

			-- chat bubble, drawn while typing or for a few seconds after they send
			local info = Schema.overheadChat[speaker]

			if (info) then
				if (info.expire < CurTime()) then
					Schema.overheadChat[speaker] = nil
				elseif (client:GetPos():DistToSqr(origin) <= OVERHEAD_MAX_DISTANCE * OVERHEAD_MAX_DISTANCE) then
					local textPos = origin + Vector(0, 0, (speaker:OBBMaxs().z or 72) + 10)
					local screen = textPos:ToScreen()

					if (screen.visible) then
						local remaining = info.expire - CurTime()
						local alpha = (!info.bTyping and remaining < OVERHEAD_FADE_TIME)
							and math.Clamp((remaining / OVERHEAD_FADE_TIME) * 255, 0, 255) or 255

						surface.SetFont("ixChatFont")
						local w, h = surface.GetTextSize(info.text)
						local paddingX, paddingY = 10, 6

						draw.RoundedBox(6, screen.x - w / 2 - paddingX, screen.y - h - paddingY * 2,
							w + paddingX * 2, h + paddingY * 2, ColorAlpha(Color(20, 20, 20), alpha * 0.75))

						draw.SimpleText(info.text, "ixChatFont", screen.x, screen.y - paddingY - h / 2,
							ColorAlpha(color_white, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
					end
				end
			end
		end
	end)

	hook.Add("HUDShouldDraw", "ixHideDefaultVoiceHUD", function(name)
		if (name == "CHudVoiceStatus") then
			return false
		end
	end)
end

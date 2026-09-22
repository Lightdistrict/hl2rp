Schema.name = "HL2 RP"
Schema.author = "nebulous.cloud"
Schema.description = "A schema based on Half-Life 2."

-- Include netstream
ix.util.Include("libs/thirdparty/sh_netstream2.lua")

ix.util.Include("sh_configs.lua")
ix.util.Include("sh_commands.lua")
ix.util.Include("libs/sh_civicpoints.lua")

ix.util.Include("cl_schema.lua")
ix.util.Include("cl_hooks.lua")
ix.util.Include("sh_hooks.lua")
ix.util.Include("sh_voices.lua")
ix.util.Include("sv_schema.lua")
ix.util.Include("sv_hooks.lua")

ix.util.Include("meta/sh_player.lua")
ix.util.Include("meta/sv_player.lua")
ix.util.Include("meta/sh_character.lua")

ix.flag.Add("v", "Access to light blackmarket goods.")
ix.flag.Add("V", "Access to heavy blackmarket goods.")

ix.anim.SetModelClass("models/eliteghostcp.mdl", "metrocop")
ix.anim.SetModelClass("models/eliteshockcp.mdl", "metrocop")
ix.anim.SetModelClass("models/leet_police2.mdl", "metrocop")
ix.anim.SetModelClass("models/sect_police2.mdl", "metrocop")
ix.anim.SetModelClass("models/policetrench.mdl", "metrocop")
ix.anim.SetModelClass("models/combine_soldier.mdl", "overwatch")
ix.anim.SetModelClass("models/combine_soldier_prisonguard.mdl","overwatch")
ix.anim.SetModelClass("models/combine_super_soldier.mdl", "overwatch")

-- The HLVR Combine port below DOES have a relaxed idle/walk sequence, just
-- under different capitalization than the stock "overwatch" anim class
-- expects: this model's actual sequences (confirmed via GetSequenceList())
-- are "Idle_Unarmed" and "WalkUnarmed_all", not "idle_unarmed"/
-- "walkunarmed_all" - GMod's named-sequence lookup is apparently
-- case-sensitive here, so the lowercase names silently failed to match and
-- fell back to a T-pose. overwatch_hlvr is a copy of "overwatch" with the
-- correct casing for this model.
ix.anim.overwatch_hlvr = {
	normal = {
		[ACT_MP_STAND_IDLE] = {"Idle_Unarmed", ACT_IDLE_ANGRY},
		[ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
		[ACT_MP_WALK] = {"WalkUnarmed_all", ACT_WALK_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	pistol = {
		[ACT_MP_STAND_IDLE] = {"Idle_Unarmed", ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
		[ACT_MP_WALK] = {"WalkUnarmed_all", ACT_WALK_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	smg = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	shotgun = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SHOTGUN},
		[ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_SHOTGUN},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_SHOTGUN},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	grenade = {
		[ACT_MP_STAND_IDLE] = {"Idle_Unarmed", ACT_IDLE_ANGRY},
		[ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
		[ACT_MP_WALK] = {"WalkUnarmed_all", ACT_WALK_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	melee = {
		[ACT_MP_STAND_IDLE] = {"Idle_Unarmed", ACT_IDLE_ANGRY},
		[ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
		[ACT_MP_WALK] = {"WalkUnarmed_all", ACT_WALK_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_MELEE_ATTACK_SWING_GESTURE
	},
	glide = ACT_GLIDE
}

ix.anim.SetModelClass("models/jq/hlvr/characters/combine/grunt/combine_grunt_hlvr_npc.mdl","overwatch_hlvr")
ix.anim.SetModelClass("models/synapse/combine/combine_soldier_elite_h.mdl", "metrocop")
ix.anim.SetModelClass("models/synapse/combine/combine_soldier_h.mdl", "metrocop")
ix.anim.SetModelClass("models/synapse/combine/combine_supressor.mdl", "metrocop")
ix.anim.SetModelClass("models/willardnetworks/conscripts/female_01.mdl", "citizen_female")
ix.anim.SetModelClass("models/willardnetworks/conscripts/female_02.mdl", "citizen_female")
ix.anim.SetModelClass("models/willardnetworks/conscripts/female_03.mdl", "citizen_female")
ix.anim.SetModelClass("models/willardnetworks/conscripts/female_04.mdl", "citizen_female")
ix.anim.SetModelClass("models/willardnetworks/conscripts/female_05.mdl", "citizen_female")
ix.anim.SetModelClass("models/willardnetworks/conscripts/female_06.mdl", "citizen_female")
ix.anim.SetModelClass("models/willardnetworks/conscripts/male_01.mdl", "citizen_male")
ix.anim.SetModelClass("models/willardnetworks/conscripts/male_02.mdl", "citizen_male")
ix.anim.SetModelClass("models/willardnetworks/conscripts/male_03.mdl", "citizen_male")
ix.anim.SetModelClass("models/willardnetworks/conscripts/male_04.mdl", "citizen_male")
ix.anim.SetModelClass("models/willardnetworks/conscripts/male_05.mdl", "citizen_male")
ix.anim.SetModelClass("models/willardnetworks/conscripts/male_06.mdl", "citizen_male")
ix.anim.SetModelClass("models/willardnetworks/conscripts/male_07.mdl", "citizen_male")
ix.anim.SetModelClass("models/willardnetworks/conscripts/male_08.mdl", "citizen_male")
ix.anim.SetModelClass("models/willardnetworks/conscripts/male_09.mdl", "citizen_male")
ix.anim.SetModelClass("models/willardnetworks/conscripts/male_10.mdl", "citizen_male")
ix.anim.SetModelClass("models/wn7new/metropolice_c24/female_01.mdl.", "metrocop")
ix.anim.SetModelClass("models/wn7new/metropolice_c24/female_02.mdl", "metrocop")
ix.anim.SetModelClass("models/wn7new/metropolice_c24/female_03.mdl", "metrocop")
ix.anim.SetModelClass("models/wn7new/metropolice_c24/female_04.mdl", "metrocop")
ix.anim.SetModelClass("models/wn7new/metropolice_c24/female_05.mdl", "metrocop")
ix.anim.SetModelClass("models/wn7new/metropolice_c24/female_06.mdl", "metrocop")
ix.anim.SetModelClass("models/wn7new/metropolice_c24/male_01.mdl", "metrocop")
ix.anim.SetModelClass("models/wn7new/metropolice_c24/male_02.mdl", "metrocop")
ix.anim.SetModelClass("models/wn7new/metropolice_c24/male_03.mdl", "metrocop")
ix.anim.SetModelClass("models/wn7new/metropolice_c24/male_04.mdl", "metrocop")
ix.anim.SetModelClass("models/wn7new/metropolice_c24/male_05.mdl", "metrocop")
ix.anim.SetModelClass("models/wn7new/metropolice_c24/male_06.mdl", "metrocop")
ix.anim.SetModelClass("models/wn7new/metropolice_c24/male_07.mdl", "metrocop")
ix.anim.SetModelClass("models/wn7new/metropolice_c24/male_08.mdl", "metrocop")
ix.anim.SetModelClass("models/wn7new/metropolice_c24/male_09.mdl", "metrocop")
ix.anim.SetModelClass("models/wn7new/metropolice_c24/male_10.mdl", "metrocop")




function Schema:ZeroNumber(number, length)
	local amount = math.max(0, length - string.len(number))
	return string.rep("0", amount)..tostring(number)
end

function Schema:IsCombineRank(text, rank)
	return string.find(text, "[%D+]"..rank.."[%D+]")
end

do
	local CLASS = {}
	CLASS.color = Color(150, 100, 100)
	CLASS.format = "Dispatch broadcasts \"%s\""

	function CLASS:CanSay(speaker, text)
		if (!speaker:IsDispatch()) then
			speaker:NotifyLocalized("notAllowed")

			return false
		end
	end

	function CLASS:OnChatAdd(speaker, text)
		chat.AddText(self.color, string.format(self.format, text))
	end

	ix.chat.Register("dispatch", CLASS)
end

do
	local CLASS = {}
	CLASS.color = Color(75, 150, 50)
	CLASS.format = "%s radios in \"%s\""

	function CLASS:CanHear(speaker, listener)
		local character = listener:GetCharacter()
		local inventory = character:GetInventory()
		local bHasRadio = false

		for k, v in pairs(inventory:GetItemsByUniqueID("handheld_radio", true)) do
			if (v:GetData("enabled", false) and speaker:GetCharacter():GetData("frequency") == character:GetData("frequency")) then
				bHasRadio = true
				break
			end
		end

		return bHasRadio
	end

	function CLASS:OnChatAdd(speaker, text)
		text = speaker:IsCombine() and string.format("<:: %s ::>", text) or text
		chat.AddText(self.color, string.format(self.format, speaker:Name(), text))
	end

	ix.chat.Register("radio", CLASS)
end

do
	local CLASS = {}
	CLASS.color = Color(255, 255, 175)
	CLASS.format = "%s radios in \"%s\""

	function CLASS:GetColor(speaker, text)
		if (LocalPlayer():GetEyeTrace().Entity == speaker) then
			return Color(175, 255, 175)
		end

		return self.color
	end

	function CLASS:CanHear(speaker, listener)
		if (ix.chat.classes.radio:CanHear(speaker, listener)) then
			return false
		end

		local chatRange = ix.config.Get("chatRange", 280)

		return (speaker:GetPos() - listener:GetPos()):LengthSqr() <= (chatRange * chatRange)
	end

	function CLASS:OnChatAdd(speaker, text)
		text = speaker:IsCombine() and string.format("<:: %s ::>", text) or text
		chat.AddText(self.color, string.format(self.format, speaker:Name(), text))
	end

	ix.chat.Register("radio_eavesdrop", CLASS)
end

do
	local CLASS = {}
	CLASS.color = Color(175, 125, 100)
	CLASS.format = "%s requests \"%s\""

	function CLASS:CanHear(speaker, listener)
		return listener:IsCombine() or speaker:Team() == FACTION_ADMIN
	end

	function CLASS:OnChatAdd(speaker, text)
		chat.AddText(self.color, string.format(self.format, speaker:Name(), text))
	end

	ix.chat.Register("request", CLASS)
end

do
	local CLASS = {}
	CLASS.color = Color(175, 125, 100)
	CLASS.format = "%s requests \"%s\""

	function CLASS:CanHear(speaker, listener)
		if (ix.chat.classes.request:CanHear(speaker, listener)) then
			return false
		end

		local chatRange = ix.config.Get("chatRange", 280)

		return (speaker:Team() == FACTION_CITIZEN and listener:Team() == FACTION_CITIZEN)
		and (speaker:GetPos() - listener:GetPos()):LengthSqr() <= (chatRange * chatRange)
	end

	function CLASS:OnChatAdd(speaker, text)
		chat.AddText(self.color, string.format(self.format, speaker:Name(), text))
	end

	ix.chat.Register("request_eavesdrop", CLASS)
end

do
	local CLASS = {}
	CLASS.color = Color(150, 125, 175)
	CLASS.format = "%s broadcasts \"%s\""

	function CLASS:CanSay(speaker, text)
		if (speaker:Team() != FACTION_ADMIN) then
			speaker:NotifyLocalized("notAllowed")

			return false
		end
	end

	function CLASS:OnChatAdd(speaker, text)
		chat.AddText(self.color, string.format(self.format, speaker:Name(), text))
	end

	ix.chat.Register("broadcast", CLASS)
end


AddCSLuaFile()

SWEP.Base = "base_ix_medical"

if (CLIENT) then
	SWEP.PrintName = "Stim Dose"
end

SWEP.ViewModel = Model("models/genesis/vm/c_syn_hlastimdose.mdl")
SWEP.WorldModel = Model("models/genesis/props/w_stimdose.mdl")
SWEP.UseHands = true
SWEP.HealAmount = 35
SWEP.UseTime = 3

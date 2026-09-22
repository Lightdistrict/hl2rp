
AddCSLuaFile()

SWEP.Base = "base_ix_medical"

if (CLIENT) then
	SWEP.PrintName = "Stim Dose"
end

SWEP.WorldModel = Model("models/genesis/props/w_stimdose.mdl")
SWEP.HealAmount = 35

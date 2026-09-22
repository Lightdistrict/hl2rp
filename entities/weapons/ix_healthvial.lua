
AddCSLuaFile()

SWEP.Base = "base_ix_medical"

if (CLIENT) then
	SWEP.PrintName = "Health Vial"
end

SWEP.WorldModel = Model("models/genesis/props/w_healthvial.mdl")
SWEP.HealAmount = 20

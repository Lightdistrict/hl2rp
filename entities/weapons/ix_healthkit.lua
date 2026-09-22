
AddCSLuaFile()

SWEP.Base = "base_ix_medical"

if (CLIENT) then
	SWEP.PrintName = "Health Kit"
end

SWEP.WorldModel = Model("models/genesis/props/w_healthkit.mdl")
SWEP.HealAmount = 50

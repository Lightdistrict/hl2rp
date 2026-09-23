
AddCSLuaFile()

SWEP.Base = "base_ix_medical"

if (CLIENT) then
	SWEP.PrintName = "Health Vial"
end

SWEP.ViewModel = Model("models/genesis/vm/c_genesis_healthvial.mdl")
SWEP.WorldModel = Model("models/genesis/props/w_healthvial.mdl")
SWEP.UseHands = true
SWEP.HealAmount = 20
SWEP.UseTime = 3


AddCSLuaFile()

SWEP.Base = "base_ix_medical"

if (CLIENT) then
	SWEP.PrintName = "Health Kit"
end

SWEP.ViewModel = Model("models/genesis/vm/c_genesis_healthkit.mdl")
SWEP.WorldModel = Model("models/genesis/props/w_healthkit.mdl")
SWEP.UseHands = true
SWEP.HealAmount = 50
SWEP.UseTime = 4

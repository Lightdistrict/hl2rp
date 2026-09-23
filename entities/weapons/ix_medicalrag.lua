
AddCSLuaFile()

SWEP.Base = "base_ix_medical"

if (CLIENT) then
	SWEP.PrintName = "Medical Rag"
end

SWEP.ViewModel = Model("models/genesis/vm/c_genesis_medicalrag.mdl")
SWEP.WorldModel = Model("models/genesis/props/w_medical_rag.mdl")
SWEP.UseHands = true
SWEP.HealAmount = 15
SWEP.UseTime = 3

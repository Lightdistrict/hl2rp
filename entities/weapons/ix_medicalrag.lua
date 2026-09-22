
AddCSLuaFile()

SWEP.Base = "base_ix_medical"

if (CLIENT) then
	SWEP.PrintName = "Medical Rag"
end

SWEP.WorldModel = Model("models/genesis/props/w_medical_rag.mdl")
SWEP.HealAmount = 15

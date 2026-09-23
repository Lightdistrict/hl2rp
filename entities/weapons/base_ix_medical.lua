
AddCSLuaFile()

if (CLIENT) then
	SWEP.PrintName = "Medical Item"
	SWEP.Slot = 0
	SWEP.SlotPos = 3
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = true
end

SWEP.Author = "Chessnut"
SWEP.Instructions = "Primary Fire: Use on whoever you're aiming at, or yourself if no one's there."
SWEP.Purpose = "Treats an injury, then is used up."
SWEP.Drop = false

SWEP.ViewModelFOV = 45
SWEP.ViewModelFlip = false
SWEP.AnimPrefix = "rpg"

SWEP.ViewTranslation = 4

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ""

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""

SWEP.ViewModel = Model("models/weapons/c_arms_animations.mdl")
SWEP.WorldModel = ""

SWEP.UseHands = false

SWEP.IsAlwaysRaised = true
SWEP.HoldType = "normal"

-- Overridden per item: how much health it restores, how far you can reach a
-- target with it, and roughly how long its use animation takes (the heal
-- and item consumption wait this long so the animation isn't cut short).
SWEP.HealAmount = 20
SWEP.UseRange = 96
SWEP.UseTime = 1.2

-- luacheck: globals ACT_VM_FISTS_DRAW ACT_VM_FISTS_HOLSTER
ACT_VM_FISTS_DRAW = 2
ACT_VM_FISTS_HOLSTER = 1

function SWEP:Holster()
	if (!IsValid(self.Owner)) then
		return
	end

	local viewModel = self.Owner:GetViewModel()

	if (IsValid(viewModel)) then
		viewModel:SetPlaybackRate(1)
		viewModel:ResetSequence(ACT_VM_FISTS_HOLSTER)
	end

	return true
end

function SWEP:Precache()
end

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
end

function SWEP:GetUseTarget()
	local data = {}
		data.start = self.Owner:GetShootPos()
		data.endpos = data.start + self.Owner:GetAimVector() * self.UseRange
		data.filter = self.Owner
	local entity = util.TraceLine(data).Entity

	if (IsValid(entity) and entity:IsPlayer() and entity:Alive() and entity:GetCharacter()) then
		return entity
	end

	return self.Owner
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + self.UseTime)

	if (!IsFirstTimePredicted()) then
		return
	end

	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self.Owner:SetAnimation(PLAYER_ATTACK1)

	if (CLIENT) then
		return
	end

	if (!self.Owner:GetCharacter()) then
		return
	end

	local target = self:GetUseTarget()

	if (!target:Alive() or target:Health() >= target:GetMaxHealth()) then
		self.Owner:Notify((target == self.Owner and "You are" or (target:Name().." is")).." already at full health.")

		return
	end

	local weapon = self
	local owner = self.Owner

	-- Wait for the use animation to actually finish playing before healing
	-- and consuming the item, instead of yanking the weapon away mid-anim.
	timer.Simple(self.UseTime, function()
		if (!IsValid(weapon) or !IsValid(owner) or !IsValid(target) or owner:GetActiveWeapon() != weapon) then
			return
		end

		target:SetHealth(math.min(target:Health() + weapon.HealAmount, target:GetMaxHealth()))
		target:EmitSound("items/medshot4.wav")

		if (target != owner) then
			target:Notify(owner:Name().." has used "..weapon.PrintName.." on you.")
		end

		local item = weapon.ixItem

		if (item) then
			item:Remove()
		end
	end)
end

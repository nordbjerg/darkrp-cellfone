AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/props/cs_assault/money.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	phys:Wake()

	self:SetOperator(self:Getowning_ent().CFVars["company"]["name"])
end

function ENT:SpawnFunction(ply, tr, className)
    if not tr.Hit then return end
    
    local spawnPos = tr.HitPos + tr.HitNormal * 16
    
    local ent = ents.Create(className)
        ent:SetPos(spawnPos)
    ent:Spawn()
    ent:Activate()
    
    return ent
end

function ENT:Use(activator)
	if activator:Team() == TEAM_CELLOP then
		GAMEMODE:Notify(activator, 0, 4, "You can not pick up this SIM card, as you own your own cell operator company.")
	else
		activator:SetDarkRPVar("CF.Operator", self:GetOperator())
		GAMEMODE:Notify(activator, 0, 4, "Your cell operator is now " .. self:GetOperator())
		GAMEMODE:Notify(activator, 0, 4, "Rates pr. minute: $" .. self:Getowning_ent().CFVars["company"]["call"])
		GAMEMODE:Notify(activator, 0, 4, "Rates pr. SMS: $" .. self:Getowning_ent().CFVars["company"]["sms"])

		self:Remove()
	end
end
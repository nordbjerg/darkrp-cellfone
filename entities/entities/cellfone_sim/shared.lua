ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "SIM card"
ENT.Author = "Blaze"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "Operator")
	self:NetworkVar("Entity", 1, "owning_ent")
end
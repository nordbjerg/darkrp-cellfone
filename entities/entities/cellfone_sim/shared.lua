--[[----------------------------------------------------------------------------
    "THE BEER-WARE LICENSE" (Revision 42):
    nordbjerg@github wrote this file. As long as you retain this notice you
    can do whatever you want with this stuff. If we meet some day, and you think
    this stuff is worth it, you can buy me a beer in return Oliver Nordbjerg
    ----------------------------------------------------------------------------]]--

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
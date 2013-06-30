--[[----------------------------------------------------------------------------
    "THE BEER-WARE LICENSE" (Revision 42):
    nordbjerg@github wrote this file. As long as you retain this notice you
    can do whatever you want with this stuff. If we meet some day, and you think
    this stuff is worth it, you can buy me a beer in return Oliver Nordbjerg
    ----------------------------------------------------------------------------]]--

include("shared.lua")

function ENT:Draw()
	self:DrawModel()

	local pos = self:GetPos()
	local ang = self:GetAngles()

	surface.SetFont("ChatFont")
	local textWidth = surface.GetTextSize(self:GetOperator())

	cam.Start3D2D(pos + ang:Up() * 0.9, ang, 0.1)
		draw.WordBox(2, -textWidth*0.5, -10, self:GetOperator(), "ChatFont", Color(140, 0, 0, 100), Color(255,255,255,255))
	cam.End3D2D()

	ang:RotateAroundAxis(ang:Right(), 180)

	cam.Start3D2D(pos, ang, 0.1)
		draw.WordBox(2, -textWidth*0.5, -10, self:GetOperator(), "ChatFont", Color(140, 0, 0, 100), Color(255,255,255,255))
	cam.End3D2D()
end
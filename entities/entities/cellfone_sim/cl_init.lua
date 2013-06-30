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
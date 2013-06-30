---------------------------------------------------------
-- CUSTOM HOOKS
---------------------------------------------------------
local CF = {}
CF.__index = CF

function CF.HandleMessage(um)
	local color = Color(um:ReadShort(), um:ReadShort(), um:ReadShort())

	chat.AddText(color, um:ReadString())
end
usermessage.Hook("CF.SendMessage", CF.HandleMessage)

---------------------------------------------------------
-- INTERFACE
---------------------------------------------------------
function CF.ConfigureCompanyWindow()
	-- Create window
	local window = vgui.Create("DFrame")
	window:SetPos(ScrW() / 2 - 200, ScrH() / 2 - 100)
	window:SetSize(400, 210)
	window:SetTitle("CellFone - New cell operator")
	window:SetVisible(true)
	window:SetDraggable(false)
	window:SetBackgroundBlur(true)
	window:ShowCloseButton(false)
	window:MakePopup()

	local welcome = vgui.Create("DLabel", window)
	welcome:SetPos(25, 35)
	welcome:SetText("Welcome as a Cell Operator! To get started, you have to enter some\ninformation about your new company.")
	welcome:SizeToContents()

	local name = vgui.Create("DTextEntry", window)
	name:SetSize(350, 20)
	name:SetPos(25, 75)
	name:SetText("Company name")
	name.OnMousePressed = function()
		name:SetText("")
	end

	local callSlider = vgui.Create("DNumSlider", window)
	callSlider:SetPos(25, 90)
	callSlider:SetSize(350, 50)
	callSlider:SetText("Price pr. minute")
	callSlider:SetMin(0)
	callSlider:SetMax(400)
	callSlider:SetDecimals(0)

	local smsSlider = vgui.Create("DNumSlider", window)
	smsSlider:SetPos(25, 120)
	smsSlider:SetSize(350, 50)
	smsSlider:SetText("Price pr. SMS")
	smsSlider:SetMin(0)
	smsSlider:SetMax(400)
	smsSlider:SetDecimals(0)

	local button = vgui.Create("DButton", window)
	button:SetSize(50, 25)
	button:SetText("Create")
	button:SetPos(325, 170)
	button.DoClick = function()
		if string.len(name:GetValue()) >= 3 and
			callSlider:GetValue() > 0 and callSlider:GetValue() <= 400 and
			smsSlider:GetValue() > 0 and callSlider:GetValue() <= 400 then
			window:SetVisible(false)
			LocalPlayer():ConCommand("cf_confcomp " .. name:GetValue() .. " " .. callSlider:GetValue() .. " " .. smsSlider:GetValue())
		end
	end
end
concommand.Add("cf_confcompwin", CF.ConfigureCompanyWindow)
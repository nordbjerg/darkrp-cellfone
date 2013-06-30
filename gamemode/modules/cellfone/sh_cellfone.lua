--[[----------------------------------------------------------------------------
    "THE BEER-WARE LICENSE" (Revision 42):
    nordbjerg@github wrote this file. As long as you retain this notice you
    can do whatever you want with this stuff. If we meet some day, and you think
    this stuff is worth it, you can buy me a beer in return Oliver Nordbjerg
    ----------------------------------------------------------------------------]]--

---------------------------------------------------------
-- JOBS
---------------------------------------------------------
TEAM_CELLOP = AddExtraTeam("Cellphone Operator", {
	color = Color(255, 0, 255),
	model = "models/player/mossman.mdl",
	description = [[You run a cell phone operating company. Sell SIM cards to
get filthy rich!]],
	weapons = {},
	command = "cellop",
	max = 3,
	salary = 25,
	admin = 0,
	vote = true,
    customCheck = function(ply) return table.HasValue({"donator","admin","owner","co-owner","superadmin"}, ply:GetNWString("usergroup")) end,
    CustomCheckFailMsg = "You need to be an Donator to become a Cellphone Operator."
})

---------------------------------------------------------
-- SOUNDS
---------------------------------------------------------
resource.AddFile("sound/cellfone/ringtone.wav")
resource.AddFile("sound/cellfone/text_message.wav")
resource.AddFile("sound/cellfone/dial.wav")

util.PrecacheSound("cellfone/ringtone.wav")
util.PrecacheSound("cellfone/text_message.wav")
util.PrecacheSound("cellfone/dial.wav")

local CF = {}
CF.__index = CF

function CF.UpdateCallSound()
	for index, ply in pairs(player.GetAll()) do
		if ply:IsValid() and ply.DarkRPVars["CF.Call.Status"] == 1 then
			ply:EmitSound("cellfone/ringtone.wav", 75, 100)
		end
	end
end
timer.Create("CF.CallSound", 4.5, 0, CF.UpdateCallSound)
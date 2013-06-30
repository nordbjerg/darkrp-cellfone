--[[----------------------------------------------------------------------------
    "THE BEER-WARE LICENSE" (Revision 42):
    nordbjerg@github wrote this file. As long as you retain this notice you
    can do whatever you want with this stuff. If we meet some day, and you think
    this stuff is worth it, you can buy me a beer in return Oliver Nordbjerg
    ----------------------------------------------------------------------------]]--

---------------------------------------------------------
-- MISC. FUNCTIONS
---------------------------------------------------------
local CF = {
	SIM = {}
}
CF.__index = CF

local meta = FindMetaTable("Player")
function meta:SendMessage(color, message)
	if not self:IsPlayer() or not self:IsValid() then return end
	umsg.Start("CF.SendMessage", self)
		umsg.Short(color.r)
		umsg.Short(color.g)
		umsg.Short(color.b)
		umsg.String(message)
	umsg.End()
end

function string.explode ( str , seperator , plain )
	assert ( type ( seperator ) == "string" and seperator ~= "" , "Invalid seperator (need string of length >= 1)" )
	local t , nexti = { } , 1
	local pos = 1
	while true do
		local st , sp = str:find ( seperator , pos , plain )
		if not st then break end -- No more seperators found
			if pos ~= st then
				t [ nexti ] = str:sub ( pos , st - 1 ) -- Attach chars left of current divider
				nexti = nexti + 1
			end
			pos = sp + 1 -- Jump past current divider
		end
		t [ nexti ] = str:sub ( pos ) -- Attach chars right of last divider
	return t
end

---------------------------------------------------------
-- HOOKS
---------------------------------------------------------
function CF.PlayerInitialSpawn(ply)
	ply.CFVars = {}

	ply.CFVars["company"] = nil -- A variable containing a table with info about the users own cell company
	ply.CFVars["call"] = {
		caller = nil,
		time = 0,
		target = nil
	}

	ply:SetDarkRPVar("CF.Operator", nil) -- A variable containing the name of the users cell operator
	ply:SetDarkRPVar("CF.Signal", 0)

	-- 0 = no call
	-- 1 = incoming call
	-- 2 = call in progress (incoming)
	-- 3 = call in progress (outgoing)
	ply:SetDarkRPVar("CF.Call.Status", 0)
end
hook.Add("PlayerInitialSpawn", "CF.PlayerInitialSpawn", CF.PlayerInitialSpawn)

function CF.PlayerSpawn(ply)
	ply:SetDarkRPVar("CF.Call.Status", 0)
end
hook.Add("PlayerSpawn", "CF.PlayerSpawn", CF.PlayerSpawn)

function CF.PlayerDeath(ply, inflictor, attacker)
	-- Abort the current call upon death
	if ply.DarkRPVars["CF.Call.Status"] > 0 then
		local other = ply.CFVars["call"]["caller"]
		if other == ply then
			other = ply.CFVars["call"]["target"]
		end

		-- Send a message saying the call was interrupted
		if ply:SteamID() == attacker:SteamID() then
			-- Yikes, we have committed suicide!
			other:SendMessage(Color(160, 32, 240), "You hear a loud gunshot. You assume " .. ply:Nick() .. " has committed suicide.")
		else
			-- We died. Dang it!
			other:SendMessage(Color(160, 32, 240), "You hear some rambling, which sounds like the voice of " .. attacker:Nick() .. ". Your conversation is silenced.")
		end

		-- Update call status
		ply:SetDarkRPVar("CF.Call.Status", 0)
		other:SetDarkRPVar("CF.Call.Status", 0)

		ply.CFVars["call"]["caller"] = nil
		ply.CFVars["call"]["target"] = nil
		other.CFVars["call"]["caller"] = nil
		other.CFVars["call"]["target"] = nil

		ply.CFVars["call"]["time"] = 0
		other.CFVars["call"]["time"] = 0
	end
end
hook.Add("PlayerDeath", "CF.PlayerDeath", CF.PlayerDeath)

function CF.ConfigureCompany(ply, cmd, args)
	local sms = args[#args]
	table.remove(args, #args)
	local call = args[#args]
	table.remove(args, #args)
	local name = table.concat(args, " ")

	ply:SetDarkRPVar("CF.Operator", name)
	ply.CFVars["company"] = {
		name = name,
		call = call,
		sms = sms
	}
	ply:SendMessage(Color(160, 32, 240), "Awesome! Your company called " .. ply.DarkRPVars["CF.Operator"] .. " was created.")

end
concommand.Add("cf_confcomp", CF.ConfigureCompany)

-- Check for team changes and stuff
-- yarr
function CF.TeamChanged()
	for index, ply in pairs(player.GetAll()) do
		if ply:Team() == TEAM_CELLOP and ply.CFVars["company"] == nil then
			-- We have a new cell operator!
			ply:SetDarkRPVar("CF.Operator", "__TEMP")
			ply.CFVars["company"] = {
				name = "__TEMP",
				call = 0,
				sms = 0
			}
			ply:ConCommand("cf_confcompwin")
		elseif ply:Team() != TEAM_CELLOP and ply.CFVars["company"] != nil then
			-- Disband the company
			for _, customer in pairs(player.GetAll()) do
				if customer.DarkRPVars["CF.Operator"] == ply.CFVars["company"]["name"] then
					if customer != ply then
						customer:SendMessage(Color(160, 32, 240), "IMPORTANT: Your cell operator has been disbanded! Your phone will no longer work.")
					end
					customer:SetDarkRPVar("CF.Operator", nil)
				end
			end

			ply.CFVars["company"] = nil
		end
	end
end

---------------------------------------------------------
-- CUSTOM HOOKS
---------------------------------------------------------
hook.Add("CF.Hook.PayCall", "CellFone Hook for paying calls", function(call)
	-- Takes in the call as a table.
	-- To see how the call table should be structured, refer to
	-- the initial spawn hook at the top of this file.

	local company = nil
	local owner = nil
	for index, ply in pairs(team.GetPlayers(TEAM_CELLOP)) do
		if call["caller"].DarkRPVars["CF.Operator"] == ply.CFVars["company"]["name"] then
			company = ply.CFVars["company"]
			owner = ply
			break
		end
	end

	if company == nil or owner == call["caller"] then
		-- If there is no owner of the company (weird?) or we are the owner
		-- cancel the whole payment
		return
	end

	local price = math.floor(call["time"] / 60 * company["call"])
	if not call["caller"]:CanAfford(price) then
		owner:SendMessage(Color(160, 32, 240), call["caller"]:Nick() .. " used your service but could not afford to pay up.")
		owner:SendMessage(Color(160, 32, 240), "They owe you $" .. price .. "!")
		call["caller"]:SendMessage(Color(160, 32, 240), "You could not afford to pay for the call.")
		call["caller"]:SendMessage(Color(160, 32, 240), "You now owe $" .. price .. " to " .. owner:Nick())
	else
		call["caller"]:AddMoney(-price)
		owner:AddMoney(price)

		owner:SendMessage(Color(160, 32, 240), call["caller"]:Nick() .. " used your service. You gained $" .. price)
		call["caller"]:SendMessage(Color(160, 32, 240), "You paid $" .. price .. " for the phone call.")
	end
end)

hook.Add("CF.Hook.PaySMS", "CellFone Hook for paying SMS", function(ply)
	local company = nil
	local owner = nil
	for index, pl in pairs(team.GetPlayers(TEAM_CELLOP)) do
		if ply.DarkRPVars["CF.Operator"] == pl.CFVars["company"]["name"] then
			company = pl.CFVars["company"]
			owner = pl
			break
		end
	end

	if company == nil or owner == ply then
		-- If there is no owner of the company (weird?) or we are the owner
		-- cancel the whole payment
		return true
	end

	local price = company["sms"]
	if not ply:CanAfford(price) then
		return false
	end

	ply:AddMoney(-price)
	owner:AddMoney(price)

	owner:SendMessage(Color(160, 32, 240), ply:Nick() .. " used your service. You gained $" .. price)
	return true
end)

---------------------------------------------------------
-- SIGNAL & CALL SYSTEM
---------------------------------------------------------
function CF.UpdateSignal()
	for index, ply in pairs(player.GetAll()) do
		if ply.DarkRPVars["CF.Operator"] == nil then
			-- If there is no operator, we'll skip this person
			ply:SetDarkRPVar("CF.Signal", 0)
			continue
		end

		-- The signal is based on how many entities are nearby
		local props = 0
		for k, ent in pairs(ents.FindInSphere(ply:GetPos(), 690)) do
			if ent:IsValid() and ent:GetClass() == "prop_physics" then
				props = props + 1
			end
		end

		-- NOTE: VERY simple signal system
		-- Should be expanded in the future. Maybe with towers etc.
		-- NOTE: Any way to check if the user is "underground" (e.g. checking if there is a roof overhead)?
		if props <= 8 then
			ply:SetDarkRPVar("CF.Signal", 4)
		elseif props > 8 and props < 16 then
			ply:SetDarkRPVar("CF.Signal", 3)
		elseif props >= 16 and props < 30 then
			ply:SetDarkRPVar("CF.Signal", 2)
		elseif props >= 30 and props < 35 then
			ply:SetDarkRPVar("CF.Signal", 1)
		else
			ply:SetDarkRPVar("CF.Signal", 0)
		end
	end
end

function CF.UpdateCall()
	for index, ply in pairs(player.GetAll()) do
		if ply.DarkRPVars["CF.Call.Status"] > 0 and (ply.DarkRPVars["CF.Signal"] == 0 or ply.DarkRPVars["CF.Operator"] == nil) then
			-- err merr gerd, we lost the signal!1!!
			-- This can be because we actually lost signal,
			-- or because our cell operator has been disbanded.

			local caller = ply.CFVars["call"]["caller"]
			if caller == ply then
				caller = ply.CFVars["call"]["target"]
			end

			-- Notify the users
			caller:SendMessage(Color(160, 32, 240), "Your conversation terminated because you lost signal.")
			ply:SendMessage(Color(160, 32, 240), "The conversation abruptly terminates.")

			-- End the call
			ply:SetDarkRPVar("CF.Call.Status", 0)
			caller:SetDarkRPVar("CF.Call.Status", 0)

			-- Make the caller pay
			hook.Call("CF.Hook.PayCall", GAMEMODE, ply.CFVars["call"])
		end
	end
end

function CF.UpdateCallTimer()
	-- Every second we add another second to the call timer
	-- ... obviously, duh
	for index, ply in pairs(player.GetAll()) do
		if ply.DarkRPVars["CF.Call.Status"] > 1 then
			ply.CFVars["call"]["time"] = ply.CFVars["call"]["time"] + 1
		end
	end
end
timer.Create("CF.CallTimer", 1, 0, CF.UpdateCallTimer)

function CF.Call(ply, args)
	if not args or args == "" then return end
	local target = GAMEMODE:FindPlayer(args)
	
	if ply.DarkRPVars["CF.Operator"] == nil then
		ply:SendMessage(Color(160, 32, 240), "You need a SIM card to make a call.")
	elseif ply.DarkRPVars["CF.Signal"] == 0 then
		ply:SendMessage(Color(160, 32, 240), "You need a signal to make a call.")
	elseif target then
		if target == ply then
			ply:SendMessage(Color(160, 32, 240), "You try to call yourself. Your cell phone refuses.")
		elseif target.DarkRPVars["CF.Operator"] == nil then
			ply:SendMessage(Color(160, 32, 240), "We could not find the cell phone for " .. target:Nick() .. ".")
		elseif target.DarkRPVars["CF.Call.Status"] > 0 then
			-- Target is busy
			ply:SendMessage(Color(160, 32, 240), "You get a busy tone..")
		elseif target.DarkRPVars["CF.Signal"] == 0 then
			ply:SendMessage(Color(160, 32, 240), target:Nick() .. " is currently unreachable.")
		else
			-- Make the call
			ply:SetDarkRPVar("CF.Call.Status", 3)
			target:SetDarkRPVar("CF.Call.Status", 1)

			local call = {
				caller = ply,
				time = 0,
				target = target
			}
			ply.CFVars["call"] = call
			target.CFVars["call"] = call

			-- Send some messages and stuff
			ply:SendMessage(Color(160, 32, 240), "Calling " .. target:Nick() .. "..")
			GAMEMODE:TalkToRange(target, "Event", target:Nick() .. "'s phone starts ringing.", 250)
			target:SendMessage(Color(160, 32, 240), "Incoming call from " .. ply:Nick() .. ".")
			target:SendMessage(Color(160, 32, 240), "Type /pickup or /hangup")
		end
	else
		ply:SendMessage(Color(160, 32, 240), "We could not find " .. args .. ".")
	end

	return ""
end
hook.Add("PlayerSay", "CF.Call", function(ply, message, isTeam)
	-- Override the default call command
	if string.find(message, "/call") then
		message = message:gsub("^/call([ ]?)", "")
		CF.Call(ply, message)

		return "" -- Return a string so no other hook of this type will be called
	end
end)

function CF.AnswerCall(ply, args)
	local caller = ply.CFVars["call"]["caller"]

	if ply.DarkRPVars["CF.Operator"] == nil then
		ply:SendMessage(Color(160, 32, 240), "You need a SIM card to answer a call.")
	elseif ply.DarkRPVars["CF.Call.Status"] == 0 then
		ply:SendMessage(Color(160, 32, 240), "Your phone is not ringing.")
	elseif caller then
		GAMEMODE:TalkToRange(ply, "Event", ply:Nick() .. " answers their phone.", 250)

		ply:SendMessage(Color(160, 32, 240), "You picked up the call.")
		caller:SendMessage(Color(160, 32, 240), ply:Nick() .. " picked up the call.")

		ply:SetDarkRPVar("CF.Call.Status", 2) 
	end

	return ""
end
AddChatCommand("/pickup", CF.AnswerCall)

function CF.CallTalk(listener, talker)
	-- Would you normally in DarkRP?
	local darkRP, darkRP3D = GAMEMODE:PlayerCanHearPlayersVoice(listener, talker)

	if listener.DarkRPVars["CF.Call.Status"] > 1 and talker.DarkRPVars["CF.Call.Status"] > 1 then
		local call = listener.CFVars["call"]

		if (call["caller"] == talker and call["target"] == listener)
			or (call["caller"] == listener and call["target"] == talker) then
			return true, false
		end
	end

	return darkRP, darkRP3D
end
hook.Add("PlayerCanHearPlayersVoice", "CF.CallTalk", CF.CallTalk)

function CF.Hangup(ply, args)
	if ply.DarkRPVars["CF.Operator"] == nil then
		ply:SendMessage(Color(160, 32, 240), "You need a cell phone to do this.")
	elseif ply.DarkRPVars["CF.Call.Status"] == 0 then
		ply:SendMessage(Color(160, 32, 240), "You press the 'End call' button for no reason.")
		GAMEMODE:TalkToRange(ply, "Event", ply:Nick() .. " presses the 'End call' button on their phone for no reason.", 250)
	else
		local other = ply.CFVars["call"]["caller"]
		if other == ply then
			other = ply.CFVars["call"]["target"]
		end

		-- Notify the users
		other:SendMessage(Color(160, 32, 240), ply:Nick() .. " hangs up the phone.")
		ply:SendMessage(Color(160, 32, 240), "You hung up.")

		-- End the call
		ply:SetDarkRPVar("CF.Call.Status", 0)
		other:SetDarkRPVar("CF.Call.Status", 0)

		-- Make the caller pay
		hook.Call("CF.Hook.PayCall", GAMEMODE, ply.CFVars["call"])
	end
end
AddChatCommand("/hangup", CF.Hangup)
hook.Add("PlayerDisconnected", "CF.Hangup", CF.Hangup)

---------------------------------------------------------
-- TEXT MESSAGES SYSTEM
---------------------------------------------------------
-- SMS maybe?
-- NOTE: Refactor to SMS
function CF.SMS(ply, args)
	if args == "" then return "" end
	if ply.DarkRPVars["CF.Operator"] == nil then
		ply:SendMessage(Color(160, 32, 240), "You need a cell phone to do this.")
	else
		args = string.explode(args, " ")
		local target = GAMEMODE:FindPlayer(args[1])
		table.remove(args, 1)
		local message = table.concat(args, " ")

		if target then
			local canAfford = hook.Call("CF.Hook.PaySMS", GAMEMODE, ply)
			if canAfford then
				ply:SendMessage(Color(160, 32, 240), "(SMS) " .. ply:Nick() .. " -> " .. target:Nick() .. ": " .. message)
				target:SendMessage(Color(160, 32, 240), "(SMS) " .. ply:Nick() .. " -> " .. target:Nick() .. ": " .. message)
				target:EmitSound("cellfone/text_message.wav", 75, 100)
			else
				ply:SendMessage(Color(160, 32, 240), "You cannot afford to send a text message.")
			end
		else
			ply:SendMessage(Color(160, 32, 240), "We could not find " .. args[1] .. ".")
		end
	end

	return ""
end
AddChatCommand("/text", CF.SMS)
AddChatCommand("/sms", CF.SMS)

---------------------------------------------------------
-- SIM CARDS
---------------------------------------------------------
-- TODO: Make this into a cool entity!
/*function CF.OfferSIM(ply, args)
	if not args or args == "" then return end

	if ply.CFVars["company"] == nil then
		ply:SendMessage(Color(160, 32, 240), "You do not own a cell operator company.")
	else
		local target = GAMEMODE:FindPlayer(args)

		if target and target != ply then
			if target.CFVars["company"] != nil then
				ply:SendMessage(Color(160, 32, 240), "You can not offer other cell operator company owners a SIM card.")
			else
				ply:SendMessage(Color(160, 32, 240), target:Nick() .. " was offered a SIM card.")

				-- Output prices and such
				target:SendMessage(Color(160, 32, 240), "You were offered a SIM card by " .. ply.CFVars["company"]["name"] .. ".")
				target:SendMessage(Color(147, 112, 219), "Rates pr. minute: $" .. ply.CFVars["company"]["call"])
				target:SendMessage(Color(147, 112, 219), "Rates pr. SMS: $" .. ply.CFVars["company"]["sms"])
				target:SendMessage(Color(147, 112, 219), "Type /simaccept to accept this SIM card")

				CF.SIM[target] = ply.CFVars["company"]["name"]
			end
		else
			ply:SendMessage(Color(160, 32, 240), "We could not find " .. args .. ".")
		end
	end

	return ""
end
AddChatCommand("/simoffer", CF.OfferSIM)

function CF.AcceptSIM(ply, args)
	if CF.SIM[ply] != nil then
		ply:SetDarkRPVar("CF.Operator", CF.SIM[ply])

		ply:SendMessage(Color(160, 32, 240), "You have accepted the SIM card.")
		for _, owner in pairs(player.GetAll()) do
			if owner.CFVars["company"] == nil then continue end
			if owner.CFVars["company"]["name"] == CF.SIM[ply] then
				owner:SendMessage(Color(160, 32, 240), ply:Nick() .. " has accepted your SIM card.")
				break
			end
		end
		CF.SIM[ply] = nil
	end
	return ""
end
AddChatCommand("/simaccept", CF.AcceptSIM)

function CF.RejectSIM(ply, args)
	ply:SendMessage(Color(160, 32, 240), "You have rejected the SIM card.")
	for _, owner in pairs(player.GetAll()) do
		if owner.CFVars["company"] == nil then continue end
		if owner.CFVars["company"]["name"] == CF.SIM[ply] then
			owner:SendMessage(Color(160, 32, 240), ply:Nick() .. " has rejected your SIM card.")
			break
		end
	end
	CF.SIM[ply] = nil
	return ""
end
AddChatCommand("/simreject", CF.RejectSIM)*/

---------------------------------------------------------
-- THINK
---------------------------------------------------------
local tickNext = CurTime()
local tickDelay = 1

function CF.Think()
	if CurTime() >= tickNext then
		CF.TeamChanged()
		CF.UpdateSignal()
		CF.UpdateCall()

		tickNext = CurTime() + tickDelay
	end
end
hook.Add("Think", "CF.Think", CF.Think)
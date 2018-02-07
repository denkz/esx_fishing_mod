local Keys = {
  ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57, ["F11"] = 58,
  ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
  ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
  ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
  ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
  ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
  ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
  ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
  ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

ESX = nil
local PlayerData = {}
local HasAlreadyEnteredMarker = false
local LastZone = nil
local CurrentAction = nil
local FishHooked = FISH_WAITING
local CurrentFishingOdds = 0
local CurrentPikeLeaderboad = {}
local CurrentBassLeaderboad = {}
local CurrentSalmonLeaderboad = {}
local CurrentLeaderboard = nil

local FISH_WAITING = 1
local FISH_HOOKED = 2
local FISH_CAUGHT = 3

local ACTION_FISHING = 'fishing'
local ACTION_IN_FISHING_ZONE = 'in_fishing_zone'
local ACTION_SELLING_FISH = 'selling_fish'
local ACTION_FISHING_LEADERBOARD = 'fishing_leaderboard'

local CaughtTest = nil
local CaughtFish = nil

function DrawScreenText(text, color, position, size, center)
	SetTextCentre(center)
	SetTextColour(color[1], color[2], color[3], color[4])
	SetTextFont(color[5])
	SetTextScale(size[1], size[2])
	Citizen.InvokeNative(0x61BB1D9B3A95D802, 7)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(position[1], position[2])
end

function DrawScreenRect(color, position, size)
	Citizen.InvokeNative(0x61BB1D9B3A95D802, 6)
	DrawRect(position[1], position[2], size[1], size[2], color[1], color[2], color[3], color[4])
end

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  PlayerData = xPlayer
end)

RegisterNetEvent('esx_fishing:playFishingAnimation')
AddEventHandler('esx_fishing:playFishingAnimation', function()
	TaskStartScenarioInPlace(GetPlayerPed(-1), "WORLD_HUMAN_STAND_FISHING", 0, false)
	CurrentAction = ACTION_FISHING
	CurrentActionMsg  = 'Håll ner E för att sluta fiska'
	FishHooked = FISH_WAITING
end)

AddEventHandler('esx_fishing:hasEnteredMarker', function(zone)
	if zone == 'FishingPosition1' or zone == 'FishingPosition2' or zone == 'FishingPosition3' or zone == 'FishingPosition4' or zone == 'FishingPosition5' or zone == 'FishingPosition6' then
		CurrentActionMsg  = 'Tryck E för att fiska'
		CurrentAction = ACTION_IN_FISHING_ZONE
	end

	if zone == 'SellFish' then
		CurrentActionMsg  = 'Tryck E för att sälja fisken'
		CurrentAction = ACTION_SELLING_FISH
	end

	if zone == 'FishingLeaderboard' then
		CurrentActionMsg  = 'Tryck E för att se Fishing Leaderboard'
		CurrentAction = ACTION_FISHING_LEADERBOARD
	end
end)

AddEventHandler('esx_fishing:hasExitedMarker', function(zone)
	CurrentAction = nil
end)


RegisterNetEvent('esx_fishing:setblip')
AddEventHandler('esx_fishing:setblip', function(position)
	StealBlip1 = AddBlipForCoord(Config.Zones.StealCarPosition1.Pos.x, Config.Zones.StealCarPosition1.Pos.y, Config.Zones.StealCarPosition1.Pos.z)

	SetBlipSprite (StealBlip1, 229)
	SetBlipDisplay(StealBlip1, 4)
	SetBlipScale  (StealBlip1, 0.6)
	SetBlipColour (StealBlip1, 1)
	SetBlipAsShortRange(StealBlip1, true)

	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Valuable Car")
	EndTextCommandSetBlipName(StealBlip1)
end)

-- Display markers
Citizen.CreateThread(function()
	while true do

		Wait(0)

		local coords = GetEntityCoords(GetPlayerPed(-1))

		for k,v in pairs(Config.Zones) do
			if(v.Type ~= -1 and GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < Config.DrawDistance) then
				DrawMarker(v.Type, v.Pos.x, v.Pos.y, v.Pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, v.Size.x, v.Size.y, v.Size.z, v.Color.r, v.Color.g, v.Color.b, 100, false, true, 2, false, false, false, false)
			end
		end

		local isInMarker  = false
		local currentZone = nil

		for k,v in pairs(Config.Zones) do
			if(GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < v.Size.x) then
				isInMarker  = true
				currentZone = k
			end
		end

		if (isInMarker and not HasAlreadyEnteredMarker) or (isInMarker and LastZone ~= currentZone) then
			HasAlreadyEnteredMarker = true
			LastZone = currentZone
			TriggerEvent('esx_fishing:hasEnteredMarker', currentZone)
		end

		if not isInMarker and HasAlreadyEnteredMarker then
			HasAlreadyEnteredMarker = false
			TriggerEvent('esx_fishing:hasExitedMarker', LastZone)
		end
	end
end)

-- GUI
Citizen.CreateThread(function()
	while true do
		Wait(0) 

		while FishHooked == FISH_HOOKED and CurrentAction == ACTION_FISHING do
			DrawScreenText('Tryck ~g~SPACE ~w~för att fånga fisk!', {255, 255, 255, 255, 1}, { 0.448, 0.3725 }, { 0.75, 0.75 }, true)
			DrawScreenRect({33, 33, 33, 150}, { 0.448, 0.3925 }, {0.25, 0.08})
			Wait(0)
		end

		while CaughtFish ~= nil do
			local bigOrSmall = ''

			if CaughtFish.big > 90 then
				bigOrSmall = 'stor'
			end

			if CaughtFish.big < 25 then
				bigOrSmall = 'liten'
			end

			DrawScreenText("Du fånga en " .. bigOrSmall .. " " .. CaughtFish.name .. " " .. CaughtFish.sex .. " vikt ~g~ " .. CaughtFish.weight .. " gram~w~!", {255, 255, 255, 255, 1}, { 0.448, 0.3725 }, { 0.75, 0.75 }, true)
			DrawScreenRect({33, 33, 33, 150}, { 0.448, 0.3925 }, {0.45, 0.08})
			Wait(0)
		end

		--while DisplayLeaderboard and CurrentPikeLeaderboard ~= nil and CurrentSalmonLeaderboad ~= nil and CurrentBassLeaderboad ~= nil do
		while DisplayLeaderboard do
			local titleMessage = "Current Fishing Leaderboard"
			local pikeMessage = "Gädda - Ingen fångad idag!"
			local salmonMessage = "Lax - Ingen fångad idag!"
			local bassMessage = "Havsabborre - Ingen fångad idag!"

			if CurrentPikeLeaderboad[1] ~= nil then
				pikeMessage = "Gädda - ~g~" .. CurrentPikeLeaderboad[1].owner_name .. "~w~ - " .. CurrentPikeLeaderboad[1].weight .. " gram"
			end
			if CurrentSalmonLeaderboad[1] ~= nil then
				salmonMessage = "Lax - ~g~" .. CurrentSalmonLeaderboad[1].owner_name .. "~w~ - " .. CurrentSalmonLeaderboad[1].weight .. " gram"
			end
			if CurrentBassLeaderboad[1] ~= nil then
				bassMessage = "Havsabborre - ~g~" .. CurrentBassLeaderboad[1].owner_name .. "~w~ - " .. CurrentBassLeaderboad[1].weight .. " gram"
			end

			DrawScreenText(titleMessage, {255, 255, 255, 255, 1}, { 0.448, 0.3025 }, { 0.45, 0.45 }, true)
			DrawScreenText(pikeMessage, {255, 255, 255, 255, 1}, { 0.448, 0.3225 }, { 0.45, 0.45 }, true)
			DrawScreenText(salmonMessage, {255, 255, 255, 255, 1}, { 0.448, 0.3425 }, { 0.45, 0.45 }, true)
			DrawScreenText(bassMessage, {255, 255, 255, 255, 1}, { 0.448, 0.3625 }, { 0.45, 0.45 }, true)

			DrawScreenRect({33, 33, 33, 150}, { 0.448, 0.3425 }, {0.25, 0.12})
			Wait(0)
		end
	end
end)

-- Create Blips
Citizen.CreateThread(function()
	for k,v in pairs(Config.Blips) do
		local blip = AddBlipForCoord(v.Pos.x, v.Pos.y, v.Pos.z)

		SetBlipSprite (blip, v.BlipId)
		SetBlipDisplay(blip, 4)
		SetBlipScale  (blip, 1.0)
		SetBlipColour (blip, 38)
		SetBlipAsShortRange(blip, true)

		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(v.BlipName)
		EndTextCommandSetBlipName(blip)
	end
end)

-- Display alerts
Citizen.CreateThread(function()
	while true do

		Wait(0)

		local playerPedPos = GetEntityCoords(GetPlayerPed(-1), true)
		local fishingRod = GetClosestObjectOfType(playerPedPos, 10.0, GetHashKey("prop_fishing_rod_01"), false, false, false)
		
		if (IsPedActiveInScenario(GetPlayerPed(-1)) == false) then
			SetEntityAsMissionEntity(fishingRod, 1, 1)
			DeleteEntity(fishingRod)
		end
	end
end)

--Display alerts
Citizen.CreateThread(function()
	while true do

		Wait(0)

		if CurrentAction ~= nil then
			SetTextComponentFormat('STRING')
			AddTextComponentString(CurrentActionMsg)
			DisplayHelpTextFromStringLabel(0, 0, 1, -1)
		end
	end
end)


-- Fishing logic
Citizen.CreateThread(function()
	while true do

		Wait(0)

		if IsControlPressed(0,  Keys['E']) and CurrentAction == ACTION_IN_FISHING_ZONE then
			TriggerServerEvent('esx_fishing:fish')
			CurrentAction = 'tryfish'
			Wait(1000)
		end

		if IsControlPressed(0,  Keys['E']) and CurrentAction == ACTION_FISHING then
			ClearPedTasksImmediately(GetPlayerPed(-1))
			CurrentAction = nil				
		end

		if IsControlPressed(0,  Keys['E']) and CurrentAction == ACTION_FISHING_LEADERBOARD then
			ESX.TriggerServerCallback('esx_fishing:getLeaderboard', function(leaderboard) 
				for k,v in pairs(leaderboard) do
					if k == 'Pike' then
						CurrentPikeLeaderboad = v
					end

					if k == 'Bass' then
						CurrentBassLeaderboad = v
					end

					if k == 'Salmon' then
						CurrentSalmonLeaderboad = v
					end
				end
			end)

			DisplayLeaderboard = true

			Wait(1000)
			DisplayLeaderboard = true

			Wait(10000)

			DisplayLeaderboard = false

			CurrentAction = nil				
		end

		if IsControlPressed(0,  Keys['E']) and CurrentAction == ACTION_SELLING_FISH then
			TriggerServerEvent('esx_fishing:sellAllFish')
			CurrentAction = nil
		end

		if IsControlPressed(0,  Keys['F9']) then
			ClearPedTasksImmediately(GetPlayerPed(-1))
			CurrentAction = nil				
		end

		if CurrentAction == ACTION_FISHING then
			Wait(0)

			if FishHooked == FISH_WAITING then
				-- Waiting for a fish to bite, sleep 1 second and check if we got something
				Wait(1000)

				if CurrentFishingOdds < 15 then
					CurrentFishingOdds = CurrentFishingOdds + 1
				end

				if math.random(1, 600) < CurrentFishingOdds then
					FishHooked = FISH_HOOKED
				end
			end

			if FishHooked == FISH_HOOKED and IsControlPressed(0, Keys['SPACE']) then
				FishHooked = FISH_CAUGHT

				ESX.TriggerServerCallback('esx_fishing:receiveFish', function(fish) 
					CaughtFish = fish
				end)

				CurrentAction = nil
				ClearPedTasksImmediately(GetPlayerPed(-1))
				FishHooked = false
				CurrentFishingOdds = 0

				Wait(10000)
				CaughtFish = nil
			end
		end
	end
end)


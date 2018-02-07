ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('esx_fishing:giveme')
AddEventHandler('esx_fishing:giveme', function()
	local xPlayer        = ESX.GetPlayerFromId(source)

	xPlayer.addInventoryItem("Fishing Lure", 100)
end)


ESX.RegisterServerCallback('esx_fishing:getLeaderboard', function(source, cb)
	local xPlayer    = ESX.GetPlayerFromId(source)
	MySQL.Async.fetchAll('SELECT o.* FROM `fishes` o LEFT JOIN `fishes` b ON o.name = b.name AND (o.weight < b.weight or (o.weight = b.weight and o.id < b.id)) WHERE b.weight is NULL', {}, function(result)
		local leaderboard  = {}
		for i=1, #result, 1 do
			if leaderboard[result[i].name] == nil then
				leaderboard[result[i].name] = {}
			end

			table.insert(leaderboard[result[i].name], {
				owner_name = result[i].owner_name,
				weight = result[i].weight
			})
		end
		
		cb(leaderboard)
	end)
end)

ESX.RegisterServerCallback('esx_fishing:receiveFish', function(source, cb)
	local xPlayer    = ESX.GetPlayerFromId(source)

	local fishes = {'Pike', 'Bass', 'Salmon'}
	local sexes = {'Hona', 'Hane'}

	local smallPikeWeights = {500, 1000}
	local smallBassWeights = {100, 500}
	local smallSalmonWeights = {500, 1000}

	local pikeWeights = {1000, 5000}
	local bassWeights = {250, 500}
	local salmonWeights = {1000, 6000}

	local bigPikeWeights = {5000, 20000}
	local bigBassWeights = {500, 1500}
	local bigSalmonWeights = {6000, 30000}

	math.randomseed(os.time())

	local randomFish = fishes[math.random(1, 3)]
	local randomSex = sexes[math.random(1, 2)]
	local randomWeight = 0
	local randomSmallOrBigFish = math.random(1,100)

	--BIG FISHES
	if randomFish == 'Pike' and randomSmallOrBigFish > 90 then
		randomWeight = math.random(bigPikeWeights[1], bigPikeWeights[2])
	elseif randomFish == 'Bass' and randomSmallOrBigFish > 90 then
		randomWeight = math.random(bigBassWeights[1], bigBassWeights[2])
	elseif randomFish == 'Salmon' and randomSmallOrBigFish > 90 then
		randomWeight = math.random(bigSalmonWeights[1], bigSalmonWeights[2])
	-- SMALL FISHES
	elseif randomFish == 'Pike' and randomSmallOrBigFish < 25 then
		randomWeight = math.random(smallPikeWeights[1], smallPikeWeights[2])
	elseif randomFish == 'Bass' and randomSmallOrBigFish < 25 then
		randomWeight = math.random(smallBassWeights[1], smallBassWeights[2])
	elseif randomFish == 'Salmon' and randomSmallOrBigFish < 25 then
		randomWeight = math.random(smallSalmonWeights[1], smallSalmonWeights[2])
	-- NORMAL FISHES
	elseif randomFish == 'Pike' and randomSmallOrBigFish > 24 and randomSmallOrBigFish < 91 then
		randomWeight = math.random(pikeWeights[1], pikeWeights[2])
	elseif randomFish == 'Bass' and randomSmallOrBigFish > 24 and randomSmallOrBigFish < 91 then
		randomWeight = math.random(bassWeights[1], bassWeights[2])
	elseif randomFish == 'Salmon' and randomSmallOrBigFish > 24 and randomSmallOrBigFish < 91 then
		randomWeight = math.random(salmonWeights[1], salmonWeights[2])
	end

	local itemName = randomFish

	if randomSmallOrBigFish < 25 then
		itemName = 'Small ' .. randomFish
	end

	if randomSmallOrBigFish > 90 then
		itemName = 'Big ' .. randomFish
	end

	local fish = {weight = randomWeight, name = randomFish, sex = randomSex, big = randomSmallOrBigFish}

	xPlayer.addInventoryItem(itemName, 1)

	local result = MySQL.Sync.fetchAll("SELECT * FROM users WHERE identifier = @identifier", {
	['@identifier'] = xPlayer.identifier
	})

	local firstname     = "Unknown"
	local lastname      = ""

	local user      = result[1]
	firstname     = user['firstname']
	lastname      = user['lastname']


	-- SAVE FISH TO DATABASE
	MySQL.Async.execute('INSERT INTO fishes (`owner_identifier`, `owner_name`, `weight`, `name`, `sex`) VALUES (@identifier, @owner_name, @weight, @name, @sex);', {identifier = xPlayer.identifier, owner_name = firstname .. " " .. lastname, weight = fish.weight, name = fish.name, sex = fish.sex}, function(e)
		cb(fish)
	end)
end)

RegisterServerEvent('esx_fishing:sellAllFish')
AddEventHandler('esx_fishing:sellAllFish', function()
	local xPlayer    = ESX.GetPlayerFromId(source)

	local amountOfBass = 0
	local amountOfSalmon = 0
	local amountOfPike = 0
	local amountOfSmallBass = 0
	local amountOfSmallSalmon = 0
	local amountOfSmallPike = 0
	local amountOfBigBass = 0
	local amountOfBigSalmon = 0
	local amountOfBigPike = 0
	local amountOfCashToReceive = 0

	for i=1, #xPlayer.inventory, 1 do
		local item = xPlayer.inventory[i]

		if item.name == "Bass" and item.count > 0 then
			amountOfBass = item.count

			amountOfCashToReceive = amountOfCashToReceive + item.count * Config.FishPrices.Bass
		end

		if item.name == "Salmon" and item.count > 0 then
			amountOfSalmon = item.count

			amountOfCashToReceive = amountOfCashToReceive + item.count * Config.FishPrices.Salmon
		end

		if item.name == "Pike" and item.count > 0 then
			amountOfPike = item.count

			amountOfCashToReceive = amountOfCashToReceive + item.count * Config.FishPrices.Pike
		end

		if item.name == "Small Bass" and item.count > 0 then
			amountOfSmallBass = item.count

			amountOfCashToReceive = amountOfCashToReceive + item.count * Config.FishPrices.SmallBass
		end

		if item.name == "Small Salmon" and item.count > 0 then
			amountOfSmallSalmon = item.count

			amountOfCashToReceive = amountOfCashToReceive + item.count * Config.FishPrices.SmallSalmon
		end

		if item.name == "Small Pike" and item.count > 0 then
			amountOfSmallPike = item.count

			amountOfCashToReceive = amountOfCashToReceive + item.count * Config.FishPrices.SmallPike
		end

		if item.name == "Big Bass" and item.count > 0 then
			amountOfBigBass = item.count

			amountOfCashToReceive = amountOfCashToReceive + item.count * Config.FishPrices.BigBass
		end

		if item.name == "Big Salmon" and item.count > 0 then
			amountOfBigSalmon = item.count

			amountOfCashToReceive = amountOfCashToReceive + item.count * Config.FishPrices.BigSalmon
		end

		if item.name == "Big Pike" and item.count > 0 then
			amountOfBigPike = item.count

			amountOfCashToReceive = amountOfCashToReceive + item.count * Config.FishPrices.BigPike
		end
	end

	if amountOfBass > 0 then
		xPlayer.removeInventoryItem('Bass', amountOfBass)
	end
	if amountOfPike > 0 then
		xPlayer.removeInventoryItem('Pike', amountOfPike)
	end
	if amountOfSalmon > 0 then
		xPlayer.removeInventoryItem('Salmon', amountOfSalmon)
	end

	if amountOfSmallBass > 0 then
		xPlayer.removeInventoryItem('Small Bass', amountOfSmallBass)
	end
	if amountOfSmallPike > 0 then
		xPlayer.removeInventoryItem('Small Pike', amountOfSmallPike)
	end
	if amountOfSmallSalmon > 0 then
		xPlayer.removeInventoryItem('Small Salmon', amountOfSmallSalmon)
	end

	if amountOfBigBass > 0 then
		xPlayer.removeInventoryItem('Big Bass', amountOfBigBass)
	end
	if amountOfBigPike > 0 then
		xPlayer.removeInventoryItem('Big Pike', amountOfBigPike)
	end
	if amountOfBigSalmon > 0 then
		xPlayer.removeInventoryItem('Big Salmon', amountOfBigSalmon)
	end
	
	if amountOfSalmon == 0 and amountOfBass == 0 and amountOfPike == 0 and amountOfBigSalmon == 0 and amountOfBigBass == 0 and amountOfBigPike == 0 and amountOfSmallSalmon == 0 and amountOfSmallBass == 0 and amountOfSmallPike == 0then
		TriggerClientEvent('esx:showNotification', xPlayer.source, 'Du har ingen fisk att sälja!')
	else
		xPlayer.addMoney(amountOfCashToReceive)

		TriggerClientEvent('esx:showNotification', xPlayer.source, 'Du sålde all din fisk för $' .. amountOfCashToReceive)
	end

end)

RegisterServerEvent('esx_fishing:fish')
AddEventHandler('esx_fishing:fish', function()
	local xPlayer    = ESX.GetPlayerFromId(source)

	local hasFishingRod = false
	local amountOfLure = 0

	for i=1, #xPlayer.inventory, 1 do
		local item = xPlayer.inventory[i]

		if item.name == "Fishing Rod" and item.count > 0 then
			hasFishingRod = true
		end

		if item.name == "Fishing Lure" then
			amountOfLure = item.count
		end
	end

	local time = os.date('*t')

	if time.hour < 24 then
		if hasFishingRod and amountOfLure > 0 then
			TriggerClientEvent('esx_fishing:playFishingAnimation', source)
			xPlayer.removeInventoryItem('Fishing Lure', 1)
		else 
			TriggerClientEvent('esx:showNotification', xPlayer.source, 'Du behöver ett fiskespö och bete, besök en affär för att köpa det!')
		end
	else 
		TriggerClientEvent('esx:showNotification', xPlayer.source, 'Fiskarna sover..')
	end
end)

ESX.RegisterServerCallback('esx_fishing:getPlayerInventory', function(source, cb)

  local xPlayer    = ESX.GetPlayerFromId(source)
  local items      = xPlayer.inventory

  cb({
    items      = items
  })

end)

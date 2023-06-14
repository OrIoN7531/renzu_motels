--DeleteResourceKvp('renzu_motels')
GlobalState.Motels = nil
local db = import 'server/sql'
local rental_period = {
	['hour'] = 3600,
	['day'] = 86400,
	['month'] = 2592000
}
CreateInventoryHooks = function(motel,Type)
	if GetResourceState('ox_inventory') ~= 'started' then return end
	local inventory = '^'..Type..'_'..motel..'_%w+'
	local hookId = exports.ox_inventory:registerHook('swapItems', function(payload)
		return false
	end, {
		print = false,
		itemFilter = config.stashblacklist[Type].blacklist,
		inventoryFilter = {
			inventory,
		}
	})
end

local function resetKeyOk(data)
    local motels = GlobalState.Motels

        motels[data.motel].rooms[data.index].lockKey = GenerateLockKey() -- Update the lockKey for the player

        GlobalState.Motels = motels

        local motels = GlobalState.Motels
        local name = data.motel .. "-" .. data.index
        local doorlockData = db.fetchDoorlockDataByName(name)
        local door = exports.ox_doorlock:getDoorFromName(name)
        local id = db.getDoorlockIDByName(name)

        if doorlockData and door and id then
            local decodedData = json.decode(doorlockData)
            if type(decodedData) ~= "table" then
                decodedData = { decodedData }
            end

            if decodedData and type(decodedData) == "table" then
                if decodedData.items and decodedData.items[1] then
                    decodedData.items[1].metadata = motels[data.motel].rooms[data.index].lockKey
                    print(motels[data.motel].rooms[data.index].lockKey)
                else
                    decodedData.items = {
                        {
                            metadata = motels[data.motel].rooms[data.index].lockKey,
                            name = "keys"
                        }
                    }
                end

                local coords = vector3(decodedData.coords.x, decodedData.coords.y, decodedData.coords.z)
                decodedData.coords = coords

                exports.ox_doorlock:editDoor(id, decodedData)
            end
        end
end

Citizen.CreateThreadNow(function()
    Wait(2000)
    GlobalState.Motels = db.fetchAll()
    local motels = GlobalState.Motels
    for k, v in pairs(config.motels) do
        for doorIndex, _ in pairs(v.doors) do
            local doorIndex = tonumber(doorIndex)
            local motelData = motels[v.motel]
            if motelData then
                motelData.rooms[doorIndex].lock = true
                if v.motel and v.owned then
                    motelData.owned = v.owned
                    motelData.ownerLockKey = v.ownerLockKey
                    db.updateall('owned = ?, ownerLockKey = ?', '`motel`', v.motel, motelData.owned, motelData.ownerLockKey)
                end
                if motelData.rooms[doorIndex].players and GetResourceState('ox_inventory') == 'started' then
                    for id, _ in pairs(motelData.rooms[doorIndex].players) do
                        local stashid = v.uniquestash and id or 'room'
                        exports.ox_inventory:RegisterStash('stash_' .. v.motel .. '_' .. stashid .. '_' .. doorIndex, 'Storage', 70, 70000, false)
                        exports.ox_inventory:RegisterStash('fridge_' .. v.motel .. '_' .. stashid .. '_' .. doorIndex, 'Fridge', 70, 70000, false)
                    end
                    CreateInventoryHooks(v.motel, 'stash')
                    CreateInventoryHooks(v.motel, 'fridge')
                end
            else
                print("Motel data not found for " .. v.motel)
            end
        end
    end
    GlobalState.Motels = motels
    local save = {}
    while true do
        if config.autokickIfExpire then
            local motels = GlobalState.Motels
            for motel, data in pairs(motels) do
                if not save[motel] then
                    save[motel] = 0
                end
                for doorIndex, v in pairs(data.rooms or {}) do
                    local doorIndex = tonumber(doorIndex)
                    for player, char in pairs(v.players or {}) do
                        if (char.duration - os.time()) < 0 then
                            motels[motel].rooms[doorIndex].players[player] = nil
                            local resetData = { motel = motel, index = doorIndex }
                            resetKeyOk(resetData) -- Call the resetKey function with the expired room data
                            db.updateall('rooms = ?', '`motel`', motel, json.encode(motels[motel].rooms))
                        end
                    end
                    if save[motel] <= 0 then
                        save[motel] = 60
                        db.updateall('rooms = ?', '`motel`', motel, json.encode(motels[motel].rooms))
                    end
                end
                save[motel] -= 1
            end
            GlobalState.Motels = motels
        else
            local motels = GlobalState.Motels
            for motel, data in pairs(motels) do
                if not save[motel] then
                    save[motel] = 0
                end
                for doorIndex, v in pairs(data.rooms or {}) do
                    local doorIndex = tonumber(doorIndex)
                    for player, char in pairs(v.players or {}) do
                        if (char.duration - os.time()) < 0 then
                            local resetData = { motel = motel, index = doorIndex }
                            resetKeyOk(resetData) -- Call the resetKey function with the expired room data
                        end
                    end
                end
            end
            GlobalState.Motels = motels
        end
        GlobalState.MotelTimer = os.time()
        Wait(60000)
    end
end)

lib.callback.register('renzu_motels:rentaroom', function(src, data)
    local xPlayer = GetPlayerFromId(src)
    local motels = GlobalState.Motels
    local identifier = xPlayer.identifier
    if not motels[data.motel].rooms[data.index].players[identifier] and data.duration > 0 then
        local money = xPlayer.getAccount(data.payment).money
        local amount = data.duration * data.rate
        if money < amount then
            return false
        end
        xPlayer.removeAccountMoney(data.payment, amount)
        if not motels[data.motel].rooms[data.index].players[identifier] then
            motels[data.motel].rooms[data.index].players[identifier] = {}
        end
        motels[data.motel].rooms[data.index].players[identifier].name = xPlayer.name
        motels[data.motel].rooms[data.index].players[identifier].duration = os.time() + (data.duration * rental_period[data.rental_period])
        motels[data.motel].revenue = motels[data.motel].revenue + amount
        motels[data.motel].rooms[data.index].lockKey = GenerateLockKey()
        GlobalState.Motels = motels
        db.updateall('rooms = ?, revenue = ?', '`motel`', data.motel, json.encode(motels[data.motel].rooms), motels[data.motel].revenue)

        local name = data.motel .. "-" .. data.index
        local doorlockData = db.fetchDoorlockDataByName(name)
        local door = exports.ox_doorlock:getDoorFromName(name)
        local id = db.getDoorlockIDByName(name)

        if doorlockData and door and id then
            local decodedData = json.decode(doorlockData)
            if type(decodedData) ~= "table" then
                decodedData = { decodedData }
            end

            if decodedData and type(decodedData) == "table" then
                if decodedData.items and decodedData.items[1] then
                    decodedData.items[1].metadata = motels[data.motel].rooms[data.index].lockKey
                else
                    decodedData.items = {
                        {
                            metadata = motels[data.motel].rooms[data.index].lockKey,
                            name = "keys"
                        }
                    }
                end

                local coords = vector3(decodedData.coords.x, decodedData.coords.y, decodedData.coords.z)
                decodedData.coords = coords

                exports.ox_doorlock:editDoor(id, decodedData)
            end
        end

        if GetResourceState('ox_inventory') == 'started' then
            local stashid = data.uniquestash and identifier or 'room'
            exports.ox_inventory:RegisterStash('stash_' .. data.motel .. '_' .. stashid .. '_' .. data.index, 'Storage', 70, 70000, false)
            exports.ox_inventory:RegisterStash('fridge_' .. data.motel .. '_' .. stashid .. '_' .. data.index, 'Fridge', 70, 70000, false)
        end

        return true
    end

    return false
end)

lib.callback.register('renzu_motels:payrent', function(src,data)
	local xPlayer = GetPlayerFromId(src)
	local motels = GlobalState.Motels
	local duration = data.amount / data.rate
	if duration < 1.0 then return false end
	local money = xPlayer.getAccount(data.payment).money
	if money < data.amount then
		return false
	end
	if motels[data.motel].rooms[data.index].players[xPlayer.identifier] then
		xPlayer.removeAccountMoney(data.payment,data.amount)
		motels[data.motel].revenue += data.amount
		motels[data.motel].rooms[data.index].players[xPlayer.identifier].duration += ( duration * rental_period[data.rental_period])
		GlobalState.Motels = motels
		db.updateall('rooms = ?, revenue = ?', '`motel`', data.motel, json.encode(motels[data.motel].rooms),motels[data.motel].revenue)
		return true
	end
	return false
end)

lib.callback.register('renzu_motels:getMotels', function(src,data)
	local xPlayer = GetPlayerFromId(src)
	local motels = GlobalState.Motels
	return motels, os.time()
end)

function GenerateLockKey()
    math.randomseed(os.time()) -- Set a new random seed

    local randomChars = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local lockKey = ""

    for i = 1, 6 do
        local randomIndex = math.random(1, #randomChars)
        local randomChar = string.sub(randomChars, randomIndex, randomIndex)
        lockKey = lockKey .. randomChar
    end

    return lockKey
end

function OwnerGenerateLockKey()
    math.randomseed(os.time()) -- Set a new random seed

    local randomChars = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local ownerLockKey = ""

    for i = 1, 4 do
        local randomIndex = math.random(1, #randomChars)
        local randomChar = string.sub(randomChars, randomIndex, randomIndex)
        ownerLockKey = ownerLockKey .. randomChar
    end

    return ownerLockKey
end

lib.callback.register('renzu_motels:motelkey', function(src, data)
	local xPlayer = GetPlayerFromId(src)
	local motels = GlobalState.Motels
	local lockKluc = motels[data.motel].rooms[data.index].lockKey

	local metadata = {
		type = lockKluc, -- Set the lockkey as the metadata type
		label = 'Motel Key',
		description = 'Motel: ' .. data.motel .. '  \n Číslo izby: ' .. '#' .. data.index .. '  \n Majiteľ: ' .. xPlayer.name .. ' ' .. xPlayer.lname,
		owner = xPlayer.identifier
	}

	return AddItem(src, 'keys', 1, metadata)
end)

lib.callback.register('renzu_motels:ownermotelkey', function(src, data)
    local xPlayer = GetPlayerFromId(src)
    local motels = GlobalState.Motels
    local ownerLockKey = motels[data.motel].ownerLockKey
    print(ownerLockKey)

    if ownerLockKey then
        local metadata = {
            type = ''.. ownerLockKey, -- Set the lockkey as the metadata type
            label = 'Uni. kľúč    \n',
            description = 'Motel: ' .. data.motel .. '  \n Majiteľ Motela: ' ..xPlayer.name.. ' ' ..xPlayer.lname,
            owner = xPlayer.identifier
        }

        print(metadata.type)
        print(ownerLockKey)

        return AddItem(src, 'keys', 1, metadata)
    else
        print("Owner lock key not found for the specified motel.")
        return false
    end
end)

lib.callback.register('renzu_motels:resetkey', function(src, data)
    local xPlayer = GetPlayerFromId(src)
    local motels = GlobalState.Motels
    local identifier = xPlayer.identifier

    if motels[data.motel].rooms[data.index].players[identifier] then
        motels[data.motel].rooms[data.index].lockKey = GenerateLockKey() -- Update the lockKey for the player
        motels[data.motel].rooms[data.index].players[identifier].name = xPlayer.name

        GlobalState.Motels = motels

        local name = data.motel .. "-" .. data.index
        local doorlockData = db.fetchDoorlockDataByName(name)
        local door = exports.ox_doorlock:getDoorFromName(name)
        local id = db.getDoorlockIDByName(name)

        if doorlockData and door and id then
            local decodedData = json.decode(doorlockData)
            if type(decodedData) ~= "table" then
                decodedData = { decodedData }
            end

            if decodedData and type(decodedData) == "table" then
                if decodedData.items and decodedData.items[1] then
                    decodedData.items[1].metadata = motels[data.motel].rooms[data.index].lockKey
                else
                    decodedData.items = {
                        {
                            metadata = motels[data.motel].rooms[data.index].lockKey,
                            name = "keys"
                        }
                    }
                end

                local coords = vector3(decodedData.coords.x, decodedData.coords.y, decodedData.coords.z)
                decodedData.coords = coords

                exports.ox_doorlock:editDoor(id, decodedData)
                db.updateall('rooms = ?', '`motel`', data.motel, json.encode(motels[data.motel].rooms))

                TriggerClientEvent('chatMessage', src, '^2Key Reset', {255, 255, 255}, 'The key for door "' .. name .. '" has been reset.')
                return true
            else
                print("Failed to decode data or decoded data is not a table.")
            end
        else
            print("No data found for the specified name or door ID.")
        end
    end

    return false
end)

lib.callback.register('renzu_motels:resetownerkey', function(src, data)
    local xPlayer = GetPlayerFromId(src)
    local motels = GlobalState.Motels
    local motelName = data.motel
    local ownerLockKeyGenerated = OwnerGenerateLockKey()

    motels[motelName].ownerLockKey = motelName .. "_" .. ownerLockKeyGenerated
    GlobalState.Motels = motels -- Update the GlobalState.Motels variable with the updated motels table

    local roomPrefix = motelName .. "-"
    local roomsToUpdate = {}

    for index, room in pairs(motels[motelName].rooms) do
        table.insert(roomsToUpdate, index)
    end

    if #roomsToUpdate > 0 then
        for _, roomIndex in ipairs(roomsToUpdate) do
            local doorName = motelName .. "-" .. roomIndex
            local doorlockData = db.fetchDoorlockDataByName(doorName)
            local door = exports.ox_doorlock:getDoorFromName(doorName)
            local doorlockID = db.getDoorlockIDByName(doorName)

            if doorlockData and door and doorlockID then
                local decodedData = json.decode(doorlockData)

                if type(decodedData) ~= "table" then
                    decodedData = { decodedData }
                end

                if decodedData and type(decodedData) == "table" then
                    if decodedData.items and decodedData.items[2] then
                        decodedData.items[2].metadata = motelName .. '_' .. ownerLockKeyGenerated
                    else
                        decodedData.items = {
                            decodedData.items[1],
                            {
                                metadata = motelName .. '_' .. ownerLockKeyGenerated,
                                name = "keys"
                            }
                        }
                    end

                    local coords = vector3(decodedData.coords.x, decodedData.coords.y, decodedData.coords.z)
                    decodedData.coords = coords

                    exports.ox_doorlock:editDoor(doorlockID, decodedData)
                    db.updateall('rooms = ?, ownerLockKey = ?', '`motel`', motelName, json.encode(motels[motelName].rooms), motels[motelName].ownerLockKey)
                else
                    print("Failed to decode data or decoded data is not a table.")
                end
            else
                print("No data found for the specified door name or door ID.")
            end
        end

        return true -- Return true to indicate success
    else
        print("No rooms found for the specified motel: " .. motelName)
    end

    return false
end)



lib.callback.register('renzu_motels:buymotel', function(src,data)
	local xPlayer = GetPlayerFromId(src)
	local motels = GlobalState.Motels
	local money = xPlayer.getAccount(data.payment).money
	if not motels[data.motel].owned and money >= data.businessprice then
		xPlayer.removeAccountMoney(data.payment,data.businessprice)
		motels[data.motel].owned = xPlayer.identifier
		GlobalState.Motels = motels
		db.updateall('owned = ?', '`motel`', data.motel, motels[data.motel].owned)
		return true
	end
	return false
end)


RegisterCommand("test2", function()
    local motels = GlobalState.Motels

    for motelName, motelData in pairs(motels) do
        print("Processing motel: " .. motelName)

        -- Check if the motel is owned
        if motelData.owned then
            local owner = motelData.owned
            print("Owner of motel " .. motelName .. ": " .. owner)

            -- Continue with the rest of the logic for processing rooms
            if motelData.rooms then
                for doorIndex, doorData in pairs(motelData.rooms) do
                    print("Processing door: " .. doorIndex)

                    -- Check if doorData is a table
                    if type(doorData) == "table" then
                        -- Iterate over numeric indices of doorData
                        for roomIndex, roomData in ipairs(doorData) do
                            print("Processing room: " .. roomIndex)

                            -- Rest of the code for processing rooms goes here
                            -- ...
                        end
                    else
                        print("Invalid data structure for doorData in motel " .. motelName)
                    end
                end
            else
                print("No room data found for motel " .. motelName)
            end
        else
            print("Motel " .. motelName .. " is not owned")
        end
    end
end)

lib.callback.register('renzu_motels:removeoccupant', function(src, data, index, player)
    local xPlayer = GetPlayerFromId(src)
    local motels = GlobalState.Motels
    if motels[data.motel].owned == xPlayer.identifier or motels[data.motel].rooms[index].players[player] then
        motels[data.motel].rooms[index].players[player] = nil
        motels[data.motel].rooms[data.index].lockKey = nil
        GlobalState.Motels = motels
        db.updateall('rooms = ?', '`motel`', data.motel, json.encode(motels[data.motel].rooms))

        local name = data.motel .. "-" .. data.index
        local doorlockData = db.fetchDoorlockDataByName(name)
        local door = exports.ox_doorlock:getDoorFromName(name)
        local id = db.getDoorlockIDByName(name)

        if doorlockData and door and id then
            local decodedData = json.decode(doorlockData)
            if type(decodedData) ~= "table" then
                decodedData = { decodedData }
            end

            if decodedData and type(decodedData) == "table" then
                if decodedData.items and decodedData.items[1] then
                    decodedData.items[1].metadata = "notowned"
                else
                    decodedData.items = {
                        {
                            metadata = "notowned",
                            name = "keys"
                        }
                    }
                end

                local coords = vector3(decodedData.coords.x, decodedData.coords.y, decodedData.coords.z)
                decodedData.coords = coords

                exports.ox_doorlock:editDoor(id, decodedData)
            end
        end

        return true
    end
    return false
end)

lib.callback.register('renzu_motels:addoccupant', function(src,data,index,player)
	local xPlayer = GetPlayerFromId(src)
	local toPlayer = GetPlayerFromId(tonumber(player[1]))
	local motels = GlobalState.Motels
	if motels[data.motel].owned == xPlayer.identifier and toPlayer then
		if motels[data.motel].rooms[index].players[toPlayer.identifier] then return 'exist' end
		if not motels[data.motel].rooms[index].players[toPlayer.identifier] then motels[data.motel].rooms[index].players[toPlayer.identifier] = {} end
		motels[data.motel].rooms[index].players[toPlayer.identifier].name = toPlayer.name
		motels[data.motel].rooms[index].players[toPlayer.identifier].duration = ( os.time() + (tonumber(player[2]) * rental_period[data.rental_period]))
		motels[data.motel].rooms[index].players[toPlayer.identifier].lockKey = GenerateLockKey()

		GlobalState.Motels = motels
		db.updateall('rooms = ?', '`motel`', data.motel, json.encode(motels[data.motel].rooms))
		if GetResourceState('ox_inventory') == 'started' then
			local stashid = data.uniquestash and toPlayer.identifier or 'room'
			exports.ox_inventory:RegisterStash('stash_'..data.motel..'_'..stashid..'_'..index, 'Storage', 70, 70000, false)
			exports.ox_inventory:RegisterStash('fridge_'..data.motel..'_'..stashid..'_'..index, 'Fridge', 70, 70000, false)
		end
		return true
	end
	return false
end)

lib.callback.register('renzu_motels:editrate', function(src,motel,rate)
	local xPlayer = GetPlayerFromId(src)
	local motels = GlobalState.Motels
	if motels[motel].owned == xPlayer.identifier then
		motels[motel].hour_rate = tonumber(rate)
		db.updateall('hour_rate = ?', '`motel`', motel, motels[motel].hour_rate)
		GlobalState.Motels = motels
		return true
	end
	return false
end)

lib.callback.register('renzu_motels:addemployee', function(src,motel,id)
	local xPlayer = GetPlayerFromId(src)
	local toPlayer = GetPlayerFromId(tonumber(id))
	local motels = GlobalState.Motels
	if motels[motel].owned == xPlayer.identifier and toPlayer then
		motels[motel].employees[toPlayer.identifier] = toPlayer.name ..' '.. toPlayer.lname
		GlobalState.Motels = motels
		db.updateall('employees = ?', '`motel`', motel, json.encode(motels[motel].employees))
		return true
	end
	return false
end)

lib.callback.register('renzu_motels:removeemployee', function(src,motel,identifier)
	local xPlayer = GetPlayerFromId(src)
	local motels = GlobalState.Motels
	if motels[motel].owned == xPlayer.identifier then
		motels[motel].employees[identifier] = nil
		GlobalState.Motels = motels
		db.updateall('employees = ?', '`motel`', motel, json.encode(motels[motel].employees))
		return true
	end
	return false
end)

lib.callback.register('renzu_motels:transfermotel', function(src,motel,id)
	local xPlayer = GetPlayerFromId(src)
	local toPlayer = GetPlayerFromId(tonumber(id))
	local motels = GlobalState.Motels
	if motels[motel].owned == xPlayer.identifier and toPlayer then
		motels[motel].owned = toPlayer.identifier
		GlobalState.Motels = motels
		db.updateall('owned = ?', '`motel`', motel, motels[motel].owned)
		return true
	end
	return false
end)

lib.callback.register('renzu_motels:sellmotel', function(src, data)
    local xPlayer = GetPlayerFromId(src)
    local motels = GlobalState.Motels
    if motels[data.motel].owned == xPlayer.identifier then
        motels[data.motel].owned = nil
        motels[data.motel].employees = {}
        motels[data.motel].ownerLockKey = "notOwnedMotel"
        GlobalState.Motels = motels
        db.updateall('owned = ?, employees = ?, ownerLockKey = ?', '`motel`', data.motel, motels[data.motel].owned, '[]', motels[data.motel].ownerLockKey)
        xPlayer.addMoney(data.businessprice / 2)
        return true
    end
    return false
end)


lib.callback.register('renzu_motels:withdrawfund', function(src,motel,amount)
	local xPlayer = GetPlayerFromId(src)
	local motels = GlobalState.Motels
	if motels[motel].owned == xPlayer.identifier then
		if motels[motel].revenue < amount or amount < 0 then return false end
		motels[motel].revenue -= amount
		GlobalState.Motels = motels
		db.updateall('revenue = ?', '`motel`', motel, motels[motel].revenue)
		xPlayer.addMoney(tonumber(amount))
		return true
	end
	return false
end)

local invoices = {}
lib.callback.register('renzu_motels:sendinvoice', function(src, motel, data)
	local toPlayer = tonumber(data[1])
	if data[1] == -1 or not GetPlayerFromId(toPlayer) then return false end
	local xPlayer = GetPlayerFromId(src)
	local motels = GlobalState.Motels
	if motels[motel].owned == xPlayer.identifier or motels[motel].employees[xPlayer.identifier] then
		local id = math.random(999,9999)
		invoices[id] = data[2]
		TriggerClientEvent('renzu_motels:invoice',toPlayer,{
			motel = motel,
			amount = data[2],
			description = data[3],
			id = id,
			payment = data[4],
			sender = src,
            motelname = motel
		})
		local timer = 60
		while invoices[id] ~= 'paid' and timer > 0 do timer -= 1 Wait(1000) end
		local paid = invoices[id] == 'paid'
		invoices[id] = nil
		return paid
	end
	return false
end)

lib.callback.register('renzu_motels:payinvoice', function(src, data)
	local xPlayer = GetPlayerFromId(src)
	local motels = GlobalState.Motels
	if invoices[data.id] then
		local money = xPlayer.getAccount('bank').money
		if money >= data.amount then
			motels[data.motel].revenue += tonumber(data.amount)
            --exports['Renewed-Banking']:handleTransaction(xPlayer, 'Motel '.. motels[data.motel], tonumber(data.amount), 'Invoice payment from hotel '.. motels[data.motel], 'Motel '.. motels[data.motel], xPlayer.name.. ' ' ..xPlayer.lname, 'withdraw')
            exports['Renewed-Banking']:handleTransaction(xPlayer.identifier, data.motel..' Motel ', tonumber(data.amount), data.description, 'Motel '.. data.motel ..'Invoice',  '', 'withdraw')
            xPlayer.removeAccountMoney('bank', tonumber(data.amount))
			GlobalState.Motels = motels
			invoices[data.id] = 'paid'
			db.updateall('revenue = ?', '`motel`', data.motel, motels[data.motel].revenue)
		end
		return invoices[data.id] == 'paid'
	end
	return false
end)

local routings = {}
lib.callback.register('renzu_motels:SetRouting', function(src,data,Type)
	local xPlayer = GetPlayerFromId(src)
	if Type == 'enter' then
		routings[src] = GetPlayerRoutingBucket(src)
		SetPlayerRoutingBucket(src,data.index+100)
	else
		SetPlayerRoutingBucket(src,routings[src])
	end
	return true
end)

lib.callback.register('renzu_motels:MessageOwner', function(src,data)
	local motels = GlobalState.Motels
	if not motels[data.motel] or motels[data.motel].owned ~= data.identifier then return end
	local xPlayer = GetPlayerFromId(data.identifier)
	if xPlayer then
		TriggerClientEvent('renzu_motels:MessageOwner',xPlayer.source, data)
		return true
	end
	return false
end)

RegisterServerEvent("renzu_motels:Door")
AddEventHandler('renzu_motels:Door', function(data)
	if not data.Mlo then
		local motels = GlobalState.Motels
		motels[data.motel].rooms[data.index].lock = not motels[data.motel].rooms[data.index].lock
		--db.updateall('rooms = ?', '`motel`', data.motel, json.encode(motels[data.motel].rooms))
		GlobalState.Motels = motels
	end
end)
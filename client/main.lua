local kvpname = GetCurrentServerEndpoint()..'_inshells'
CreateBlips = function()
	for k,v in pairs(config.motels) do
		local blip = AddBlipForCoord(v.rentcoord.x,v.rentcoord.y,v.rentcoord.z)
		SetBlipSprite(blip,475)
		SetBlipColour(blip,2)
		SetBlipAsShortRange(blip,true)
		SetBlipScale(blip,0.6)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(v.label)
		EndTextCommandSetBlipName(blip)
	end
end

RegisterNetEvent('renzu_motels:invoice')
AddEventHandler('renzu_motels:invoice', function(data)
	local motels = GlobalState.Motels
	local success2 = exports['qb-phone']:PhoneNotification('Price: '..data.amount ..' |  From '.. data.motel, data.description ..'', 'fas fa-users', '#FFBF00', 'NONE', 'fas fa-check-circle', 'fas fa-times-circle')
	local success = lib.callback.await('renzu_motels:payinvoice', false, data)
	if success2 then
		if success then
			Notify('You Successfully Pay the Invoice', 'success')
		else
			Notify('You dont have enough money', 'error')
		end
	else
		Notify('You declined payment request', 'error')
	end
end)

DoesPlayerHaveAccess = function(data)
    for identifier, _ in pairs(data) do
        if identifier == PlayerData?.identifier then return true end
    end
    return false
end

DoesPlayerHaveKey = function(data, room)
    local items = exports.ox_inventory:GetSlotsWithItem('keys')
	local motels = GlobalState.Motels
    if not items then return false end
    for _, slot in ipairs(items) do
        local metadata = slot.metadata
        if metadata and metadata.type == motels[data.motel].rooms[data.index].lockKey  then
            local owner = metadata.owner
            if owner and room and room.players[owner] then
                return room.players[owner]
            else
                return false
            end
        end
    end
    return false
end

GetPlayerKeys = function(data, room)
    local items = exports.ox_inventory:GetSlotsWithItem('keys')
	local motels = GlobalState.Motels
    if not items then return false end
    local keys = {}
    for _, slot in ipairs(items) do
        local metadata = slot.metadata
        if metadata and metadata.type == motels[data.motel].rooms[data.index].lockKey  then
            local key = metadata.owner and room and room.players[metadata.owner]
            if key then
                keys[metadata.owner] = key.name
            end
        end
    end
    return keys
end

Door = function(data)
    local dist = #(data.coord - GetEntityCoords(cache.ped)) < 2
    local motel = GlobalState.Motels[data.motel]
    local moteldoor = motel and motel.rooms[data.index]
	if data.Mlo then return end
    if (moteldoor and DoesPlayerHaveKey(data, moteldoor)) or (IsOwnerOrEmployee(data.motel)) then
        lib.RequestAnimDict('mp_doorbell')
        TaskPlayAnim(PlayerPedId(), "mp_doorbell", "open_door", 1.0, 1.0, 1000, 1, 1, 0, 0, 0)
        TriggerServerEvent('renzu_motels:Door', {
            motel = data.motel,
            index = data.index,
            doorindex = data.doorindex,
            coord = data.coord,
        })
        local text
        Wait(1000)
        local data = {
            file = 'door',
            volume = 0.5
        }
        SendNUIMessage({
            type = "playsound",
            content = data
        })
        Notify(text, 'inform')
    else
        Notify('you dont have access', 'error')
    end
end


isRentExpired = function(data)
	local motels = GlobalState.Motels[data.motel]
	local room = motels?.rooms[data.index] or {}
	local player = room?.players[PlayerData.identifier] or {}
	return player?.duration and player?.duration < GlobalState.MotelTimer
end

RoomFunction = function(data,identifier)
	if isRentExpired(data) then
		return Notify('Your Rent is Due.  \n  Please Pay to Access')
	end
	if data.type == 'door' then
		return Door(data)
	elseif data.type == 'stash' then
		local stashid = identifier or data.uniquestash and PlayerData.identifier or 'room'
		return OpenStash(data,stashid)
	elseif data.type == 'wardrobe' then
		return config.wardrobes[config.wardrobe]()
	elseif config.extrafunction[data.type] then
		local stashid = identifier or data.uniquestash and PlayerData.identifier or 'room'
		return config.extrafunction[data.type](data,stashid)
	end
end

LockPick = function(data)
	if data.Mlo then return end
	local success = nil
	SetTimeout(1000,function()
		repeat
		local lockpick = lib.progressBar({
			duration = 10000,
			label = 'Breaking in..',
			useWhileDead = false,
			canCancel = true,
			anim = {
				dict = 'veh@break_in@0h@p_m_one@',
				clip = 'low_force_entry_ds' 
			},
		})
		Wait(0)
		until success ~= nil
	end)
	success = lib.skillCheck({'easy', 'easy', {areaSize = 60, speedMultiplier = 2}, 'easy'})
	if lib.progressActive() then
		lib.cancelProgress()
	end
	if success then
		TriggerServerEvent('renzu_motels:Door', {
            motel = data.motel,
            index = data.index,
			doorindex = data.doorindex,
            coord = data.coord,
        })
	end
end

Notify = function(msg,type)
	lib.notify({
		description = msg,
		type = type or 'inform'
	})
end

MyRoomMenu = function(data)
    local motels = GlobalState.Motels
    local rate = motels[data.motel].hour_rate or data.rate

    local options = {
        {
            title = 'My Room ['..data.index..'] - Pay a rent',
            description = 'Pay your rent in due or advanced to Door '..data.index..' \n Rent Duration: '..data.duration..' \n '..data.rental_period..' Rate: $ '..rate,
            icon = 'money-bill-wave-alt',
            onSelect = function()
                local input = lib.inputDialog('Pay or Deposit to motel', {
                    {type = 'number', label = 'Amount to Deposit', description = '$ '..rate..' per '..data.rental_period..'  \n  Payment Method: '..data.payment, icon = 'money', default = rate},
                })
                if not input then return end
                local success = lib.callback.await('renzu_motels:payrent', false, {
                    payment = data.payment,
                    index = data.index,
                    motel = data.motel,
                    amount = input[1],
                    rate = rate,
                    rental_period = data.rental_period
                })
                if success then
                    Notify('Successfully pay a rent', 'success')
                else
                    Notify('Fail to pay a rent', 'error')
                end
            end,
            arrow = true,
        },
        {
            title = 'Generate Key Item',
            description = 'Request a Door Key',
            icon = 'key',
            onSelect = function()
				if isRentExpired(data) then
                    Notify('Failed to generate key for room '..data.index..'  \n  Reason: your have a Balance Debt to pay','error')
                    return
                end
                local success = lib.callback.await('renzu_motels:motelkey', false, {
                    index = data.index,
                    motel = data.motel,
                })
                if success then
                    Notify('Successfully requested a sharable motel key', 'success')
                else
                    Notify('Fail to Generate Key', 'error')
                end
            end,
            arrow = true,
        },
        {
            title = 'Reset Key',
            description = 'Reset the Door Key',
            icon = 'key',
            onSelect = function()
				if isRentExpired(data) then
                    Notify('Failed to generate key for room '..data.index..'  \n  Reason: your have a Balance Debt to pay','error')
                    return
                end
                local success = lib.callback.await('renzu_motels:resetkey', false, {
                    index = data.index,
                    motel = data.motel,
                })
                if success then
                    Notify('Successfully reset the motel key', 'success')
                else
                    Notify('Failed to reset the motel key', 'error')
                end
            end,
            arrow = true,
        },
        {
            title = 'End Rent',
            description = 'End your rental period',
            icon = 'ban',
            onSelect = function()
                if isRentExpired(data) then
                    Notify('Failed to End rent to room '..data.index..'  \n  Reason: your have a Balance Debt to pay','error')
                    return
                end
                local End = lib.alertDialog({
                    header = '## Warning',
                    content = ' You will no longer have access to the door and to your safes.',
                    centered = true,
                    labels = {
                        cancel = 'close',
                        confirm = 'End',
                    },
                    cancel = true
                })
                if End == 'cancel' then return end
                local success = lib.callback.await('renzu_motels:removeoccupant', false, data, data.index, PlayerData.identifier)
                if success then
                    Notify('Successfully End Your Rent to room '..data.index, 'success')
                else
                    Notify('Failed to End rent to room '..data.index, 'error')
                end
            end,
            arrow = true,
        },
    }

    lib.registerContext({
        id = 'myroom',
        menu = 'roomlist',
        title = 'My Motel Room Option',
        options = options
    })
    lib.showContext('myroom')
end

CountOccupants = function(players)
	local count = 0
	for k,v in pairs(players or {}) do
		count += 1
	end
	return count
end

RoomList = function(data)
	local motels , time = lib.callback.await('renzu_motels:getMotels',false)
	local rate = motels[data.motel].hour_rate or data.rate
	local options = {}
	for doorindex,v in ipairs(data.doors) do
		local playerroom = motels[data.motel].rooms[doorindex].players[PlayerData.identifier]
		local duration = playerroom?.duration
		local occupants = CountOccupants(motels[data.motel].rooms[doorindex].players)
		if occupants < data.maxoccupants and not duration then
			table.insert(options,{
				title = 'Rent Motel room #'..doorindex,
				description = 'Choose room #'..doorindex..' \n Occupants: '..occupants..'/'..data.maxoccupants,
				icon = 'door-closed',
				onSelect = function()
					local input = lib.inputDialog('Rent Duration', {
						{type = 'number', label = 'Select a Duration in '..data.rental_period..'s', description = '$ '..rate..' per '..data.rental_period..'   \n   Payment Method: '..data.payment, icon = 'clock', default = 1},
					})
					if not input then return end
					local success = lib.callback.await('renzu_motels:rentaroom',false,{
						index = doorindex,
						motel = data.motel,
						duration = input[1],
						rate = rate,
						rental_period = data.rental_period,
						payment = data.payment,
						uniquestash = data.uniquestash
					})
					if success then
						local success2 = lib.callback.await('renzu_motels:motelkey', false, {index = doorindex, motel = data.motel})
						if success2 then
							Notify('Successfully rent a room', 'success')
						else
							Notify('Fail to Rent a Room', 'error')
						end
					else
						Notify('You dont have enough money', 'error')
					end
				end,
				arrow = true,
			})
		elseif duration then
			local hour = math.floor((duration - time) / 3600)
			local duration_left = hour .. ' Hours : '..math.floor(((duration - time) / 60) - (60 * hour))..' Minutes'
			table.insert(options,{
				title = 'My Room Door #'..doorindex..' Options',
				description = 'Pay your rent or request a motel key',
				icon = 'cog',
				onSelect = function()
					return MyRoomMenu({
						payment = data.payment,
						index = doorindex,
						motel = data.motel,
						duration = duration_left,
						rate = rate,
						rental_period = data.rental_period
					})
				end,
				arrow = true,
			})
		end
	end
    lib.registerContext({
        id = 'roomlist',
		menu = 'rentmenu',
        title = 'Choose a Room',
        options = options
    })
	lib.showContext('roomlist')
end

IsOwnerOrEmployee = function(motel)
	local motels = GlobalState.Motels
	return motels[motel].owned == PlayerData.identifier or motels[motel].employees[PlayerData.identifier]
end

MotelRentalMenu = function(data)
    local motels = GlobalState.Motels
    local rate = motels[data.motel].hour_rate or data.rate
    local options = {}

    if not data.manual then
        table.insert(options, {
            title = 'Rent a New Motel Room',
            description = '![rent](nui://renzu_motels/data/image/'..data.motel..'.png) \n Choose a room to rent \n '..data.rental_period..' Rate: $'..rate,
            icon = 'hotel',
            onSelect = function()
                return RoomList(data)
            end,
            arrow = true,
        })
    end

    if (not motels[data.motel].owned and config.business and motels[data.motel].owned ~= PlayerData.identifier) then
        local title = 'Buy Motel Business'
        local description = 'Cost: '..data.businessprice
        table.insert(options, {
            title = title,
            description = description,
            icon = 'hotel',
            onSelect = function()
                return MotelOwner(data)
            end,
            arrow = true,
        })
    elseif IsOwnerOrEmployee(data.motel) and config.business then
        local title = 'Motel Management'
        local description = 'Manage Employees, Occupants, and Finance.'
        table.insert(options, {
            title = title,
            description = description,
            icon = 'hotel',
            onSelect = function()
                return MotelOwner(data)
            end,
            arrow = true,
        })
    end

    if #options == 0 then
        Notify('This Motel Manually Accepts Occupants\nContact the Owner')
        Wait(1500)
        return SendMessageApi(data.motel)
    end

    lib.registerContext({
        id = 'rentmenu',
        title = data.label,
        options = options
    })
    lib.showContext('rentmenu')
end


SendMessageApi = function(motel)
	local message = lib.alertDialog({
		header = 'Do you want to Message the Owner?',
		content = '## Message Motel Owner',
		centered = true,
		labels = {
			cancel = 'close',
			confirm = 'Message',
		},
		cancel = true
	})
	if message == 'cancel' then return end
	local input = lib.inputDialog('Message', {
		{type = 'input', label = 'Title', description = 'title of your message', icon = 'hash', required = true},
		{type = 'textarea', label = 'Description', description = 'your message', icon = 'mail', required = true},
		{type = 'number', label = 'Contact Number', icon = 'phone', required = false},
	})
	
	config.messageApi({title = input[1], message = input[2], motel = motel})
end

Owner = {}
Owner.Rooms = {}
Owner.Rooms.Occupants = function(data, index)
    local motels, time = lib.callback.await('renzu_motels:getMotels', false)
    local motel = motels[data.motel]
    local players = motel.rooms[index] and motel.rooms[index].players or {}
    local options = {}
    
    for player, char in pairs(players) do
        local hour = math.floor((char.duration - time) / 3600)
        local name = char.name or 'No Name'
        local duration_left = hour .. ' Hours : '..math.floor(((char.duration - time) / 60) - (60 * hour))..' Minutes'
        table.insert(options, {
            title = 'Occupant '..name,
            description = 'Rent Duration: '..duration_left,
            icon = 'hotel',
            onSelect = function()
                local kick = lib.alertDialog({
                    header = 'Confirmation',
                    content = '## Kick Occupant \n  **Name:** '..name,
                    centered = true,
                    labels = {
                        cancel = 'close',
                        confirm = 'Kick',
                        waw = 'waw'
                    },
                    cancel = true
                })
                if kick == 'cancel' then return end
                local success = lib.callback.await('renzu_motels:removeoccupant', false, data, index, player)
                if success then
                    Notify('Successfully kicked '..name..' from room '..index, 'success')
                else
                    Notify('Failed to kick '..name..' from room '..index, 'error')
                end
            end,
            arrow = true,
        })
    end
    
    if data.maxoccupants > #options then
        for i = 1, data.maxoccupants - #options do
            table.insert(options, {
                title = 'Vacant Slot ',
                icon = 'hotel',
                onSelect = function()
                    local input = lib.inputDialog('New Occupant', {
                        {type = 'number', label = 'Citizen ID', description = 'ID of the citizen you want to add', icon = 'id-card', required = true},
                        {type = 'number', label = 'Select a Duration in '..data.rental_period..'s', description = 'how many '..data.rental_period..'s', icon = 'clock', default = 1},
                    })
                    if not input then return end
                    local success = lib.callback.await('renzu_motels:addoccupant', false, data, index, input)
                    if success == 'exist' then
                        Notify('Already exists in room '..index, 'error')
                    elseif success then
                        Notify('Successfully added '..input[1]..' to room '..index, 'success')
                    else
                        Notify('Failed to add '..input[1]..' to room '..index, 'error')
                    end
                end,
                arrow = true,
            })
        end
    end
    
    lib.registerContext({
        menu = 'owner_rooms',
        id = 'occupants_lists',
        title = 'Room #'..index..' Occupants',
        options = options
    })
    lib.showContext('occupants_lists')
end


Owner.Rooms.List = function(data)
	local motels = GlobalState.Motels
	local options = {}
	for doorindex,v in ipairs(data.doors) do
		local occupants = CountOccupants(motels[data.motel].rooms[doorindex].players)
		table.insert(options,{
			title = 'Room #'..doorindex,
			description = 'Add or Kick Occupants from room #'..doorindex..' \n ***Occupants:*** '..occupants,
			icon = 'hotel',
			onSelect = function()
				return Owner.Rooms.Occupants(data,doorindex)
			end,
			arrow = true,
		})
	end
	lib.registerContext({
		menu = 'motelmenu',
        id = 'owner_rooms',
        title = data.label,
        options = options
    })
	lib.showContext('owner_rooms')
end

Owner.Employee = {}
Owner.Employee.Manage = function(data)
	local motel = GlobalState.Motels[data.motel]
	local options = {
		{
			title = 'Add Employee',
			description = 'Add nearby citizen to your motel employees',
			icon = 'hotel',
			onSelect = function()
				local input = lib.inputDialog('Add Employee', {
					{type = 'number', label = 'Citizen ID', description = 'ID of the citizen you want to add', icon = 'id-card', required = true},
				})
				if not input then return end
				local success = lib.callback.await('renzu_motels:addemployee', false, data.motel, input[1])
				if success then
					Notify('Successfully Add to Employee Lists','success')
				else
					Notify('Failed to Add to Employee','error')
				end
			end,
			arrow = true,
		}
	}
	if motel and motel.employees then
		for identifier, name in pairs(motel.employees) do
			print('Identifier:', identifier)
			print('Name:', name)
			
			table.insert(options, {
				title = name,
				description = 'Remove '.. name .. ' from your Employee List',
				icon = 'hotel',
				onSelect = function()
					local success = lib.callback.await('renzu_motels:removeemployee', false, data.motel, identifier)
					if success then
						Notify('Successfully removed '.. name .. ' from Employee List', 'success')
					else
						Notify('Failed to remove '.. name .. ' from Employee', 'error')
					end
				end,
				arrow = true,
			})
		end
	end
	
	lib.registerContext({
        id = 'employee_manage',
        title = 'Employee Manage',
        options = options
    })
	lib.showContext('employee_manage')
end

local keyOptions = {
    {
        title = 'Generate Key for Owner',
        description = 'Generate a key for the owner',
        icon = 'key',
        onSelect = function()
            local success = lib.callback.await('renzu_motels:ownermotelkey', false, {
                motel = data.motel,
            })
            if success then
                Notify('Successfully requested a sharable motel key', 'success')
            else
                Notify('Fail to Generate Key', 'error')
            end
        end,
        arrow = true,
    },
    {
        title = 'Change Key Locks',
        description = 'Change the key locks for the room',
        icon = 'key',
        onSelect = function()
            local success = lib.callback.await('renzu_motels:resetownerkey', false, {
                index = data.index,
                motel = data.motel,
            })
            if success then
                Notify('Successfully changed locks', 'success')
            else
                Notify('Fail to change locks', 'error')
            end
        end,
        arrow = true,
    },
}

lib.registerContext({
    id = 'key_management',
    title = 'Key Management',
    options = keyOptions,
})

MotelOwner = function(data)
	local motels = GlobalState.Motels
	local piden = PlayerData.identifier
	local owning = motels[data.motel].owned
	if (not owning and owning ~= piden) then
		local buy = lib.alertDialog({
			header = data.label,
			content = '![motel](nui://renzu_motels/data/image/'..data.motel..'.png) \n ## INFO \n **Rooms:** '..#data.doors..'  \n  **Maximum Occupants:** '..#data.doors * data.maxoccupants..'  \n  **Price:** $'..data.businessprice,
			centered = true,
			labels = {
				cancel = 'close',
				confirm = 'buy'
			},
			cancel = true
		})
		if buy ~= 'cancel' then
			local success = lib.callback.await('renzu_motels:buymotel', false, data)
			if success then
				local success2 = lib.callback.await('renzu_motels:resetownerkey', false, {index = data.index, motel = data.motel})
				if success2 then
					Notify('You Successfully buy the motel', 'success')
				else
					Notify('Neco se nam tu pojebalo', 'error')
				end
			else
				Notify('You dont have enought money', 'error')
			end
		end
	elseif IsOwnerOrEmployee(data.motel) then
		local revenue = motels[data.motel].revenue or 0
		local rate = motels[data.motel].hour_rate or data.rate
		local options = {
			{
				title = 'Motel Rooms',
				description = 'Add or Kick Occupants',
				icon = 'hotel',
				onSelect = function()
					return Owner.Rooms.List(data)
				end,
				arrow = true,
			},
			{
				title = 'Send Invoice',
				description = 'Invoice nearby citizens',
				icon = 'hotel',
				onSelect = function()
					local input = lib.inputDialog('Send Invoice', {
						{type = 'number', label = 'Citizen ID', description = 'id of nearby citizen', icon = 'money', required = true},
						{type = 'number', label = 'Amount', description = 'total amount to request', icon = 'money', required = true},
						{type = 'input', label = 'Describe', description = 'Description of Invoice', icon = 'info'},
					})
					if not input then return end
					Notify('You Successfully Send the Invoice to '..input[1],'success')
					local success = lib.callback.await('renzu_motels:sendinvoice', false, data.motel, input)
					if success then
						Notify('Invoice has been paid','success')
					else
						Notify('Invoice is not paid','error')
					end
				end,
				arrow = true,
			}
		}
		if motels[data.motel].owned == PlayerData.identifier then

			table.insert(options,{
				title = 'Adjust Hour Rates',
				description = 'Modify current '..data.rental_period..' rates. \n '..data.rental_period..' Rates: '..rate,
				icon = 'hotel',
				onSelect = function()
					local input = lib.inputDialog('Edit '..data.rental_period..' Rate', {
						{type = 'number', label = 'Rate', description = 'Rate per '..data.rental_period..'', icon = 'money', required = true},
					})
					if not input then return end
					local success = lib.callback.await('renzu_motels:editrate',false,data.motel,input[1])
					if success then
						Notify('You Successfully Change the '..data.rental_period..' Rate','success')
					else
						Notify('Fail to Modify','error')
					end
				end,
				arrow = true,
			})
			table.insert(options,{
				title = 'Motel Revenue',
				description = 'Total: '..revenue,
				icon = 'hotel',
				onSelect = function()
					local input = lib.inputDialog('Withdraw Funds', {
						{type = 'number', label = 'Fund Amount', icon = 'money', required = true},
					})
					if not input then return end
					local success = lib.callback.await('renzu_motels:withdrawfund',false,data.motel,input[1])
					if success then
						Notify('You Successfully Withdraw Funds','success')
					else
						Notify('Fail to Withdraw','error')
					end
				end,
				arrow = true,
			})
			table.insert(options,{
				title = 'Employee Management',
				description = 'Add / Remove Employee',
				icon = 'hotel',
				onSelect = function()
					return Owner.Employee.Manage(data)
				end,
				arrow = true,
			})

			table.insert(options, {
				title = 'Key Management',
				description = 'Manage motel keys',
				icon = 'key',
				onSelect = function()
					return Owner.Key.Manage(data)
				end,
				arrow = true,
			})

			table.insert(options,{
				title = 'Transfer Ownership',
				description = 'transfer to other nearby citizens',
				icon = 'hotel',
				onSelect = function()
					local input = lib.inputDialog('Transfer Motel', {
						{type = 'number', label = 'Citizen ID', description = 'ID of the citizen you want to be transfered', icon = 'id-card', required = true},
					})
					if not input then return end
					local success = lib.callback.await('renzu_motels:transfermotel',false,data.motel,input[1])
					if success then
						Notify('Successfully Transfer Motel Ownership','success')
					else
						Notify('Failed to Transfer','error')
					end
				end,
				arrow = true,
			})
			table.insert(options,{
				title = 'Sell Motel',
				description = 'Sell motel for half price',
				icon = 'hotel',
				onSelect = function()
					local sell = lib.alertDialog({
						header = data.label,
						content = '![motel](nui://renzu_motels/data/image/'..data.motel..'.png) \n ## INFO \n  **Selling Value:** $'..data.businessprice / 2,
						centered = true,
						labels = {
							cancel = 'close',
							confirm = 'Sell'
						},
						cancel = true
					})
					if sell ~= 'cancel' then
						local success = lib.callback.await('renzu_motels:sellmotel', false, data)
						if success then
							Notify('You Successfully Sell the motel','success')
						else
							Notify('Fail to sell the motel','error')
						end
					end
				end,
				arrow = true,
			})
		end
		lib.registerContext({
			id = 'motelmenu',
			menu = 'rentmenu',
			title = data.label,
			options = options
		})
		lib.showContext('motelmenu')
	end
end

Owner.Key = {}

Owner.Key.Manage = function(data)
    local keyOptions = {}

    table.insert(keyOptions, {
        title = 'Generate Key for Owner',
        description = 'Generate a key for the owner',
        icon = 'key',
        onSelect = function()
            local success = lib.callback.await('renzu_motels:ownermotelkey', false, {
                motel = data.motel,
            })
            if success then
                Notify('Successfully requested a sharable motel key', 'success')
            else
                Notify('Fail to Generate Key', 'error')
            end
        end,
        arrow = true,
    })

    table.insert(keyOptions, {
        title = 'Change Key Locks',
        description = 'Change the key locks for the room',
        icon = 'key',
        onSelect = function()
            local success = lib.callback.await('renzu_motels:resetownerkey', false, {
                index = data.index,
                motel = data.motel,
            })
            if success then
                Notify('Successfully changed locks', 'success')
            else
                Notify('Fail to change locks', 'error')
            end
        end,
        arrow = true,
    })

    lib.registerContext({
        id = 'key_management',
        title = 'Key Management',
        options = keyOptions,
    })

    lib.showContext('key_management')
end

MotelRentalPoints = function(data)
    local point = lib.points.new(data.rentcoord, 5, data)

    function point:onEnter()
		lib.showTextUI('[E] - Motel Rent', {
			position = "top-center",
			icon = 'hotel',
			style = {
				borderRadius = 0,
				backgroundColor = '#48BB78',
				color = 'white'
			}
		})
	end

    function point:onExit() 
		lib.hideTextUI()
	end

    function point:nearby()
        DrawMarker(2, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0,0.0, 0.0, 180.0, 0.0, 0.7, 0.7, 0.7, 225, 225, 211, 50, false,true, 2, nil, nil, false)
        if self.currentDistance < 1 and IsControlJustReleased(0, 38) then
            MotelRentalMenu(data)
        end
    end
	return point
end

local inMotelZone = false
MotelZone = function(data)
	local point = nil
    function onEnter(self) 
		inMotelZone = true
		Citizen.CreateThreadNow(function()
			for index, doors in pairs(data.doors) do
				for type, door in pairs(doors) do
					if type == 'door' then
						for doorindex,v in pairs(door) do
							MotelFunction({
								payment = data.payment or 'money',
								uniquestash = data.uniquestash, 
								shell = data.shell, 
								Mlo = data.Mlo, 
								type = type, 
								index = index,
								doorindex = index + doorindex,
								coord = v.coord, 
								label = config.Text[type], 
								motel = data.motel, 
								door = v.model
							})
						end
					else
						MotelFunction({
							payment = data.payment or 'money',
							uniquestash = data.uniquestash, 
							shell = data.shell, 
							Mlo = data.Mlo, 
							type = type, 
							index = index, 
							coord = door, 
							label = config.Text[type], 
							motel = data.motel, 
							door = data.door
						})
					end
				end
			end
			point = MotelRentalPoints(data) 
		end)
	end

    function onExit(self)
		inMotelZone = false
		point:remove()
		for k,id in pairs(zones) do
			removeTargetZone(id)
		end
		for k,id in pairs(blips) do
			if DoesBlipExist(id) then
				RemoveBlip(id)
			end
		end
		zones = {}
	end

    local sphere = lib.zones.sphere({
        coords = data.coord,
        radius = data.radius,
        debug = false,
        inside = inside,
        onEnter = onEnter,
        onExit = onExit
    })
end

--qb-interior func
local house
local inhouse = false
function Teleport(x, y, z, h ,exit)
    CreateThread(function()
        SetEntityCoords(cache.ped, x, y, z, 0, 0, 0, false)
        SetEntityHeading(cache.ped, h or 0.0)
        Wait(1001)
        DoScreenFadeIn(1000)
    end)
	if exit then
		inhouse = false
		TriggerEvent('qb-weathersync:client:EnableSync')
		for k,id in pairs(shelzones) do
			removeTargetZone(id)
		end
		DeleteEntity(house)
		lib.callback.await('renzu_motels:SetRouting',false,data,'exit')
		shelzones = {}
		DeleteResourceKvp(kvpname)
		LocalPlayer.state:set('inshell',false,true)
	end
end

EnterShell = function(data,login)
	local motels = GlobalState.Motels
	if motels[data.motel].rooms[data.index].lock and not login then
		Notify('Door is Locked', 'error')
		return false
	end
	local shelldata = config.shells[data.shell or data.motel]
	if not shelldata then 
		warn('Shell is not configure')
		return 
	end
	lib.callback.await('renzu_motels:SetRouting',false,data,'enter')
	inhouse = true
	Wait(1000)
	local spawn = vec3(data.coord.x,data.coord.y,data.coord.z)+vec3(0.0,0.0,1500.0)
    local offsets = shelldata.offsets
	local model = shelldata.shell
	DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(10)
    end
	inhouse = true
	TriggerEvent('qb-weathersync:client:DisableSync')
	RequestModel(model)
	while not HasModelLoaded(model) do
	    Wait(1000)
	end
	local lastloc = GetEntityCoords(cache.ped)
	house = CreateObject(model, spawn.x, spawn.y, spawn.z, false, false, false)
    FreezeEntityPosition(house, true)
	LocalPlayer.state:set('lastloc',data.lastloc or lastloc,false)
	data.lastloc = data.lastloc or lastloc
	if not login then
		SendNUIMessage({
			type = 'door'
		})
	end
	Teleport(spawn.x + offsets.exit.x, spawn.y + offsets.exit.y, spawn.z+0.1, offsets.exit.h)
	SetResourceKvp(kvpname,json.encode(data))

	Citizen.CreateThreadNow(function()
		ShellTargets(data,offsets,spawn,house)
		while inhouse do
			SetWeatherTypePersist('CLEAR')
			SetWeatherTypeNow('CLEAR')
			SetWeatherTypeNowPersist('CLEAR')
			NetworkOverrideClockTime(18, 0, 0)
			Wait(1)
		end
	end)
    return house
end

function RotationToDirection(rotation)
	local adjustedRotation = 
	{ 
		x = (math.pi / 180) * rotation.x, 
		y = (math.pi / 180) * rotation.y, 
		z = (math.pi / 180) * rotation.z 
	}
	local direction = 
	{
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
		z = math.sin(adjustedRotation.x)
	}
	return direction
end

function RayCastGamePlayCamera(distance,flag)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
	local direction = RotationToDirection(cameraRotation)
	local destination =  vector3(cameraCoord.x + direction.x * distance, 
		cameraCoord.y + direction.y * distance, 
		cameraCoord.z + direction.z * distance 
    )
    if not flag then
        flag = 1
    end

	local a, b, c, d, e = GetShapeTestResultIncludingMaterial(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, flag, -1, 1))
	return b, c, e, destination
end

RegisterNetEvent('renzu_motels:MessageOwner', function(data)
	AddTextEntry('esxAdvancedNotification', data.message)
    BeginTextCommandThefeedPost('esxAdvancedNotification')
	ThefeedSetNextPostBackgroundColor(1)
	AddTextComponentSubstringPlayerName(data.message)
    EndTextCommandThefeedPostMessagetext('CHAR_FACEBOOK', 'CHAR_FACEBOOK', false, 1, data.motel, data.title)
    EndTextCommandThefeedPostTicker(flash or false, true)
end)

Citizen.CreateThread(function()
	while GlobalState.Motels == nil do Wait(1) end
    for motel, data in pairs(config.motels) do
        MotelZone(data)
    end
	CreateBlips()
end)
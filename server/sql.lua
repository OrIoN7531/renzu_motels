local db = setmetatable({}, {
    __call = function(self)
        self.insert = function(...)
            local str = 'INSERT INTO %s (%s, %s, %s, %s, %s, %s, %s) VALUES (?, ?, ?, ?, ?, ?, ?)'
            return MySQL.insert.await(str:format('renzu_motels', 'motel', 'hour_rate', 'revenue', 'employees', 'rooms', 'owned', 'ownerLockKey'), {...})
        end

        self.update = function(column, where, string, data)
            local str = 'UPDATE %s SET %s = ? WHERE %s = ?'
            return MySQL.update(str:format('renzu_motels', column, where), {data, string})
        end

        self.updateall = function(pattern, where, string, ...)
            local str = 'UPDATE %s SET %s WHERE %s = ?'
            local data = {...}
            table.insert(data, string)
            return MySQL.update(str:format('renzu_motels', pattern, where), data)
        end

        self.query = function(column, where, string)
            local str = 'SELECT %s FROM %s WHERE %s = ?'
            return MySQL.query.await(str:format(column, 'renzu_motels', where), {string})
        end

        self.fetchDoorlockDataByName = function(name)
            local query = MySQL.query.await('SELECT name, data FROM ox_doorlock WHERE name = ?', {name})
            if query[1] then
                local data = query[1].data
                return data
            end
            return nil
        end
          
        self.updateDoorlockDataByName = function(name, newData)
            local encodedData = json.encode(newData)
            local success = MySQL.update('UPDATE ox_doorlock SET data = ? WHERE name = ?', {encodedData, name})
            return success
        end

        self.getDoorlockIDByName = function(name)
            local query = MySQL.query.await('SELECT id FROM ox_doorlock WHERE name = ?', {name})
            if query[1] then
                return query[1].id
            end
            return nil
        end

        self.insertDoorlockData = function(name, data)
            local encodedData = json.encode(data)
            return MySQL.insert.await('INSERT INTO ox_doorlock (name, data) VALUES (?, ?)', {name, encodedData})
        end

        self.fetchAll = function()
            local str = 'SELECT * FROM renzu_motels'
            local query = MySQL.query.await(str)
            local data = {}
            for _, v in pairs(query) do
                if v.motel then
                    if not data[v.motel] then data[v.motel] = {} end
                    for column, value in pairs(v) do
                        if column ~= 'id' and column ~= 'motel' then
                            local success, result = pcall(json.decode, value)
                            if success then
                                if column == 'owned' and result == 0 then result = nil end
                                if column == 'hour_rate' and result == 0 then result = nil end
                                data[v.motel][column] = result
                            else
                                data[v.motel][column] = value
                            end
                        end
                    end
                end
            end
            return data
        end

        return self
    end
})

Citizen.CreateThreadNow(function()
    local success, result = pcall(MySQL.scalar.await, 'SELECT 1 FROM renzu_motels')
    if not success then
        MySQL.query.await([[CREATE TABLE `renzu_motels` (
            `id` int NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `motel` varchar(64) DEFAULT NULL,
            `hour_rate` int DEFAULT 0,
            `revenue` int DEFAULT 0,
            `employees` longtext DEFAULT NULL,
            `rooms` longtext DEFAULT NULL,
            `owned` varchar(64) DEFAULT NULL,
            `ownerLockKey` longtext DEFAULT NULL
        )]])
        print("^2SQL INSTALL SUCCESSFULLY ^0")
    end
    Wait(500)
    
    -- Fetch and process motel data
    for k, v in pairs(config.motels) do
        local query = MySQL.query.await('SELECT rooms, owned, ownerLockKey FROM renzu_motels WHERE `motel` = ?', {v.motel})
        if not query[1] then
            local doors = {}
            for doorindex, _ in pairs(v.doors) do
                if not doors.rooms then doors.rooms = {} end
                if not doors.rooms[doorindex] then doors.rooms[doorindex] = {} end
                if not doors.rooms[doorindex].players then doors.rooms[doorindex].players = {} end
                if not doors.rooms[doorindex].lockKey then doors.rooms[doorindex].lockKey = {} end
                if not doors.rooms[doorindex].ownerLockKey then doors.rooms[doorindex].ownerLockKey = {} end
                doors.rooms[doorindex].lock = true
            end
            db.insert(v.motel, 0, 0, '[]', json.encode(doors.rooms), nil, nil) -- No initial owner
        elseif query[1] and #v.doors > #json.decode(query[1].rooms) then
            local addnew = (#v.doors - #json.decode(query[1].rooms))
            local rooms = json.decode(query[1].rooms) or {}
            for i = 1, addnew do
                table.insert(rooms, {players = {}, lock = true, lockKey = {}, ownerLockKey = {}})
            end
            db.updateall('rooms = ?', '`motel`', v.motel, json.encode(rooms))
        end
        
        local owned = query[1] and query[1].owned or nil
        local ownerLockKey = query[1] and query[1].ownerLockKey or nil
        -- Use the 'owned' and 'ownerLockKey' values as needed in your logic or data processing
        -- For example, you can store them in your 'config.motels' table or perform further operations
        -- on the motel data based on the ownership status.
        config.motels[k].owned = owned
        config.motels[k].ownerLockKey = ownerLockKey
        
        -- Print the 'owned' and 'ownerLockKey' values for the current motel
        print("Owned value for " .. k .. ": " .. tostring(config.motels[k].owned))
        print("OwnerLockKey value for " .. k .. ": " .. tostring(config.motels[k].ownerLockKey))
    end
end)

Citizen.CreateThreadNow(function()
    local success, result = pcall(MySQL.scalar.await, 'SELECT 1 FROM ox_doorlock')
    if not success then
        MySQL.query.await([[CREATE TABLE `ox_doorlock` (
            `id` int NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `name` varchar(255) DEFAULT NULL,
            `data` longtext DEFAULT NULL
        )]])
        print("^2ox_doorlock TABLE CREATED SUCCESSFULLY^0")
    end
    -- Additional code for door creation in the ox_doorlock table
    for _, motelData in pairs(config.motels) do
        for doorIndex, doors in pairs(motelData.doors) do
            for doorType, doorData in pairs(doors) do
                if doorType == 'door' then
                    for _, doorInfo in pairs(doorData) do
                        local doorCoord = doorInfo.coord
                        local doorName = motelData.motel .. "-" .. doorIndex
                        local doorlockData = db.fetchDoorlockDataByName(doorName)
                        if not doorlockData then
                            local defaultData = {
                                state = 1,
                                doors = false,
                                maxDistance = 2,
                                autolock = 10,
                                coords = doorCoord,
                                model = doorInfo.model, -- Update to use door model from config
                                items = {
                                    {name = "keys", metadata = "notowned"},
                                    {name = "keys", metadata = "owner"}
                                }
                            }
                            db.insertDoorlockData(doorName, defaultData)
                        end
                    end
                end
            end
        end
    end
end)

return db()

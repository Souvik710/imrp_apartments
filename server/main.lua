-----------------------------------------------------------
-- IMRP Apartments - Server Main
-- Author: Ragna | Immortal Roleplay
-----------------------------------------------------------

local OwnedApartments = {}
local NextBucketId = Config.BucketStart

-----------------------------------------------------------
-- Initialize Database & Load Apartments
-----------------------------------------------------------
CreateThread(function()
    MySQL.ready(function()
        -- Create tables if they don't exist
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS `apartments` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `citizenid` VARCHAR(50) NOT NULL,
                `apartment_id` VARCHAR(100) NOT NULL UNIQUE,
                `apartment_name` VARCHAR(100) NOT NULL,
                `apartment_type` VARCHAR(50) NOT NULL,
                `bucket_id` INT NOT NULL,
                `purchase_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                `expire_date` DATETIME NOT NULL,
                `purchase_type` VARCHAR(20) NOT NULL DEFAULT 'buy',
                INDEX `idx_citizenid` (`citizenid`),
                INDEX `idx_apartment_name` (`apartment_name`),
                INDEX `idx_expire_date` (`expire_date`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])

        MySQL.query([[
            CREATE TABLE IF NOT EXISTS `apartment_keys` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `apartment_id` VARCHAR(100) NOT NULL,
                `citizenid` VARCHAR(50) NOT NULL,
                `key_type` VARCHAR(20) NOT NULL DEFAULT 'permanent',
                `granted_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                INDEX `idx_apartment_id` (`apartment_id`),
                INDEX `idx_citizenid` (`citizenid`),
                UNIQUE KEY `unique_key` (`apartment_id`, `citizenid`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])

        MySQL.query([[
            CREATE TABLE IF NOT EXISTS `apartment_guests` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `apartment_id` VARCHAR(100) NOT NULL,
                `citizenid` VARCHAR(50) NOT NULL,
                `invited_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                INDEX `idx_apartment_id` (`apartment_id`),
                INDEX `idx_citizenid` (`citizenid`),
                UNIQUE KEY `unique_guest` (`apartment_id`, `citizenid`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])

        MySQL.query([[
            CREATE TABLE IF NOT EXISTS `apartment_logs` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `citizenid` VARCHAR(50) NOT NULL,
                `apartment_id` VARCHAR(100) DEFAULT NULL,
                `action` VARCHAR(100) NOT NULL,
                `details` TEXT DEFAULT NULL,
                `date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                INDEX `idx_citizenid` (`citizenid`),
                INDEX `idx_date` (`date`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])

        -- Load existing apartments
        local apartments = MySQL.query.await('SELECT * FROM apartments WHERE expire_date > NOW()')
        if apartments then
            for _, apt in ipairs(apartments) do
                OwnedApartments[apt.apartment_id] = {
                    citizenid = apt.citizenid,
                    apartment_name = apt.apartment_name,
                    apartment_type = apt.apartment_type,
                    bucket_id = apt.bucket_id,
                    purchase_date = apt.purchase_date,
                    expire_date = apt.expire_date,
                    purchase_type = apt.purchase_type
                }
                if apt.bucket_id >= NextBucketId then
                    NextBucketId = apt.bucket_id + 1
                end
            end
        end

        IMRP.Debug(('Loaded %d apartments'):format(CountTable(OwnedApartments)))
    end)
end)

-----------------------------------------------------------
-- Utility Functions
-----------------------------------------------------------
function CountTable(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function GetNextBucketId()
    local id = NextBucketId
    NextBucketId = NextBucketId + 1
    return id
end

function GetPlayerApartments(citizenid)
    local apartments = {}
    for id, data in pairs(OwnedApartments) do
        if data.citizenid == citizenid then
            apartments[id] = data
        end
    end
    return apartments
end

function GetPlayerApartmentCount(citizenid)
    local count = 0
    for _, data in pairs(OwnedApartments) do
        if data.citizenid == citizenid then
            count = count + 1
        end
    end
    return count
end

function HasAccessToApartment(citizenid, apartmentKey)
    -- Check ownership
    for id, data in pairs(OwnedApartments) do
        if data.citizenid == citizenid and data.apartment_name == apartmentKey then
            return true, id, data
        end
    end

    -- Check keys
    for id, data in pairs(OwnedApartments) do
        if data.apartment_name == apartmentKey then
            local hasKey = MySQL.scalar.await('SELECT COUNT(*) FROM apartment_keys WHERE apartment_id = ? AND citizenid = ?', { id, citizenid })
            if hasKey and hasKey > 0 then
                return true, id, data
            end
        end
    end

    -- Check guest access
    for id, data in pairs(OwnedApartments) do
        if data.apartment_name == apartmentKey then
            local isGuest = MySQL.scalar.await('SELECT COUNT(*) FROM apartment_guests WHERE apartment_id = ? AND citizenid = ?', { id, citizenid })
            if isGuest and isGuest > 0 then
                return true, id, data
            end
        end
    end

    return false, nil, nil
end

function IsOwner(citizenid, apartmentKey)
    for id, data in pairs(OwnedApartments) do
        if data.citizenid == citizenid and data.apartment_name == apartmentKey then
            return true, id
        end
    end
    return false, nil
end

function LogAction(citizenid, apartmentId, action, details)
    MySQL.insert('INSERT INTO apartment_logs (citizenid, apartment_id, action, details) VALUES (?, ?, ?, ?)', {
        citizenid, apartmentId, action, details
    })
end

-----------------------------------------------------------
-- Buy / Rent Apartment
-----------------------------------------------------------
lib.callback.register('imrp_apartments:server:buyApartment', function(source, apartmentKey, purchaseType)
    local player, citizenid, err = IMRP.GetPlayerOrFail(source)
    if not player then return err end

    -- Validate apartment exists
    if not Config.Apartments[apartmentKey] then
        return { success = false, message = 'Invalid apartment' }
    end

    -- Check max apartments
    if GetPlayerApartmentCount(citizenid) >= Config.MaxApartments then
        return { success = false, message = IMRP.Locale('max_apartments_reached') }
    end

    -- Check if already owns this apartment
    local isOwner, _ = IsOwner(citizenid, apartmentKey)
    if isOwner then
        return { success = false, message = IMRP.Locale('already_own_apartment') }
    end

    -- Get price
    local typeData = IMRP.GetApartmentTypeData(apartmentKey)
    if not typeData then
        return { success = false, message = 'Invalid apartment type' }
    end

    local price = purchaseType == 'rent' and typeData.rental_price or typeData.price

    -- Check money
    local moneyType = Config.BankPayment and 'bank' or 'cash'
    local playerMoney = player.PlayerData.money[moneyType] or 0

    if playerMoney < price then
        return { success = false, message = IMRP.Locale('not_enough_money') }
    end

    -- Deduct money
    player.Functions.RemoveMoney(moneyType, price, 'apartment-purchase')

    -- Generate bucket
    local bucketId = GetNextBucketId()
    local apartmentId = IMRP.GenerateApartmentId(apartmentKey, bucketId)

    -- Calculate expire date
    local expireDate = os.date('%Y-%m-%d %H:%M:%S', os.time() + (Config.ApartmentDuration * 86400))
    local purchaseDate = os.date('%Y-%m-%d %H:%M:%S')

    -- Save to database
    MySQL.insert('INSERT INTO apartments (citizenid, apartment_id, apartment_name, apartment_type, bucket_id, purchase_date, expire_date, purchase_type) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        citizenid, apartmentId, apartmentKey, Config.Apartments[apartmentKey].type, bucketId, purchaseDate, expireDate, purchaseType
    })

    -- Cache
    OwnedApartments[apartmentId] = {
        citizenid = citizenid,
        apartment_name = apartmentKey,
        apartment_type = Config.Apartments[apartmentKey].type,
        bucket_id = bucketId,
        purchase_date = purchaseDate,
        expire_date = expireDate,
        purchase_type = purchaseType
    }

    -- Register stash
    local stashId = IMRP.GenerateStashId(apartmentId)
    exports.ox_inventory:RegisterStash(stashId, ('%s Stash'):format(Config.Apartments[apartmentKey].label), typeData.stash_slots, typeData.stash_weight)

    -- Log
    LogAction(citizenid, apartmentId, 'purchase', ('Type: %s | Price: %d | Method: %s'):format(purchaseType, price, moneyType))

    IMRP.Debug(('Player %s purchased %s (ID: %s, Bucket: %d)'):format(citizenid, apartmentKey, apartmentId, bucketId))

    return { success = true, apartment_id = apartmentId, bucket_id = bucketId }
end)

-----------------------------------------------------------
-- Enter Apartment
-----------------------------------------------------------
lib.callback.register('imrp_apartments:server:enterApartment', function(source, apartmentKey)
    local player, citizenid, err = IMRP.GetPlayerOrFail(source)
    if not player then return err end

    -- Check access
    local hasAccess, apartmentId, aptData = HasAccessToApartment(citizenid, apartmentKey)
    if not hasAccess then
        return { success = false, message = IMRP.Locale('no_access') }
    end

    -- Set routing bucket
    if Config.UseRoutingBuckets then
        SetPlayerRoutingBucket(source, aptData.bucket_id)
        SetRoutingBucketPopulationEnabled(aptData.bucket_id, Config.BucketPopulation)
        SetRoutingBucketEntityLockdownMode(aptData.bucket_id, Config.BucketLockdown)
    end

    -- Log
    LogAction(citizenid, apartmentId, 'enter', nil)

    return { success = true, apartment_id = apartmentId, bucket_id = aptData.bucket_id }
end)

-----------------------------------------------------------
-- Exit Apartment
-----------------------------------------------------------
lib.callback.register('imrp_apartments:server:exitApartment', function(source)
    -- Reset routing bucket to 0
    if Config.UseRoutingBuckets then
        SetPlayerRoutingBucket(source, 0)
    end

    return { success = true }
end)

-----------------------------------------------------------
-- Renew Apartment
-----------------------------------------------------------
lib.callback.register('imrp_apartments:server:renewApartment', function(source, apartmentKey)
    local player, citizenid, err = IMRP.GetPlayerOrFail(source)
    if not player then return err end

    -- Check ownership
    local isOwner, apartmentId = IsOwner(citizenid, apartmentKey)
    if not isOwner then
        return { success = false, message = IMRP.Locale('not_owner') }
    end

    -- Get renewal price
    local typeData = IMRP.GetApartmentTypeData(apartmentKey)
    if not typeData then
        return { success = false, message = 'Invalid apartment type' }
    end

    local renewPrice = typeData.rental_price

    -- Check money
    local moneyType = Config.BankPayment and 'bank' or 'cash'
    local playerMoney = player.PlayerData.money[moneyType] or 0

    if playerMoney < renewPrice then
        return { success = false, message = IMRP.Locale('not_enough_money') }
    end

    -- Deduct money
    player.Functions.RemoveMoney(moneyType, renewPrice, 'apartment-renewal')

    -- Extend expiry
    local aptData = OwnedApartments[apartmentId]
    local currentExpire = aptData.expire_date
    local newExpireTimestamp = os.time() + (Config.ApartmentDuration * 86400)
    local newExpireDate = os.date('%Y-%m-%d %H:%M:%S', newExpireTimestamp)

    MySQL.update('UPDATE apartments SET expire_date = ? WHERE apartment_id = ?', { newExpireDate, apartmentId })
    OwnedApartments[apartmentId].expire_date = newExpireDate

    -- Log
    LogAction(citizenid, apartmentId, 'renew', ('Price: %d | New Expire: %s'):format(renewPrice, newExpireDate))

    return { success = true }
end)

-----------------------------------------------------------
-- Sell Apartment
-----------------------------------------------------------
lib.callback.register('imrp_apartments:server:sellApartment', function(source, apartmentKey)
    local player, citizenid, err = IMRP.GetPlayerOrFail(source)
    if not player then return err end

    -- Check ownership
    local isOwner, apartmentId = IsOwner(citizenid, apartmentKey)
    if not isOwner then
        return { success = false, message = IMRP.Locale('not_owner') }
    end

    -- Calculate refund
    local typeData = IMRP.GetApartmentTypeData(apartmentKey)
    if not typeData then
        return { success = false, message = 'Invalid apartment type' }
    end

    local refund = math.floor(typeData.price * Config.SellRefundPercent / 100)

    -- Give refund
    local moneyType = Config.BankPayment and 'bank' or 'cash'
    player.Functions.AddMoney(moneyType, refund, 'apartment-sell')

    -- Clean up
    CleanupApartment(apartmentId)

    -- Log
    LogAction(citizenid, apartmentId, 'sell', ('Refund: %d'):format(refund))

    return { success = true }
end)

-----------------------------------------------------------
-- Cleanup Apartment (remove from DB + cache)
-----------------------------------------------------------
function CleanupApartment(apartmentId)
    -- Remove from database
    MySQL.query('DELETE FROM apartments WHERE apartment_id = ?', { apartmentId })
    MySQL.query('DELETE FROM apartment_keys WHERE apartment_id = ?', { apartmentId })
    MySQL.query('DELETE FROM apartment_guests WHERE apartment_id = ?', { apartmentId })

    -- Clear stash if configured
    if Config.ClearStashOnExpire then
        local stashId = IMRP.GenerateStashId(apartmentId)
        exports.ox_inventory:ClearInventory(stashId)
    end

    -- Remove from cache
    OwnedApartments[apartmentId] = nil
end

-----------------------------------------------------------
-- Get Apartment Info
-----------------------------------------------------------
lib.callback.register('imrp_apartments:server:getApartmentInfo', function(source, apartmentKey)
    local player, citizenid = IMRP.GetPlayerOrFail(source)
    if not player then return nil end
    local isOwner, apartmentId = IsOwner(citizenid, apartmentKey)
    if not isOwner then return nil end

    local aptData = OwnedApartments[apartmentId]
    if not aptData then return nil end

    local keysCount = MySQL.scalar.await('SELECT COUNT(*) FROM apartment_keys WHERE apartment_id = ?', { apartmentId }) or 0
    local guestsCount = MySQL.scalar.await('SELECT COUNT(*) FROM apartment_guests WHERE apartment_id = ?', { apartmentId }) or 0

    return {
        purchase_date = aptData.purchase_date,
        expire_date = aptData.expire_date,
        days_remaining = IMRP.DaysRemaining(aptData.expire_date),
        keys_count = keysCount,
        guests_count = guestsCount
    }
end)

-----------------------------------------------------------
-- Key System
-----------------------------------------------------------
lib.callback.register('imrp_apartments:server:getKeys', function(source, apartmentKey)
    local player, citizenid = IMRP.GetPlayerOrFail(source)
    if not player then return nil end

    local isOwner, apartmentId = IsOwner(citizenid, apartmentKey)
    if not isOwner then return nil end

    local keys = MySQL.query.await('SELECT ak.citizenid, ak.key_type, ak.granted_date FROM apartment_keys ak WHERE ak.apartment_id = ?', { apartmentId })
    if not keys then return {} end

    return IMRP.EnrichWithNames(keys)
end)

lib.callback.register('imrp_apartments:server:giveKey', function(source, apartmentKey, targetId, keyType)
    local player, citizenid, err = IMRP.GetPlayerOrFail(source)
    if not player then return err or { success = false } end
    local isOwner, apartmentId = IsOwner(citizenid, apartmentKey)
    if not isOwner then
        return { success = false, message = IMRP.Locale('not_owner') }
    end

    local targetPlayer, targetCitizenId = IMRP.GetPlayerOrFail(tonumber(targetId))
    if not targetPlayer then
        return { success = false, message = IMRP.Locale('player_not_found') }
    end

    -- Check if key already exists
    local existing = MySQL.scalar.await('SELECT COUNT(*) FROM apartment_keys WHERE apartment_id = ? AND citizenid = ?', { apartmentId, targetCitizenId })
    if existing and existing > 0 then
        return { success = false, message = IMRP.Locale('key_already_exists') }
    end

    MySQL.insert('INSERT INTO apartment_keys (apartment_id, citizenid, key_type) VALUES (?, ?, ?)', {
        apartmentId, targetCitizenId, keyType or 'permanent'
    })

    LogAction(citizenid, apartmentId, 'give_key', ('To: %s | Type: %s'):format(targetCitizenId, keyType))

    return { success = true }
end)

lib.callback.register('imrp_apartments:server:duplicateKey', function(source, apartmentKey, targetId)
    return lib.callback.await('imrp_apartments:server:giveKey', source, apartmentKey, targetId, 'permanent')
end)

lib.callback.register('imrp_apartments:server:removeKey', function(source, apartmentKey, targetCitizenId)
    local player, citizenid, err = IMRP.GetPlayerOrFail(source)
    if not player then return err or { success = false } end
    local isOwner, apartmentId = IsOwner(citizenid, apartmentKey)
    if not isOwner then
        return { success = false, message = IMRP.Locale('not_owner') }
    end

    MySQL.query('DELETE FROM apartment_keys WHERE apartment_id = ? AND citizenid = ?', { apartmentId, targetCitizenId })

    LogAction(citizenid, apartmentId, 'remove_key', ('From: %s'):format(targetCitizenId))

    return { success = true }
end)

-----------------------------------------------------------
-- Guest System
-----------------------------------------------------------
lib.callback.register('imrp_apartments:server:inviteGuest', function(source, apartmentKey, targetId)
    local player, citizenid, err = IMRP.GetPlayerOrFail(source)
    if not player then return err or { success = false } end
    local isOwner, apartmentId = IsOwner(citizenid, apartmentKey)
    if not isOwner then
        return { success = false, message = IMRP.Locale('not_owner') }
    end

    local targetPlayer, targetCitizenId = IMRP.GetPlayerOrFail(tonumber(targetId))
    if not targetPlayer then
        return { success = false, message = IMRP.Locale('player_not_found') }
    end

    -- Check if already a guest
    local existing = MySQL.scalar.await('SELECT COUNT(*) FROM apartment_guests WHERE apartment_id = ? AND citizenid = ?', { apartmentId, targetCitizenId })
    if existing and existing > 0 then
        return { success = false, message = IMRP.Locale('already_guest') }
    end

    MySQL.insert('INSERT INTO apartment_guests (apartment_id, citizenid) VALUES (?, ?)', {
        apartmentId, targetCitizenId
    })

    LogAction(citizenid, apartmentId, 'invite_guest', ('Guest: %s'):format(targetCitizenId))

    -- Notify guest
    TriggerClientEvent('ox_lib:notify', targetPlayer.PlayerData.source, {
        title = 'Apartments',
        description = IMRP.Locale('invited_to_apartment'),
        type = 'info',
        position = Config.Notification.position
    })

    return { success = true }
end)

lib.callback.register('imrp_apartments:server:getGuests', function(source, apartmentKey)
    local player, citizenid = IMRP.GetPlayerOrFail(source)
    if not player then return nil end

    local isOwner, apartmentId = IsOwner(citizenid, apartmentKey)
    if not isOwner then return nil end

    local guests = MySQL.query.await('SELECT citizenid FROM apartment_guests WHERE apartment_id = ?', { apartmentId })
    if not guests then return {} end

    return IMRP.EnrichWithNames(guests)
end)

lib.callback.register('imrp_apartments:server:removeGuest', function(source, apartmentKey, targetCitizenId)
    local player, citizenid, err = IMRP.GetPlayerOrFail(source)
    if not player then return err or { success = false } end
    local isOwner, apartmentId = IsOwner(citizenid, apartmentKey)
    if not isOwner then
        return { success = false, message = IMRP.Locale('not_owner') }
    end

    MySQL.query('DELETE FROM apartment_guests WHERE apartment_id = ? AND citizenid = ?', { apartmentId, targetCitizenId })

    LogAction(citizenid, apartmentId, 'remove_guest', ('Guest: %s'):format(targetCitizenId))

    return { success = true }
end)

-----------------------------------------------------------
-- Garage System
-----------------------------------------------------------
lib.callback.register('imrp_apartments:server:storeVehicle', function(source, apartmentKey, plate, props)
    local player, citizenid, err = IMRP.GetPlayerOrFail(source)
    if not player then return err or { success = false } end

    -- Verify access
    local hasAccess, apartmentId, _ = HasAccessToApartment(citizenid, apartmentKey)
    if not hasAccess then
        return { success = false, message = IMRP.Locale('no_access') }
    end

    -- Verify vehicle ownership
    local vehicleOwned = MySQL.scalar.await('SELECT COUNT(*) FROM player_vehicles WHERE citizenid = ? AND plate = ?', { citizenid, plate })
    if not vehicleOwned or vehicleOwned == 0 then
        return { success = false, message = IMRP.Locale('not_your_vehicle') }
    end

    -- Update vehicle garage location
    MySQL.update('UPDATE player_vehicles SET garage = ?, state = 1 WHERE citizenid = ? AND plate = ?', {
        ('apartment_%s'):format(apartmentId), citizenid, plate
    })

    LogAction(citizenid, apartmentId, 'store_vehicle', ('Plate: %s'):format(plate))

    return { success = true }
end)

lib.callback.register('imrp_apartments:server:getStoredVehicles', function(source, apartmentKey)
    local player, citizenid = IMRP.GetPlayerOrFail(source)
    if not player then return nil end

    local hasAccess, apartmentId, _ = HasAccessToApartment(citizenid, apartmentKey)
    if not hasAccess then return nil end

    local vehicles = MySQL.query.await('SELECT vehicle, plate, mods FROM player_vehicles WHERE citizenid = ? AND garage = ? AND state = 1', {
        citizenid, ('apartment_%s'):format(apartmentId)
    })

    if not vehicles then return {} end

    local result = {}
    for _, veh in ipairs(vehicles) do
        result[#result + 1] = {
            name = veh.vehicle,
            plate = veh.plate,
            model = GetHashKey(veh.vehicle),
            props = veh.mods and json.decode(veh.mods) or nil
        }
    end

    return result
end)

lib.callback.register('imrp_apartments:server:retrieveVehicle', function(source, apartmentKey, plate)
    local player, citizenid, err = IMRP.GetPlayerOrFail(source)
    if not player then return err or { success = false } end

    local hasAccess, apartmentId, _ = HasAccessToApartment(citizenid, apartmentKey)
    if not hasAccess then
        return { success = false, message = IMRP.Locale('no_access') }
    end

    MySQL.update('UPDATE player_vehicles SET state = 0 WHERE citizenid = ? AND plate = ? AND garage = ?', {
        citizenid, plate, ('apartment_%s'):format(apartmentId)
    })

    LogAction(citizenid, apartmentId, 'retrieve_vehicle', ('Plate: %s'):format(plate))

    return { success = true }
end)

-----------------------------------------------------------
-- Logout in Apartment
-----------------------------------------------------------
RegisterNetEvent('imrp_apartments:server:logoutInApartment', function()
    local player = IMRP.GetPlayerOrFail(source)
    if not player then return end

    -- Reset bucket before logout
    if Config.UseRoutingBuckets then
        SetPlayerRoutingBucket(source, 0)
    end

    -- Trigger QBX multicharacter logout
    TriggerClientEvent('qbx_core:client:Logout', src)
end)

-----------------------------------------------------------
-- Door Lock
-----------------------------------------------------------
lib.callback.register('imrp_apartments:server:toggleLock', function(source, apartmentKey)
    local player, citizenid, err = IMRP.GetPlayerOrFail(source)
    if not player then return err or { success = false } end

    local hasAccess, _, _ = HasAccessToApartment(citizenid, apartmentKey)
    if not hasAccess then
        return { success = false, message = IMRP.Locale('no_access') }
    end

    return { success = true }
end)

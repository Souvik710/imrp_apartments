-- Auto-detect framework
local QBCore = nil

-- Try to detect the framework
if GetResourceState('qb-core') == 'started' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif GetResourceState('qbx_core') == 'started' then
    QBCore = exports['qbx_core']:GetCoreObject()
elseif GetResourceState('qbcore') == 'started' then
    QBCore = exports['qbcore']:GetCoreObject()
else
    print('^1[imrp_apartments] ERROR: No supported framework found!^0')
    print('^1Please ensure qb-core, qbx_core, or qbcore is installed and started.^0')
end

local utils = require('shared.utils')

-- Initialize database on startup
CreateThread(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS player_apartments (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(50) NOT NULL,
            apartment VARCHAR(50) NOT NULL,
            roomid VARCHAR(100) NOT NULL,
            purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            expire_date TIMESTAMP NOT NULL,
            UNIQUE KEY unique_apartment (citizenid, apartment),
            INDEX idx_citizenid (citizenid),
            INDEX idx_expire_date (expire_date)
        )
    ]])
end)

-- Get player function
local function GetPlayer(source)
    if not source then return nil end
    if QBCore and QBCore.Functions then
        return QBCore.Functions.GetPlayer(source)
    end
    return nil
end

-- Get player by citizenid
local function GetPlayerByCitizenId(citizenid)
    if not citizenid then return nil end
    if QBCore and QBCore.Functions then
        return QBCore.Functions.GetPlayerByCitizenId(citizenid)
    end
    return nil
end

-- Safe database query wrapper
local function SafeFetchAll(query, params)
    local results = MySQL.Async.fetchAll(query, params or {})
    return results or {}
end

local function SafeFetchSingle(query, params)
    local result = MySQL.Async.fetchSingle(query, params or {})
    return result or nil
end

-- Check ownership
lib.callback.register('imrp_apartments:CheckOwnership', function(source, apartment_id)
    local player = GetPlayer(source)
    if not player then 
        print(string.format('[imrp_apartments] Player not found for source: %s', source))
        return false 
    end
    
    local citizenid = player.PlayerData.citizenid
    if not citizenid then return false end
    
    local result = SafeFetchSingle('SELECT * FROM player_apartments WHERE citizenid = ? AND apartment = ? AND expire_date > NOW()', {
        citizenid, apartment_id
    })
    
    return result ~= nil
end)

-- Purchase apartment
lib.callback.register('imrp_apartments:PurchaseApartment', function(source, apartment_id)
    local player = GetPlayer(source)
    if not player then 
        return false, 'Player not found' 
    end
    
    local apartment = Config.Apartments[apartment_id]
    if not apartment then 
        return false, 'Apartment not found' 
    end
    
    local citizenid = player.PlayerData.citizenid
    if not citizenid then 
        return false, 'Citizen ID not found' 
    end
    
    -- Check if player already owns this apartment
    local existing = SafeFetchSingle('SELECT * FROM player_apartments WHERE citizenid = ? AND apartment = ?', {
        citizenid, apartment_id
    })
    
    if existing then
        if existing.expire_date and existing.expire_date > os.time() then
            return false, 'You already own this apartment'
        else
            MySQL.Async.execute('DELETE FROM player_apartments WHERE id = ?', {existing.id})
        end
    end
    
    -- Check if player has enough money
    local balance = player.Functions.GetMoney('bank')
    if balance < apartment.price then
        return false, string.format('Insufficient funds. Required: $%s', FormatNumber(apartment.price))
    end
    
    -- Process payment
    local paymentSuccess = player.Functions.RemoveMoney('bank', apartment.price)
    if not paymentSuccess then
        return false, 'Payment failed'
    end
    
    -- Generate room ID
    local roomid = utils.GenerateRoomID(citizenid, apartment_id)
    
    -- Calculate expire date
    local expire_date = os.time() + (apartment.rental_days * 86400)
    
    -- Save to database
    local success = MySQL.Async.execute([[
        INSERT INTO player_apartments (citizenid, apartment, roomid, expire_date) 
        VALUES (?, ?, ?, FROM_UNIXTIME(?))
    ]], {citizenid, apartment_id, roomid, expire_date})
    
    if success then
        -- Create stash
        local stash_id = 'apartment_stash_' .. roomid
        exports.ox_inventory:RegisterStash(stash_id, apartment.label .. ' Stash', apartment.stash_slots, apartment.stash_weight)
        
        print(string.format('[imrp_apartments] Player %s purchased apartment %s for $%s', player.PlayerData.name or 'Unknown', apartment_id, apartment.price))
        
        return true, 'Apartment purchased successfully!'
    else
        -- Refund money if database insert fails
        player.Functions.AddMoney('bank', apartment.price)
        return false, 'Database error occurred'
    end
end)

-- Open stash
lib.callback.register('imrp_apartments:OpenStash', function(source, apartment_id)
    local player = GetPlayer(source)
    if not player then 
        return false 
    end
    
    local citizenid = player.PlayerData.citizenid
    if not citizenid then return false end
    
    -- Verify ownership
    local apartment_data = SafeFetchSingle('SELECT * FROM player_apartments WHERE citizenid = ? AND apartment = ? AND expire_date > NOW()', {
        citizenid, apartment_id
    })
    
    if not apartment_data then
        return false
    end
    
    local stash_id = 'apartment_stash_' .. apartment_data.roomid
    exports.ox_inventory:OpenInventory(source, stash_id)
    return true
end)

-- Renew apartment
lib.callback.register('imrp_apartments:RenewApartment', function(source, apartment_id)
    local player = GetPlayer(source)
    if not player then 
        return false, 'Player not found' 
    end
    
    local citizenid = player.PlayerData.citizenid
    if not citizenid then 
        return false, 'Citizen ID not found' 
    end
    
    -- Get existing apartment
    local apartment_data = SafeFetchSingle('SELECT * FROM player_apartments WHERE citizenid = ? AND apartment = ? AND expire_date > NOW()', {
        citizenid, apartment_id
    })
    
    if not apartment_data then
        return false, 'You do not own this apartment or it has expired'
    end
    
    local apartment = Config.Apartments[apartment_id]
    if not apartment then
        return false, 'Apartment configuration not found'
    end
    
    -- Check if player has enough money
    local balance = player.Functions.GetMoney('bank')
    if balance < apartment.rental_price then
        return false, string.format('Insufficient funds. Required: $%s', FormatNumber(apartment.rental_price))
    end
    
    -- Process payment
    local paymentSuccess = player.Functions.RemoveMoney('bank', apartment.rental_price)
    if not paymentSuccess then
        return false, 'Payment failed'
    end
    
    -- Update expiration date
    local new_expire_date = os.time() + (apartment.rental_days * 86400)
    local success = MySQL.Async.execute('UPDATE player_apartments SET expire_date = FROM_UNIXTIME(?) WHERE id = ?', {
        new_expire_date, apartment_data.id
    })
    
    if success then
        return true, 'Apartment renewed successfully!'
    else
        -- Refund money if update fails
        player.Functions.AddMoney('bank', apartment.rental_price)
        return false, 'Database error occurred'
    end
end)

-- Get my apartments
lib.callback.register('imrp_apartments:GetMyApartments', function(source)
    local player = GetPlayer(source)
    if not player then 
        return {} 
    end
    
    local citizenid = player.PlayerData.citizenid
    if not citizenid then return {} end
    
    local results = SafeFetchAll('SELECT * FROM player_apartments WHERE citizenid = ? AND expire_date > NOW()', {
        citizenid
    })
    
    return results
end)

-- Get apartment info
lib.callback.register('imrp_apartments:GetApartmentInfo', function(source, apartment_id)
    local player = GetPlayer(source)
    if not player then 
        return nil 
    end
    
    local citizenid = player.PlayerData.citizenid
    if not citizenid then return nil end
    
    local result = SafeFetchSingle('SELECT * FROM player_apartments WHERE citizenid = ? AND apartment = ? AND expire_date > NOW()', {
        citizenid, apartment_id
    })
    
    return result
end)

-- Admin command: Give apartment
RegisterCommand('apartmentgive', function(source, args, rawCommand)
    local player = GetPlayer(source)
    if not player then 
        print('[imrp_apartments] Admin command used by non-existent player')
        return 
    end
    
    -- Check admin permission
    if not HasPermission(source, Config.AdminPermissions) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'You don\'t have permission to use this command',
            type = 'error'
        })
        return
    end
    
    if not args[1] or not args[2] then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Usage',
            description = '/apartmentgive [player_id] [apartment_id]',
            type = 'info'
        })
        return
    end
    
    local target_id = tonumber(args[1])
    local apartment_id = args[2]
    
    if not target_id then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'Invalid player ID',
            type = 'error'
        })
        return
    end
    
    local target = GetPlayer(target_id)
    if not target then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'Player not found',
            type = 'error'
        })
        return
    end
    
    local success, message = GiveApartmentToPlayer(target_id, apartment_id)
    if success then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Success',
            description = 'Apartment given successfully',
            type = 'success'
        })
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = message or 'Failed to give apartment',
            type = 'error'
        })
    end
end, true)

-- Admin command: Remove apartment
RegisterCommand('apartmentremove', function(source, args, rawCommand)
    local player = GetPlayer(source)
    if not player then return end
    
    if not HasPermission(source, Config.AdminPermissions) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'You don\'t have permission to use this command',
            type = 'error'
        })
        return
    end
    
    if not args[1] then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Usage',
            description = '/apartmentremove [citizenid]',
            type = 'info'
        })
        return
    end
    
    local citizenid = args[1]
    local success = MySQL.Async.execute('DELETE FROM player_apartments WHERE citizenid = ?', {citizenid})
    
    if success then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Success',
            description = 'Apartment removed successfully',
            type = 'success'
        })
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'Failed to remove apartment',
            type = 'error'
        })
    end
end, true)

-- Admin command: List apartments
RegisterCommand('apartments', function(source, args, rawCommand)
    local player = GetPlayer(source)
    if not player then return end
    
    if not HasPermission(source, Config.AdminPermissions) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'You don\'t have permission to use this command',
            type = 'error'
        })
        return
    end
    
    local results = SafeFetchAll('SELECT * FROM player_apartments WHERE expire_date > NOW()', {})
    
    if not results or #results == 0 then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Info',
            description = 'No active apartments found',
            type = 'info'
        })
        return
    end
    
    local message = 'Active Apartments:\n'
    for _, data in ipairs(results) do
        local apartment = Config.Apartments[data.apartment]
        local apartment_name = apartment and apartment.label or data.apartment
        message = message .. string.format('%s - %s (Expires: %s)\n', 
            data.citizenid, 
            apartment_name, 
            os.date('%Y-%m-%d', data.expire_date))
    end
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Apartment List',
        description = message,
        type = 'info',
        duration = 15000
    })
end, true)

-- Admin command: Reset apartments
RegisterCommand('apartmentreset', function(source, args, rawCommand)
    local player = GetPlayer(source)
    if not player then return end
    
    if not HasPermission(source, Config.AdminPermissions) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'You don\'t have permission to use this command',
            type = 'error'
        })
        return
    end
    
    MySQL.Async.execute('TRUNCATE TABLE player_apartments', function(success)
        if success then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Success',
                description = 'All apartments have been reset',
                type = 'success'
            })
        else
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Error',
                description = 'Failed to reset apartments',
                type = 'error'
            })
        end
    end)
end, true)

-- Helper function to give apartment
function GiveApartmentToPlayer(player_id, apartment_id)
    local target = GetPlayer(player_id)
    if not target then 
        return false, 'Player not found' 
    end
    
    local apartment = Config.Apartments[apartment_id]
    if not apartment then 
        return false, 'Apartment not found' 
    end
    
    local citizenid = target.PlayerData.citizenid
    if not citizenid then 
        return false, 'Citizen ID not found' 
    end
    
    -- Check if player already owns this apartment
    local existing = SafeFetchSingle('SELECT * FROM player_apartments WHERE citizenid = ? AND apartment = ?', {
        citizenid, apartment_id
    })
    
    if existing then
        if existing.expire_date and existing.expire_date > os.time() then
            return false, 'Player already owns this apartment'
        else
            MySQL.Async.execute('DELETE FROM player_apartments WHERE id = ?', {existing.id})
        end
    end
    
    local roomid = utils.GenerateRoomID(citizenid, apartment_id)
    local expire_date = os.time() + (apartment.rental_days * 86400)
    
    local success = MySQL.Async.execute([[
        INSERT INTO player_apartments (citizenid, apartment, roomid, expire_date) 
        VALUES (?, ?, ?, FROM_UNIXTIME(?))
    ]], {citizenid, apartment_id, roomid, expire_date})
    
    if success then
        -- Create stash
        local stash_id = 'apartment_stash_' .. roomid
        exports.ox_inventory:RegisterStash(stash_id, apartment.label .. ' Stash', apartment.stash_slots, apartment.stash_weight)
        return true, 'Success'
    else
        return false, 'Database error'
    end
end

-- Permission check
function HasPermission(source, permissions)
    local player = GetPlayer(source)
    if not player then 
        return false 
    end
    
    -- Check if player has admin permissions
    if player.PlayerData.permissions then
        for _, permission in ipairs(permissions) do
            if player.PlayerData.permissions[permission] then
                return true
            end
        end
    end
    
    -- Check if player is admin via group
    if player.PlayerData.group then
        for _, permission in ipairs(permissions) do
            if player.PlayerData.group == permission then
                return true
            end
        end
    end
    
    return false
end

-- Format number helper
function FormatNumber(number)
    return string.format("%.0f", number):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

-- Auto cleanup expired apartments
CreateThread(function()
    while true do
        Wait(Config.UpdateInterval or 60000)
        
        local expired = SafeFetchAll('SELECT * FROM player_apartments WHERE expire_date < NOW()', {})
        
        if expired and #expired > 0 then
            for _, data in ipairs(expired) do
                -- Delete expired apartment
                MySQL.Async.execute('DELETE FROM player_apartments WHERE id = ?', {data.id})
                
                -- Notify player if online
                local player = GetPlayerByCitizenId(data.citizenid)
                if player then
                    TriggerClientEvent('ox_lib:notify', player.PlayerData.source, {
                        title = 'Apartment Expired',
                        description = 'Your apartment has expired. Please renew to regain access.',
                        type = 'error'
                    })
                end
            end
            
            print(string.format('[imrp_apartments] Removed %s expired apartments', #expired))
        end
    end
end)

print('^2[imrp_apartments] Apartment system loaded successfully!^0')
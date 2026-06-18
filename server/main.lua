-- Server-side main script for IMRP Apartments
-- Security: All events validate source, use parameterized SQL, enforce permissions

local QBX = exports['qbx_core']

--- Check if a player has admin permissions
--- @param source number Player server ID
--- @return boolean
local function HasAdminPermission(source)
    if not source or source <= 0 then return false end
    local player = QBX:GetPlayer(source)
    if not player then return false end

    for _, permission in ipairs(Config.AdminPermissions) do
        if QBX:HasPermission(source, permission) then
            return true
        end
    end
    return false
end

--- Validate that the event source is a real connected player
--- Prevents spoofed events from invalid sources
--- @param source number
--- @return boolean
local function IsValidSource(source)
    if not source or type(source) ~= 'number' then return false end
    if source <= 0 then return false end
    -- Verify player is actually connected
    local player = QBX:GetPlayer(source)
    return player ~= nil
end

--- Get player identifier safely
--- @param source number
--- @return string|nil
local function GetPlayerIdentifier(source)
    if not IsValidSource(source) then return nil end
    local player = QBX:GetPlayer(source)
    if not player then return nil end
    return player.PlayerData.citizenid
end

-- ============================================================================
-- DATABASE OPERATIONS (All use parameterized queries to prevent SQL injection)
-- ============================================================================

--- Create apartments table if it doesn't exist
MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `imrp_apartments` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `citizenid` VARCHAR(50) NOT NULL,
            `apartment_id` VARCHAR(50) NOT NULL,
            `owned` TINYINT(1) DEFAULT 0,
            `rental_expiry` DATETIME DEFAULT NULL,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_citizenid` (`citizenid`),
            INDEX `idx_apartment` (`apartment_id`),
            UNIQUE KEY `unique_ownership` (`citizenid`, `apartment_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

--- Get all apartments owned or rented by a player
--- @param citizenid string
--- @return table
local function GetPlayerApartments(citizenid)
    -- Parameterized query prevents SQL injection
    local result = MySQL.query.await('SELECT * FROM `imrp_apartments` WHERE `citizenid` = ?', { citizenid })
    return result or {}
end

--- Check if a player owns a specific apartment
--- @param citizenid string
--- @param apartmentId string
--- @return boolean
local function PlayerOwnsApartment(citizenid, apartmentId)
    local result = MySQL.scalar.await(
        'SELECT COUNT(*) FROM `imrp_apartments` WHERE `citizenid` = ? AND `apartment_id` = ? AND `owned` = 1',
        { citizenid, apartmentId }
    )
    return (result or 0) > 0
end

--- Count total apartments owned by a player
--- @param citizenid string
--- @return number
local function GetPlayerApartmentCount(citizenid)
    local result = MySQL.scalar.await(
        'SELECT COUNT(*) FROM `imrp_apartments` WHERE `citizenid` = ?',
        { citizenid }
    )
    return result or 0
end

--- Purchase an apartment for a player
--- @param citizenid string
--- @param apartmentId string
--- @return boolean success
local function PurchaseApartment(citizenid, apartmentId)
    local affected = MySQL.insert.await(
        'INSERT INTO `imrp_apartments` (`citizenid`, `apartment_id`, `owned`) VALUES (?, ?, 1)',
        { citizenid, apartmentId }
    )
    return affected and affected > 0
end

--- Rent an apartment for a player
--- @param citizenid string
--- @param apartmentId string
--- @param days number
--- @return boolean success
local function RentApartment(citizenid, apartmentId, days)
    if not Utils.IsValidNumber(days, 90) then return false end
    local affected = MySQL.insert.await(
        'INSERT INTO `imrp_apartments` (`citizenid`, `apartment_id`, `owned`, `rental_expiry`) VALUES (?, ?, 0, DATE_ADD(NOW(), INTERVAL ? DAY))',
        { citizenid, apartmentId, days }
    )
    return affected and affected > 0
end

--- Remove an apartment from a player (admin or eviction)
--- @param citizenid string
--- @param apartmentId string
--- @return boolean success
local function RemoveApartment(citizenid, apartmentId)
    local affected = MySQL.query.await(
        'DELETE FROM `imrp_apartments` WHERE `citizenid` = ? AND `apartment_id` = ?',
        { citizenid, apartmentId }
    )
    return affected and affected.affectedRows > 0
end

-- ============================================================================
-- EVENT HANDLERS (All validate source and inputs before processing)
-- ============================================================================

--- Player requests to purchase an apartment
RegisterNetEvent('imrp_apartments:server:purchase', function(apartmentId)
    local source = source

    -- Validate source is a real player
    if not IsValidSource(source) then return end

    -- Rate limit: 1 purchase attempt per 5 seconds
    local citizenid = GetPlayerIdentifier(source)
    if not citizenid then return end

    if Utils.IsRateLimited(citizenid, 'purchase', 5000) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Apartments',
            description = 'Please wait before trying again.',
            type = 'error'
        })
        return
    end

    -- Validate apartment ID exists in config
    if not Utils.IsValidApartmentId(apartmentId) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Apartments',
            description = 'Invalid apartment.',
            type = 'error'
        })
        return
    end

    -- Check max apartment limit
    local currentCount = GetPlayerApartmentCount(citizenid)
    if currentCount >= Config.MaxApartmentsPerPlayer then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Apartments',
            description = 'You own the maximum number of apartments.',
            type = 'error'
        })
        return
    end

    -- Check if player already owns this apartment
    if PlayerOwnsApartment(citizenid, apartmentId) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Apartments',
            description = 'You already own this apartment.',
            type = 'error'
        })
        return
    end

    -- Process payment
    local apartment = Config.Apartments[apartmentId]
    local player = QBX:GetPlayer(source)
    if not player then return end

    local paymentMethod = Config.BankPayment and 'bank' or Config.DefaultCurrency
    local price = apartment.price

    if not Utils.IsValidNumber(price, 10000000) then return end

    if player.Functions.RemoveMoney(paymentMethod, price, 'apartment-purchase') then
        if PurchaseApartment(citizenid, apartmentId) then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Apartments',
                description = 'You purchased ' .. Utils.SanitizeString(apartment.label) .. '!',
                type = 'success'
            })
        else
            -- Refund on database failure
            player.Functions.AddMoney(paymentMethod, price, 'apartment-purchase-refund')
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Apartments',
                description = 'Purchase failed. You have been refunded.',
                type = 'error'
            })
        end
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Apartments',
            description = 'You cannot afford this apartment.',
            type = 'error'
        })
    end
end)

--- Player requests to rent an apartment
RegisterNetEvent('imrp_apartments:server:rent', function(apartmentId)
    local source = source

    if not IsValidSource(source) then return end

    local citizenid = GetPlayerIdentifier(source)
    if not citizenid then return end

    if Utils.IsRateLimited(citizenid, 'rent', 5000) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Apartments',
            description = 'Please wait before trying again.',
            type = 'error'
        })
        return
    end

    if not Utils.IsValidApartmentId(apartmentId) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Apartments',
            description = 'Invalid apartment.',
            type = 'error'
        })
        return
    end

    local currentCount = GetPlayerApartmentCount(citizenid)
    if currentCount >= Config.MaxApartmentsPerPlayer then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Apartments',
            description = 'You own the maximum number of apartments.',
            type = 'error'
        })
        return
    end

    local apartment = Config.Apartments[apartmentId]
    local player = QBX:GetPlayer(source)
    if not player then return end

    local paymentMethod = Config.BankPayment and 'bank' or Config.DefaultCurrency
    local rentalPrice = apartment.rental_price

    if not Utils.IsValidNumber(rentalPrice, 10000000) then return end

    if player.Functions.RemoveMoney(paymentMethod, rentalPrice, 'apartment-rental') then
        if RentApartment(citizenid, apartmentId, apartment.rental_days) then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Apartments',
                description = 'You rented ' .. Utils.SanitizeString(apartment.label) .. '!',
                type = 'success'
            })
        else
            player.Functions.AddMoney(paymentMethod, rentalPrice, 'apartment-rental-refund')
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Apartments',
                description = 'Rental failed. You have been refunded.',
                type = 'error'
            })
        end
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Apartments',
            description = 'You cannot afford the rental.',
            type = 'error'
        })
    end
end)

--- Player requests their apartment list
RegisterNetEvent('imrp_apartments:server:getApartments', function()
    local source = source

    if not IsValidSource(source) then return end

    local citizenid = GetPlayerIdentifier(source)
    if not citizenid then return end

    if Utils.IsRateLimited(citizenid, 'list', 2000) then return end

    local apartments = GetPlayerApartments(citizenid)
    TriggerClientEvent('imrp_apartments:client:receiveApartments', source, apartments)
end)

--- Player requests to enter their apartment
RegisterNetEvent('imrp_apartments:server:enter', function(apartmentId)
    local source = source

    if not IsValidSource(source) then return end

    local citizenid = GetPlayerIdentifier(source)
    if not citizenid then return end

    if not Utils.IsValidApartmentId(apartmentId) then return end

    -- Verify ownership before allowing entry
    if not PlayerOwnsApartment(citizenid, apartmentId) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Apartments',
            description = 'You do not have access to this apartment.',
            type = 'error'
        })
        return
    end

    local apartment = Config.Apartments[apartmentId]
    TriggerClientEvent('imrp_apartments:client:enterApartment', source, apartmentId, apartment.location.interior)
end)

-- ============================================================================
-- ADMIN COMMANDS (Permission-gated)
-- ============================================================================

--- Admin: Remove a player's apartment
RegisterNetEvent('imrp_apartments:server:adminRemove', function(targetCitizenId, apartmentId)
    local source = source

    if not IsValidSource(source) then return end

    -- Enforce admin permission check
    if not HasAdminPermission(source) then
        -- Log unauthorized admin attempt
        print(('[SECURITY] Player %d attempted admin action without permission'):format(source))
        return
    end

    if not Utils.IsValidString(targetCitizenId) then return end
    if not Utils.IsValidApartmentId(apartmentId) then return end

    if RemoveApartment(targetCitizenId, apartmentId) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Admin',
            description = 'Apartment removed successfully.',
            type = 'success'
        })
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Admin',
            description = 'Failed to remove apartment.',
            type = 'error'
        })
    end
end)

--- Admin: List all apartments (for admin panel)
RegisterNetEvent('imrp_apartments:server:adminList', function()
    local source = source

    if not IsValidSource(source) then return end

    if not HasAdminPermission(source) then
        print(('[SECURITY] Player %d attempted admin list without permission'):format(source))
        return
    end

    -- Parameterized query with limit to prevent excessive data retrieval
    local result = MySQL.query.await('SELECT * FROM `imrp_apartments` ORDER BY `created_at` DESC LIMIT 100')
    TriggerClientEvent('imrp_apartments:client:adminReceiveList', source, result or {})
end)

-- ============================================================================
-- CLEANUP: Expire rentals periodically
-- ============================================================================

CreateThread(function()
    while true do
        Wait(Config.UpdateInterval)
        MySQL.query('DELETE FROM `imrp_apartments` WHERE `owned` = 0 AND `rental_expiry` IS NOT NULL AND `rental_expiry` < NOW()')
    end
end)

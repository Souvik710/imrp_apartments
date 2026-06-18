local Utils = {}

function Utils.GenerateRoomID(citizenid, apartment_id)
    if not citizenid or not apartment_id then
        print('[imrp_apartments] GenerateRoomID: missing citizenid or apartment_id')
        return string.format('unknown_%s', os.time())
    end
    return string.format('%s_%s_%s', citizenid, apartment_id, os.time())
end

function Utils.IsNullOrEmpty(str)
    return str == nil or str == ''
end

function Utils.FormatCurrency(amount)
    if type(amount) ~= 'number' then return '$0.00' end
    return '$' .. string.format("%.2f", amount)
end

function Utils.GetDaysRemaining(expire_date)
    if not expire_date then return 0 end
    local current_time = os.time()
    local expire_timestamp = expire_date
    if type(expire_timestamp) ~= 'number' then return 0 end
    local time_diff = expire_timestamp - current_time
    return math.max(0, math.ceil(time_diff / 86400))
end

function Utils.GetApartmentById(id)
    if not id then return nil end
    if not Config or not Config.Apartments then
        print('[imrp_apartments] GetApartmentById: Config.Apartments not available')
        return nil
    end
    return Config.Apartments[id]
end

function Utils.PlayerOwnsApartment(player_id, apartment_id)
    if not IsDuplicityVersion() then
        print('[imrp_apartments] PlayerOwnsApartment can only be called server-side')
        return false
    end

    if not player_id or not apartment_id then return false end

    local QBCore = nil
    if GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
    elseif GetResourceState('qbx_core') == 'started' then
        QBCore = exports['qbx_core']:GetCoreObject()
    end

    if not QBCore then
        print('[imrp_apartments] PlayerOwnsApartment: framework not available')
        return false
    end

    local player = QBCore.Functions.GetPlayer(player_id)
    if not player then return false end

    local citizenid = player.PlayerData.citizenid
    if not citizenid then return false end

    local ok, result = pcall(MySQL.Async.fetchSingle,
        'SELECT COUNT(*) as count FROM player_apartments WHERE citizenid = ? AND apartment = ? AND expire_date > NOW()',
        {citizenid, apartment_id}
    )
    if not ok then
        print(string.format('[imrp_apartments] PlayerOwnsApartment DB error: %s', tostring(result)))
        return false
    end

    return result and result.count and result.count > 0
end

function Utils.GetPlayerApartments(player_id)
    if not IsDuplicityVersion() then
        print('[imrp_apartments] GetPlayerApartments can only be called server-side')
        return {}
    end

    if not player_id then return {} end

    local QBCore = nil
    if GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
    elseif GetResourceState('qbx_core') == 'started' then
        QBCore = exports['qbx_core']:GetCoreObject()
    end

    if not QBCore then
        print('[imrp_apartments] GetPlayerApartments: framework not available')
        return {}
    end

    local player = QBCore.Functions.GetPlayer(player_id)
    if not player then return {} end

    local citizenid = player.PlayerData.citizenid
    if not citizenid then return {} end

    local ok, results = pcall(MySQL.Async.fetchAll,
        'SELECT * FROM player_apartments WHERE citizenid = ? AND expire_date > NOW()',
        {citizenid}
    )
    if not ok then
        print(string.format('[imrp_apartments] GetPlayerApartments DB error: %s', tostring(results)))
        return {}
    end

    return results or {}
end

function Utils.GetAllApartments()
    if not IsDuplicityVersion() then
        print('[imrp_apartments] GetAllApartments can only be called server-side')
        return {}
    end

    local ok, results = pcall(MySQL.Async.fetchAll,
        'SELECT * FROM player_apartments WHERE expire_date > NOW()', {}
    )
    if not ok then
        print(string.format('[imrp_apartments] GetAllApartments DB error: %s', tostring(results)))
        return {}
    end

    return results or {}
end

return Utils

local Utils = {}

function Utils.GenerateRoomID(citizenid, apartment_id)
    return string.format('%s_%s_%s', citizenid, apartment_id, os.time())
end

function Utils.IsNullOrEmpty(str)
    return str == nil or str == ''
end

function Utils.FormatCurrency(amount)
    return '$' .. string.format("%.2f", amount)
end

function Utils.GetDaysRemaining(expire_date)
    local current_time = os.time()
    local expire_timestamp = expire_date
    local time_diff = expire_timestamp - current_time
    return math.max(0, math.ceil(time_diff / 86400))
end

function Utils.GetApartmentById(id)
    for k, v in pairs(Config.Apartments) do
        if k == id then
            return v
        end
    end
    return nil
end

function Utils.PlayerOwnsApartment(player_id, apartment_id)
    local player = exports.qb_core:GetPlayer(player_id)
    if not player then return false end
    
    local citizenid = player.PlayerData.citizenid
    local result = MySQL.Async.fetchSingle('SELECT COUNT(*) as count FROM player_apartments WHERE citizenid = ? AND apartment = ? AND expire_date > NOW()', {
        citizenid, apartment_id
    })
    
    return result and result.count > 0
end

function Utils.GetPlayerApartments(player_id)
    local player = exports.qb_core:GetPlayer(player_id)
    if not player then return {} end
    
    local citizenid = player.PlayerData.citizenid
    local results = MySQL.Async.fetchAll('SELECT * FROM player_apartments WHERE citizenid = ? AND expire_date > NOW()', {
        citizenid
    })
    
    return results or {}
end

function Utils.GetAllApartments()
    local results = MySQL.Async.fetchAll('SELECT * FROM player_apartments WHERE expire_date > NOW()', {})
    return results or {}
end

return Utils
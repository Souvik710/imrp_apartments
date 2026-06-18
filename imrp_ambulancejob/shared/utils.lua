-----------------------------------------------------------
-- Shared Utility Functions
-----------------------------------------------------------

EMSUtils = {}

function EMSUtils.Notify(msg, type, duration)
    if IsDuplicityVersion() then return end
    lib.notify({
        title = 'IMRP EMS',
        description = msg,
        type = type or 'info',
        duration = duration or 5000,
        position = Config.Notification.position,
    })
end

function EMSUtils.IsEMS(source)
    if IsDuplicityVersion() then
        local player = exports.qbx_core:GetPlayer(source)
        if not player then return false end
        return player.PlayerData.job.name == Config.JobName
    else
        local playerData = exports.qbx_core:GetPlayerData()
        if not playerData then return false end
        return playerData.job.name == Config.JobName
    end
end

function EMSUtils.IsOnDuty(source)
    if IsDuplicityVersion() then
        local player = exports.qbx_core:GetPlayer(source)
        if not player then return false end
        return player.PlayerData.job.name == Config.JobName and player.PlayerData.job.onduty
    else
        local playerData = exports.qbx_core:GetPlayerData()
        if not playerData then return false end
        return playerData.job.name == Config.JobName and playerData.job.onduty
    end
end

function EMSUtils.GetRank(source)
    if IsDuplicityVersion() then
        local player = exports.qbx_core:GetPlayer(source)
        if not player then return 0 end
        return player.PlayerData.job.grade.level or 0
    else
        local playerData = exports.qbx_core:GetPlayerData()
        if not playerData then return 0 end
        return playerData.job.grade.level or 0
    end
end

function EMSUtils.HasPermission(source, permission)
    local grade = EMSUtils.GetRank(source)
    return Ranks.HasPermission(grade, permission)
end

function EMSUtils.GetClosestPlayer(coords, maxDist)
    maxDist = maxDist or 3.0
    local players = GetActivePlayers()
    local closestPlayer = nil
    local closestDist = maxDist

    for _, playerId in ipairs(players) do
        local ped = GetPlayerPed(playerId)
        if ped ~= PlayerPedId() then
            local playerCoords = GetEntityCoords(ped)
            local dist = #(coords - playerCoords)
            if dist < closestDist then
                closestDist = dist
                closestPlayer = GetPlayerServerId(playerId)
            end
        end
    end

    return closestPlayer, closestDist
end

function EMSUtils.FormatMoney(amount)
    local formatted = tostring(amount)
    local k
    while true do
        formatted, k = string.gsub(formatted, '^(-?%d+)(%d%d%d)', '%1,%2')
        if k == 0 then break end
    end
    return '$' .. formatted
end

function EMSUtils.FormatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format('%02d:%02d', mins, secs)
end

function EMSUtils.GenerateId()
    return string.format('%s-%s', os.time(), math.random(1000, 9999))
end

function EMSUtils.IsAdmin(source)
    if not IsDuplicityVersion() then return false end
    for _, perm in ipairs(Config.AdminPermissions) do
        if IsPlayerAceAllowed(tostring(source), perm) then
            return true
        end
    end
    return false
end

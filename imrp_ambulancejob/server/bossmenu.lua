-----------------------------------------------------------
-- IMRP Ambulance Job - Server Boss Menu Handlers
-----------------------------------------------------------

-----------------------------------------------------------
-- Get Employees
-----------------------------------------------------------
lib.callback.register('imrp_ambulancejob:server:getEmployees', function(source)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player or player.PlayerData.job.name ~= Config.JobName then return {} end
    if not Ranks.HasPermission(player.PlayerData.job.grade.level, 'boss_menu') then return {} end

    local employees = MySQL.query.await([[
        SELECT p.citizenid,
               JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')) as firstname,
               JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname')) as lastname,
               JSON_UNQUOTE(JSON_EXTRACT(p.job, '$.grade.level')) as grade,
               JSON_UNQUOTE(JSON_EXTRACT(p.job, '$.grade.name')) as grade_name
        FROM players p
        WHERE JSON_UNQUOTE(JSON_EXTRACT(p.job, '$.name')) = ?
        ORDER BY CAST(JSON_UNQUOTE(JSON_EXTRACT(p.job, '$.grade.level')) AS UNSIGNED) DESC
    ]], { Config.JobName })

    if not employees then return {} end

    local result = {}
    for _, emp in ipairs(employees) do
        local grade = tonumber(emp.grade) or 0
        table.insert(result, {
            citizenid = emp.citizenid,
            name = (emp.firstname or '') .. ' ' .. (emp.lastname or ''),
            grade = grade,
            rank_label = Ranks.GetLabel(grade),
        })
    end

    return result
end)

-----------------------------------------------------------
-- Hire Employee
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:server:hireEmployee', function(targetSrc)
    local src = source
    local boss = exports.qbx_core:GetPlayer(src)
    if not boss or boss.PlayerData.job.name ~= Config.JobName then return end
    if not Ranks.HasPermission(boss.PlayerData.job.grade.level, 'boss_menu') then return end

    local target = exports.qbx_core:GetPlayer(targetSrc)
    if not target then
        TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'Player not found', type = 'error' })
        return
    end

    target.Functions.SetJob(Config.JobName, 0)

    local targetName = target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname
    local bossName = boss.PlayerData.charinfo.firstname .. ' ' .. boss.PlayerData.charinfo.lastname

    -- Add to staff table
    MySQL.insert([[
        INSERT INTO ems_staff (citizenid, name, rank, rank_label)
        VALUES (?, ?, 0, 'Trainee EMT')
        ON DUPLICATE KEY UPDATE is_active = 1, rank = 0, rank_label = 'Trainee EMT'
    ]], { target.PlayerData.citizenid, targetName })

    LogAction(boss.PlayerData.citizenid, bossName, 'hire', 'Hired ' .. targetName, target.PlayerData.citizenid)

    TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'Hired ' .. targetName .. ' as Trainee EMT', type = 'success' })
    TriggerClientEvent('ox_lib:notify', targetSrc, { title = 'IMRP EMS', description = 'You have been hired as Trainee EMT!', type = 'success' })
end)

-----------------------------------------------------------
-- Fire Employee
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:server:fireEmployee', function(citizenid)
    local src = source
    local boss = exports.qbx_core:GetPlayer(src)
    if not boss or boss.PlayerData.job.name ~= Config.JobName then return end
    if not Ranks.HasPermission(boss.PlayerData.job.grade.level, 'boss_menu') then return end

    local target = exports.qbx_core:GetPlayerByCitizenId(citizenid)
    if target then
        target.Functions.SetJob('unemployed', 0)
        TriggerClientEvent('ox_lib:notify', target.PlayerData.source, { title = 'IMRP EMS', description = 'You have been fired from EMS', type = 'error' })
    else
        MySQL.update("UPDATE players SET job = JSON_SET(job, '$.name', 'unemployed', '$.grade.level', 0) WHERE citizenid = ?", { citizenid })
    end

    MySQL.update('UPDATE ems_staff SET is_active = 0 WHERE citizenid = ?', { citizenid })

    local bossName = boss.PlayerData.charinfo.firstname .. ' ' .. boss.PlayerData.charinfo.lastname
    LogAction(boss.PlayerData.citizenid, bossName, 'fire', 'Fired employee', citizenid)

    TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'Employee terminated', type = 'success' })
end)

-----------------------------------------------------------
-- Promote Employee
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:server:promoteEmployee', function(citizenid)
    local src = source
    local boss = exports.qbx_core:GetPlayer(src)
    if not boss or boss.PlayerData.job.name ~= Config.JobName then return end
    if not Ranks.HasPermission(boss.PlayerData.job.grade.level, 'staff_management') then return end

    local target = exports.qbx_core:GetPlayerByCitizenId(citizenid)
    if target then
        local currentGrade = target.PlayerData.job.grade.level
        local newGrade = math.min(currentGrade + 1, 9)

        if newGrade >= boss.PlayerData.job.grade.level then
            TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'Cannot promote to your rank or higher', type = 'error' })
            return
        end

        target.Functions.SetJob(Config.JobName, newGrade)

        MySQL.update('UPDATE ems_staff SET rank = ?, rank_label = ? WHERE citizenid = ?', {
            newGrade, Ranks.GetLabel(newGrade), citizenid
        })

        TriggerClientEvent('ox_lib:notify', target.PlayerData.source, {
            title = 'IMRP EMS',
            description = 'You have been promoted to ' .. Ranks.GetLabel(newGrade),
            type = 'success',
        })
    else
        -- Offline promotion
        local staffData = MySQL.single.await('SELECT rank FROM ems_staff WHERE citizenid = ?', { citizenid })
        if staffData then
            local newGrade = math.min(staffData.rank + 1, 9)
            MySQL.update('UPDATE ems_staff SET rank = ?, rank_label = ? WHERE citizenid = ?', {
                newGrade, Ranks.GetLabel(newGrade), citizenid
            })
            MySQL.update("UPDATE players SET job = JSON_SET(job, '$.grade.level', ?) WHERE citizenid = ?", { newGrade, citizenid })
        end
    end

    local bossName = boss.PlayerData.charinfo.firstname .. ' ' .. boss.PlayerData.charinfo.lastname
    LogAction(boss.PlayerData.citizenid, bossName, 'promote', 'Promoted employee', citizenid)

    TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'Employee promoted', type = 'success' })
end)

-----------------------------------------------------------
-- Demote Employee
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:server:demoteEmployee', function(citizenid)
    local src = source
    local boss = exports.qbx_core:GetPlayer(src)
    if not boss or boss.PlayerData.job.name ~= Config.JobName then return end
    if not Ranks.HasPermission(boss.PlayerData.job.grade.level, 'staff_management') then return end

    local target = exports.qbx_core:GetPlayerByCitizenId(citizenid)
    if target then
        local currentGrade = target.PlayerData.job.grade.level
        local newGrade = math.max(currentGrade - 1, 0)

        target.Functions.SetJob(Config.JobName, newGrade)

        MySQL.update('UPDATE ems_staff SET rank = ?, rank_label = ? WHERE citizenid = ?', {
            newGrade, Ranks.GetLabel(newGrade), citizenid
        })

        TriggerClientEvent('ox_lib:notify', target.PlayerData.source, {
            title = 'IMRP EMS',
            description = 'You have been demoted to ' .. Ranks.GetLabel(newGrade),
            type = 'error',
        })
    else
        local staffData = MySQL.single.await('SELECT rank FROM ems_staff WHERE citizenid = ?', { citizenid })
        if staffData then
            local newGrade = math.max(staffData.rank - 1, 0)
            MySQL.update('UPDATE ems_staff SET rank = ?, rank_label = ? WHERE citizenid = ?', {
                newGrade, Ranks.GetLabel(newGrade), citizenid
            })
            MySQL.update("UPDATE players SET job = JSON_SET(job, '$.grade.level', ?) WHERE citizenid = ?", { newGrade, citizenid })
        end
    end

    local bossName = boss.PlayerData.charinfo.firstname .. ' ' .. boss.PlayerData.charinfo.lastname
    LogAction(boss.PlayerData.citizenid, bossName, 'demote', 'Demoted employee', citizenid)

    TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'Employee demoted', type = 'success' })
end)

-----------------------------------------------------------
-- Set Callsign
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:server:setCallsign', function(citizenid, callsign)
    local src = source
    local boss = exports.qbx_core:GetPlayer(src)
    if not boss or boss.PlayerData.job.name ~= Config.JobName then return end

    MySQL.update('UPDATE ems_staff SET callsign = ? WHERE citizenid = ?', { callsign, citizenid })

    TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'Callsign updated to: ' .. callsign, type = 'success' })
end)

-----------------------------------------------------------
-- Society Account
-----------------------------------------------------------
lib.callback.register('imrp_ambulancejob:server:getSocietyBalance', function(source)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player or player.PlayerData.job.name ~= Config.JobName then return 0 end
    if not Ranks.HasPermission(player.PlayerData.job.grade.level, 'boss_menu') then return 0 end

    local account = exports.qbx_core:GetAccount(Config.JobName)
    return account or 0
end)

RegisterNetEvent('imrp_ambulancejob:server:societyDeposit', function(amount)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player or player.PlayerData.job.name ~= Config.JobName then return end
    if not Ranks.HasPermission(player.PlayerData.job.grade.level, 'boss_menu') then return end

    amount = tonumber(amount)
    if not amount or amount <= 0 then return end

    if player.Functions.RemoveMoney(Config.DefaultCurrency, amount, 'ems-society-deposit') then
        exports.qbx_core:AddMoney(Config.JobName, amount)
        TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'Deposited ' .. EMSUtils.FormatMoney(amount), type = 'success' })
    else
        TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'Insufficient funds', type = 'error' })
    end
end)

RegisterNetEvent('imrp_ambulancejob:server:societyWithdraw', function(amount)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player or player.PlayerData.job.name ~= Config.JobName then return end
    if not Ranks.HasPermission(player.PlayerData.job.grade.level, 'boss_menu') then return end

    amount = tonumber(amount)
    if not amount or amount <= 0 then return end

    local balance = exports.qbx_core:GetAccount(Config.JobName) or 0
    if balance >= amount then
        exports.qbx_core:RemoveMoney(Config.JobName, amount)
        player.Functions.AddMoney(Config.DefaultCurrency, amount, 'ems-society-withdraw')
        TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'Withdrew ' .. EMSUtils.FormatMoney(amount), type = 'success' })
    else
        TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'Insufficient society funds', type = 'error' })
    end
end)

-----------------------------------------------------------
-- Employee Logs
-----------------------------------------------------------
lib.callback.register('imrp_ambulancejob:server:getEmployeeLogs', function(source)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player or player.PlayerData.job.name ~= Config.JobName then return {} end

    return MySQL.query.await('SELECT * FROM ems_logs ORDER BY created_at DESC LIMIT 100') or {}
end)

-----------------------------------------------------------
-- Log action helper
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:server:logAction', function(action, details)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    LogAction(player.PlayerData.citizenid, name, action, details)
end)

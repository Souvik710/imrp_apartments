-----------------------------------------------------------
-- IMRP Ambulance Job - Server Main
-- Framework: QBX Core | Author: Ragna
-----------------------------------------------------------

local onDutyEMS = {}

-----------------------------------------------------------
-- Auto-create DB tables on resource start
-----------------------------------------------------------
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ems_patients` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `citizenid` VARCHAR(50) NOT NULL,
            `name` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
            `injuries` LONGTEXT DEFAULT NULL,
            `blood_level` INT NOT NULL DEFAULT 100,
            `pain_level` INT NOT NULL DEFAULT 0,
            `is_dead` TINYINT(1) NOT NULL DEFAULT 0,
            `last_treated_by` VARCHAR(50) DEFAULT NULL,
            `last_treated_at` TIMESTAMP NULL DEFAULT NULL,
            `insurance_type` VARCHAR(20) DEFAULT NULL,
            `insurance_expires` TIMESTAMP NULL DEFAULT NULL,
            `notes` TEXT DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY `uk_citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ems_reports` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `report_id` VARCHAR(50) NOT NULL,
            `author_citizenid` VARCHAR(50) NOT NULL,
            `author_name` VARCHAR(100) NOT NULL,
            `patient_citizenid` VARCHAR(50) NOT NULL,
            `patient_name` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
            `title` VARCHAR(255) NOT NULL,
            `description` TEXT NOT NULL,
            `injuries_found` LONGTEXT DEFAULT NULL,
            `treatment_given` LONGTEXT DEFAULT NULL,
            `diagnosis` TEXT DEFAULT NULL,
            `outcome` VARCHAR(50) DEFAULT 'treated',
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `uk_report_id` (`report_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ems_calls` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `call_id` VARCHAR(50) NOT NULL,
            `caller_citizenid` VARCHAR(50) DEFAULT NULL,
            `caller_name` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
            `call_type` VARCHAR(50) NOT NULL,
            `description` TEXT DEFAULT NULL,
            `location` VARCHAR(255) DEFAULT NULL,
            `coords_x` FLOAT DEFAULT NULL,
            `coords_y` FLOAT DEFAULT NULL,
            `coords_z` FLOAT DEFAULT NULL,
            `status` VARCHAR(20) NOT NULL DEFAULT 'pending',
            `responding_units` INT NOT NULL DEFAULT 0,
            `assigned_to` VARCHAR(50) DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `responded_at` TIMESTAMP NULL DEFAULT NULL,
            `completed_at` TIMESTAMP NULL DEFAULT NULL,
            UNIQUE KEY `uk_call_id` (`call_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ems_insurance` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `citizenid` VARCHAR(50) NOT NULL,
            `name` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
            `insurance_type` VARCHAR(20) NOT NULL DEFAULT 'basic',
            `discount_percent` INT NOT NULL DEFAULT 25,
            `purchased_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `expires_at` TIMESTAMP NOT NULL,
            `is_active` TINYINT(1) NOT NULL DEFAULT 1
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ems_logs` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `citizenid` VARCHAR(50) NOT NULL,
            `name` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
            `action` VARCHAR(100) NOT NULL,
            `details` TEXT DEFAULT NULL,
            `target_citizenid` VARCHAR(50) DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ems_staff` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `citizenid` VARCHAR(50) NOT NULL,
            `name` VARCHAR(100) NOT NULL,
            `rank` INT NOT NULL DEFAULT 0,
            `rank_label` VARCHAR(50) NOT NULL DEFAULT 'Trainee EMT',
            `callsign` VARCHAR(20) DEFAULT NULL,
            `specialization` VARCHAR(50) DEFAULT NULL,
            `hired_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `last_duty` TIMESTAMP NULL DEFAULT NULL,
            `total_hours` FLOAT NOT NULL DEFAULT 0,
            `total_treatments` INT NOT NULL DEFAULT 0,
            `total_revives` INT NOT NULL DEFAULT 0,
            `is_active` TINYINT(1) NOT NULL DEFAULT 1,
            UNIQUE KEY `uk_citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ems_billing` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `bill_id` VARCHAR(50) NOT NULL,
            `patient_citizenid` VARCHAR(50) NOT NULL,
            `patient_name` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
            `ems_citizenid` VARCHAR(50) NOT NULL,
            `ems_name` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
            `amount` INT NOT NULL DEFAULT 0,
            `original_amount` INT NOT NULL DEFAULT 0,
            `discount_applied` INT NOT NULL DEFAULT 0,
            `reason` VARCHAR(255) NOT NULL DEFAULT 'Medical Treatment',
            `status` VARCHAR(20) NOT NULL DEFAULT 'unpaid',
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `paid_at` TIMESTAMP NULL DEFAULT NULL,
            UNIQUE KEY `uk_bill_id` (`bill_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    print('[IMRP] Ambulance Job loaded successfully')
end)

-----------------------------------------------------------
-- Clock In / Out
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:server:clockIn', function()
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    if player.PlayerData.job.name ~= Config.JobName then return end

    onDutyEMS[src] = {
        citizenid = player.PlayerData.citizenid,
        name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        grade = player.PlayerData.job.grade.level,
        clockInTime = os.time(),
    }

    LogAction(player.PlayerData.citizenid, player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname, 'clock_in', 'Clocked in for duty')

    MySQL.update('UPDATE ems_staff SET last_duty = NOW() WHERE citizenid = ?', { player.PlayerData.citizenid })
end)

RegisterNetEvent('imrp_ambulancejob:server:clockOut', function()
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    if onDutyEMS[src] then
        local duration = os.time() - onDutyEMS[src].clockInTime
        local hours = duration / 3600

        MySQL.update('UPDATE ems_staff SET total_hours = total_hours + ? WHERE citizenid = ?', {
            hours, player.PlayerData.citizenid
        })

        LogAction(player.PlayerData.citizenid, player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname, 'clock_out', string.format('Clocked out after %.1f hours', hours))
    end

    onDutyEMS[src] = nil
end)

-----------------------------------------------------------
-- Player Dropped
-----------------------------------------------------------
AddEventHandler('playerDropped', function()
    local src = source
    if onDutyEMS[src] then
        onDutyEMS[src] = nil
    end
end)

-----------------------------------------------------------
-- Sync Injuries to DB
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:server:syncInjuries', function(data)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    MySQL.insert([[
        INSERT INTO ems_patients (citizenid, name, injuries, blood_level, pain_level)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            injuries = VALUES(injuries),
            blood_level = VALUES(blood_level),
            pain_level = VALUES(pain_level),
            updated_at = NOW()
    ]], {
        player.PlayerData.citizenid,
        player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        json.encode(data.injuries),
        data.bloodLevel,
        data.painLevel,
    })
end)

-----------------------------------------------------------
-- Log Action Helper
-----------------------------------------------------------
function LogAction(citizenid, name, action, details, targetCitizenid)
    MySQL.insert('INSERT INTO ems_logs (citizenid, name, action, details, target_citizenid) VALUES (?, ?, ?, ?, ?)', {
        citizenid, name, action, details, targetCitizenid
    })
end

-----------------------------------------------------------
-- Get On Duty EMS Count
-----------------------------------------------------------
function GetOnDutyCount()
    local count = 0
    for _ in pairs(onDutyEMS) do
        count = count + 1
    end
    return count
end

exports('GetOnDutyCount', GetOnDutyCount)
exports('GetOnDutyEMS', function() return onDutyEMS end)

-----------------------------------------------------------
-- NPC Doctor Heal
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:server:npcDoctorHeal', function(hospitalId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local cost = Config.NPCDoctor.cost
    local discount = GetInsuranceDiscount(player.PlayerData.citizenid)
    local finalCost = math.floor(cost * (1 - discount / 100))

    if player.Functions.RemoveMoney(Config.DefaultCurrency, finalCost, 'npc-doctor-treatment') then
        TriggerClientEvent('imrp_ambulancejob:client:healAll', src)

        MySQL.update('UPDATE ems_patients SET injuries = NULL, blood_level = 100, pain_level = 0, is_dead = 0, last_treated_at = NOW() WHERE citizenid = ?', {
            player.PlayerData.citizenid
        })

        if discount > 0 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'IMRP EMS',
                description = string.format('Treated by doctor. Cost: $%d (Insurance: %d%% off)', finalCost, discount),
                type = 'success',
            })
        end
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'IMRP EMS',
            description = 'Insufficient funds for treatment',
            type = 'error',
        })
    end
end)

-----------------------------------------------------------
-- Get Insurance Discount
-----------------------------------------------------------
function GetInsuranceDiscount(citizenid)
    local result = MySQL.single.await('SELECT discount_percent FROM ems_insurance WHERE citizenid = ? AND is_active = 1 AND expires_at > NOW()', { citizenid })
    if result then
        return result.discount_percent
    end
    return 0
end

-----------------------------------------------------------
-- Request EMS (citizen call)
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:server:requestEMS', function()
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local callerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname

    local callData = {
        call_id = GenerateId(),
        type = 'emergency',
        type_label = 'Emergency Call',
        caller_citizenid = player.PlayerData.citizenid,
        caller_name = callerName,
        description = 'Citizen requested EMS assistance',
        location = 'GPS Coordinates',
        coords = { x = coords.x, y = coords.y, z = coords.z },
        responding_units = 0,
    }

    SaveCall(callData)
    BroadcastToEMS('imrp_ambulancejob:client:dispatchAlert', callData)

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'IMRP EMS',
        description = 'EMS has been notified. Please wait.',
        type = 'success',
    })
end)

-----------------------------------------------------------
-- Broadcast to all on-duty EMS
-----------------------------------------------------------
function BroadcastToEMS(event, ...)
    for src, _ in pairs(onDutyEMS) do
        TriggerClientEvent(event, src, ...)
    end
end

-----------------------------------------------------------
-- Generate Unique ID
-----------------------------------------------------------
function GenerateId()
    return string.format('%d-%04d', os.time(), math.random(1000, 9999))
end

-----------------------------------------------------------
-- Save Call to DB
-----------------------------------------------------------
function SaveCall(callData)
    MySQL.insert('INSERT INTO ems_calls (call_id, caller_citizenid, caller_name, call_type, description, location, coords_x, coords_y, coords_z, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        callData.call_id,
        callData.caller_citizenid,
        callData.caller_name,
        callData.type,
        callData.description,
        callData.location,
        callData.coords.x,
        callData.coords.y,
        callData.coords.z,
        'pending',
    })
end

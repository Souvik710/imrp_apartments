-----------------------------------------------------------
-- IMRP Ambulance Job - Server Injury Handlers
-----------------------------------------------------------

local playerInjuryData = {}

-----------------------------------------------------------
-- Store injury data from client sync
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:server:syncInjuries', function(data)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    playerInjuryData[src] = data
end)

-----------------------------------------------------------
-- Get Patient Injuries Callback
-----------------------------------------------------------
lib.callback.register('imrp_ambulancejob:server:getPatientInjuries', function(source, targetSrc)
    local src = source
    local emsPLayer = exports.qbx_core:GetPlayer(src)
    if not emsPLayer or emsPLayer.PlayerData.job.name ~= Config.JobName then return nil end

    local data = playerInjuryData[targetSrc]
    if not data then
        return {
            injuries = {},
            bleedLevel = 0,
            painLevel = 0,
            bloodLevel = 100,
            brokenBones = {},
            bullets = {},
            patientName = 'Unknown',
        }
    end

    local patient = exports.qbx_core:GetPlayer(targetSrc)
    local patientName = 'Unknown'
    if patient then
        patientName = patient.PlayerData.charinfo.firstname .. ' ' .. patient.PlayerData.charinfo.lastname
    end

    data.patientName = patientName
    data.patientId = targetSrc

    return data
end)

-----------------------------------------------------------
-- Check Vitals Callback
-----------------------------------------------------------
lib.callback.register('imrp_ambulancejob:server:checkVitals', function(source, targetSrc, vitalType)
    local src = source
    local emsPlayer = exports.qbx_core:GetPlayer(src)
    if not emsPlayer or emsPlayer.PlayerData.job.name ~= Config.JobName then return nil end

    local injuryData = playerInjuryData[targetSrc]
    local bloodLevel = injuryData and injuryData.bloodLevel or 100
    local painLevel = injuryData and injuryData.painLevel or 0

    if vitalType == 'pulse' then
        local basePulse = 72
        local painModifier = painLevel * 0.3
        local bloodModifier = (100 - bloodLevel) * 0.5
        local pulse = math.floor(basePulse + painModifier + bloodModifier + math.random(-5, 5))

        if bloodLevel <= 0 then pulse = 0 end

        return { pulse = pulse }

    elseif vitalType == 'bp' then
        local baseSystolic = 120
        local baseDiastolic = 80
        local bloodModifier = (100 - bloodLevel) * 0.3

        local systolic = math.floor(baseSystolic - bloodModifier + math.random(-5, 5))
        local diastolic = math.floor(baseDiastolic - (bloodModifier * 0.5) + math.random(-3, 3))

        return { systolic = systolic, diastolic = diastolic }

    elseif vitalType == 'oxygen' then
        local baseOxygen = 98
        local bloodModifier = (100 - bloodLevel) * 0.2
        local oxygen = math.floor(baseOxygen - bloodModifier + math.random(-2, 2))
        oxygen = math.max(oxygen, 0)

        return { oxygen = oxygen }
    end

    return nil
end)

-----------------------------------------------------------
-- Player downed events
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:server:playerDowned', function(reason)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    MySQL.update('UPDATE ems_patients SET is_dead = 1 WHERE citizenid = ?', { player.PlayerData.citizenid })

    local coords = GetEntityCoords(GetPlayerPed(src))
    local callerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname

    local callType = reason == 'bullet' and 'gunshot'
        or reason == 'vehicle_crash' and 'vehicle_accident'
        or reason == 'bleedout' and 'unconscious'
        or 'emergency'

    local callData = {
        call_id = GenerateId(),
        type = callType,
        type_label = GetCallTypeLabel(callType),
        caller_citizenid = player.PlayerData.citizenid,
        caller_name = callerName,
        description = callerName .. ' is down - ' .. (reason or 'unknown cause'),
        location = 'Auto-detected',
        coords = { x = coords.x, y = coords.y, z = coords.z },
        responding_units = 0,
    }

    SaveCall(callData)
    BroadcastToEMS('imrp_ambulancejob:client:dispatchAlert', callData)
end)

RegisterNetEvent('imrp_ambulancejob:server:playerUnconcious', function()
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    -- Already saved as dead in playerDowned
end)

RegisterNetEvent('imrp_ambulancejob:server:playerDead', function()
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    -- Already tracked
end)

-----------------------------------------------------------
-- Distress Signal
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:server:distressSignal', function(coords)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local callerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname

    local callData = {
        call_id = GenerateId(),
        type = 'emergency',
        type_label = 'Distress Signal',
        caller_citizenid = player.PlayerData.citizenid,
        caller_name = callerName,
        description = 'DISTRESS SIGNAL from ' .. callerName,
        location = 'GPS Signal',
        coords = { x = coords.x, y = coords.y, z = coords.z },
        responding_units = 0,
    }

    BroadcastToEMS('imrp_ambulancejob:client:dispatchAlert', callData)
end)

-----------------------------------------------------------
-- Respawn
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:server:respawn', function(type)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    if type == 'hospital' then
        player.Functions.RemoveMoney(Config.DefaultCurrency, Config.DeathSystem.deathPenalty, 'hospital-respawn')
    end

    MySQL.update('UPDATE ems_patients SET is_dead = 0, injuries = NULL, blood_level = 100, pain_level = 0 WHERE citizenid = ?', {
        player.PlayerData.citizenid
    })

    playerInjuryData[src] = nil

    LogAction(player.PlayerData.citizenid, player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname, 'respawn', 'Respawned at ' .. type)
end)

-----------------------------------------------------------
-- Helper: Get Call Type Label
-----------------------------------------------------------
function GetCallTypeLabel(callType)
    local labels = {
        gunshot = 'Gunshot Victim',
        vehicle_accident = 'Vehicle Accident',
        unconscious = 'Unconscious Person',
        cardiac = 'Cardiac Arrest',
        emergency = 'Emergency Call',
        fall = 'Fall Victim',
        burn = 'Burn Victim',
        overdose = 'Overdose',
    }
    return labels[callType] or 'Emergency'
end

-----------------------------------------------------------
-- Player disconnect cleanup
-----------------------------------------------------------
AddEventHandler('playerDropped', function()
    local src = source
    playerInjuryData[src] = nil
end)

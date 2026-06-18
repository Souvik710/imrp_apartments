-----------------------------------------------------------
-- IMRP Ambulance Job - Server Treatment Handlers
-----------------------------------------------------------

-----------------------------------------------------------
-- Treat Patient
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:server:treatPatient', function(targetSrc, treatmentType)
    local src = source
    local emsPlayer = exports.qbx_core:GetPlayer(src)
    if not emsPlayer then return end
    if emsPlayer.PlayerData.job.name ~= Config.JobName then return end
    if not emsPlayer.PlayerData.job.onduty then return end

    local patient = exports.qbx_core:GetPlayer(targetSrc)
    if not patient then return end

    local emsName = emsPlayer.PlayerData.charinfo.firstname .. ' ' .. emsPlayer.PlayerData.charinfo.lastname
    local patientName = patient.PlayerData.charinfo.firstname .. ' ' .. patient.PlayerData.charinfo.lastname

    if treatmentType == 'stop_bleeding' then
        TriggerClientEvent('imrp_ambulancejob:client:reduceBleed', targetSrc, 2)
        LogTreatment(emsPlayer, patient, 'Stopped bleeding')

    elseif treatmentType == 'bandage' then
        TriggerClientEvent('imrp_ambulancejob:client:reduceBleed', targetSrc, 1)
        LogTreatment(emsPlayer, patient, 'Applied bandage')

    elseif treatmentType == 'remove_bullet' then
        TriggerClientEvent('imrp_ambulancejob:client:removeBullet', targetSrc, 1)
        LogTreatment(emsPlayer, patient, 'Removed bullet')

    elseif treatmentType == 'cpr' then
        TriggerClientEvent('imrp_ambulancejob:client:restoreBlood', targetSrc, 10)
        LogTreatment(emsPlayer, patient, 'Performed CPR')

    elseif treatmentType == 'defibrillator' then
        TriggerClientEvent('imrp_ambulancejob:client:emsRevive', targetSrc)
        LogTreatment(emsPlayer, patient, 'Used defibrillator')
        IncrementRevives(emsPlayer.PlayerData.citizenid)

    elseif treatmentType == 'splint' then
        TriggerClientEvent('imrp_ambulancejob:client:fixBone', targetSrc, 'leg_left')
        TriggerClientEvent('imrp_ambulancejob:client:fixBone', targetSrc, 'leg_right')
        TriggerClientEvent('imrp_ambulancejob:client:fixBone', targetSrc, 'arm_left')
        TriggerClientEvent('imrp_ambulancejob:client:fixBone', targetSrc, 'arm_right')
        LogTreatment(emsPlayer, patient, 'Applied splint')

    elseif treatmentType == 'painkiller' then
        if RemoveItemFromEMS(src, 'painkillers', 1) then
            TriggerClientEvent('imrp_ambulancejob:client:reducePain', targetSrc, 20)
            LogTreatment(emsPlayer, patient, 'Administered painkillers')
        end

    elseif treatmentType == 'morphine' then
        if RemoveItemFromEMS(src, 'morphine', 1) then
            TriggerClientEvent('imrp_ambulancejob:client:reducePain', targetSrc, 50)
            LogTreatment(emsPlayer, patient, 'Administered morphine')
        end

    elseif treatmentType == 'antibiotics' then
        if RemoveItemFromEMS(src, 'antibiotics', 1) then
            LogTreatment(emsPlayer, patient, 'Administered antibiotics')
        end

    elseif treatmentType == 'adrenaline' then
        if RemoveItemFromEMS(src, 'adrenaline', 1) then
            TriggerClientEvent('imrp_ambulancejob:client:reducePain', targetSrc, 30)
            TriggerClientEvent('imrp_ambulancejob:client:restoreBlood', targetSrc, 10)
            LogTreatment(emsPlayer, patient, 'Administered adrenaline')
        end

    elseif treatmentType == 'blood_bag' then
        if RemoveItemFromEMS(src, 'blood_bag', 1) then
            TriggerClientEvent('imrp_ambulancejob:client:restoreBlood', targetSrc, 30)
            LogTreatment(emsPlayer, patient, 'Administered blood bag')
        end

    elseif treatmentType == 'saline' then
        if RemoveItemFromEMS(src, 'saline', 1) then
            TriggerClientEvent('imrp_ambulancejob:client:restoreBlood', targetSrc, 15)
            LogTreatment(emsPlayer, patient, 'Administered saline IV')
        end
    end

    IncrementTreatments(emsPlayer.PlayerData.citizenid)
end)

-----------------------------------------------------------
-- Revive Patient
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:server:revivePatient', function(targetSrc)
    local src = source
    local emsPlayer = exports.qbx_core:GetPlayer(src)
    if not emsPlayer then return end
    if emsPlayer.PlayerData.job.name ~= Config.JobName then return end
    if not emsPlayer.PlayerData.job.onduty then return end

    local grade = emsPlayer.PlayerData.job.grade.level
    if grade < 2 then return end

    local patient = exports.qbx_core:GetPlayer(targetSrc)
    if not patient then return end

    TriggerClientEvent('imrp_ambulancejob:client:emsRevive', targetSrc)
    TriggerClientEvent('imrp_ambulancejob:client:healAll', targetSrc)

    MySQL.update('UPDATE ems_patients SET is_dead = 0, injuries = NULL, blood_level = 100, pain_level = 0, last_treated_by = ?, last_treated_at = NOW() WHERE citizenid = ?', {
        emsPlayer.PlayerData.citizenid,
        patient.PlayerData.citizenid,
    })

    local emsName = emsPlayer.PlayerData.charinfo.firstname .. ' ' .. emsPlayer.PlayerData.charinfo.lastname
    local patientName = patient.PlayerData.charinfo.firstname .. ' ' .. patient.PlayerData.charinfo.lastname

    LogAction(emsPlayer.PlayerData.citizenid, emsName, 'revive', 'Revived ' .. patientName, patient.PlayerData.citizenid)
    IncrementRevives(emsPlayer.PlayerData.citizenid)
    IncrementTreatments(emsPlayer.PlayerData.citizenid)

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'IMRP EMS',
        description = 'Patient revived successfully',
        type = 'success',
    })
end)

-----------------------------------------------------------
-- Surgery Complete
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:server:surgeryComplete', function(targetSrc, surgeryType)
    local src = source
    local emsPlayer = exports.qbx_core:GetPlayer(src)
    if not emsPlayer then return end
    if emsPlayer.PlayerData.job.name ~= Config.JobName then return end

    local patient = exports.qbx_core:GetPlayer(targetSrc)
    if not patient then return end

    if surgeryType == 'bullet_removal' then
        TriggerClientEvent('imrp_ambulancejob:client:removeBullet', targetSrc, 1)
        TriggerClientEvent('imrp_ambulancejob:client:removeBullet', targetSrc, 2)
        TriggerClientEvent('imrp_ambulancejob:client:removeBullet', targetSrc, 3)
    elseif surgeryType == 'bone_repair' then
        TriggerClientEvent('imrp_ambulancejob:client:fixBone', targetSrc, 'head')
        TriggerClientEvent('imrp_ambulancejob:client:fixBone', targetSrc, 'chest')
        TriggerClientEvent('imrp_ambulancejob:client:fixBone', targetSrc, 'arm_left')
        TriggerClientEvent('imrp_ambulancejob:client:fixBone', targetSrc, 'arm_right')
        TriggerClientEvent('imrp_ambulancejob:client:fixBone', targetSrc, 'leg_left')
        TriggerClientEvent('imrp_ambulancejob:client:fixBone', targetSrc, 'leg_right')
    elseif surgeryType == 'internal_bleeding' then
        TriggerClientEvent('imrp_ambulancejob:client:reduceBleed', targetSrc, 5)
        TriggerClientEvent('imrp_ambulancejob:client:restoreBlood', targetSrc, 40)
    elseif surgeryType == 'full_reconstruction' then
        TriggerClientEvent('imrp_ambulancejob:client:healAll', targetSrc)
    end

    local emsName = emsPlayer.PlayerData.charinfo.firstname .. ' ' .. emsPlayer.PlayerData.charinfo.lastname
    LogTreatment(emsPlayer, patient, 'Surgery: ' .. surgeryType)
end)

-----------------------------------------------------------
-- Helper: Remove Item from EMS Inventory
-----------------------------------------------------------
function RemoveItemFromEMS(src, item, amount)
    local hasItem = exports.ox_inventory:Search(src, 'count', item)
    if hasItem and hasItem >= amount then
        exports.ox_inventory:RemoveItem(src, item, amount)
        return true
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'IMRP EMS',
            description = 'Missing required item: ' .. item,
            type = 'error',
        })
        return false
    end
end

-----------------------------------------------------------
-- Helper: Log Treatment
-----------------------------------------------------------
function LogTreatment(emsPlayer, patient, treatment)
    local emsName = emsPlayer.PlayerData.charinfo.firstname .. ' ' .. emsPlayer.PlayerData.charinfo.lastname
    local patientName = patient.PlayerData.charinfo.firstname .. ' ' .. patient.PlayerData.charinfo.lastname

    LogAction(emsPlayer.PlayerData.citizenid, emsName, 'treatment', treatment .. ' on ' .. patientName, patient.PlayerData.citizenid)

    MySQL.update('UPDATE ems_patients SET last_treated_by = ?, last_treated_at = NOW() WHERE citizenid = ?', {
        emsPlayer.PlayerData.citizenid,
        patient.PlayerData.citizenid,
    })
end

-----------------------------------------------------------
-- Helper: Increment treatment count
-----------------------------------------------------------
function IncrementTreatments(citizenid)
    MySQL.update('UPDATE ems_staff SET total_treatments = total_treatments + 1 WHERE citizenid = ?', { citizenid })
end

-----------------------------------------------------------
-- Helper: Increment revive count
-----------------------------------------------------------
function IncrementRevives(citizenid)
    MySQL.update('UPDATE ems_staff SET total_revives = total_revives + 1 WHERE citizenid = ?', { citizenid })
end

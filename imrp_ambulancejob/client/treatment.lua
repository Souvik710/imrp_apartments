-----------------------------------------------------------
-- IMRP Ambulance Job - Client Treatment System
-- EMS inspection, treatment actions, minigames
-----------------------------------------------------------

local currentPatient = nil

-----------------------------------------------------------
-- Patient Inspection (ox_target on downed players)
-----------------------------------------------------------
CreateThread(function()
    Wait(2000)
    exports.ox_target:addGlobalPlayer({
        {
            name = 'ems_inspect_patient',
            label = 'Inspect Patient',
            icon = 'fa-solid fa-stethoscope',
            onSelect = function(data)
                if not data.entity then return end
                local targetSrc = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
                InspectPatient(targetSrc)
            end,
            canInteract = function(entity)
                if not EMSUtils.IsOnDuty() then return false end
                local targetPed = entity
                return IsEntityDead(targetPed) or IsPedRagdoll(targetPed)
                    or GetEntityHealth(targetPed) < 150
            end,
        },
        {
            name = 'ems_treat_patient',
            label = 'Treat Patient',
            icon = 'fa-solid fa-kit-medical',
            onSelect = function(data)
                if not data.entity then return end
                local targetSrc = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
                OpenTreatmentMenu(targetSrc)
            end,
            canInteract = function()
                return EMSUtils.IsOnDuty()
            end,
        },
        {
            name = 'ems_revive_patient',
            label = 'Revive Patient',
            icon = 'fa-solid fa-heart-pulse',
            onSelect = function(data)
                if not data.entity then return end
                local targetSrc = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
                RevivePatient(targetSrc)
            end,
            canInteract = function(entity)
                if not EMSUtils.IsOnDuty() then return false end
                return IsEntityDead(entity) or IsPedRagdoll(entity)
            end,
        },
    })
end)

-----------------------------------------------------------
-- Inspect Patient
-----------------------------------------------------------
function InspectPatient(targetSrc)
    currentPatient = targetSrc

    lib.progressBar({
        duration = Config.Treatment.diagnoseTime,
        label = 'Diagnosing patient...',
        useWhileDead = false,
        canCancel = true,
        anim = {
            dict = 'anim@gangops@morgue@table@',
            clip = 'body_search',
        },
    })

    lib.callback('imrp_ambulancejob:server:getPatientInjuries', false, function(data)
        if not data then
            EMSUtils.Notify('Unable to inspect patient', 'error')
            return
        end

        SendNUIMessage({
            action = 'showPatientInspection',
            data = data,
        })
    end, targetSrc)
end

-----------------------------------------------------------
-- Treatment Menu
-----------------------------------------------------------
function OpenTreatmentMenu(targetSrc)
    currentPatient = targetSrc
    local grade = EMSUtils.GetRank()

    local options = {
        {
            title = 'Check Pulse',
            description = 'Check the patient\'s pulse',
            icon = 'fa-solid fa-heart-pulse',
            onSelect = function() PerformCheckPulse(targetSrc) end,
        },
        {
            title = 'Check Blood Pressure',
            description = 'Measure blood pressure',
            icon = 'fa-solid fa-gauge-high',
            onSelect = function() PerformCheckBP(targetSrc) end,
        },
        {
            title = 'Check Oxygen',
            description = 'Check oxygen saturation',
            icon = 'fa-solid fa-lungs',
            onSelect = function() PerformCheckOxygen(targetSrc) end,
        },
        {
            title = 'Diagnose Injuries',
            description = 'Full injury diagnosis',
            icon = 'fa-solid fa-magnifying-glass',
            onSelect = function() InspectPatient(targetSrc) end,
        },
        {
            title = 'Stop Bleeding',
            description = 'Apply pressure to stop bleeding',
            icon = 'fa-solid fa-droplet',
            onSelect = function() PerformStopBleeding(targetSrc) end,
        },
        {
            title = 'Apply Bandage',
            description = 'Bandage wounds',
            icon = 'fa-solid fa-bandage',
            onSelect = function() PerformBandage(targetSrc) end,
        },
        {
            title = 'Remove Bullets',
            description = 'Extract bullets from wounds',
            icon = 'fa-solid fa-crosshairs',
            onSelect = function() PerformBulletExtraction(targetSrc) end,
            disabled = grade < 2,
        },
        {
            title = 'CPR',
            description = 'Perform cardiopulmonary resuscitation',
            icon = 'fa-solid fa-hand-holding-heart',
            onSelect = function() PerformCPR(targetSrc) end,
        },
        {
            title = 'Use Defibrillator',
            description = 'Emergency cardiac defibrillation',
            icon = 'fa-solid fa-bolt',
            onSelect = function() PerformDefibrillator(targetSrc) end,
            disabled = grade < 2,
        },
        {
            title = 'Splint Broken Bones',
            description = 'Apply splint to fractures',
            icon = 'fa-solid fa-bone',
            onSelect = function() PerformSplint(targetSrc) end,
        },
        {
            title = 'Administer Medicine',
            description = 'Give medication to patient',
            icon = 'fa-solid fa-syringe',
            onSelect = function() OpenMedicineMenu(targetSrc) end,
            disabled = grade < 1,
        },
    }

    lib.registerContext({
        id = 'ems_treatment_menu',
        title = 'Treatment Options',
        options = options,
    })
    lib.showContext('ems_treatment_menu')
end

-----------------------------------------------------------
-- Check Pulse
-----------------------------------------------------------
function PerformCheckPulse(targetSrc)
    local success = lib.progressBar({
        duration = Config.Treatment.checkPulseTime,
        label = 'Checking pulse...',
        useWhileDead = false,
        canCancel = true,
        anim = {
            dict = 'anim@gangops@morgue@table@',
            clip = 'body_search',
        },
    })

    if success then
        lib.callback('imrp_ambulancejob:server:checkVitals', false, function(vitals)
            if vitals then
                EMSUtils.Notify(string.format('Pulse: %d BPM', vitals.pulse), 'info', 8000)
            end
        end, targetSrc, 'pulse')
    end
end

-----------------------------------------------------------
-- Check Blood Pressure
-----------------------------------------------------------
function PerformCheckBP(targetSrc)
    local success = lib.progressBar({
        duration = Config.Treatment.checkBPTime,
        label = 'Checking blood pressure...',
        useWhileDead = false,
        canCancel = true,
        anim = {
            dict = 'anim@gangops@morgue@table@',
            clip = 'body_search',
        },
    })

    if success then
        lib.callback('imrp_ambulancejob:server:checkVitals', false, function(vitals)
            if vitals then
                EMSUtils.Notify(string.format('Blood Pressure: %d/%d mmHg', vitals.systolic, vitals.diastolic), 'info', 8000)
            end
        end, targetSrc, 'bp')
    end
end

-----------------------------------------------------------
-- Check Oxygen
-----------------------------------------------------------
function PerformCheckOxygen(targetSrc)
    local success = lib.progressBar({
        duration = Config.Treatment.checkOxygenTime,
        label = 'Checking oxygen levels...',
        useWhileDead = false,
        canCancel = true,
        anim = {
            dict = 'anim@gangops@morgue@table@',
            clip = 'body_search',
        },
    })

    if success then
        lib.callback('imrp_ambulancejob:server:checkVitals', false, function(vitals)
            if vitals then
                EMSUtils.Notify(string.format('Oxygen Saturation: %d%%', vitals.oxygen), 'info', 8000)
            end
        end, targetSrc, 'oxygen')
    end
end

-----------------------------------------------------------
-- Stop Bleeding
-----------------------------------------------------------
function PerformStopBleeding(targetSrc)
    local success = lib.progressBar({
        duration = Config.Treatment.stopBleedingTime,
        label = 'Applying pressure to wounds...',
        useWhileDead = false,
        canCancel = true,
        anim = {
            dict = 'mini@repair',
            clip = 'fixing_a_player',
        },
    })

    if success then
        TriggerServerEvent('imrp_ambulancejob:server:treatPatient', targetSrc, 'stop_bleeding')
    end
end

-----------------------------------------------------------
-- Apply Bandage
-----------------------------------------------------------
function PerformBandage(targetSrc)
    local success = lib.progressBar({
        duration = Config.Treatment.applyBandageTime,
        label = 'Applying bandage...',
        useWhileDead = false,
        canCancel = true,
        anim = {
            dict = 'mini@repair',
            clip = 'fixing_a_player',
        },
    })

    if success then
        TriggerServerEvent('imrp_ambulancejob:server:treatPatient', targetSrc, 'bandage')
    end
end

-----------------------------------------------------------
-- Bullet Extraction (with minigame)
-----------------------------------------------------------
function PerformBulletExtraction(targetSrc)
    EMSUtils.Notify('Starting bullet extraction...', 'info')

    local success = PlayMinigame('bulletExtraction')
    if not success then
        EMSUtils.Notify('Bullet extraction failed!', 'error')
        return
    end

    local progressSuccess = lib.progressBar({
        duration = Config.Treatment.removeBulletTime,
        label = 'Extracting bullet...',
        useWhileDead = false,
        canCancel = true,
        anim = {
            dict = 'mini@repair',
            clip = 'fixing_a_player',
        },
    })

    if progressSuccess then
        TriggerServerEvent('imrp_ambulancejob:server:treatPatient', targetSrc, 'remove_bullet')
    end
end

-----------------------------------------------------------
-- CPR (with minigame)
-----------------------------------------------------------
function PerformCPR(targetSrc)
    EMSUtils.Notify('Starting CPR...', 'info')

    local success = PlayMinigame('cpr')
    if not success then
        EMSUtils.Notify('CPR attempt failed!', 'error')
        return
    end

    local progressSuccess = lib.progressBar({
        duration = Config.Treatment.cprTime,
        label = 'Performing CPR...',
        useWhileDead = false,
        canCancel = true,
        anim = {
            dict = 'mini@cpr@char_a@cpr_str',
            clip = 'cpr_pumpchest',
        },
    })

    if progressSuccess then
        TriggerServerEvent('imrp_ambulancejob:server:treatPatient', targetSrc, 'cpr')
    end
end

-----------------------------------------------------------
-- Defibrillator (with minigame)
-----------------------------------------------------------
function PerformDefibrillator(targetSrc)
    local hasDefib = exports.ox_inventory:Search('count', 'defibrillator')
    if not hasDefib or hasDefib < 1 then
        EMSUtils.Notify('You need a defibrillator!', 'error')
        return
    end

    EMSUtils.Notify('Preparing defibrillator...', 'info')

    local success = PlayMinigame('defibrillator')
    if not success then
        EMSUtils.Notify('Defibrillation failed! Try again.', 'error')
        return
    end

    local progressSuccess = lib.progressBar({
        duration = Config.Treatment.defibrillatorTime,
        label = 'Using defibrillator...',
        useWhileDead = false,
        canCancel = false,
        anim = {
            dict = 'mini@cpr@char_a@cpr_str',
            clip = 'cpr_pumpchest',
        },
    })

    if progressSuccess then
        TriggerServerEvent('imrp_ambulancejob:server:treatPatient', targetSrc, 'defibrillator')
    end
end

-----------------------------------------------------------
-- Splint
-----------------------------------------------------------
function PerformSplint(targetSrc)
    local success = lib.progressBar({
        duration = Config.Treatment.splintTime,
        label = 'Applying splint...',
        useWhileDead = false,
        canCancel = true,
        anim = {
            dict = 'mini@repair',
            clip = 'fixing_a_player',
        },
    })

    if success then
        TriggerServerEvent('imrp_ambulancejob:server:treatPatient', targetSrc, 'splint')
    end
end

-----------------------------------------------------------
-- Medicine Menu
-----------------------------------------------------------
function OpenMedicineMenu(targetSrc)
    local medicines = {
        { item = 'painkillers', label = 'Painkillers', action = 'painkiller' },
        { item = 'morphine', label = 'Morphine', action = 'morphine' },
        { item = 'antibiotics', label = 'Antibiotics', action = 'antibiotics' },
        { item = 'adrenaline', label = 'Adrenaline Shot', action = 'adrenaline' },
        { item = 'blood_bag', label = 'Blood Bag', action = 'blood_bag' },
        { item = 'saline', label = 'Saline IV', action = 'saline' },
    }

    local options = {}
    for _, med in ipairs(medicines) do
        local count = exports.ox_inventory:Search('count', med.item) or 0
        table.insert(options, {
            title = med.label,
            description = string.format('In inventory: %d', count),
            icon = 'fa-solid fa-syringe',
            disabled = count < 1,
            onSelect = function()
                PerformAdministerMedicine(targetSrc, med)
            end,
        })
    end

    lib.registerContext({
        id = 'ems_medicine_menu',
        title = 'Administer Medicine',
        menu = 'ems_treatment_menu',
        options = options,
    })
    lib.showContext('ems_medicine_menu')
end

-----------------------------------------------------------
-- Administer Medicine
-----------------------------------------------------------
function PerformAdministerMedicine(targetSrc, medicine)
    local success = lib.progressBar({
        duration = Config.Treatment.administerMedicineTime,
        label = 'Administering ' .. medicine.label .. '...',
        useWhileDead = false,
        canCancel = true,
        anim = {
            dict = 'mini@repair',
            clip = 'fixing_a_player',
        },
    })

    if success then
        TriggerServerEvent('imrp_ambulancejob:server:treatPatient', targetSrc, medicine.action)
    end
end

-----------------------------------------------------------
-- Revive Patient
-----------------------------------------------------------
function RevivePatient(targetSrc)
    local grade = EMSUtils.GetRank()
    if grade < 2 then
        EMSUtils.Notify('You need Advanced EMT rank or higher to revive', 'error')
        return
    end

    EMSUtils.Notify('Attempting to revive patient...', 'info')

    -- Stabilization minigame
    local success = PlayMinigame('stabilization')
    if not success then
        EMSUtils.Notify('Stabilization failed! Try again.', 'error')
        return
    end

    local progressSuccess = lib.progressBar({
        duration = 15000,
        label = 'Reviving patient...',
        useWhileDead = false,
        canCancel = false,
        anim = {
            dict = 'mini@cpr@char_a@cpr_str',
            clip = 'cpr_pumpchest',
        },
    })

    if progressSuccess then
        TriggerServerEvent('imrp_ambulancejob:server:revivePatient', targetSrc)
    end
end

-----------------------------------------------------------
-- Minigame System
-----------------------------------------------------------
function PlayMinigame(type)
    local config = Config.Minigames[type]
    if not config then return true end

    local success = lib.skillCheck(
        GenerateSkillCheckPattern(config.keys),
        { 'w', 'a', 's', 'd' }
    )

    return success
end

function GenerateSkillCheckPattern(keys)
    local pattern = {}
    local difficulties = { 'easy', 'easy', 'medium', 'medium', 'hard' }

    for i = 1, keys do
        local diffIndex = math.min(i, #difficulties)
        table.insert(pattern, difficulties[diffIndex])
    end

    return pattern
end

-----------------------------------------------------------
-- Surgery Minigame (for NUI-based surgery)
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:client:startSurgery', function(targetSrc, surgeryType)
    if not EMSUtils.IsOnDuty() then return end

    local success = PlayMinigame('surgery')
    if success then
        lib.progressBar({
            duration = 15000,
            label = 'Performing surgery...',
            useWhileDead = false,
            canCancel = false,
            anim = {
                dict = 'anim@gangops@morgue@table@',
                clip = 'body_search',
            },
        })
        TriggerServerEvent('imrp_ambulancejob:server:surgeryComplete', targetSrc, surgeryType)
        EMSUtils.Notify('Surgery completed successfully!', 'success')
    else
        EMSUtils.Notify('Surgery failed!', 'error')
    end
end)

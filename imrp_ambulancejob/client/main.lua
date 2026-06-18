-----------------------------------------------------------
-- IMRP Ambulance Job - Client Main
-- Framework: QBX Core | Author: Ragna
-----------------------------------------------------------

local isOnDuty = false
local playerJob = nil
local playerGrade = 0
local dutyBlips = {}

-----------------------------------------------------------
-- Initialize
-----------------------------------------------------------
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    local playerData = exports.qbx_core:GetPlayerData()
    if playerData then
        playerJob = playerData.job
        if playerJob and playerJob.name == Config.JobName then
            playerGrade = playerJob.grade.level or 0
            isOnDuty = playerJob.onduty or false
            SetupEMSJob()
        end
    end
end)

AddEventHandler('QBCore:Client:OnJobUpdate', function(job)
    local wasEMS = playerJob and playerJob.name == Config.JobName
    playerJob = job

    if job.name == Config.JobName then
        playerGrade = job.grade.level or 0
        isOnDuty = job.onduty or false
        SetupEMSJob()
    elseif wasEMS then
        CleanupEMSJob()
    end
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(onDuty)
    isOnDuty = onDuty
    if onDuty then
        EMSUtils.Notify('You are now on duty', 'success')
        TriggerServerEvent('imrp_ambulancejob:server:clockIn')
    else
        EMSUtils.Notify('You are now off duty', 'error')
        TriggerServerEvent('imrp_ambulancejob:server:clockOut')
    end
end)

-----------------------------------------------------------
-- Setup EMS Job (targets, blips, etc)
-----------------------------------------------------------
function SetupEMSJob()
    SetupDutyPoints()
    SetupHospitalBlips()
    SetupHospitalTargets()
    SetupCloakroom()
    SetupBossMenuNPC()
    SetupArmory()
end

function CleanupEMSJob()
    isOnDuty = false
    playerGrade = 0
    RemoveEMSBlips()
end

-----------------------------------------------------------
-- Duty Points
-----------------------------------------------------------
function SetupDutyPoints()
    for i, duty in ipairs(Config.DutyLocations) do
        -- Spawn NPC at duty point
        if duty.npc then
            SpawnNPC(duty.npc)
        end

        exports.ox_target:addSphereZone({
            coords = duty.coords,
            radius = 1.5,
            options = {
                {
                    name = 'ems_duty_' .. i,
                    label = duty.label,
                    icon = 'fa-solid fa-clipboard-check',
                    onSelect = function()
                        ToggleDuty()
                    end,
                    canInteract = function()
                        return EMSUtils.IsEMS()
                    end,
                },
            },
        })
    end
end

function ToggleDuty()
    isOnDuty = not isOnDuty
    TriggerServerEvent('QBCore:ToggleDuty')
end

-----------------------------------------------------------
-- Hospital Blips
-----------------------------------------------------------
function SetupHospitalBlips()
    RemoveEMSBlips()

    for _, hospital in pairs(Hospitals.Locations) do
        if hospital.blip then
            local blip = AddBlipForCoord(hospital.blip.coords)
            SetBlipSprite(blip, hospital.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, hospital.blip.scale)
            SetBlipColour(blip, hospital.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(hospital.label)
            EndTextCommandSetBlipName(blip)
            table.insert(dutyBlips, blip)
        end
    end

    for _, garage in ipairs(EMSVehicles.Garages) do
        if garage.blip and EMSUtils.IsEMS() then
            local blip = AddBlipForCoord(garage.coords)
            SetBlipSprite(blip, garage.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, garage.blip.scale)
            SetBlipColour(blip, garage.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(garage.label)
            EndTextCommandSetBlipName(blip)
            table.insert(dutyBlips, blip)
        end
    end
end

function RemoveEMSBlips()
    for _, blip in ipairs(dutyBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    dutyBlips = {}
end

-----------------------------------------------------------
-- Hospital Targets
-----------------------------------------------------------
function SetupHospitalTargets()
    for hospitalId, hospital in pairs(Hospitals.Locations) do
        if hospital.reception and hospital.reception.npc then
            SpawnNPC(hospital.reception.npc)
            exports.ox_target:addSphereZone({
                coords = hospital.reception.coords,
                radius = 2.0,
                options = {
                    {
                        name = 'hospital_checkin_' .. hospitalId,
                        label = 'Check In',
                        icon = 'fa-solid fa-hospital-user',
                        onSelect = function()
                            TriggerEvent('imrp_ambulancejob:client:openCheckIn', hospitalId)
                        end,
                    },
                },
            })
        end

        if hospital.npc_doctor and Config.NPCDoctor.enabled then
            SpawnNPC({
                model = hospital.npc_doctor.model,
                coords = hospital.npc_doctor.coords,
                label = hospital.npc_doctor.label,
            })
            exports.ox_target:addSphereZone({
                coords = vec3(hospital.npc_doctor.coords.x, hospital.npc_doctor.coords.y, hospital.npc_doctor.coords.z),
                radius = 2.0,
                options = {
                    {
                        name = 'npc_doctor_' .. hospitalId,
                        label = 'Visit Doctor',
                        icon = 'fa-solid fa-user-doctor',
                        onSelect = function()
                            VisitNPCDoctor(hospitalId)
                        end,
                    },
                },
            })
        end

        if hospital.pharmacy and hospital.pharmacy.npc then
            SpawnNPC(hospital.pharmacy.npc)
            exports.ox_target:addSphereZone({
                coords = hospital.pharmacy.coords,
                radius = 2.0,
                options = {
                    {
                        name = 'pharmacy_' .. hospitalId,
                        label = 'Pharmacy',
                        icon = 'fa-solid fa-prescription-bottle-medical',
                        onSelect = function()
                            OpenPharmacy(hospitalId)
                        end,
                    },
                },
            })
        end
    end
end

-----------------------------------------------------------
-- NPC Spawn
-----------------------------------------------------------
local spawnedNPCs = {}

function SpawnNPC(data)
    local modelHash = joaat(data.model)
    lib.requestModel(modelHash)

    local x, y, z, h
    if type(data.coords) == 'vector4' then
        x, y, z, h = data.coords.x, data.coords.y, data.coords.z, data.coords.w
    else
        x, y, z = data.coords.x, data.coords.y, data.coords.z
        h = 0.0
    end

    local npc = CreatePed(4, modelHash, x, y, z - 1.0, h, false, true)
    SetEntityAsMissionEntity(npc, true, true)
    SetPedFleeAttributes(npc, 0, false)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetEntityInvincible(npc, true)
    FreezeEntityPosition(npc, true)

    table.insert(spawnedNPCs, npc)
end

-----------------------------------------------------------
-- NPC Doctor Visit
-----------------------------------------------------------
function VisitNPCDoctor(hospitalId)
    local cost = Config.NPCDoctor.cost

    local input = lib.alertDialog({
        header = 'NPC Doctor',
        content = string.format('Treatment cost: %s\n\nThe doctor will heal all your injuries.', EMSUtils.FormatMoney(cost)),
        centered = true,
        cancel = true,
    })

    if input == 'confirm' then
        lib.progressBar({
            duration = Config.NPCDoctor.waitTime,
            label = 'Being treated by doctor...',
            useWhileDead = false,
            canCancel = false,
            anim = {
                dict = 'anim@gangops@morgue@table@',
                clip = 'body_search',
            },
        })

        TriggerServerEvent('imrp_ambulancejob:server:npcDoctorHeal', hospitalId)
    end
end

-----------------------------------------------------------
-- Pharmacy
-----------------------------------------------------------
function OpenPharmacy(hospitalId)
    local options = {}
    for _, item in ipairs(Config.Pharmacy) do
        table.insert(options, {
            title = item.label,
            description = string.format('%s - %s', item.description, EMSUtils.FormatMoney(item.price)),
            icon = 'fa-solid fa-pills',
            onSelect = function()
                local input = lib.inputDialog('Purchase ' .. item.label, {
                    { type = 'number', label = 'Quantity', default = 1, min = 1, max = 10 },
                })
                if input then
                    TriggerServerEvent('imrp_ambulancejob:server:buyPharmacy', item.item, input[1], hospitalId)
                end
            end,
        })
    end

    lib.registerContext({
        id = 'ems_pharmacy',
        title = 'Hospital Pharmacy',
        options = options,
    })
    lib.showContext('ems_pharmacy')
end

-----------------------------------------------------------
-- Check In
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:client:openCheckIn', function(hospitalId)
    local options = {
        {
            title = 'Request Treatment',
            description = 'Request EMS treatment',
            icon = 'fa-solid fa-notes-medical',
            onSelect = function()
                TriggerServerEvent('imrp_ambulancejob:server:requestEMS')
            end,
        },
        {
            title = 'Buy Insurance',
            description = 'Purchase medical insurance',
            icon = 'fa-solid fa-shield-halved',
            onSelect = function()
                OpenInsuranceMenu(hospitalId)
            end,
        },
        {
            title = 'Check Insurance',
            description = 'View your insurance status',
            icon = 'fa-solid fa-file-medical',
            onSelect = function()
                TriggerServerEvent('imrp_ambulancejob:server:checkInsurance')
            end,
        },
        {
            title = 'Visit Pharmacy',
            description = 'Buy medicines and supplies',
            icon = 'fa-solid fa-prescription-bottle-medical',
            onSelect = function()
                OpenPharmacy(hospitalId)
            end,
        },
    }

    lib.registerContext({
        id = 'hospital_checkin',
        title = 'Hospital Reception',
        options = options,
    })
    lib.showContext('hospital_checkin')
end)

-----------------------------------------------------------
-- Insurance Menu
-----------------------------------------------------------
function OpenInsuranceMenu(hospitalId)
    if not Config.Insurance.enabled then
        EMSUtils.Notify('Insurance system is not available', 'error')
        return
    end

    local options = {
        {
            title = 'Basic Insurance',
            description = string.format('%s - %d%% discount for %d days', EMSUtils.FormatMoney(Config.Insurance.basicPrice), Config.Insurance.basicDiscount, Config.Insurance.duration),
            icon = 'fa-solid fa-shield',
            onSelect = function()
                TriggerServerEvent('imrp_ambulancejob:server:buyInsurance', 'basic', hospitalId)
            end,
        },
        {
            title = 'Premium Insurance',
            description = string.format('%s - %d%% discount for %d days', EMSUtils.FormatMoney(Config.Insurance.premiumPrice), Config.Insurance.premiumDiscount, Config.Insurance.duration),
            icon = 'fa-solid fa-shield-halved',
            onSelect = function()
                TriggerServerEvent('imrp_ambulancejob:server:buyInsurance', 'premium', hospitalId)
            end,
        },
        {
            title = 'VIP Insurance',
            description = string.format('%s - %d%% discount for %d days', EMSUtils.FormatMoney(Config.Insurance.vipPrice), Config.Insurance.vipDiscount, Config.Insurance.duration),
            icon = 'fa-solid fa-shield-heart',
            onSelect = function()
                TriggerServerEvent('imrp_ambulancejob:server:buyInsurance', 'vip', hospitalId)
            end,
        },
    }

    lib.registerContext({
        id = 'insurance_menu',
        title = 'Medical Insurance',
        options = options,
    })
    lib.showContext('insurance_menu')
end

-----------------------------------------------------------
-- Insurance Status Callback
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:client:showInsurance', function(data)
    if data then
        lib.alertDialog({
            header = 'Insurance Status',
            content = string.format(
                '**Type:** %s\n**Discount:** %d%%\n**Expires:** %s',
                data.insurance_type:upper(),
                data.discount_percent,
                data.expires_at
            ),
            centered = true,
        })
    else
        EMSUtils.Notify('You do not have active insurance', 'info')
    end
end)

-----------------------------------------------------------
-- Cloakroom / Job Clothing
-----------------------------------------------------------
function SetupCloakroom()
    if not Config.Cloakroom then return end

    -- Spawn NPC
    if Config.Cloakroom.npc then
        SpawnNPC(Config.Cloakroom.npc)
    end

    exports.ox_target:addSphereZone({
        coords = Config.Cloakroom.coords,
        radius = 1.5,
        options = {
            {
                name = 'ems_cloakroom',
                label = Config.Cloakroom.label,
                icon = 'fa-solid fa-shirt',
                onSelect = function()
                    OpenCloakroom()
                end,
                canInteract = function()
                    return EMSUtils.IsEMS()
                end,
            },
        },
    })
end

function OpenCloakroom()
    local playerData = exports.qbx_core:GetPlayerData()
    if not playerData then return end

    local gender = playerData.charinfo.gender == 0 and 'male' or 'female'
    local grade = EMSUtils.GetRank()
    local options = {}

    -- EMS outfits
    for id, outfit in pairs(Config.Cloakroom.outfits) do
        local genderMatch = outfit.gender == 'any' or outfit.gender == gender
        local rankMatch = not outfit.minRank or grade >= outfit.minRank

        if genderMatch then
            table.insert(options, {
                title = outfit.label,
                description = rankMatch
                    and 'Click to equip'
                    or 'Requires higher rank',
                icon = 'fa-solid fa-shirt',
                disabled = not rankMatch,
                onSelect = function()
                    ApplyOutfit(outfit)
                end,
            })
        end
    end

    -- Civilian clothes option
    table.insert(options, {
        title = 'Civilian Clothes',
        description = 'Change back to civilian outfit',
        icon = 'fa-solid fa-user',
        onSelect = function()
            RestoreCivilianClothes()
        end,
    })

    lib.registerContext({
        id = 'ems_cloakroom',
        title = Config.Cloakroom.label,
        options = options,
    })
    lib.showContext('ems_cloakroom')
end

local savedOutfit = nil

function ApplyOutfit(outfit)
    local ped = PlayerPedId()

    -- Save current outfit before changing
    if not savedOutfit then
        savedOutfit = {}
        for compId = 0, 11 do
            savedOutfit[compId] = {
                drawable = GetPedDrawableVariation(ped, compId),
                texture = GetPedTextureVariation(ped, compId),
            }
        end
    end

    -- Apply EMS outfit
    if outfit.components then
        for componentId, data in pairs(outfit.components) do
            SetPedComponentVariation(ped, componentId, data.drawable, data.texture, 0)
        end
    end

    EMSUtils.Notify('Changed into: ' .. outfit.label, 'success')
end

function RestoreCivilianClothes()
    if not savedOutfit then
        EMSUtils.Notify('No civilian outfit saved', 'error')
        return
    end

    local ped = PlayerPedId()
    for componentId, data in pairs(savedOutfit) do
        SetPedComponentVariation(ped, componentId, data.drawable, data.texture, 0)
    end

    savedOutfit = nil
    EMSUtils.Notify('Changed into civilian clothes', 'success')
end

-----------------------------------------------------------
-- Boss Menu NPC
-----------------------------------------------------------
function SetupBossMenuNPC()
    if Config.BossMenu.npc then
        SpawnNPC(Config.BossMenu.npc)
    end
end

-----------------------------------------------------------
-- Item Armory
-----------------------------------------------------------
function SetupArmory()
    if not Config.Armory then return end

    -- Spawn NPC
    if Config.Armory.npc then
        SpawnNPC(Config.Armory.npc)
    end

    exports.ox_target:addSphereZone({
        coords = Config.Armory.coords,
        radius = 1.5,
        options = {
            {
                name = 'ems_armory',
                label = Config.Armory.label,
                icon = 'fa-solid fa-kit-medical',
                onSelect = function()
                    OpenArmory()
                end,
                canInteract = function()
                    return EMSUtils.IsOnDuty()
                end,
            },
        },
    })
end

function OpenArmory()
    if not EMSUtils.IsOnDuty() then
        EMSUtils.Notify('You must be on duty', 'error')
        return
    end

    local grade = EMSUtils.GetRank()
    local options = {}

    for _, armoryItem in ipairs(Config.Armory.items) do
        local rankOk = not armoryItem.minRank or grade >= armoryItem.minRank
        table.insert(options, {
            title = armoryItem.label,
            description = rankOk
                and string.format('Take %dx', armoryItem.amount)
                or 'Requires higher rank',
            icon = 'fa-solid fa-pills',
            disabled = not rankOk,
            onSelect = function()
                TriggerServerEvent('imrp_ambulancejob:server:takeArmoryItem', armoryItem.item, armoryItem.amount)
            end,
        })
    end

    lib.registerContext({
        id = 'ems_armory',
        title = Config.Armory.label,
        options = options,
    })
    lib.showContext('ems_armory')
end

-----------------------------------------------------------
-- Exports for other resources
-----------------------------------------------------------
exports('IsEMSOnDuty', function()
    return isOnDuty
end)

exports('GetEMSGrade', function()
    return playerGrade
end)

exports('IsEMS', function()
    return EMSUtils.IsEMS()
end)

-----------------------------------------------------------
-- IMRP Ambulance Job - Client Hospital System
-- Bed management, ICU, Surgery Room
-----------------------------------------------------------

local occupiedBed = nil
local healingThread = false

-----------------------------------------------------------
-- Hospital Bed System
-----------------------------------------------------------
CreateThread(function()
    Wait(3000)
    for hospitalId, hospital in pairs(Hospitals.Locations) do
        if hospital.beds then
            for i, bed in ipairs(hospital.beds) do
                exports.ox_target:addSphereZone({
                    coords = bed.coords,
                    radius = 1.0,
                    options = {
                        {
                            name = 'hospital_bed_' .. hospitalId .. '_' .. i,
                            label = 'Use Hospital Bed',
                            icon = 'fa-solid fa-bed',
                            onSelect = function()
                                UseBed(hospitalId, i)
                            end,
                            canInteract = function()
                                return not bed.occupied and not occupiedBed
                            end,
                        },
                        {
                            name = 'hospital_bed_leave_' .. hospitalId .. '_' .. i,
                            label = 'Leave Bed',
                            icon = 'fa-solid fa-right-from-bracket',
                            onSelect = function()
                                LeaveBed(hospitalId, i)
                            end,
                            canInteract = function()
                                return occupiedBed and occupiedBed.hospital == hospitalId and occupiedBed.index == i
                            end,
                        },
                    },
                })
            end
        end

        -- ICU Beds
        if hospital.icu then
            for i, icu in ipairs(hospital.icu) do
                exports.ox_target:addSphereZone({
                    coords = icu.coords,
                    radius = 1.0,
                    options = {
                        {
                            name = 'hospital_icu_' .. hospitalId .. '_' .. i,
                            label = 'ICU Bed (EMS Only)',
                            icon = 'fa-solid fa-bed-pulse',
                            onSelect = function()
                                UseICUBed(hospitalId, i)
                            end,
                            canInteract = function()
                                return EMSUtils.IsOnDuty() and not icu.occupied
                            end,
                        },
                    },
                })
            end
        end

        -- Surgery Room
        if hospital.surgery_room then
            exports.ox_target:addSphereZone({
                coords = hospital.surgery_room.coords,
                radius = 2.0,
                options = {
                    {
                        name = 'surgery_room_' .. hospitalId,
                        label = hospital.surgery_room.label,
                        icon = 'fa-solid fa-scissors',
                        onSelect = function()
                            OpenSurgeryMenu(hospitalId)
                        end,
                        canInteract = function()
                            return EMSUtils.IsOnDuty() and EMSUtils.GetRank() >= 3
                        end,
                    },
                },
            })
        end
    end
end)

-----------------------------------------------------------
-- Use Hospital Bed
-----------------------------------------------------------
function UseBed(hospitalId, bedIndex)
    local hospital = Hospitals.Locations[hospitalId]
    if not hospital or not hospital.beds[bedIndex] then return end

    local bed = hospital.beds[bedIndex]

    TriggerServerEvent('imrp_ambulancejob:server:occupyBed', hospitalId, bedIndex)

    local ped = PlayerPedId()
    SetEntityCoords(ped, bed.coords.x, bed.coords.y, bed.coords.z, false, false, false, true)
    SetEntityHeading(ped, bed.heading)

    lib.requestAnimDict('anim@gangops@morgue@table@')
    TaskPlayAnim(ped, 'anim@gangops@morgue@table@', 'body_search', 8.0, 8.0, -1, 1, 0, false, false, false)

    occupiedBed = { hospital = hospitalId, index = bedIndex }

    StartHealingThread()
    EMSUtils.Notify('Resting in hospital bed. You will heal over time.', 'success')
end

-----------------------------------------------------------
-- Leave Bed
-----------------------------------------------------------
function LeaveBed(hospitalId, bedIndex)
    if not occupiedBed then return end

    TriggerServerEvent('imrp_ambulancejob:server:leaveBed', hospitalId, bedIndex)

    local ped = PlayerPedId()
    ClearPedTasks(ped)

    occupiedBed = nil
    healingThread = false

    EMSUtils.Notify('You left the hospital bed', 'info')
end

-----------------------------------------------------------
-- ICU Bed (EMS places patient)
-----------------------------------------------------------
function UseICUBed(hospitalId, icuIndex)
    local closestPlayer, dist = EMSUtils.GetClosestPlayer(GetEntityCoords(PlayerPedId()), 3.0)
    if not closestPlayer then
        EMSUtils.Notify('No patient nearby', 'error')
        return
    end

    TriggerServerEvent('imrp_ambulancejob:server:placeInICU', closestPlayer, hospitalId, icuIndex)
    EMSUtils.Notify('Patient placed in ICU', 'success')
end

-----------------------------------------------------------
-- Healing Thread
-----------------------------------------------------------
function StartHealingThread()
    if healingThread then return end
    healingThread = true

    CreateThread(function()
        while healingThread and occupiedBed do
            Wait(Config.BedSystem.healInterval)

            local ped = PlayerPedId()
            local currentHealth = GetEntityHealth(ped)
            local maxHealth = GetEntityMaxHealth(ped)

            if currentHealth < maxHealth then
                SetEntityHealth(ped, math.min(currentHealth + Config.BedSystem.healRate, maxHealth))
            end
        end
        healingThread = false
    end)
end

-----------------------------------------------------------
-- Surgery Menu
-----------------------------------------------------------
function OpenSurgeryMenu(hospitalId)
    local closestPlayer, dist = EMSUtils.GetClosestPlayer(GetEntityCoords(PlayerPedId()), 5.0)
    if not closestPlayer then
        EMSUtils.Notify('No patient nearby for surgery', 'error')
        return
    end

    local options = {
        {
            title = 'Bullet Removal Surgery',
            description = 'Surgically remove embedded bullets',
            icon = 'fa-solid fa-crosshairs',
            onSelect = function()
                TriggerEvent('imrp_ambulancejob:client:startSurgery', closestPlayer, 'bullet_removal')
            end,
        },
        {
            title = 'Bone Repair Surgery',
            description = 'Surgical repair of fractured bones',
            icon = 'fa-solid fa-bone',
            onSelect = function()
                TriggerEvent('imrp_ambulancejob:client:startSurgery', closestPlayer, 'bone_repair')
            end,
        },
        {
            title = 'Internal Bleeding Surgery',
            description = 'Repair internal hemorrhaging',
            icon = 'fa-solid fa-droplet',
            onSelect = function()
                TriggerEvent('imrp_ambulancejob:client:startSurgery', closestPlayer, 'internal_bleeding')
            end,
        },
        {
            title = 'Full Reconstruction',
            description = 'Complete trauma surgery',
            icon = 'fa-solid fa-heart-circle-plus',
            onSelect = function()
                TriggerEvent('imrp_ambulancejob:client:startSurgery', closestPlayer, 'full_reconstruction')
            end,
        },
    }

    lib.registerContext({
        id = 'surgery_menu',
        title = 'Surgery Room - Patient #' .. closestPlayer,
        options = options,
    })
    lib.showContext('surgery_menu')
end

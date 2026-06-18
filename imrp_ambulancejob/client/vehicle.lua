-----------------------------------------------------------
-- IMRP Ambulance Job - Client Vehicle System
-- EMS Garage, Livery, Impound
-----------------------------------------------------------

local spawnedVehicles = {}

-----------------------------------------------------------
-- Garage Targets
-----------------------------------------------------------
CreateThread(function()
    Wait(3000)
    for i, garage in ipairs(EMSVehicles.Garages) do
        exports.ox_target:addSphereZone({
            coords = garage.coords,
            radius = 3.0,
            options = {
                {
                    name = 'ems_garage_' .. i,
                    label = garage.label,
                    icon = 'fa-solid fa-warehouse',
                    onSelect = function()
                        OpenGarageMenu(i)
                    end,
                    canInteract = function()
                        return EMSUtils.IsOnDuty() and Ranks.HasPermission(EMSUtils.GetRank(), 'garage_access')
                    end,
                },
                {
                    name = 'ems_garage_store_' .. i,
                    label = 'Store Vehicle',
                    icon = 'fa-solid fa-square-parking',
                    onSelect = function()
                        StoreVehicle(i)
                    end,
                    canInteract = function()
                        return EMSUtils.IsOnDuty() and IsPedInAnyVehicle(PlayerPedId(), false)
                    end,
                },
            },
        })

        -- Blip
        if garage.blip then
            local blip = AddBlipForCoord(garage.coords)
            SetBlipSprite(blip, garage.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, garage.blip.scale)
            SetBlipColour(blip, garage.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(garage.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

-----------------------------------------------------------
-- Open Garage Menu
-----------------------------------------------------------
function OpenGarageMenu(garageIndex)
    local garage = EMSVehicles.Garages[garageIndex]
    if not garage then return end

    local grade = EMSUtils.GetRank()
    local options = {}

    for vehicleId, vehicle in pairs(EMSVehicles.List) do
        if vehicle.category == garage.type then
            local canAccess = grade >= vehicle.min_rank
            local helicopterCheck = vehicle.category == 'air' and Ranks.HasPermission(grade, 'helicopter')

            if vehicle.category ~= 'air' or helicopterCheck then
                table.insert(options, {
                    title = vehicle.label,
                    description = canAccess
                        and string.format('Rank required: %s', Ranks.GetLabel(vehicle.min_rank))
                        or '🔒 Locked - Insufficient rank',
                    icon = vehicle.category == 'air' and 'fa-solid fa-helicopter' or 'fa-solid fa-truck-medical',
                    disabled = not canAccess,
                    onSelect = function()
                        SpawnEMSVehicle(vehicleId, garageIndex)
                    end,
                })
            end
        end
    end

    lib.registerContext({
        id = 'ems_garage_menu',
        title = garage.label,
        options = options,
    })
    lib.showContext('ems_garage_menu')
end

-----------------------------------------------------------
-- Spawn Vehicle
-----------------------------------------------------------
function SpawnEMSVehicle(vehicleId, garageIndex)
    local vehicle = EMSVehicles.List[vehicleId]
    local garage = EMSVehicles.Garages[garageIndex]
    if not vehicle or not garage then return end

    local modelHash = joaat(vehicle.model)
    lib.requestModel(modelHash)

    local spawn = garage.spawn
    local veh = CreateVehicle(modelHash, spawn.x, spawn.y, spawn.z, spawn.w, true, false)

    SetVehicleOnGroundProperly(veh)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleEngineOn(veh, true, true, false)
    SetVehicleFuelLevel(veh, vehicle.fuel)
    SetVehicleDirtLevel(veh, 0.0)

    -- Apply livery
    if vehicle.livery then
        SetVehicleLivery(veh, vehicle.livery)
    end

    -- Apply extras
    if vehicle.extras then
        for _, extra in ipairs(vehicle.extras) do
            SetVehicleExtra(veh, extra, false)
        end
    end

    -- Set color (white/red for EMS)
    SetVehicleColours(veh, 111, 111)

    -- Enter vehicle
    local ped = PlayerPedId()
    TaskWarpPedIntoVehicle(ped, veh, -1)

    table.insert(spawnedVehicles, veh)

    EMSUtils.Notify('Vehicle spawned: ' .. vehicle.label, 'success')
    TriggerServerEvent('imrp_ambulancejob:server:logAction', 'vehicle_spawn', 'Spawned ' .. vehicle.label)
end

-----------------------------------------------------------
-- Store Vehicle
-----------------------------------------------------------
function StoreVehicle(garageIndex)
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        EMSUtils.Notify('You must be in a vehicle', 'error')
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)

    TaskLeaveVehicle(ped, vehicle, 0)
    Wait(1500)

    DeleteEntity(vehicle)

    for i, veh in ipairs(spawnedVehicles) do
        if veh == vehicle then
            table.remove(spawnedVehicles, i)
            break
        end
    end

    EMSUtils.Notify('Vehicle stored', 'success')
end

-----------------------------------------------------------
-- Livery Selection
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:client:openLiveryMenu', function()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        EMSUtils.Notify('You must be in a vehicle', 'error')
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    local options = {}

    for _, livery in ipairs(EMSVehicles.Liveries) do
        table.insert(options, {
            title = livery.label,
            icon = 'fa-solid fa-paint-roller',
            onSelect = function()
                SetVehicleLivery(vehicle, livery.index)
                EMSUtils.Notify('Livery applied: ' .. livery.label, 'success')
            end,
        })
    end

    lib.registerContext({
        id = 'ems_livery_menu',
        title = 'EMS Livery Selection',
        options = options,
    })
    lib.showContext('ems_livery_menu')
end)

-----------------------------------------------------------
-- Impound System
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:client:openImpound', function()
    if not Ranks.HasPermission(EMSUtils.GetRank(), 'impound') then
        EMSUtils.Notify('You do not have impound access', 'error')
        return
    end

    lib.callback('imrp_ambulancejob:server:getImpoundedVehicles', false, function(vehicles)
        if not vehicles or #vehicles == 0 then
            EMSUtils.Notify('No impounded vehicles', 'info')
            return
        end

        local options = {}
        for _, veh in ipairs(vehicles) do
            table.insert(options, {
                title = veh.label,
                description = string.format('Impound fee: %s', EMSUtils.FormatMoney(EMSVehicles.Impound.price)),
                icon = 'fa-solid fa-car',
                onSelect = function()
                    TriggerServerEvent('imrp_ambulancejob:server:retrieveImpound', veh.id)
                end,
            })
        end

        lib.registerContext({
            id = 'ems_impound_menu',
            title = 'EMS Impound',
            options = options,
        })
        lib.showContext('ems_impound_menu')
    end)
end)

-----------------------------------------------------------
-- Cleanup
-----------------------------------------------------------
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for _, veh in ipairs(spawnedVehicles) do
            if DoesEntityExist(veh) then
                DeleteEntity(veh)
            end
        end
        spawnedVehicles = {}
    end
end)

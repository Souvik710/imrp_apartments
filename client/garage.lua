-----------------------------------------------------------
-- IMRP Apartments - Client Garage
-- Author: Ragna | Immortal Roleplay
-----------------------------------------------------------

-----------------------------------------------------------
-- Open Garage Menu
-----------------------------------------------------------
function OpenGarageMenu()
    if not Config.UseGarage then return end

    local currentApt = exports['imrp_apartments']:GetCurrentApartment()
    if not currentApt then
        lib.notify({ title = 'Garage', description = IMRP.Locale('not_in_apartment'), type = 'error', position = Config.Notification.position })
        return
    end

    local options = {
        {
            title = IMRP.Locale('store_vehicle'),
            description = IMRP.Locale('store_vehicle_desc'),
            icon = 'warehouse',
            onSelect = function()
                StoreVehicle()
            end
        },
        {
            title = IMRP.Locale('retrieve_vehicle'),
            description = IMRP.Locale('retrieve_vehicle_desc'),
            icon = 'car',
            onSelect = function()
                RetrieveVehicle()
            end
        },
        {
            title = IMRP.Locale('vehicle_list'),
            description = IMRP.Locale('vehicle_list_desc'),
            icon = 'list',
            onSelect = function()
                ShowVehicleList()
            end
        }
    }

    lib.registerContext({
        id = 'apartment_garage_menu',
        title = IMRP.Locale('garage'),
        menu = 'apartment_inside_menu',
        options = options
    })
    lib.showContext('apartment_garage_menu')
end

-----------------------------------------------------------
-- Store Vehicle
-----------------------------------------------------------
function StoreVehicle()
    local currentApt = exports['imrp_apartments']:GetCurrentApartment()
    if not currentApt then return end

    local vehicle = GetVehiclePedIsIn(cache.ped, true)
    if vehicle == 0 then
        vehicle = GetClosestVehicle(GetEntityCoords(cache.ped), 5.0, 0, 71)
    end

    if vehicle == 0 then
        lib.notify({ title = 'Garage', description = IMRP.Locale('no_vehicle_nearby'), type = 'error', position = Config.Notification.position })
        return
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    local props = lib.getVehicleProperties(vehicle)

    lib.callback('imrp_apartments:server:storeVehicle', false, function(result)
        if result and result.success then
            if DoesEntityExist(vehicle) then
                DeleteEntity(vehicle)
            end
            lib.notify({ title = 'Garage', description = IMRP.Locale('vehicle_stored'), type = 'success', position = Config.Notification.position })
        else
            lib.notify({ title = 'Garage', description = result and result.message or IMRP.Locale('store_failed'), type = 'error', position = Config.Notification.position })
        end
    end, currentApt.key, plate, props)
end

-----------------------------------------------------------
-- Retrieve Vehicle
-----------------------------------------------------------
function RetrieveVehicle()
    local currentApt = exports['imrp_apartments']:GetCurrentApartment()
    if not currentApt then return end

    lib.callback('imrp_apartments:server:getStoredVehicles', false, function(vehicles)
        if not vehicles or #vehicles == 0 then
            lib.notify({ title = 'Garage', description = IMRP.Locale('no_stored_vehicles'), type = 'info', position = Config.Notification.position })
            return
        end

        local options = {}
        for _, veh in ipairs(vehicles) do
            options[#options + 1] = {
                title = ('%s [%s]'):format(veh.name or 'Vehicle', veh.plate),
                description = IMRP.Locale('click_to_retrieve'),
                icon = 'car',
                onSelect = function()
                    SpawnVehicleFromGarage(veh, currentApt.key)
                end
            }
        end

        lib.registerContext({
            id = 'apartment_retrieve_vehicle',
            title = IMRP.Locale('retrieve_vehicle'),
            menu = 'apartment_garage_menu',
            options = options
        })
        lib.showContext('apartment_retrieve_vehicle')
    end, currentApt.key)
end

-----------------------------------------------------------
-- Spawn Vehicle
-----------------------------------------------------------
function SpawnVehicleFromGarage(vehicleData, apartmentKey)
    local apt = Config.Apartments[apartmentKey]
    if not apt then return end

    local spawnCoords = apt.garage_spawn

    lib.callback('imrp_apartments:server:retrieveVehicle', false, function(result)
        if not result or not result.success then
            lib.notify({ title = 'Garage', description = result and result.message or IMRP.Locale('retrieve_failed'), type = 'error', position = Config.Notification.position })
            return
        end

        lib.requestModel(vehicleData.model or GetHashKey('adder'), 5000)
        local vehicle = CreateVehicle(vehicleData.model or GetHashKey('adder'), spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, false)

        if DoesEntityExist(vehicle) then
            if vehicleData.props then
                lib.setVehicleProperties(vehicle, vehicleData.props)
            end
            SetVehicleNumberPlateText(vehicle, vehicleData.plate)
            SetEntityAsMissionEntity(vehicle, true, true)
            SetVehicleHasBeenOwnedByPlayer(vehicle, true)
            SetVehicleEngineOn(vehicle, true, true, false)

            lib.notify({ title = 'Garage', description = IMRP.Locale('vehicle_retrieved'), type = 'success', position = Config.Notification.position })
        end
    end, apartmentKey, vehicleData.plate)
end

-----------------------------------------------------------
-- Vehicle List
-----------------------------------------------------------
function ShowVehicleList()
    local currentApt = exports['imrp_apartments']:GetCurrentApartment()
    if not currentApt then return end

    lib.callback('imrp_apartments:server:getStoredVehicles', false, function(vehicles)
        if not vehicles or #vehicles == 0 then
            lib.notify({ title = 'Garage', description = IMRP.Locale('no_stored_vehicles'), type = 'info', position = Config.Notification.position })
            return
        end

        local options = {}
        for _, veh in ipairs(vehicles) do
            options[#options + 1] = {
                title = ('%s [%s]'):format(veh.name or 'Vehicle', veh.plate),
                description = IMRP.Locale('stored_in_garage'),
                icon = 'car',
                readOnly = true
            }
        end

        lib.registerContext({
            id = 'apartment_vehicle_list',
            title = IMRP.Locale('vehicle_list'),
            menu = 'apartment_garage_menu',
            options = options
        })
        lib.showContext('apartment_vehicle_list')
    end, currentApt.key)
end

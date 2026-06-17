local QBCore = exports['qb-core']:GetCoreObject()  -- Changed from qbx_core to qb-core
local PlayerData = {}

-- Initialize player data
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    SetupApartmentEntrances()
    SetupApartmentNPC()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    RemoveApartmentTargets()
end)

-- Setup apartment entrances
function SetupApartmentEntrances()
    for apartment_id, apartment in pairs(Config.Apartments) do
        local entrance = apartment.location.entrance
        
        exports.ox_target:addSphereZone({
            coords = entrance,
            radius = 1.5,
            options = {
                {
                    name = 'apartment_enter_' .. apartment_id,
                    label = 'Enter Apartment',
                    icon = 'fa-solid fa-door-open',
                    onSelect = function()
                        EnterApartment(apartment_id)
                    end,
                    distance = 2.0
                }
            },
            debug = false,
            useZ = true
        })
    end
end

-- Setup apartment NPC
function SetupApartmentNPC()
    local npc = Config.NPC
    local model = npc.model
    
    lib.requestModel(model, 1000)
    local npc_ped = CreatePed(4, model, npc.coords.x, npc.coords.y, npc.coords.z, npc.coords.w, false, true)
    SetEntityInvincible(npc_ped, true)
    SetBlockingOfNonTemporaryEvents(npc_ped, true)
    FreezeEntityPosition(npc_ped, true)
    SetPedCanRagdoll(npc_ped, false)
    
    exports.ox_target:addLocalEntity(npc_ped, {
        {
            name = 'apartment_manager',
            label = 'Apartment Manager',
            icon = 'fa-solid fa-building',
            onSelect = function()
                OpenApartmentMenu()
            end,
            distance = 2.0
        }
    })
end

-- Remove apartment targets
function RemoveApartmentTargets()
    for apartment_id, _ in pairs(Config.Apartments) do
        exports.ox_target:removeZone('apartment_enter_' .. apartment_id)
    end
    exports.ox_target:removeLocalEntity('apartment_manager')
end

-- Enter apartment function
function EnterApartment(apartment_id)
    if not apartment_id then
        lib.notify({ title = 'Error', description = 'Invalid apartment ID', type = 'error' })
        return
    end
    
    local apartment = Config.Apartments[apartment_id]
    if not apartment then
        lib.notify({ title = 'Error', description = 'Apartment not found', type = 'error' })
        return
    end
    
    -- Check ownership
    lib.callback.await('imrp_apartments:CheckOwnership', false, function(owned)
        if not owned then
            lib.notify({ title = 'Access Denied', description = 'You do not own this apartment', type = 'error' })
            return
        end
        
        -- Teleport to interior
        local interior_coords = apartment.location.interior
        SetEntityCoords(PlayerPedId(), interior_coords.x, interior_coords.y, interior_coords.z, false, false, false, false)
        
        -- Setup interior interactions
        SetupInteriorInteractions(apartment_id, apartment)
        
        -- Show notification
        lib.notify({ title = 'Apartment', description = 'Welcome to your apartment!', type = 'success' })
    end, apartment_id)
end

-- Setup interior interactions
function SetupInteriorInteractions(apartment_id, apartment)
    -- Stash
    exports.ox_target:addSphereZone({
        coords = apartment.location.stash,
        radius = 1.5,
        options = {
            {
                name = 'apartment_stash_' .. apartment_id,
                label = 'Open Stash',
                icon = 'fa-solid fa-box',
                onSelect = function()
                    OpenApartmentStash(apartment_id)
                end,
                distance = 2.0
            }
        },
        debug = false,
        useZ = true
    })
    
    -- Wardrobe
    if Config.EnableWardrobe then
        exports.ox_target:addSphereZone({
            coords = apartment.location.wardrobe,
            radius = 1.5,
            options = {
                {
                    name = 'apartment_wardrobe_' .. apartment_id,
                    label = 'Wardrobe',
                    icon = 'fa-solid fa-tshirt',
                    onSelect = function()
                        OpenWardrobe(apartment_id)
                    end,
                    distance = 2.0
                }
            },
            debug = false,
            useZ = true
        })
    end
    
    -- Exit
    exports.ox_target:addSphereZone({
        coords = apartment.location.exit,
        radius = 1.5,
        options = {
            {
                name = 'apartment_exit_' .. apartment_id,
                label = 'Exit Apartment',
                icon = 'fa-solid fa-door-closed',
                onSelect = function()
                    ExitApartment(apartment_id, apartment)
                end,
                distance = 2.0
            }
        },
        debug = false,
        useZ = true
    })
end

-- Open apartment stash
function OpenApartmentStash(apartment_id)
    lib.callback.await('imrp_apartments:OpenStash', false, function(success)
        if not success then
            lib.notify({ title = 'Error', description = 'Failed to open stash', type = 'error' })
        end
    end, apartment_id)
end

-- Open wardrobe
function OpenWardrobe(apartment_id)
    if Config.AppearanceSystem == 'illenium-appearance' then
        exports['illenium-appearance']:OpenWardrobe()
    elseif Config.AppearanceSystem == 'fivem-appearance' then
        exports['fivem-appearance']:OpenWardrobe()
    else
        lib.notify({ title = 'Error', description = 'Appearance system not configured', type = 'error' })
    end
end

-- Exit apartment
function ExitApartment(apartment_id, apartment)
    local exit_coords = apartment.location.exit
    
    -- Clean up interactions
    exports.ox_target:removeZone('apartment_stash_' .. apartment_id)
    exports.ox_target:removeZone('apartment_wardrobe_' .. apartment_id)
    exports.ox_target:removeZone('apartment_exit_' .. apartment_id)
    
    -- Teleport to exit
    SetEntityCoords(PlayerPedId(), exit_coords.x, exit_coords.y, exit_coords.z, false, false, false, false)
    
    lib.notify({ title = 'Apartment', description = 'You have left your apartment', type = 'info' })
end

-- Open apartment menu (NPC interaction)
function OpenApartmentMenu()
    local options = {
        {
            title = 'View Available Apartments',
            description = 'See all apartments for sale',
            icon = 'building',
            onSelect = function()
                ShowAvailableApartments()
            end
        },
        {
            title = 'My Apartments',
            description = 'View your owned apartments',
            icon = 'home',
            onSelect = function()
                ShowMyApartments()
            end
        },
        {
            title = 'Rent Information',
            description = 'Learn about renting',
            icon = 'info-circle',
            onSelect = function()
                ShowRentInfo()
            end
        }
    }
    
    lib.registerContext({
        id = 'apartment_menu',
        title = 'Apartment Manager',
        options = options
    })
    lib.showContext('apartment_menu')
end

-- Show available apartments
function ShowAvailableApartments()
    local options = {}
    
    for apartment_id, apartment in pairs(Config.Apartments) do
        table.insert(options, {
            title = apartment.label,
            description = string.format('Price: $%s | Rent: $%s/week', 
                FormatNumber(apartment.price), 
                FormatNumber(apartment.rental_price)),
            icon = 'home',
            onSelect = function()
                PurchaseApartment(apartment_id)
            end
        })
    end
    
    lib.registerContext({
        id = 'available_apartments',
        title = 'Available Apartments',
        options = options
    })
    lib.showContext('available_apartments')
end

-- Show my apartments
function ShowMyApartments()
    lib.callback.await('imrp_apartments:GetMyApartments', false, function(apartments)
        if not apartments or #apartments == 0 then
            lib.notify({ title = 'Info', description = 'You don\'t own any apartments', type = 'info' })
            return
        end
        
        local options = {}
        for _, apartment_data in ipairs(apartments) do
            local apartment = Config.Apartments[apartment_data.apartment]
            if apartment then
                local days_remaining = GetDaysRemaining(apartment_data.expire_date)
                options[#options + 1] = {
                    title = apartment.label,
                    description = string.format('Days remaining: %s', days_remaining),
                    icon = 'home',
                    onSelect = function()
                        ShowApartmentOptions(apartment_data.apartment)
                    end
                }
            end
        end
        
        lib.registerContext({
            id = 'my_apartments',
            title = 'My Apartments',
            options = options
        })
        lib.showContext('my_apartments')
    end)
end

-- Show apartment options
function ShowApartmentOptions(apartment_id)
    local options = {
        {
            title = 'Enter Apartment',
            icon = 'door-open',
            onSelect = function()
                EnterApartment(apartment_id)
            end
        },
        {
            title = 'Renew Rent',
            icon = 'clock',
            onSelect = function()
                RenewApartment(apartment_id)
            end
        },
        {
            title = 'Information',
            icon = 'info-circle',
            onSelect = function()
                ShowApartmentInfo(apartment_id)
            end
        }
    }
    
    lib.registerContext({
        id = 'apartment_options',
        title = 'Apartment Options',
        options = options
    })
    lib.showContext('apartment_options')
end

-- Show apartment info
function ShowApartmentInfo(apartment_id)
    lib.callback.await('imrp_apartments:GetApartmentInfo', false, function(info)
        if not info then
            lib.notify({ title = 'Error', description = 'Could not get apartment info', type = 'error' })
            return
        end
        
        local apartment = Config.Apartments[apartment_id]
        local days_remaining = GetDaysRemaining(info.expire_date)
        
        lib.notify({ 
            title = apartment.label,
            description = string.format(
                'Price: $%s\nRent: $%s/week\nDays Remaining: %s\nPurchase Date: %s',
                FormatNumber(apartment.price),
                FormatNumber(apartment.rental_price),
                days_remaining,
                os.date('%Y-%m-%d', info.purchase_date)
            ),
            type = 'info',
            duration = 15000
        })
    end, apartment_id)
end

-- Purchase apartment
function PurchaseApartment(apartment_id)
    local apartment = Config.Apartments[apartment_id]
    if not apartment then
        lib.notify({ title = 'Error', description = 'Apartment not found', type = 'error' })
        return
    end
    
    lib.callback.await('imrp_apartments:PurchaseApartment', false, function(success, message)
        if success then
            lib.notify({ title = 'Success', description = message or 'Apartment purchased successfully!', type = 'success' })
        else
            lib.notify({ title = 'Error', description = message or 'Failed to purchase apartment', type = 'error' })
        end
    end, apartment_id)
end

-- Renew apartment
function RenewApartment(apartment_id)
    lib.callback.await('imrp_apartments:RenewApartment', false, function(success, message)
        if success then
            lib.notify({ title = 'Success', description = message or 'Apartment renewed successfully!', type = 'success' })
        else
            lib.notify({ title = 'Error', description = message or 'Failed to renew apartment', type = 'error' })
        end
    end, apartment_id)
end

-- Show rent information
function ShowRentInfo()
    lib.notify({
        title = 'Rent Information',
        description = 'Apartments are rented on a weekly basis. You must renew your rent before it expires to maintain access.',
        type = 'info',
        duration = 10000
    })
end

-- Helper functions
function FormatNumber(number)
    return string.format("%.0f", number):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

function GetDaysRemaining(expire_date)
    local current_time = os.time()
    local expire_timestamp = expire_date
    local time_diff = expire_timestamp - current_time
    return math.max(0, math.ceil(time_diff / 86400))
end
-- Client-side main script for IMRP Apartments
-- Security: Never trust client-side data for authorization decisions;
-- all sensitive operations are validated server-side.

local QBX = exports['qbx_core']
local isInsideApartment = false
local currentApartment = nil

-- ============================================================================
-- NPC SETUP
-- ============================================================================

local function SpawnNPC()
    local model = Config.NPC.model
    if not IsModelValid(GetHashKey(model)) then
        print('[imrp_apartments] Invalid NPC model: ' .. tostring(model))
        return
    end

    lib.requestModel(model)
    local npc = CreatePed(4, GetHashKey(model), Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z, Config.NPC.coords.w, false, true)
    SetEntityAsMissionEntity(npc, true, true)
    SetPedFleeAttributes(npc, 0, false)
    SetBlockingOfNonTemporaryEvents(npc, true)
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)

    if Config.UseTarget then
        exports.ox_target:addLocalEntity(npc, {
            {
                name = 'apartment_manager',
                label = Config.NPC.label,
                icon = 'fas fa-building',
                onSelect = function()
                    OpenApartmentMenu()
                end,
                distance = 2.5
            }
        })
    end
end

-- ============================================================================
-- APARTMENT MENU
-- ============================================================================

function OpenApartmentMenu()
    local options = {}

    for id, apartment in pairs(Config.Apartments) do
        options[#options + 1] = {
            title = apartment.label,
            description = ('Purchase: $%s | Rent: $%s/%dd'):format(
                apartment.price,
                apartment.rental_price,
                apartment.rental_days
            ),
            onSelect = function()
                OpenApartmentDetails(id, apartment)
            end
        }
    end

    lib.registerContext({
        id = 'apartment_menu',
        title = 'Available Apartments',
        options = options
    })
    lib.showContext('apartment_menu')
end

function OpenApartmentDetails(apartmentId, apartment)
    -- Input validation: ensure apartmentId is a string that exists in config
    if not Utils.IsValidApartmentId(apartmentId) then return end

    lib.registerContext({
        id = 'apartment_details',
        title = apartment.label,
        menu = 'apartment_menu',
        options = {
            {
                title = 'Purchase - $' .. tostring(apartment.price),
                description = 'Buy this apartment permanently',
                icon = 'fas fa-key',
                onSelect = function()
                    -- Server validates ownership, funds, and limits
                    TriggerServerEvent('imrp_apartments:server:purchase', apartmentId)
                end
            },
            {
                title = 'Rent - $' .. tostring(apartment.rental_price) .. '/' .. tostring(apartment.rental_days) .. ' days',
                description = 'Rent this apartment temporarily',
                icon = 'fas fa-clock',
                onSelect = function()
                    -- Server validates everything
                    TriggerServerEvent('imrp_apartments:server:rent', apartmentId)
                end
            },
            {
                title = 'Enter Apartment',
                description = 'Go inside (requires ownership)',
                icon = 'fas fa-door-open',
                onSelect = function()
                    -- Server validates ownership before teleporting
                    TriggerServerEvent('imrp_apartments:server:enter', apartmentId)
                end
            }
        }
    })
    lib.showContext('apartment_details')
end

-- ============================================================================
-- APARTMENT ENTRY/EXIT
-- ============================================================================

RegisterNetEvent('imrp_apartments:client:enterApartment', function(apartmentId, interiorCoords)
    -- Validate data received from server
    if not apartmentId or not interiorCoords then return end
    if not Utils.IsValidApartmentId(apartmentId) then return end

    local ped = PlayerPedId()
    SetEntityCoords(ped, interiorCoords.x, interiorCoords.y, interiorCoords.z, false, false, false, true)
    isInsideApartment = true
    currentApartment = apartmentId

    -- Register stash and wardrobe points
    local apartment = Config.Apartments[apartmentId]

    -- Stash access via ox_inventory
    if apartment.location.stash then
        exports.ox_target:addSphereZone({
            coords = apartment.location.stash,
            radius = 1.0,
            options = {
                {
                    name = 'apartment_stash_' .. apartmentId,
                    label = 'Apartment Stash',
                    icon = 'fas fa-box',
                    onSelect = function()
                        exports.ox_inventory:openInventory('stash', {
                            id = 'apartment_' .. apartmentId,
                            slots = apartment.stash_slots,
                            weight = apartment.stash_weight
                        })
                    end,
                    distance = 1.5
                }
            }
        })
    end

    -- Wardrobe access
    if Config.EnableWardrobe and apartment.location.wardrobe then
        exports.ox_target:addSphereZone({
            coords = apartment.location.wardrobe,
            radius = 1.0,
            options = {
                {
                    name = 'apartment_wardrobe_' .. apartmentId,
                    label = 'Wardrobe',
                    icon = 'fas fa-tshirt',
                    onSelect = function()
                        exports[Config.AppearanceSystem]:openWardrobe()
                    end,
                    distance = 1.5
                }
            }
        })
    end

    -- Exit point
    if apartment.location.exit then
        exports.ox_target:addSphereZone({
            coords = vec3(interiorCoords.x, interiorCoords.y, interiorCoords.z),
            radius = 1.0,
            options = {
                {
                    name = 'apartment_exit_' .. apartmentId,
                    label = 'Exit Apartment',
                    icon = 'fas fa-door-open',
                    onSelect = function()
                        ExitApartment()
                    end,
                    distance = 2.0
                }
            }
        })
    end
end)

function ExitApartment()
    if not isInsideApartment or not currentApartment then return end
    if not Utils.IsValidApartmentId(currentApartment) then return end

    local apartment = Config.Apartments[currentApartment]
    local ped = PlayerPedId()
    SetEntityCoords(ped, apartment.location.exit.x, apartment.location.exit.y, apartment.location.exit.z, false, false, false, true)

    -- Cleanup target zones
    exports.ox_target:removeZone('apartment_stash_' .. currentApartment)
    exports.ox_target:removeZone('apartment_wardrobe_' .. currentApartment)
    exports.ox_target:removeZone('apartment_exit_' .. currentApartment)

    isInsideApartment = false
    currentApartment = nil
end

-- ============================================================================
-- RECEIVE DATA FROM SERVER
-- ============================================================================

RegisterNetEvent('imrp_apartments:client:receiveApartments', function(apartments)
    if type(apartments) ~= 'table' then return end

    local options = {}
    for _, apt in ipairs(apartments) do
        if apt.apartment_id and Config.Apartments[apt.apartment_id] then
            local config = Config.Apartments[apt.apartment_id]
            options[#options + 1] = {
                title = config.label,
                description = apt.owned == 1 and 'Owned' or ('Rental expires: ' .. tostring(apt.rental_expiry)),
                onSelect = function()
                    TriggerServerEvent('imrp_apartments:server:enter', apt.apartment_id)
                end
            }
        end
    end

    if #options == 0 then
        lib.notify({ title = 'Apartments', description = 'You have no apartments.', type = 'info' })
        return
    end

    lib.registerContext({
        id = 'my_apartments',
        title = 'My Apartments',
        options = options
    })
    lib.showContext('my_apartments')
end)

-- ============================================================================
-- BLIP SETUP
-- ============================================================================

CreateThread(function()
    for _, apartment in pairs(Config.Apartments) do
        if apartment.blip and apartment.blip.enabled then
            local blip = AddBlipForCoord(apartment.location.entrance.x, apartment.location.entrance.y, apartment.location.entrance.z)
            SetBlipSprite(blip, apartment.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, apartment.blip.scale)
            SetBlipColour(blip, apartment.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(apartment.blip.label)
            EndTextCommandSetBlipName(blip)
        end
    end

    -- Spawn NPC after short delay to ensure world is loaded
    Wait(2000)
    SpawnNPC()
end)

-----------------------------------------------------------
-- IMRP Apartments - Client Main
-- Author: Ragna | Immortal Roleplay
-----------------------------------------------------------

local QBX = exports['qbx_core']
local PlayerData = {}
local CurrentApartment = nil
local InsideApartment = false
local CurrentBucket = 0

-----------------------------------------------------------
-- Initialize
-----------------------------------------------------------
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBX:GetPlayerData()
    InitBlips()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    CurrentApartment = nil
    InsideApartment = false
    RemoveBlips()
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    PlayerData = QBX:GetPlayerData()
    if PlayerData and PlayerData.citizenid then
        InitBlips()
    end
end)

-----------------------------------------------------------
-- Blips
-----------------------------------------------------------
local Blips = {}

function InitBlips()
    RemoveBlips()
    if not Config.Blip.enabled then return end

    for key, apt in pairs(Config.Apartments) do
        local blip = AddBlipForCoord(apt.entrance.x, apt.entrance.y, apt.entrance.z)
        SetBlipSprite(blip, Config.Blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Blip.scale)
        SetBlipColour(blip, Config.Blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(apt.blip_label or apt.label)
        EndTextCommandSetBlipName(blip)
        Blips[key] = blip
    end
end

function RemoveBlips()
    for key, blip in pairs(Blips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    Blips = {}
end

-----------------------------------------------------------
-- Enter Apartment
-----------------------------------------------------------
function EnterApartment(apartmentKey, apartmentData)
    if InsideApartment then
        IMRP.Notify(IMRP.Locale('already_inside'), 'error')
        return
    end

    lib.callback('imrp_apartments:server:enterApartment', false, function(result)
        if not result or not result.success then
            IMRP.Notify(result and result.message or IMRP.Locale('enter_failed'), 'error')
            return
        end

        local apt = Config.Apartments[apartmentKey]
        if not apt then return end

        CurrentApartment = {
            key = apartmentKey,
            id = result.apartment_id,
            bucket = result.bucket_id,
            data = apartmentData
        }

        DoScreenFadeOut(500)
        Wait(500)

        SetEntityCoords(cache.ped, apt.interior_coords.x, apt.interior_coords.y, apt.interior_coords.z, false, false, false, false)
        SetEntityHeading(cache.ped, apt.interior_heading)
        FreezeEntityPosition(cache.ped, false)

        InsideApartment = true
        CurrentBucket = result.bucket_id

        Wait(500)
        DoScreenFadeIn(500)

        IMRP.Notify(IMRP.Locale('entered_apartment', apt.label), 'success')

        SetupInteriorTargets(apartmentKey)
    end, apartmentKey)
end

-----------------------------------------------------------
-- Exit Apartment
-----------------------------------------------------------
function ExitApartment()
    if not InsideApartment or not CurrentApartment then return end

    lib.callback('imrp_apartments:server:exitApartment', false, function(result)
        if not result or not result.success then
            IMRP.Notify(IMRP.Locale('exit_failed'), 'error')
            return
        end

        local apt = Config.Apartments[CurrentApartment.key]
        if not apt then return end

        DoScreenFadeOut(500)
        Wait(500)

        SetEntityCoords(cache.ped, apt.entrance.x, apt.entrance.y, apt.entrance.z, false, false, false, false)
        SetEntityHeading(cache.ped, apt.heading)
        FreezeEntityPosition(cache.ped, false)

        RemoveInteriorTargets()

        InsideApartment = false
        CurrentApartment = nil
        CurrentBucket = 0

        Wait(500)
        DoScreenFadeIn(500)

        IMRP.Notify(IMRP.Locale('exited_apartment'), 'success')
    end)
end

-----------------------------------------------------------
-- Interior Targets (Exit, Stash, Wardrobe)
-----------------------------------------------------------
local InteriorZones = {}

function SetupInteriorTargets(apartmentKey)
    local apt = Config.Apartments[apartmentKey]
    if not apt then return end

    local stashCoords = apt.interior_coords + apt.stash_offset
    local wardrobeCoords = apt.interior_coords + apt.wardrobe_offset

    InteriorZones[#InteriorZones + 1] = exports.ox_target:addSphereZone({
        coords = apt.interior_coords,
        radius = 1.5,
        options = {
            {
                name = 'apartment_exit',
                label = IMRP.Locale('exit_apartment'),
                icon = 'fas fa-door-open',
                onSelect = function()
                    ExitApartment()
                end
            },
            {
                name = 'apartment_logout',
                label = IMRP.Locale('logout_here'),
                icon = 'fas fa-sign-out-alt',
                onSelect = function()
                    TriggerServerEvent('imrp_apartments:server:logoutInApartment')
                end
            }
        }
    })

    InteriorZones[#InteriorZones + 1] = exports.ox_target:addSphereZone({
        coords = stashCoords,
        radius = 1.0,
        options = {
            {
                name = 'apartment_stash',
                label = IMRP.Locale('open_stash'),
                icon = 'fas fa-box',
                onSelect = function()
                    OpenApartmentStash()
                end
            }
        }
    })

    if Config.UseWardrobe then
        InteriorZones[#InteriorZones + 1] = exports.ox_target:addSphereZone({
            coords = wardrobeCoords,
            radius = 1.0,
            options = {
                {
                    name = 'apartment_wardrobe',
                    label = IMRP.Locale('open_wardrobe'),
                    icon = 'fas fa-tshirt',
                    onSelect = function()
                        OpenWardrobe()
                    end
                }
            }
        })
    end
end

function RemoveInteriorTargets()
    for _, zone in ipairs(InteriorZones) do
        exports.ox_target:removeZone(zone)
    end
    InteriorZones = {}
end

-----------------------------------------------------------
-- Open Stash
-----------------------------------------------------------
function OpenApartmentStash()
    if not CurrentApartment then return end

    local stashId = IMRP.GenerateStashId(CurrentApartment.id)
    local typeData = IMRP.GetApartmentTypeData(CurrentApartment.key)
    local slots = typeData and typeData.stash_slots or Config.DefaultStashSlots
    local weight = typeData and typeData.stash_weight or Config.DefaultStashWeight

    exports.ox_inventory:openInventory('stash', {
        id = stashId,
        slots = slots,
        weight = weight,
        label = ('%s Stash'):format(Config.Apartments[CurrentApartment.key].label)
    })
end

-----------------------------------------------------------
-- Apartment Menu (Command: /apartment)
-----------------------------------------------------------
RegisterCommand('apartment', function()
    if not InsideApartment and not IsNearAnyApartment() then
        IMRP.Notify(IMRP.Locale('not_near_apartment'), 'error')
        return
    end

    if InsideApartment then
        OpenInsideMenu()
    else
        OpenOutsideMenu()
    end
end, false)

function IsNearAnyApartment()
    local playerCoords = GetEntityCoords(cache.ped)
    for key, apt in pairs(Config.Apartments) do
        if #(playerCoords - apt.entrance) < 10.0 then
            return true, key
        end
    end
    return false, nil
end

function GetNearestApartment()
    local playerCoords = GetEntityCoords(cache.ped)
    local nearest = nil
    local nearestDist = math.huge

    for key, apt in pairs(Config.Apartments) do
        local dist = #(playerCoords - apt.entrance)
        if dist < nearestDist then
            nearest = key
            nearestDist = dist
        end
    end

    return nearest, nearestDist
end

-----------------------------------------------------------
-- Inside Apartment Menu
-----------------------------------------------------------
function OpenInsideMenu()
    if not CurrentApartment then return end

    local options = {
        {
            title = IMRP.Locale('exit_apartment'),
            description = IMRP.Locale('exit_apartment_desc'),
            icon = 'door-open',
            onSelect = function()
                ExitApartment()
            end
        },
        {
            title = IMRP.Locale('apartment_info'),
            description = IMRP.Locale('apartment_info_desc'),
            icon = 'info-circle',
            onSelect = function()
                ShowApartmentInfo()
            end
        },
        {
            title = IMRP.Locale('open_stash'),
            description = IMRP.Locale('open_stash_desc'),
            icon = 'box',
            onSelect = function()
                OpenApartmentStash()
            end
        }
    }

    if Config.UseWardrobe then
        options[#options + 1] = {
            title = IMRP.Locale('open_wardrobe'),
            description = IMRP.Locale('open_wardrobe_desc'),
            icon = 'tshirt',
            onSelect = function()
                OpenWardrobe()
            end
        }
    end

    if Config.UseKeys then
        options[#options + 1] = {
            title = IMRP.Locale('manage_keys'),
            description = IMRP.Locale('manage_keys_desc'),
            icon = 'key',
            onSelect = function()
                OpenKeyMenu()
            end
        }
    end

    if Config.UseGuestSystem then
        options[#options + 1] = {
            title = IMRP.Locale('invite_player'),
            description = IMRP.Locale('invite_player_desc'),
            icon = 'user-plus',
            onSelect = function()
                InvitePlayer()
            end
        }
        options[#options + 1] = {
            title = IMRP.Locale('remove_guest'),
            description = IMRP.Locale('remove_guest_desc'),
            icon = 'user-minus',
            onSelect = function()
                RemoveGuest()
            end
        }
    end

    if Config.UseGarage then
        options[#options + 1] = {
            title = IMRP.Locale('garage'),
            description = IMRP.Locale('garage_desc'),
            icon = 'car',
            onSelect = function()
                OpenGarageMenu()
            end
        }
    end

    options[#options + 1] = {
        title = IMRP.Locale('renew_apartment'),
        description = IMRP.Locale('renew_apartment_desc'),
        icon = 'redo',
        onSelect = function()
            RenewApartment()
        end
    }

    options[#options + 1] = {
        title = IMRP.Locale('sell_apartment'),
        description = IMRP.Locale('sell_apartment_desc'),
        icon = 'dollar-sign',
        onSelect = function()
            SellApartment()
        end
    }

    options[#options + 1] = {
        title = IMRP.Locale('logout_here'),
        description = IMRP.Locale('logout_here_desc'),
        icon = 'sign-out-alt',
        onSelect = function()
            TriggerServerEvent('imrp_apartments:server:logoutInApartment')
        end
    }

    lib.registerContext({
        id = 'apartment_inside_menu',
        title = IMRP.Locale('apartment_menu_title'),
        options = options
    })
    lib.showContext('apartment_inside_menu')
end

-----------------------------------------------------------
-- Outside Apartment Menu
-----------------------------------------------------------
function OpenOutsideMenu()
    local _, nearestKey = IsNearAnyApartment()
    if not nearestKey then
        nearestKey = GetNearestApartment()
    end
    if not nearestKey then return end

    local apt = Config.Apartments[nearestKey]
    local typeData = Config.ApartmentTypes[apt.type]

    local options = {
        {
            title = IMRP.Locale('buy_apartment'),
            description = IMRP.Locale('buy_apartment_desc', IMRP.FormatCurrency(typeData.price)),
            icon = 'home',
            onSelect = function()
                BuyApartment(nearestKey)
            end
        },
        {
            title = IMRP.Locale('rent_apartment'),
            description = IMRP.Locale('rent_apartment_desc', IMRP.FormatCurrency(typeData.rental_price)),
            icon = 'calendar',
            onSelect = function()
                RentApartment(nearestKey)
            end
        },
        {
            title = IMRP.Locale('enter_apartment'),
            description = IMRP.Locale('enter_apartment_desc'),
            icon = 'door-open',
            onSelect = function()
                EnterApartment(nearestKey, nil)
            end
        },
        {
            title = IMRP.Locale('apartment_info'),
            description = IMRP.Locale('apartment_info_desc'),
            icon = 'info-circle',
            onSelect = function()
                ShowApartmentInfoExternal(nearestKey)
            end
        }
    }

    lib.registerContext({
        id = 'apartment_outside_menu',
        title = apt.label,
        options = options
    })
    lib.showContext('apartment_outside_menu')
end

-----------------------------------------------------------
-- Buy Apartment
-----------------------------------------------------------
function BuyApartment(apartmentKey)
    local alert = lib.alertDialog({
        header = IMRP.Locale('confirm_purchase'),
        content = IMRP.Locale('confirm_purchase_desc', Config.Apartments[apartmentKey].label, IMRP.FormatCurrency(IMRP.GetApartmentPrice(apartmentKey))),
        centered = true,
        cancel = true
    })

    if alert ~= 'confirm' then return end

    lib.callback('imrp_apartments:server:buyApartment', false, function(result)
        if result and result.success then
            IMRP.Notify(IMRP.Locale('purchase_success', Config.Apartments[apartmentKey].label), 'success')
            SendNUIMessage({ action = 'showNotification', data = { type = 'success', message = IMRP.Locale('purchase_success', Config.Apartments[apartmentKey].label) } })
        else
            IMRP.Notify(result and result.message or IMRP.Locale('purchase_failed'), 'error')
        end
    end, apartmentKey, 'buy')
end

-----------------------------------------------------------
-- Rent Apartment
-----------------------------------------------------------
function RentApartment(apartmentKey)
    local alert = lib.alertDialog({
        header = IMRP.Locale('confirm_rental'),
        content = IMRP.Locale('confirm_rental_desc', Config.Apartments[apartmentKey].label, IMRP.FormatCurrency(IMRP.GetRentalPrice(apartmentKey)), Config.ApartmentDuration),
        centered = true,
        cancel = true
    })

    if alert ~= 'confirm' then return end

    lib.callback('imrp_apartments:server:buyApartment', false, function(result)
        if result and result.success then
            IMRP.Notify(IMRP.Locale('rental_success', Config.Apartments[apartmentKey].label), 'success')
        else
            IMRP.Notify(result and result.message or IMRP.Locale('rental_failed'), 'error')
        end
    end, apartmentKey, 'rent')
end

-----------------------------------------------------------
-- Renew Apartment
-----------------------------------------------------------
function RenewApartment()
    if not CurrentApartment then return end

    local typeData = IMRP.GetApartmentTypeData(CurrentApartment.key)
    local renewPrice = typeData and typeData.rental_price or 0

    local alert = lib.alertDialog({
        header = IMRP.Locale('confirm_renew'),
        content = IMRP.Locale('confirm_renew_desc', IMRP.FormatCurrency(renewPrice), Config.ApartmentDuration),
        centered = true,
        cancel = true
    })

    if alert ~= 'confirm' then return end

    lib.callback('imrp_apartments:server:renewApartment', false, function(result)
        if result and result.success then
            IMRP.Notify(IMRP.Locale('renew_success'), 'success')
        else
            IMRP.Notify(result and result.message or IMRP.Locale('renew_failed'), 'error')
        end
    end, CurrentApartment.key)
end

-----------------------------------------------------------
-- Sell Apartment
-----------------------------------------------------------
function SellApartment()
    if not CurrentApartment then return end

    local typeData = IMRP.GetApartmentTypeData(CurrentApartment.key)
    local sellPrice = math.floor((typeData and typeData.price or 0) * Config.SellRefundPercent / 100)

    local alert = lib.alertDialog({
        header = IMRP.Locale('confirm_sell'),
        content = IMRP.Locale('confirm_sell_desc', IMRP.FormatCurrency(sellPrice)),
        centered = true,
        cancel = true
    })

    if alert ~= 'confirm' then return end

    lib.callback('imrp_apartments:server:sellApartment', false, function(result)
        if result and result.success then
            IMRP.Notify(IMRP.Locale('sell_success', IMRP.FormatCurrency(sellPrice)), 'success')
            ExitApartment()
        else
            IMRP.Notify(result and result.message or IMRP.Locale('sell_failed'), 'error')
        end
    end, CurrentApartment.key)
end

-----------------------------------------------------------
-- Apartment Info
-----------------------------------------------------------
function ShowApartmentInfo()
    if not CurrentApartment then return end

    lib.callback('imrp_apartments:server:getApartmentInfo', false, function(info)
        if not info then return end

        SendNUIMessage({
            action = 'showApartmentInfo',
            data = {
                name = Config.Apartments[CurrentApartment.key].label,
                type = Config.ApartmentTypes[Config.Apartments[CurrentApartment.key].type].label,
                id = CurrentApartment.id,
                bucket = CurrentApartment.bucket,
                purchase_date = info.purchase_date,
                expire_date = info.expire_date,
                days_remaining = info.days_remaining,
                keys_given = info.keys_count,
                guests = info.guests_count
            }
        })
        SetNuiFocus(true, true)
    end, CurrentApartment.key)
end

function ShowApartmentInfoExternal(apartmentKey)
    local apt = Config.Apartments[apartmentKey]
    local typeData = Config.ApartmentTypes[apt.type]

    SendNUIMessage({
        action = 'showApartmentInfo',
        data = {
            name = apt.label,
            type = typeData.label,
            price = IMRP.FormatCurrency(typeData.price),
            rental_price = IMRP.FormatCurrency(typeData.rental_price),
            stash_slots = typeData.stash_slots,
            stash_weight = typeData.stash_weight,
            garage_slots = typeData.garage_slots,
            duration = Config.ApartmentDuration
        }
    })
    SetNuiFocus(true, true)
end

-----------------------------------------------------------
-- Key Management
-----------------------------------------------------------
function OpenKeyMenu()
    if not CurrentApartment then return end

    lib.callback('imrp_apartments:server:getKeys', false, function(keys)
        if not keys then return end

        local options = {
            {
                title = IMRP.Locale('give_key'),
                description = IMRP.Locale('give_key_desc'),
                icon = 'key',
                onSelect = function()
                    GiveKey()
                end
            },
            {
                title = IMRP.Locale('duplicate_key'),
                description = IMRP.Locale('duplicate_key_desc'),
                icon = 'copy',
                onSelect = function()
                    DuplicateKey()
                end
            }
        }

        for _, keyData in ipairs(keys) do
            options[#options + 1] = {
                title = keyData.name or keyData.citizenid,
                description = IMRP.Locale('key_type') .. ': ' .. (keyData.key_type or 'permanent'),
                icon = 'user',
                onSelect = function()
                    RemoveKey(keyData.citizenid)
                end,
                arrow = true
            }
        end

        lib.registerContext({
            id = 'apartment_key_menu',
            title = IMRP.Locale('key_management'),
            menu = 'apartment_inside_menu',
            options = options
        })
        lib.showContext('apartment_key_menu')
    end, CurrentApartment.key)
end

function GiveKey()
    if not CurrentApartment then return end

    local input = lib.inputDialog(IMRP.Locale('give_key'), {
        { type = 'number', label = IMRP.Locale('player_id'), required = true },
        { type = 'select', label = IMRP.Locale('key_type'), options = {
            { value = 'permanent', label = IMRP.Locale('permanent_key') },
            { value = 'temporary', label = IMRP.Locale('temporary_key') }
        }, required = true }
    })

    if not input then return end

    lib.callback('imrp_apartments:server:giveKey', false, function(result)
        if result and result.success then
            IMRP.Notify(IMRP.Locale('key_given'), 'success')
        else
            IMRP.Notify(result and result.message or IMRP.Locale('key_give_failed'), 'error')
        end
    end, CurrentApartment.key, input[1], input[2])
end

function DuplicateKey()
    if not CurrentApartment then return end

    local input = lib.inputDialog(IMRP.Locale('duplicate_key'), {
        { type = 'number', label = IMRP.Locale('player_id'), required = true }
    })

    if not input then return end

    lib.callback('imrp_apartments:server:duplicateKey', false, function(result)
        if result and result.success then
            IMRP.Notify(IMRP.Locale('key_duplicated'), 'success')
        else
            IMRP.Notify(result and result.message or IMRP.Locale('key_duplicate_failed'), 'error')
        end
    end, CurrentApartment.key, input[1])
end

function RemoveKey(targetCitizenId)
    local alert = lib.alertDialog({
        header = IMRP.Locale('confirm_remove_key'),
        content = IMRP.Locale('confirm_remove_key_desc'),
        centered = true,
        cancel = true
    })

    if alert ~= 'confirm' then return end

    lib.callback('imrp_apartments:server:removeKey', false, function(result)
        if result and result.success then
            IMRP.Notify(IMRP.Locale('key_removed'), 'success')
        else
            IMRP.Notify(result and result.message or IMRP.Locale('key_remove_failed'), 'error')
        end
    end, CurrentApartment.key, targetCitizenId)
end

-----------------------------------------------------------
-- Guest System
-----------------------------------------------------------
function InvitePlayer()
    if not CurrentApartment then return end

    local input = lib.inputDialog(IMRP.Locale('invite_player'), {
        { type = 'number', label = IMRP.Locale('player_id'), required = true }
    })

    if not input then return end

    lib.callback('imrp_apartments:server:inviteGuest', false, function(result)
        if result and result.success then
            IMRP.Notify(IMRP.Locale('guest_invited'), 'success')
        else
            IMRP.Notify(result and result.message or IMRP.Locale('invite_failed'), 'error')
        end
    end, CurrentApartment.key, input[1])
end

function RemoveGuest()
    if not CurrentApartment then return end

    lib.callback('imrp_apartments:server:getGuests', false, function(guests)
        if not guests or #guests == 0 then
            IMRP.Notify(IMRP.Locale('no_guests'), 'info')
            return
        end

        local options = {}
        for _, guest in ipairs(guests) do
            options[#options + 1] = {
                title = guest.name or guest.citizenid,
                icon = 'user',
                onSelect = function()
                    lib.callback('imrp_apartments:server:removeGuest', false, function(result)
                        if result and result.success then
                            IMRP.Notify(IMRP.Locale('guest_removed'), 'success')
                        else
                            IMRP.Notify(IMRP.Locale('guest_remove_failed'), 'error')
                        end
                    end, CurrentApartment.key, guest.citizenid)
                end
            }
        end

        lib.registerContext({
            id = 'apartment_guest_menu',
            title = IMRP.Locale('remove_guest'),
            menu = 'apartment_inside_menu',
            options = options
        })
        lib.showContext('apartment_guest_menu')
    end, CurrentApartment.key)
end

-----------------------------------------------------------
-- Door Lock
-----------------------------------------------------------
RegisterNetEvent('imrp_apartments:client:toggleLock', function(locked)
    if not CurrentApartment then return end
    local msg = locked and IMRP.Locale('door_locked') or IMRP.Locale('door_unlocked')
    IMRP.Notify(msg, 'info')
end)

-----------------------------------------------------------
-- Exports
-----------------------------------------------------------
exports('IsInsideApartment', function()
    return InsideApartment
end)

exports('GetCurrentApartment', function()
    return CurrentApartment
end)

exports('GetCurrentBucket', function()
    return CurrentBucket
end)

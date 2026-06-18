-----------------------------------------------------------
-- IMRP Apartments - Client Target (ox_target)
-- Author: Ragna | Immortal Roleplay
-----------------------------------------------------------

local function canInteractOutside()
    return not exports['imrp_apartments']:IsInsideApartment()
end

local function CreateEntranceOption(key, name, localeKey, icon, onSelect)
    return {
        name = ('%s_%s'):format(name, key),
        label = IMRP.Locale(localeKey) .. ' - ' .. Config.Apartments[key].label,
        icon = icon,
        onSelect = onSelect,
        canInteract = canInteractOutside,
    }
end

-----------------------------------------------------------
-- Setup ox_target zones for apartment entrances
-----------------------------------------------------------
CreateThread(function()
    if not Config.UseOxTarget then return end

    for key, apt in pairs(Config.Apartments) do
        exports.ox_target:addSphereZone({
            coords = apt.entrance,
            radius = 2.0,
            options = {
                CreateEntranceOption(key, 'apt_buy', 'buy_apartment', 'fas fa-home', function()
                    BuyApartment(key)
                end),
                CreateEntranceOption(key, 'apt_rent', 'rent_apartment', 'fas fa-calendar-alt', function()
                    RentApartment(key)
                end),
                CreateEntranceOption(key, 'apt_enter', 'enter_apartment', 'fas fa-door-open', function()
                    EnterApartment(key, nil)
                end),
                CreateEntranceOption(key, 'apt_info', 'apartment_info', 'fas fa-info-circle', function()
                    ShowApartmentInfoExternal(key)
                end),
            }
        })
    end
end)

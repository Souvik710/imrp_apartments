-----------------------------------------------------------
-- IMRP Apartments - Client Target (ox_target)
-- Author: Ragna | Immortal Roleplay
-----------------------------------------------------------

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
                {
                    name = ('apt_buy_%s'):format(key),
                    label = IMRP.Locale('buy_apartment') .. ' - ' .. apt.label,
                    icon = 'fas fa-home',
                    onSelect = function()
                        BuyApartment(key)
                    end,
                    canInteract = function()
                        return not exports['imrp_apartments']:IsInsideApartment()
                    end
                },
                {
                    name = ('apt_rent_%s'):format(key),
                    label = IMRP.Locale('rent_apartment') .. ' - ' .. apt.label,
                    icon = 'fas fa-calendar-alt',
                    onSelect = function()
                        RentApartment(key)
                    end,
                    canInteract = function()
                        return not exports['imrp_apartments']:IsInsideApartment()
                    end
                },
                {
                    name = ('apt_enter_%s'):format(key),
                    label = IMRP.Locale('enter_apartment') .. ' - ' .. apt.label,
                    icon = 'fas fa-door-open',
                    onSelect = function()
                        EnterApartment(key, nil)
                    end,
                    canInteract = function()
                        return not exports['imrp_apartments']:IsInsideApartment()
                    end
                },
                {
                    name = ('apt_info_%s'):format(key),
                    label = IMRP.Locale('apartment_info') .. ' - ' .. apt.label,
                    icon = 'fas fa-info-circle',
                    onSelect = function()
                        ShowApartmentInfoExternal(key)
                    end,
                    canInteract = function()
                        return not exports['imrp_apartments']:IsInsideApartment()
                    end
                }
            }
        })
    end
end)

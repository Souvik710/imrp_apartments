-----------------------------------------------------------
-- IMRP Apartments - Server Expiry System
-- Author: Ragna | Immortal Roleplay
-----------------------------------------------------------

-----------------------------------------------------------
-- Check for expired apartments
-----------------------------------------------------------
function CheckExpiredApartments()
    local expired = MySQL.query.await('SELECT apartment_id, citizenid FROM apartments WHERE expire_date <= NOW()')

    if not expired or #expired == 0 then
        IMRP.Debug('No expired apartments found')
        return
    end

    IMRP.Debug(('Found %d expired apartments'):format(#expired))

    for _, apt in ipairs(expired) do
        IMRP.Debug(('Expiring apartment: %s (Owner: %s)'):format(apt.apartment_id, apt.citizenid))

        -- Cleanup apartment
        CleanupApartment(apt.apartment_id)

        -- Log the expiry
        LogAction(apt.citizenid, apt.apartment_id, 'expired', 'Automatic expiry')

        -- Notify owner if online
        local players = exports['qbx_core']:GetQBPlayers()
        for _, player in pairs(players) do
            if player and player.PlayerData and player.PlayerData.citizenid == apt.citizenid then
                TriggerClientEvent('ox_lib:notify', player.PlayerData.source, {
                    title = 'Apartments',
                    description = IMRP.Locale('apartment_expired'),
                    type = 'error',
                    position = Config.Notification.position
                })
                break
            end
        end
    end
end

-----------------------------------------------------------
-- Run on server start
-----------------------------------------------------------
CreateThread(function()
    Wait(5000) -- Wait for DB to be ready
    CheckExpiredApartments()
end)

-----------------------------------------------------------
-- Periodic check (every Config.ExpiryCheckInterval ms)
-----------------------------------------------------------
CreateThread(function()
    while true do
        Wait(Config.ExpiryCheckInterval)
        CheckExpiredApartments()
    end
end)

-----------------------------------------------------------
-- IMRP Apartments - Server Expiry System
-- Author: Ragna | Immortal Roleplay
-----------------------------------------------------------

-----------------------------------------------------------
-- Check for expired apartments
-----------------------------------------------------------
function CheckExpiredApartments()
    local ok, expired = pcall(MySQL.query.await, 'SELECT apartment_id, citizenid FROM apartments WHERE expire_date <= NOW()')
    if not ok then
        print(('^1[imrp_apartments] Expiry check DB error: %s^0'):format(tostring(expired)))
        return
    end

    if not expired or #expired == 0 then
        IMRP.Debug('No expired apartments found')
        return
    end

    IMRP.Debug(('Found %d expired apartments'):format(#expired))

    local removed = 0
    for _, apt in ipairs(expired) do
        IMRP.Debug(('Expiring apartment: %s (Owner: %s)'):format(apt.apartment_id, apt.citizenid))

        local cleanupOk = CleanupApartment(apt.apartment_id)
        if cleanupOk then
            removed = removed + 1
            LogAction(apt.citizenid, apt.apartment_id, 'expired', 'Automatic expiry')

            -- Notify owner if online
            local playersOk, players = pcall(exports['qbx_core'].GetQBPlayers, exports['qbx_core'])
            if playersOk and players then
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
        else
            print(('^3[imrp_apartments] Warning: Failed to cleanup expired apartment %s^0'):format(apt.apartment_id))
        end
    end

    if removed > 0 then
        print(('[imrp_apartments] Removed %d expired apartment(s)'):format(removed))
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

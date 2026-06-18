-----------------------------------------------------------
-- IMRP Ambulance Job - Server Commands
-- Admin and utility commands
-----------------------------------------------------------

-----------------------------------------------------------
-- Admin: Force revive player
-----------------------------------------------------------
RegisterCommand('emsrevive', function(source, args)
    local src = source
    if src == 0 then -- Console
        if not args[1] then
            print('[IMRP EMS] Usage: emsrevive [player_id]')
            return
        end
        local targetSrc = tonumber(args[1])
        TriggerClientEvent('imrp_ambulancejob:client:emsRevive', targetSrc)
        TriggerClientEvent('imrp_ambulancejob:client:healAll', targetSrc)
        print('[IMRP EMS] Revived player ' .. targetSrc)
        return
    end

    if not EMSUtils.IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'No permission', type = 'error' })
        return
    end

    local targetSrc = tonumber(args[1]) or src
    TriggerClientEvent('imrp_ambulancejob:client:emsRevive', targetSrc)
    TriggerClientEvent('imrp_ambulancejob:client:healAll', targetSrc)
    TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'Player revived', type = 'success' })
end, false)

-----------------------------------------------------------
-- Admin: Heal player
-----------------------------------------------------------
RegisterCommand('emsheal', function(source, args)
    local src = source
    if src == 0 then
        local targetSrc = tonumber(args[1])
        if targetSrc then
            TriggerClientEvent('imrp_ambulancejob:client:healAll', targetSrc)
            print('[IMRP EMS] Healed player ' .. targetSrc)
        end
        return
    end

    if not EMSUtils.IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'No permission', type = 'error' })
        return
    end

    local targetSrc = tonumber(args[1]) or src
    TriggerClientEvent('imrp_ambulancejob:client:healAll', targetSrc)
    TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'Player healed', type = 'success' })
end, false)

-----------------------------------------------------------
-- Admin: Set EMS rank
-----------------------------------------------------------
RegisterCommand('emssetrank', function(source, args)
    local src = source
    if src ~= 0 and not EMSUtils.IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'No permission', type = 'error' })
        return
    end

    local targetSrc = tonumber(args[1])
    local grade = tonumber(args[2])

    if not targetSrc or not grade then
        local msg = 'Usage: emssetrank [player_id] [grade 0-9]'
        if src == 0 then print('[IMRP EMS] ' .. msg) else
            TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = msg, type = 'error' })
        end
        return
    end

    grade = math.max(0, math.min(9, grade))

    local target = exports.qbx_core:GetPlayer(targetSrc)
    if not target then return end

    target.Functions.SetJob(Config.JobName, grade)

    MySQL.update('UPDATE ems_staff SET rank = ?, rank_label = ? WHERE citizenid = ?', {
        grade, Ranks.GetLabel(grade), target.PlayerData.citizenid
    })

    local msg = string.format('Set %s rank to %s (Grade %d)', GetPlayerName(targetSrc), Ranks.GetLabel(grade), grade)
    if src == 0 then
        print('[IMRP EMS] ' .. msg)
    else
        TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = msg, type = 'success' })
    end
end, false)

-----------------------------------------------------------
-- Admin: Get EMS on duty count
-----------------------------------------------------------
RegisterCommand('emsonduty', function(source)
    local src = source
    local count = GetOnDutyCount()
    local msg = string.format('EMS on duty: %d', count)

    if src == 0 then
        print('[IMRP EMS] ' .. msg)
    else
        TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = msg, type = 'info' })
    end
end, false)

-----------------------------------------------------------
-- Admin: Clear all calls
-----------------------------------------------------------
RegisterCommand('emsclearcalls', function(source)
    local src = source
    if src ~= 0 and not EMSUtils.IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'No permission', type = 'error' })
        return
    end

    MySQL.update("UPDATE ems_calls SET status = 'completed', completed_at = NOW() WHERE status != 'completed'")

    local msg = 'All active calls cleared'
    if src == 0 then
        print('[IMRP EMS] ' .. msg)
    else
        TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = msg, type = 'success' })
    end
end, false)

-----------------------------------------------------------
-- Admin: Give EMS item
-----------------------------------------------------------
RegisterCommand('emsgiveitem', function(source, args)
    local src = source
    if src ~= 0 and not EMSUtils.IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'No permission', type = 'error' })
        return
    end

    local targetSrc = tonumber(args[1])
    local itemName = args[2]
    local quantity = tonumber(args[3]) or 1

    if not targetSrc or not itemName then
        local msg = 'Usage: emsgiveitem [player_id] [item_name] [quantity]'
        if src == 0 then print('[IMRP EMS] ' .. msg) else
            TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = msg, type = 'error' })
        end
        return
    end

    exports.ox_inventory:AddItem(targetSrc, itemName, quantity)

    local msg = string.format('Gave %dx %s to player %d', quantity, itemName, targetSrc)
    if src == 0 then
        print('[IMRP EMS] ' .. msg)
    else
        TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = msg, type = 'success' })
    end
end, false)

-----------------------------------------------------------
-- Admin: Reset patient injuries
-----------------------------------------------------------
RegisterCommand('emsresetpatient', function(source, args)
    local src = source
    if src ~= 0 and not EMSUtils.IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'No permission', type = 'error' })
        return
    end

    local citizenid = args[1]
    if not citizenid then
        local msg = 'Usage: emsresetpatient [citizenid]'
        if src == 0 then print('[IMRP EMS] ' .. msg) else
            TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = msg, type = 'error' })
        end
        return
    end

    MySQL.update('UPDATE ems_patients SET injuries = NULL, blood_level = 100, pain_level = 0, is_dead = 0 WHERE citizenid = ?', { citizenid })

    local target = exports.qbx_core:GetPlayerByCitizenId(citizenid)
    if target then
        TriggerClientEvent('imrp_ambulancejob:client:healAll', target.PlayerData.source)
    end

    local msg = 'Patient record reset for ' .. citizenid
    if src == 0 then
        print('[IMRP EMS] ' .. msg)
    else
        TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = msg, type = 'success' })
    end
end, false)

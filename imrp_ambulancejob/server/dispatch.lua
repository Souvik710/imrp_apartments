-----------------------------------------------------------
-- IMRP Ambulance Job - Server Dispatch Handlers
-----------------------------------------------------------

local activeCalls = {}

-----------------------------------------------------------
-- Respond to Call
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:server:respondToCall', function(callId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    if player.PlayerData.job.name ~= Config.JobName then return end

    if activeCalls[callId] then
        activeCalls[callId].responding_units = (activeCalls[callId].responding_units or 0) + 1
        activeCalls[callId].status = 'responding'
    end

    MySQL.update('UPDATE ems_calls SET responding_units = responding_units + 1, status = ?, responded_at = NOW(), assigned_to = ? WHERE call_id = ? AND status != ?', {
        'responding', player.PlayerData.citizenid, callId, 'completed'
    })

    local emsName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    LogAction(player.PlayerData.citizenid, emsName, 'dispatch_respond', 'Responded to call: ' .. callId)
end)

-----------------------------------------------------------
-- Complete Call
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:server:completeCall', function(callId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    if player.PlayerData.job.name ~= Config.JobName then return end

    activeCalls[callId] = nil

    MySQL.update('UPDATE ems_calls SET status = ?, completed_at = NOW() WHERE call_id = ?', {
        'completed', callId
    })

    BroadcastToEMS('imrp_ambulancejob:client:callCompleted', callId)

    local emsName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    LogAction(player.PlayerData.citizenid, emsName, 'dispatch_complete', 'Completed call: ' .. callId)
end)

-----------------------------------------------------------
-- Get Active Calls Callback
-----------------------------------------------------------
lib.callback.register('imrp_ambulancejob:server:getActiveCalls', function(source)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player or player.PlayerData.job.name ~= Config.JobName then return {} end

    local calls = MySQL.query.await('SELECT * FROM ems_calls WHERE status != ? ORDER BY created_at DESC LIMIT 50', { 'completed' })
    return calls or {}
end)

-----------------------------------------------------------
-- Store active call reference
-----------------------------------------------------------
function StoreActiveCall(callData)
    activeCalls[callData.call_id] = callData
end

-- Hook into SaveCall from main.lua
local originalSaveCall = SaveCall
SaveCall = function(callData)
    StoreActiveCall(callData)
    if originalSaveCall then
        originalSaveCall(callData)
    else
        MySQL.insert('INSERT INTO ems_calls (call_id, caller_citizenid, caller_name, call_type, description, location, coords_x, coords_y, coords_z, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            callData.call_id,
            callData.caller_citizenid,
            callData.caller_name,
            callData.type,
            callData.description,
            callData.location,
            callData.coords.x,
            callData.coords.y,
            callData.coords.z,
            'pending',
        })
    end
end

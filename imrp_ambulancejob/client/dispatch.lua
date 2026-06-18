-----------------------------------------------------------
-- IMRP Ambulance Job - Client Dispatch System
-- Emergency calls, GPS routing, unit tracking
-----------------------------------------------------------

local activeCallBlips = {}
local respondingToCall = nil

-----------------------------------------------------------
-- Receive Dispatch Alert
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:client:dispatchAlert', function(callData)
    if not EMSUtils.IsOnDuty() then return end

    PlaySound(-1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', false, 0, true)

    local callBlip = AddBlipForCoord(callData.coords.x, callData.coords.y, callData.coords.z)
    SetBlipSprite(callBlip, 153)
    SetBlipColour(callBlip, 1)
    SetBlipScale(callBlip, 1.2)
    SetBlipFlashes(callBlip, true)
    SetBlipFlashInterval(callBlip, 500)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(callData.type_label or 'Emergency')
    EndTextCommandSetBlipName(callBlip)

    activeCallBlips[callData.call_id] = callBlip

    -- Auto-remove flash after 10 seconds
    SetTimeout(10000, function()
        if DoesBlipExist(callBlip) then
            SetBlipFlashes(callBlip, false)
        end
    end)

    -- Show dispatch notification
    SendNUIMessage({
        action = 'showDispatchAlert',
        data = callData,
    })

    -- ox_lib alert
    local input = lib.alertDialog({
        header = '🚨 EMS DISPATCH',
        content = string.format(
            '**Type:** %s\n**Location:** %s\n**Details:** %s\n**Responding:** %d units',
            callData.type_label or 'Unknown',
            callData.location or 'Unknown',
            callData.description or 'No details',
            callData.responding_units or 0
        ),
        centered = true,
        cancel = true,
        labels = {
            confirm = 'Respond',
            cancel = 'Decline',
        },
    })

    if input == 'confirm' then
        RespondToCall(callData)
    end
end)

-----------------------------------------------------------
-- Respond to Call
-----------------------------------------------------------
function RespondToCall(callData)
    respondingToCall = callData.call_id

    TriggerServerEvent('imrp_ambulancejob:server:respondToCall', callData.call_id)

    -- Set waypoint
    SetNewWaypoint(callData.coords.x, callData.coords.y)

    EMSUtils.Notify('Responding to ' .. (callData.type_label or 'emergency call'), 'success')

    -- Update blip
    if activeCallBlips[callData.call_id] then
        SetBlipRoute(activeCallBlips[callData.call_id], true)
        SetBlipRouteColour(activeCallBlips[callData.call_id], 1)
    end
end

-----------------------------------------------------------
-- Call Completed / Cancelled
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:client:callCompleted', function(callId)
    if activeCallBlips[callId] then
        if DoesBlipExist(activeCallBlips[callId]) then
            RemoveBlip(activeCallBlips[callId])
        end
        activeCallBlips[callId] = nil
    end

    if respondingToCall == callId then
        respondingToCall = nil
        EMSUtils.Notify('Call completed', 'success')
    end
end)

RegisterNetEvent('imrp_ambulancejob:client:callCancelled', function(callId)
    if activeCallBlips[callId] then
        if DoesBlipExist(activeCallBlips[callId]) then
            RemoveBlip(activeCallBlips[callId])
        end
        activeCallBlips[callId] = nil
    end

    if respondingToCall == callId then
        respondingToCall = nil
        EMSUtils.Notify('Call cancelled', 'info')
    end
end)

-----------------------------------------------------------
-- Dispatch Call Types
-----------------------------------------------------------
local CallTypes = {
    gunshot = { label = 'Gunshot Victim', priority = 'high', icon = 'fa-crosshairs' },
    vehicle_accident = { label = 'Vehicle Accident', priority = 'high', icon = 'fa-car-burst' },
    unconscious = { label = 'Unconscious Person', priority = 'medium', icon = 'fa-person-falling' },
    cardiac = { label = 'Cardiac Arrest', priority = 'critical', icon = 'fa-heart-pulse' },
    emergency = { label = 'Emergency Call', priority = 'medium', icon = 'fa-phone' },
    fall = { label = 'Fall Victim', priority = 'medium', icon = 'fa-person-falling' },
    burn = { label = 'Burn Victim', priority = 'high', icon = 'fa-fire' },
    overdose = { label = 'Overdose', priority = 'high', icon = 'fa-pills' },
}

-----------------------------------------------------------
-- Auto-Dispatch on Player Down (from death system)
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:client:autoDispatch', function(callType, coords, callerName)
    if not EMSUtils.IsOnDuty() then return end

    local typeData = CallTypes[callType] or CallTypes['emergency']

    local callData = {
        call_id = EMSUtils.GenerateId(),
        type = callType,
        type_label = typeData.label,
        priority = typeData.priority,
        coords = coords,
        location = GetStreetName(coords),
        caller_name = callerName or 'Unknown',
        description = typeData.label .. ' reported',
        responding_units = 0,
    }

    TriggerEvent('imrp_ambulancejob:client:dispatchAlert', callData)
end)

-----------------------------------------------------------
-- Get Street Name Helper
-----------------------------------------------------------
function GetStreetName(coords)
    local streetHash, crossHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(streetHash)
    local cross = GetStreetNameFromHashKey(crossHash)

    if cross and cross ~= '' then
        return street .. ' / ' .. cross
    end
    return street
end

-----------------------------------------------------------
-- Complete Active Call
-----------------------------------------------------------
function CompleteActiveCall()
    if respondingToCall then
        TriggerServerEvent('imrp_ambulancejob:server:completeCall', respondingToCall)
        respondingToCall = nil
    end
end

exports('CompleteActiveCall', CompleteActiveCall)

-----------------------------------------------------------
-- Cleanup
-----------------------------------------------------------
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for _, blip in pairs(activeCallBlips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
        activeCallBlips = {}
    end
end)

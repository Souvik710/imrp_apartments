-----------------------------------------------------------
-- IMRP Ambulance Job - Client NUI Callbacks
-- MDT, Death Screen, Minigames communication
-----------------------------------------------------------

local mdtOpen = false

-----------------------------------------------------------
-- Open MDT
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:client:openMDT', function()
    if not EMSUtils.IsEMS() then
        EMSUtils.Notify('You are not an EMS member', 'error')
        return
    end

    if not Ranks.HasPermission(EMSUtils.GetRank(), 'mdt_access') then
        EMSUtils.Notify('Insufficient rank for MDT access', 'error')
        return
    end

    mdtOpen = true
    SetNuiFocus(true, true)

    local playerData = exports.qbx_core:GetPlayerData()

    SendNUIMessage({
        action = 'openMDT',
        playerData = {
            name = playerData.charinfo.firstname .. ' ' .. playerData.charinfo.lastname,
            citizenid = playerData.citizenid,
            rank = Ranks.GetLabel(EMSUtils.GetRank()),
            grade = EMSUtils.GetRank(),
            onDuty = EMSUtils.IsOnDuty(),
        },
    })
end)

-----------------------------------------------------------
-- Close MDT
-----------------------------------------------------------
RegisterNUICallback('closeMDT', function(_, cb)
    mdtOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-----------------------------------------------------------
-- MDT: Get Dashboard Data
-----------------------------------------------------------
RegisterNUICallback('getDashboardData', function(_, cb)
    lib.callback('imrp_ambulancejob:server:getDashboardData', false, function(data)
        cb(data or {})
    end)
end)

-----------------------------------------------------------
-- MDT: Get Active Calls
-----------------------------------------------------------
RegisterNUICallback('getActiveCalls', function(_, cb)
    lib.callback('imrp_ambulancejob:server:getActiveCalls', false, function(data)
        cb(data or {})
    end)
end)

-----------------------------------------------------------
-- MDT: Get Patient Records
-----------------------------------------------------------
RegisterNUICallback('getPatientRecords', function(data, cb)
    lib.callback('imrp_ambulancejob:server:getPatientRecords', false, function(records)
        cb(records or {})
    end, data.search or '')
end)

-----------------------------------------------------------
-- MDT: Get Medical History
-----------------------------------------------------------
RegisterNUICallback('getMedicalHistory', function(data, cb)
    lib.callback('imrp_ambulancejob:server:getMedicalHistory', false, function(history)
        cb(history or {})
    end, data.citizenid)
end)

-----------------------------------------------------------
-- MDT: Get Insurance Records
-----------------------------------------------------------
RegisterNUICallback('getInsuranceRecords', function(_, cb)
    lib.callback('imrp_ambulancejob:server:getInsuranceRecords', false, function(records)
        cb(records or {})
    end)
end)

-----------------------------------------------------------
-- MDT: Get Staff List
-----------------------------------------------------------
RegisterNUICallback('getStaffList', function(_, cb)
    lib.callback('imrp_ambulancejob:server:getStaffList', false, function(staff)
        cb(staff or {})
    end)
end)

-----------------------------------------------------------
-- MDT: Get Duty Logs
-----------------------------------------------------------
RegisterNUICallback('getDutyLogs', function(_, cb)
    lib.callback('imrp_ambulancejob:server:getDutyLogs', false, function(logs)
        cb(logs or {})
    end)
end)

-----------------------------------------------------------
-- MDT: Save Report
-----------------------------------------------------------
RegisterNUICallback('saveReport', function(data, cb)
    TriggerServerEvent('imrp_ambulancejob:server:saveReport', data)
    cb('ok')
end)

-----------------------------------------------------------
-- MDT: Get Reports
-----------------------------------------------------------
RegisterNUICallback('getReports', function(_, cb)
    lib.callback('imrp_ambulancejob:server:getReports', false, function(reports)
        cb(reports or {})
    end)
end)

-----------------------------------------------------------
-- MDT: Get Billing Records
-----------------------------------------------------------
RegisterNUICallback('getBillingRecords', function(_, cb)
    lib.callback('imrp_ambulancejob:server:getBillingRecords', false, function(bills)
        cb(bills or {})
    end)
end)

-----------------------------------------------------------
-- MDT: Search Citizen
-----------------------------------------------------------
RegisterNUICallback('searchCitizen', function(data, cb)
    lib.callback('imrp_ambulancejob:server:searchCitizen', false, function(result)
        cb(result or {})
    end, data.query)
end)

-----------------------------------------------------------
-- MDT: Create Bill
-----------------------------------------------------------
RegisterNUICallback('createBill', function(data, cb)
    TriggerServerEvent('imrp_ambulancejob:server:createBill', data)
    cb('ok')
end)

-----------------------------------------------------------
-- MDT: Respond to Call from MDT
-----------------------------------------------------------
RegisterNUICallback('respondToCall', function(data, cb)
    TriggerServerEvent('imrp_ambulancejob:server:respondToCall', data.call_id)
    cb('ok')
end)

-----------------------------------------------------------
-- MDT: Complete Call from MDT
-----------------------------------------------------------
RegisterNUICallback('completeCall', function(data, cb)
    TriggerServerEvent('imrp_ambulancejob:server:completeCall', data.call_id)
    cb('ok')
end)

-----------------------------------------------------------
-- Death Screen NUI Callbacks
-----------------------------------------------------------
RegisterNUICallback('requestRespawn', function(_, cb)
    OpenRespawnMenu()
    cb('ok')
end)

RegisterNUICallback('sendDistress', function(_, cb)
    SendDistressSignal()
    cb('ok')
end)

RegisterNUICallback('toggleCrawl', function(_, cb)
    TriggerEvent('imrp_ambulancejob:client:toggleCrawl')
    cb('ok')
end)

-----------------------------------------------------------
-- ESC key to close MDT
-----------------------------------------------------------
CreateThread(function()
    while true do
        Wait(0)
        if mdtOpen then
            DisableControlAction(0, 200, true) -- ESC
            if IsDisabledControlJustPressed(0, 200) then
                mdtOpen = false
                SetNuiFocus(false, false)
                SendNUIMessage({ action = 'closeMDT' })
            end
        else
            Wait(500)
        end
    end
end)

-----------------------------------------------------------
-- IMRP Ambulance Job - Server Billing Handlers
-----------------------------------------------------------

-----------------------------------------------------------
-- Create Bill
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:server:createBill', function(data)
    local src = source
    local emsPlayer = exports.qbx_core:GetPlayer(src)
    if not emsPlayer then return end
    if emsPlayer.PlayerData.job.name ~= Config.JobName then return end

    if not Ranks.HasPermission(emsPlayer.PlayerData.job.grade.level, 'billing') then
        TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'You do not have billing permission', type = 'error' })
        return
    end

    local patientCitizenid = data.patient_citizenid
    local amount = tonumber(data.amount) or 0
    local reason = data.reason or 'Medical Treatment'

    if amount <= 0 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'Invalid amount', type = 'error' })
        return
    end

    -- Apply insurance discount
    local discount = GetInsuranceDiscount(patientCitizenid)
    local finalAmount = math.floor(amount * (1 - discount / 100))

    local emsName = emsPlayer.PlayerData.charinfo.firstname .. ' ' .. emsPlayer.PlayerData.charinfo.lastname
    local billId = GenerateId()

    MySQL.insert('INSERT INTO ems_billing (bill_id, patient_citizenid, patient_name, ems_citizenid, ems_name, amount, original_amount, discount_applied, reason) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        billId,
        patientCitizenid,
        data.patient_name or 'Unknown',
        emsPlayer.PlayerData.citizenid,
        emsName,
        finalAmount,
        amount,
        discount,
        reason,
    })

    -- Try to charge patient directly if online
    local targetPlayer = exports.qbx_core:GetPlayerByCitizenId(patientCitizenid)
    if targetPlayer then
        local targetSrc = targetPlayer.PlayerData.source
        if targetPlayer.Functions.RemoveMoney(Config.DefaultCurrency, finalAmount, 'ems-bill-' .. billId) then
            MySQL.update('UPDATE ems_billing SET status = ?, paid_at = NOW() WHERE bill_id = ?', { 'paid', billId })

            -- Add to society account
            exports.qbx_core:AddMoney(Config.JobName, finalAmount)

            TriggerClientEvent('ox_lib:notify', targetSrc, {
                title = 'IMRP EMS',
                description = string.format('Medical bill: $%d for %s', finalAmount, reason),
                type = 'info',
            })

            TriggerClientEvent('ox_lib:notify', src, {
                title = 'IMRP EMS',
                description = string.format('Bill of $%d sent and paid by patient', finalAmount),
                type = 'success',
            })
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'IMRP EMS',
                description = string.format('Bill of $%d created (patient has insufficient funds)', finalAmount),
                type = 'info',
            })
        end
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'IMRP EMS',
            description = string.format('Bill of $%d created (patient offline)', finalAmount),
            type = 'info',
        })
    end

    LogAction(emsPlayer.PlayerData.citizenid, emsName, 'billing', string.format('Created bill $%d for %s', finalAmount, reason), patientCitizenid)
end)

-----------------------------------------------------------
-- Auto-Bill for Treatment
-----------------------------------------------------------
function AutoBill(emsSrc, patientSrc, amount, reason)
    local emsPlayer = exports.qbx_core:GetPlayer(emsSrc)
    local patient = exports.qbx_core:GetPlayer(patientSrc)
    if not emsPlayer or not patient then return end

    local discount = GetInsuranceDiscount(patient.PlayerData.citizenid)
    local finalAmount = math.floor(amount * (1 - discount / 100))

    local emsName = emsPlayer.PlayerData.charinfo.firstname .. ' ' .. emsPlayer.PlayerData.charinfo.lastname
    local patientName = patient.PlayerData.charinfo.firstname .. ' ' .. patient.PlayerData.charinfo.lastname
    local billId = GenerateId()

    MySQL.insert('INSERT INTO ems_billing (bill_id, patient_citizenid, patient_name, ems_citizenid, ems_name, amount, original_amount, discount_applied, reason, status, paid_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())', {
        billId,
        patient.PlayerData.citizenid,
        patientName,
        emsPlayer.PlayerData.citizenid,
        emsName,
        finalAmount,
        amount,
        discount,
        reason,
        'paid',
    })

    patient.Functions.RemoveMoney(Config.DefaultCurrency, finalAmount, 'ems-auto-bill')
end

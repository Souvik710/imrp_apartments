-----------------------------------------------------------
-- IMRP Ambulance Job - Server MDT Handlers
-- Dashboard, Patient Records, Reports, Staff
-----------------------------------------------------------

-----------------------------------------------------------
-- Dashboard Data
-----------------------------------------------------------
lib.callback.register('imrp_ambulancejob:server:getDashboardData', function(source)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player or player.PlayerData.job.name ~= Config.JobName then return {} end

    local onDutyCount = GetOnDutyCount()
    local activeCalls = MySQL.scalar.await('SELECT COUNT(*) FROM ems_calls WHERE status != ? AND created_at > DATE_SUB(NOW(), INTERVAL 24 HOUR)', { 'completed' }) or 0
    local totalPatients = MySQL.scalar.await('SELECT COUNT(*) FROM ems_patients') or 0
    local todayTreatments = MySQL.scalar.await('SELECT COUNT(*) FROM ems_logs WHERE action = ? AND created_at > CURDATE()', { 'treatment' }) or 0
    local todayRevives = MySQL.scalar.await('SELECT COUNT(*) FROM ems_logs WHERE action = ? AND created_at > CURDATE()', { 'revive' }) or 0

    return {
        onDuty = onDutyCount,
        activeCalls = activeCalls,
        totalPatients = totalPatients,
        todayTreatments = todayTreatments,
        todayRevives = todayRevives,
    }
end)

-----------------------------------------------------------
-- Patient Records
-----------------------------------------------------------
lib.callback.register('imrp_ambulancejob:server:getPatientRecords', function(source, search)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player or player.PlayerData.job.name ~= Config.JobName then return {} end

    local query
    local params

    if search and search ~= '' then
        query = 'SELECT * FROM ems_patients WHERE name LIKE ? OR citizenid LIKE ? ORDER BY updated_at DESC LIMIT 50'
        params = { '%' .. search .. '%', '%' .. search .. '%' }
    else
        query = 'SELECT * FROM ems_patients ORDER BY updated_at DESC LIMIT 50'
        params = {}
    end

    return MySQL.query.await(query, params) or {}
end)

-----------------------------------------------------------
-- Medical History
-----------------------------------------------------------
lib.callback.register('imrp_ambulancejob:server:getMedicalHistory', function(source, citizenid)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player or player.PlayerData.job.name ~= Config.JobName then return {} end

    if not citizenid then return {} end

    local reports = MySQL.query.await('SELECT * FROM ems_reports WHERE patient_citizenid = ? ORDER BY created_at DESC LIMIT 20', { citizenid })
    local bills = MySQL.query.await('SELECT * FROM ems_billing WHERE patient_citizenid = ? ORDER BY created_at DESC LIMIT 20', { citizenid })
    local logs = MySQL.query.await('SELECT * FROM ems_logs WHERE target_citizenid = ? ORDER BY created_at DESC LIMIT 20', { citizenid })

    return {
        reports = reports or {},
        bills = bills or {},
        logs = logs or {},
    }
end)

-----------------------------------------------------------
-- Insurance Records
-----------------------------------------------------------
lib.callback.register('imrp_ambulancejob:server:getInsuranceRecords', function(source)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player or player.PlayerData.job.name ~= Config.JobName then return {} end

    return MySQL.query.await('SELECT * FROM ems_insurance WHERE is_active = 1 ORDER BY expires_at DESC LIMIT 50') or {}
end)

-----------------------------------------------------------
-- Staff List
-----------------------------------------------------------
lib.callback.register('imrp_ambulancejob:server:getStaffList', function(source)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player or player.PlayerData.job.name ~= Config.JobName then return {} end

    return MySQL.query.await('SELECT * FROM ems_staff WHERE is_active = 1 ORDER BY rank DESC, name ASC') or {}
end)

-----------------------------------------------------------
-- Duty Logs
-----------------------------------------------------------
lib.callback.register('imrp_ambulancejob:server:getDutyLogs', function(source)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player or player.PlayerData.job.name ~= Config.JobName then return {} end

    return MySQL.query.await('SELECT * FROM ems_logs WHERE action IN (?, ?) ORDER BY created_at DESC LIMIT 100', { 'clock_in', 'clock_out' }) or {}
end)

-----------------------------------------------------------
-- Save Report
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:server:saveReport', function(data)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player or player.PlayerData.job.name ~= Config.JobName then return end

    local emsName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    local reportId = GenerateId()

    MySQL.insert('INSERT INTO ems_reports (report_id, author_citizenid, author_name, patient_citizenid, patient_name, title, description, injuries_found, treatment_given, diagnosis, outcome) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        reportId,
        player.PlayerData.citizenid,
        emsName,
        data.patient_citizenid or '',
        data.patient_name or 'Unknown',
        data.title or 'Medical Report',
        data.description or '',
        json.encode(data.injuries_found or {}),
        json.encode(data.treatment_given or {}),
        data.diagnosis or '',
        data.outcome or 'treated',
    })

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'IMRP EMS',
        description = 'Report saved successfully',
        type = 'success',
    })

    LogAction(player.PlayerData.citizenid, emsName, 'report_created', 'Created report: ' .. (data.title or 'Medical Report'))
end)

-----------------------------------------------------------
-- Get Reports
-----------------------------------------------------------
lib.callback.register('imrp_ambulancejob:server:getReports', function(source)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player or player.PlayerData.job.name ~= Config.JobName then return {} end

    return MySQL.query.await('SELECT * FROM ems_reports ORDER BY created_at DESC LIMIT 50') or {}
end)

-----------------------------------------------------------
-- Search Citizen
-----------------------------------------------------------
lib.callback.register('imrp_ambulancejob:server:searchCitizen', function(source, query)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player or player.PlayerData.job.name ~= Config.JobName then return {} end

    if not query or query == '' then return {} end

    local results = MySQL.query.await([[
        SELECT citizenid, JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')) as firstname,
               JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname')) as lastname,
               JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.birthdate')) as dob,
               JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.gender')) as gender
        FROM players
        WHERE JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')) LIKE ?
           OR JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname')) LIKE ?
           OR citizenid LIKE ?
        LIMIT 20
    ]], { '%' .. query .. '%', '%' .. query .. '%', '%' .. query .. '%' })

    return results or {}
end)

-----------------------------------------------------------
-- Get Billing Records
-----------------------------------------------------------
lib.callback.register('imrp_ambulancejob:server:getBillingRecords', function(source)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player or player.PlayerData.job.name ~= Config.JobName then return {} end

    return MySQL.query.await('SELECT * FROM ems_billing ORDER BY created_at DESC LIMIT 50') or {}
end)

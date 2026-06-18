-----------------------------------------------------------
-- IMRP Ambulance Job - Server Hospital Handlers
-- Insurance, Pharmacy, Beds
-----------------------------------------------------------

-----------------------------------------------------------
-- Buy Insurance
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:server:buyInsurance', function(insuranceType, hospitalId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local prices = {
        basic = Config.Insurance.basicPrice,
        premium = Config.Insurance.premiumPrice,
        vip = Config.Insurance.vipPrice,
    }

    local discounts = {
        basic = Config.Insurance.basicDiscount,
        premium = Config.Insurance.premiumDiscount,
        vip = Config.Insurance.vipDiscount,
    }

    local price = prices[insuranceType]
    local discount = discounts[insuranceType]

    if not price or not discount then
        TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'Invalid insurance type', type = 'error' })
        return
    end

    -- Check if already has active insurance
    local existing = MySQL.single.await('SELECT id FROM ems_insurance WHERE citizenid = ? AND is_active = 1 AND expires_at > NOW()', {
        player.PlayerData.citizenid
    })

    if existing then
        TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'You already have active insurance', type = 'error' })
        return
    end

    if not player.Functions.RemoveMoney(Config.DefaultCurrency, price, 'ems-insurance-' .. insuranceType) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'Insufficient funds', type = 'error' })
        return
    end

    local playerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname

    MySQL.insert('INSERT INTO ems_insurance (citizenid, name, insurance_type, discount_percent, expires_at) VALUES (?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL ? DAY))', {
        player.PlayerData.citizenid,
        playerName,
        insuranceType,
        discount,
        Config.Insurance.duration,
    })

    -- Update patient record
    MySQL.query([[
        INSERT INTO ems_patients (citizenid, name, insurance_type, insurance_expires)
        VALUES (?, ?, ?, DATE_ADD(NOW(), INTERVAL ? DAY))
        ON DUPLICATE KEY UPDATE
            insurance_type = VALUES(insurance_type),
            insurance_expires = VALUES(insurance_expires)
    ]], {
        player.PlayerData.citizenid,
        playerName,
        insuranceType,
        Config.Insurance.duration,
    })

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'IMRP EMS',
        description = string.format('%s insurance purchased! %d%% discount for %d days.', insuranceType:upper(), discount, Config.Insurance.duration),
        type = 'success',
    })
end)

-----------------------------------------------------------
-- Check Insurance
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:server:checkInsurance', function()
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local result = MySQL.single.await('SELECT insurance_type, discount_percent, expires_at FROM ems_insurance WHERE citizenid = ? AND is_active = 1 AND expires_at > NOW() ORDER BY expires_at DESC LIMIT 1', {
        player.PlayerData.citizenid
    })

    TriggerClientEvent('imrp_ambulancejob:client:showInsurance', src, result)
end)

-----------------------------------------------------------
-- Buy Pharmacy Items
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:server:buyPharmacy', function(itemName, quantity, hospitalId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    if not quantity or quantity < 1 or quantity > 10 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'Invalid quantity', type = 'error' })
        return
    end

    local pharmacyItem = nil
    for _, item in ipairs(Config.Pharmacy) do
        if item.item == itemName then
            pharmacyItem = item
            break
        end
    end

    if not pharmacyItem then
        TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'Item not found', type = 'error' })
        return
    end

    local totalCost = pharmacyItem.price * quantity
    local discount = GetInsuranceDiscount(player.PlayerData.citizenid)
    local finalCost = math.floor(totalCost * (1 - discount / 100))

    if not player.Functions.RemoveMoney(Config.DefaultCurrency, finalCost, 'pharmacy-' .. itemName) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'Insufficient funds', type = 'error' })
        return
    end

    local success = exports.ox_inventory:AddItem(src, itemName, quantity)
    if not success then
        player.Functions.AddMoney(Config.DefaultCurrency, finalCost, 'pharmacy-refund')
        TriggerClientEvent('ox_lib:notify', src, { title = 'IMRP EMS', description = 'Inventory full', type = 'error' })
        return
    end

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'IMRP EMS',
        description = string.format('Purchased %dx %s for $%d', quantity, pharmacyItem.label, finalCost),
        type = 'success',
    })
end)

-----------------------------------------------------------
-- Bed System
-----------------------------------------------------------
local occupiedBeds = {}

RegisterNetEvent('imrp_ambulancejob:server:occupyBed', function(hospitalId, bedIndex)
    local src = source
    local key = hospitalId .. '_' .. bedIndex
    occupiedBeds[key] = src
end)

RegisterNetEvent('imrp_ambulancejob:server:leaveBed', function(hospitalId, bedIndex)
    local key = hospitalId .. '_' .. bedIndex
    occupiedBeds[key] = nil
end)

RegisterNetEvent('imrp_ambulancejob:server:placeInICU', function(targetSrc, hospitalId, icuIndex)
    local src = source
    local emsPlayer = exports.qbx_core:GetPlayer(src)
    if not emsPlayer or emsPlayer.PlayerData.job.name ~= Config.JobName then return end

    local key = hospitalId .. '_icu_' .. icuIndex
    occupiedBeds[key] = targetSrc

    TriggerClientEvent('ox_lib:notify', targetSrc, {
        title = 'IMRP EMS',
        description = 'You have been placed in the ICU',
        type = 'info',
    })
end)

-----------------------------------------------------------
-- Cleanup beds on disconnect
-----------------------------------------------------------
AddEventHandler('playerDropped', function()
    local src = source
    for key, occupant in pairs(occupiedBeds) do
        if occupant == src then
            occupiedBeds[key] = nil
        end
    end
end)

-----------------------------------------------------------
-- IMRP Apartments - Client NUI Callbacks
-- Author: Ragna | Immortal Roleplay
-----------------------------------------------------------

-----------------------------------------------------------
-- Close NUI
-----------------------------------------------------------
RegisterNUICallback('closeUI', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-----------------------------------------------------------
-- Purchase from NUI
-----------------------------------------------------------
RegisterNUICallback('purchaseApartment', function(data, cb)
    if not data or not data.apartmentKey then
        cb({ success = false })
        return
    end

    if data.purchaseType == 'rent' then
        RentApartment(data.apartmentKey)
    else
        BuyApartment(data.apartmentKey)
    end

    SetNuiFocus(false, false)
    cb({ success = true })
end)

-----------------------------------------------------------
-- Renew from NUI
-----------------------------------------------------------
RegisterNUICallback('renewApartment', function(_, cb)
    RenewApartment()
    SetNuiFocus(false, false)
    cb({ success = true })
end)

-----------------------------------------------------------
-- Sell from NUI
-----------------------------------------------------------
RegisterNUICallback('sellApartment', function(_, cb)
    SellApartment()
    SetNuiFocus(false, false)
    cb({ success = true })
end)

-----------------------------------------------------------
-- Key Management from NUI
-----------------------------------------------------------
RegisterNUICallback('giveKey', function(data, cb)
    if not data or not data.playerId then
        cb({ success = false })
        return
    end

    lib.callback('imrp_apartments:server:giveKey', false, function(result)
        cb(result or { success = false })
    end, exports['imrp_apartments']:GetCurrentApartment() and exports['imrp_apartments']:GetCurrentApartment().key, data.playerId, data.keyType or 'permanent')
end)

RegisterNUICallback('removeKey', function(data, cb)
    if not data or not data.citizenid then
        cb({ success = false })
        return
    end

    local currentApt = exports['imrp_apartments']:GetCurrentApartment()
    if not currentApt then
        cb({ success = false })
        return
    end

    lib.callback('imrp_apartments:server:removeKey', false, function(result)
        cb(result or { success = false })
    end, currentApt.key, data.citizenid)
end)

-----------------------------------------------------------
-- Get Keys List for NUI
-----------------------------------------------------------
RegisterNUICallback('getKeys', function(_, cb)
    local currentApt = exports['imrp_apartments']:GetCurrentApartment()
    if not currentApt then
        cb({ keys = {} })
        return
    end

    lib.callback('imrp_apartments:server:getKeys', false, function(keys)
        cb({ keys = keys or {} })
    end, currentApt.key)
end)

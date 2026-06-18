-----------------------------------------------------------
-- IMRP Apartments - Server Admin Commands
-- Author: Ragna | Immortal Roleplay
-----------------------------------------------------------

local QBX = exports['qbx_core']

-----------------------------------------------------------
-- Permission Check
-----------------------------------------------------------
local function HasAdminPermission(source)
    local player = QBX:GetPlayer(source)
    if not player then return false end

    for _, perm in ipairs(Config.AdminPermissions) do
        if QBX:HasPermission(source, perm) then
            return true
        end
    end

    return IsPlayerAceAllowed(source, 'command.apartment_admin')
end

-----------------------------------------------------------
-- /giveapartment [id] [apartment_name]
-----------------------------------------------------------
lib.addCommand('giveapartment', {
    help = 'Give an apartment to a player (Admin)',
    params = {
        { name = 'id', type = 'number', help = 'Player server ID' },
        { name = 'apartment', type = 'string', help = 'Apartment key name' }
    },
    restricted = 'group.admin'
}, function(source, args)
    if not HasAdminPermission(source) then
        lib.notify(source, { title = 'Apartments', description = 'No permission', type = 'error' })
        return
    end

    local targetId = args.id
    local apartmentKey = args.apartment

    if not Config.Apartments[apartmentKey] then
        lib.notify(source, { title = 'Apartments', description = 'Invalid apartment key', type = 'error' })
        return
    end

    local targetPlayer = QBX:GetPlayer(targetId)
    if not targetPlayer then
        lib.notify(source, { title = 'Apartments', description = 'Player not found', type = 'error' })
        return
    end

    local citizenid = targetPlayer.PlayerData.citizenid

    -- Generate bucket
    local bucketId = GetNextBucketId()
    local apartmentId = IMRP.GenerateApartmentId(apartmentKey, bucketId)

    -- Set expiry far in the future (admin given)
    local expireDate = os.date('%Y-%m-%d %H:%M:%S', os.time() + (365 * 86400))
    local purchaseDate = os.date('%Y-%m-%d %H:%M:%S')

    MySQL.insert('INSERT INTO apartments (citizenid, apartment_id, apartment_name, apartment_type, bucket_id, purchase_date, expire_date, purchase_type) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        citizenid, apartmentId, apartmentKey, Config.Apartments[apartmentKey].type, bucketId, purchaseDate, expireDate, 'admin'
    })

    OwnedApartments[apartmentId] = {
        citizenid = citizenid,
        apartment_name = apartmentKey,
        apartment_type = Config.Apartments[apartmentKey].type,
        bucket_id = bucketId,
        purchase_date = purchaseDate,
        expire_date = expireDate,
        purchase_type = 'admin'
    }

    -- Register stash
    local typeData = IMRP.GetApartmentTypeData(apartmentKey)
    local stashId = IMRP.GenerateStashId(apartmentId)
    exports.ox_inventory:RegisterStash(stashId, ('%s Stash'):format(Config.Apartments[apartmentKey].label), typeData.stash_slots, typeData.stash_weight)

    LogAction(citizenid, apartmentId, 'admin_give', ('By: %s'):format(GetPlayerName(source) or 'Console'))

    lib.notify(source, { title = 'Apartments', description = ('Gave %s to player %d'):format(apartmentKey, targetId), type = 'success' })
    lib.notify(targetId, { title = 'Apartments', description = ('You received %s from an admin'):format(Config.Apartments[apartmentKey].label), type = 'success' })
end)

-----------------------------------------------------------
-- /removeapartment [id] [apartment_name]
-----------------------------------------------------------
lib.addCommand('removeapartment', {
    help = 'Remove apartment from a player (Admin)',
    params = {
        { name = 'id', type = 'number', help = 'Player server ID' },
        { name = 'apartment', type = 'string', help = 'Apartment key name' }
    },
    restricted = 'group.admin'
}, function(source, args)
    if not HasAdminPermission(source) then
        lib.notify(source, { title = 'Apartments', description = 'No permission', type = 'error' })
        return
    end

    local targetId = args.id
    local apartmentKey = args.apartment

    local targetPlayer = QBX:GetPlayer(targetId)
    if not targetPlayer then
        lib.notify(source, { title = 'Apartments', description = 'Player not found', type = 'error' })
        return
    end

    local citizenid = targetPlayer.PlayerData.citizenid
    local isOwner, apartmentId = IsOwner(citizenid, apartmentKey)
    if not isOwner then
        lib.notify(source, { title = 'Apartments', description = 'Player does not own this apartment', type = 'error' })
        return
    end

    CleanupApartment(apartmentId)
    LogAction(citizenid, apartmentId, 'admin_remove', ('By: %s'):format(GetPlayerName(source) or 'Console'))

    lib.notify(source, { title = 'Apartments', description = ('Removed %s from player %d'):format(apartmentKey, targetId), type = 'success' })
    lib.notify(targetId, { title = 'Apartments', description = ('Your apartment %s has been removed by an admin'):format(Config.Apartments[apartmentKey].label), type = 'error' })
end)

-----------------------------------------------------------
-- /resetapartment [apartment_id]
-----------------------------------------------------------
lib.addCommand('resetapartment', {
    help = 'Reset an apartment by ID (Admin)',
    params = {
        { name = 'apartment_id', type = 'string', help = 'Apartment ID (e.g., integrity_way_1001)' }
    },
    restricted = 'group.admin'
}, function(source, args)
    if not HasAdminPermission(source) then
        lib.notify(source, { title = 'Apartments', description = 'No permission', type = 'error' })
        return
    end

    local apartmentId = args.apartment_id

    if not OwnedApartments[apartmentId] then
        lib.notify(source, { title = 'Apartments', description = 'Apartment ID not found', type = 'error' })
        return
    end

    local citizenid = OwnedApartments[apartmentId].citizenid
    CleanupApartment(apartmentId)
    LogAction(citizenid, apartmentId, 'admin_reset', ('By: %s'):format(GetPlayerName(source) or 'Console'))

    lib.notify(source, { title = 'Apartments', description = 'Apartment reset successfully', type = 'success' })
end)

-----------------------------------------------------------
-- /expireapartment [apartment_id]
-----------------------------------------------------------
lib.addCommand('expireapartment', {
    help = 'Force expire an apartment (Admin)',
    params = {
        { name = 'apartment_id', type = 'string', help = 'Apartment ID (e.g., integrity_way_1001)' }
    },
    restricted = 'group.admin'
}, function(source, args)
    if not HasAdminPermission(source) then
        lib.notify(source, { title = 'Apartments', description = 'No permission', type = 'error' })
        return
    end

    local apartmentId = args.apartment_id

    if not OwnedApartments[apartmentId] then
        lib.notify(source, { title = 'Apartments', description = 'Apartment ID not found', type = 'error' })
        return
    end

    local citizenid = OwnedApartments[apartmentId].citizenid

    -- Set expire to now
    MySQL.update('UPDATE apartments SET expire_date = NOW() WHERE apartment_id = ?', { apartmentId })
    OwnedApartments[apartmentId].expire_date = os.date('%Y-%m-%d %H:%M:%S')

    LogAction(citizenid, apartmentId, 'admin_expire', ('By: %s'):format(GetPlayerName(source) or 'Console'))

    lib.notify(source, { title = 'Apartments', description = 'Apartment expired successfully', type = 'success' })
end)

-----------------------------------------------------------
-- /apartmentlist
-----------------------------------------------------------
lib.addCommand('apartmentlist', {
    help = 'List all active apartments (Admin)',
    restricted = 'group.admin'
}, function(source)
    if not HasAdminPermission(source) then
        lib.notify(source, { title = 'Apartments', description = 'No permission', type = 'error' })
        return
    end

    local count = 0
    local msg = '--- Active Apartments ---\n'

    for id, data in pairs(OwnedApartments) do
        count = count + 1
        msg = msg .. ('%d. %s | Owner: %s | Bucket: %d | Expires: %s\n'):format(
            count, id, data.citizenid, data.bucket_id, data.expire_date
        )
    end

    if count == 0 then
        msg = 'No active apartments.'
    end

    -- Print to console for the admin
    print(msg)
    lib.notify(source, { title = 'Apartments', description = ('%d active apartments (see console)'):format(count), type = 'info' })
end)

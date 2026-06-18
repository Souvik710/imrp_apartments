-----------------------------------------------------------
-- IMRP Ambulance Job - Client Storage System
-- Ox Inventory Stashes with rank-based access
-----------------------------------------------------------

-----------------------------------------------------------
-- Storage Locations
-----------------------------------------------------------
local StoragePoints = {
    {
        id = 'ems_main_storage',
        label = 'EMS Main Storage',
        coords = vector3(303.07, -598.22, 43.28),
        permission = 'storage_main',
        npc = {
            model = 's_m_m_paramedic_01',
            coords = vector4(303.07, -598.22, 43.28, 250.0),
        },
        stash = {
            id = 'ems_main_storage',
            label = 'EMS Main Storage',
            slots = 100,
            weight = 500000,
        },
    },
    {
        id = 'ems_pharmacy_storage',
        label = 'Pharmacy Storage',
        coords = vector3(304.64, -601.03, 43.28),
        permission = 'storage_pharmacy',
        npc = {
            model = 's_f_y_scrubs_01',
            coords = vector4(304.64, -601.03, 43.28, 250.0),
        },
        stash = {
            id = 'ems_pharmacy_storage',
            label = 'Pharmacy Storage',
            slots = 50,
            weight = 200000,
        },
    },
    {
        id = 'ems_evidence_storage',
        label = 'Evidence Storage',
        coords = vector3(300.15, -597.72, 43.28),
        permission = 'storage_evidence',
        npc = {
            model = 's_m_m_paramedic_01',
            coords = vector4(300.15, -597.72, 43.28, 90.0),
        },
        stash = {
            id = 'ems_evidence_storage',
            label = 'Evidence Storage',
            slots = 30,
            weight = 100000,
        },
    },
}

-----------------------------------------------------------
-- Setup Storage Targets
-----------------------------------------------------------
CreateThread(function()
    Wait(3000)

    for _, storage in ipairs(StoragePoints) do
        -- Spawn NPC at storage point
        if storage.npc then
            SpawnNPC(storage.npc)
        end

        exports.ox_target:addSphereZone({
            coords = storage.coords,
            radius = 1.5,
            options = {
                {
                    name = storage.id,
                    label = storage.label,
                    icon = 'fa-solid fa-box-open',
                    onSelect = function()
                        OpenStorage(storage)
                    end,
                    canInteract = function()
                        if not EMSUtils.IsOnDuty() then return false end
                        return Ranks.HasPermission(EMSUtils.GetRank(), storage.permission)
                    end,
                },
            },
        })
    end
end)

-----------------------------------------------------------
-- Open Storage Stash
-----------------------------------------------------------
function OpenStorage(storage)
    if not EMSUtils.IsOnDuty() then
        EMSUtils.Notify('You must be on duty', 'error')
        return
    end

    if not Ranks.HasPermission(EMSUtils.GetRank(), storage.permission) then
        EMSUtils.Notify('Insufficient rank for this storage', 'error')
        return
    end

    exports.ox_inventory:openInventory('stash', {
        id = storage.stash.id,
        label = storage.stash.label,
        slots = storage.stash.slots,
        weight = storage.stash.weight,
    })
end

-----------------------------------------------------------
-- Personal Locker
-----------------------------------------------------------
local PersonalLocker = {
    coords = vector3(310.12, -594.35, 43.28),
    label = 'Personal Locker',
    permission = 'storage_personal',
    npc = {
        model = 's_f_y_scrubs_01',
        coords = vector4(310.12, -594.35, 43.28, 180.0),
    },
}

CreateThread(function()
    Wait(3000)

    -- Spawn NPC at personal locker
    if PersonalLocker.npc then
        SpawnNPC(PersonalLocker.npc)
    end

    exports.ox_target:addSphereZone({
        coords = PersonalLocker.coords,
        radius = 1.5,
        options = {
            {
                name = 'ems_personal_locker',
                label = PersonalLocker.label,
                icon = 'fa-solid fa-lock',
                onSelect = function()
                    OpenPersonalLocker()
                end,
                canInteract = function()
                    return EMSUtils.IsEMS()
                end,
            },
        },
    })
end)

function OpenPersonalLocker()
    local playerData = exports.qbx_core:GetPlayerData()
    if not playerData then return end

    local lockerId = 'ems_locker_' .. playerData.citizenid

    exports.ox_inventory:openInventory('stash', {
        id = lockerId,
        label = 'Personal Locker - ' .. playerData.charinfo.firstname,
        slots = 30,
        weight = 100000,
    })
end

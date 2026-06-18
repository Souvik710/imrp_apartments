-----------------------------------------------------------
-- IMRP Ambulance Job - Client Commands
-----------------------------------------------------------

-----------------------------------------------------------
-- /ems - Main EMS menu
-----------------------------------------------------------
RegisterCommand('ems', function()
    if not EMSUtils.IsEMS() then
        EMSUtils.Notify('You are not an EMS member', 'error')
        return
    end

    local options = {
        {
            title = 'Toggle Duty',
            description = isOnDuty and 'Go off duty' or 'Go on duty',
            icon = 'fa-solid fa-clipboard-check',
            onSelect = function()
                ToggleDuty()
            end,
        },
        {
            title = 'Open MDT',
            description = 'Access EMS MDT Tablet',
            icon = 'fa-solid fa-tablet-screen-button',
            onSelect = function()
                TriggerEvent('imrp_ambulancejob:client:openMDT')
            end,
        },
        {
            title = 'Status',
            description = 'View your EMS status',
            icon = 'fa-solid fa-id-card',
            onSelect = function()
                ShowEMSStatus()
            end,
        },
    }

    if EMSUtils.IsOnDuty() then
        table.insert(options, {
            title = 'EMS Garage',
            description = 'Spawn EMS vehicles',
            icon = 'fa-solid fa-truck-medical',
            onSelect = function()
                local closestGarage = GetClosestGarage()
                if closestGarage then
                    OpenGarageMenu(closestGarage)
                else
                    EMSUtils.Notify('No garage nearby', 'error')
                end
            end,
        })

        table.insert(options, {
            title = 'Radio',
            description = 'Join EMS radio channel',
            icon = 'fa-solid fa-walkie-talkie',
            onSelect = function()
                JoinEMSRadio()
            end,
        })
    end

    lib.registerContext({
        id = 'ems_main_menu',
        title = 'EMS Menu',
        options = options,
    })
    lib.showContext('ems_main_menu')
end, false)

-----------------------------------------------------------
-- /mdt - Open MDT
-----------------------------------------------------------
RegisterCommand('mdt', function()
    if not EMSUtils.IsEMS() then
        EMSUtils.Notify('You are not an EMS member', 'error')
        return
    end
    if not Ranks.HasPermission(EMSUtils.GetRank(), 'mdt_access') then
        EMSUtils.Notify('Insufficient rank for MDT access', 'error')
        return
    end
    TriggerEvent('imrp_ambulancejob:client:openMDT')
end, false)

-----------------------------------------------------------
-- /checkpulse - Check nearby player pulse
-----------------------------------------------------------
RegisterCommand('checkpulse', function()
    if not EMSUtils.IsOnDuty() then
        EMSUtils.Notify('You must be on duty', 'error')
        return
    end
    local coords = GetEntityCoords(PlayerPedId())
    local closestPlayer = EMSUtils.GetClosestPlayer(coords, 3.0)
    if closestPlayer then
        PerformCheckPulse(closestPlayer)
    else
        EMSUtils.Notify('No patient nearby', 'error')
    end
end, false)

-----------------------------------------------------------
-- /checkbp - Check blood pressure
-----------------------------------------------------------
RegisterCommand('checkbp', function()
    if not EMSUtils.IsOnDuty() then
        EMSUtils.Notify('You must be on duty', 'error')
        return
    end
    local coords = GetEntityCoords(PlayerPedId())
    local closestPlayer = EMSUtils.GetClosestPlayer(coords, 3.0)
    if closestPlayer then
        PerformCheckBP(closestPlayer)
    else
        EMSUtils.Notify('No patient nearby', 'error')
    end
end, false)

-----------------------------------------------------------
-- /cpr - Perform CPR
-----------------------------------------------------------
RegisterCommand('cpr', function()
    if not EMSUtils.IsOnDuty() then
        EMSUtils.Notify('You must be on duty', 'error')
        return
    end
    local coords = GetEntityCoords(PlayerPedId())
    local closestPlayer = EMSUtils.GetClosestPlayer(coords, 3.0)
    if closestPlayer then
        PerformCPR(closestPlayer)
    else
        EMSUtils.Notify('No patient nearby', 'error')
    end
end, false)

-----------------------------------------------------------
-- /stretcher - Deploy stretcher
-----------------------------------------------------------
RegisterCommand('stretcher', function()
    if not EMSUtils.IsOnDuty() then
        EMSUtils.Notify('You must be on duty', 'error')
        return
    end
    DeployProp('stretcher')
end, false)

-----------------------------------------------------------
-- /wheelchair - Deploy wheelchair
-----------------------------------------------------------
RegisterCommand('wheelchair', function()
    DeployProp('wheelchair')
end, false)

-----------------------------------------------------------
-- /crutch - Use crutches
-----------------------------------------------------------
RegisterCommand('crutch', function()
    UseCrutches()
end, false)

-----------------------------------------------------------
-- /bodybag - Place body bag
-----------------------------------------------------------
RegisterCommand('bodybag', function()
    if not EMSUtils.IsOnDuty() then
        EMSUtils.Notify('You must be on duty', 'error')
        return
    end
    DeployProp('bodybag')
end, false)

-----------------------------------------------------------
-- Deploy Prop Helper
-----------------------------------------------------------
local deployedProps = {}

function DeployProp(propType)
    local propModel = Config.Props[propType]
    if not propModel then return end

    local modelHash = joaat(propModel)
    lib.requestModel(modelHash)

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local forward = GetEntityForwardVector(ped)

    local spawnCoords = coords + forward * 1.5
    local prop = CreateObject(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, true, false, false)
    SetEntityHeading(prop, heading)
    PlaceObjectOnGroundProperly(prop)

    table.insert(deployedProps, prop)
    EMSUtils.Notify(propType:sub(1, 1):upper() .. propType:sub(2) .. ' deployed', 'success')
end

-----------------------------------------------------------
-- Crutches
-----------------------------------------------------------
local usingCrutches = false

function UseCrutches()
    usingCrutches = not usingCrutches

    if usingCrutches then
        local ped = PlayerPedId()
        lib.requestAnimDict('move_m@drunk@moderatedrunk')
        SetPedMovementClipset(ped, 'move_m@drunk@moderatedrunk', 0.25)
        SetPedMoveRateOverride(ped, 0.7)
        EMSUtils.Notify('Using crutches', 'info')
    else
        local ped = PlayerPedId()
        ResetPedMovementClipset(ped, 0.25)
        SetPedMoveRateOverride(ped, 1.0)
        EMSUtils.Notify('Stopped using crutches', 'info')
    end
end

-----------------------------------------------------------
-- EMS Status Display
-----------------------------------------------------------
function ShowEMSStatus()
    local grade = EMSUtils.GetRank()
    local rankLabel = Ranks.GetLabel(grade)

    lib.alertDialog({
        header = 'EMS Status',
        content = string.format(
            '**Name:** %s\n**Rank:** %s (Grade %d)\n**Status:** %s\n**Callsign:** N/A',
            GetPlayerName(PlayerId()),
            rankLabel,
            grade,
            isOnDuty and 'On Duty' or 'Off Duty'
        ),
        centered = true,
    })
end

-----------------------------------------------------------
-- Radio Helper
-----------------------------------------------------------
function JoinEMSRadio()
    exports['pma-voice']:setRadioChannel(Config.RadioChannel)
    EMSUtils.Notify('Joined EMS Radio Channel ' .. Config.RadioChannel, 'success')
end

-----------------------------------------------------------
-- Get Closest Garage
-----------------------------------------------------------
function GetClosestGarage()
    local coords = GetEntityCoords(PlayerPedId())
    local closest = nil
    local closestDist = 50.0

    for i, garage in ipairs(EMSVehicles.Garages) do
        local dist = #(coords - garage.coords)
        if dist < closestDist then
            closestDist = dist
            closest = i
        end
    end

    return closest
end

-----------------------------------------------------------
-- Cleanup Props
-----------------------------------------------------------
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for _, prop in ipairs(deployedProps) do
            if DoesEntityExist(prop) then
                DeleteEntity(prop)
            end
        end
        deployedProps = {}

        if usingCrutches then
            local ped = PlayerPedId()
            ResetPedMovementClipset(ped, 0.0)
            SetPedMoveRateOverride(ped, 1.0)
        end
    end
end)

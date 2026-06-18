-----------------------------------------------------------
-- IMRP Ambulance Job - Client Death System
-- Last Stand, Unconscious, Dead states + Respawn
-----------------------------------------------------------

local deathState = 'alive' -- alive, laststand, unconscious, dead
local deathTimer = 0
local respawnTimer = 0
local distressSignalCooldown = 0
local deathThread = false
local crawlEnabled = false

-----------------------------------------------------------
-- Death State Machine
-----------------------------------------------------------
function GetDeathState()
    return deathState
end

exports('GetDeathState', GetDeathState)
exports('IsDead', function() return deathState ~= 'alive' end)

-----------------------------------------------------------
-- Enter Death State
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:client:enterDeathState', function(reason)
    if deathState ~= 'alive' then return end

    deathState = 'laststand'
    deathTimer = Config.DeathSystem.lastStandDuration

    local ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetEntityInvincible(ped, true)

    EMSUtils.Notify('You are critically injured! EMS can save you.', 'error', 10000)

    SendNUIMessage({
        action = 'showDeathScreen',
        state = 'laststand',
        timer = deathTimer,
        reason = reason or 'injuries',
    })

    TriggerServerEvent('imrp_ambulancejob:server:playerDowned', reason)
    StartDeathThread()
end)

-----------------------------------------------------------
-- Monitor ped death natively
-----------------------------------------------------------
CreateThread(function()
    while true do
        Wait(500)
        local ped = PlayerPedId()
        if IsEntityDead(ped) and deathState == 'alive' then
            TriggerEvent('imrp_ambulancejob:client:enterDeathState', 'death')
        end
    end
end)

-----------------------------------------------------------
-- Death Thread
-----------------------------------------------------------
function StartDeathThread()
    if deathThread then return end
    deathThread = true

    CreateThread(function()
        while deathThread do
            Wait(1000)

            local ped = PlayerPedId()

            if deathState == 'laststand' then
                deathTimer = deathTimer - 1

                -- Crawl while downed
                if crawlEnabled then
                    DisableAllControlActions(0)
                    EnableControlAction(0, 32, true)  -- W
                    EnableControlAction(0, 33, true)  -- S
                    EnableControlAction(0, 34, true)  -- A
                    EnableControlAction(0, 35, true)  -- D
                    SetPedMoveRateOverride(ped, Config.DeathSystem.crawlSpeed)
                end

                -- Distress signal
                if IsControlJustPressed(0, 47) then -- G key
                    SendDistressSignal()
                end

                SendNUIMessage({
                    action = 'updateDeathTimer',
                    timer = deathTimer,
                    state = 'laststand',
                })

                if deathTimer <= 0 then
                    EnterUnconsciousState()
                end

            elseif deathState == 'unconscious' then
                deathTimer = deathTimer - 1

                DisableAllControlActions(0)

                SendNUIMessage({
                    action = 'updateDeathTimer',
                    timer = deathTimer,
                    state = 'unconscious',
                })

                if deathTimer <= 0 then
                    EnterDeadState()
                end

            elseif deathState == 'dead' then
                respawnTimer = respawnTimer - 1

                DisableAllControlActions(0)

                if respawnTimer <= 0 then
                    EnableControlAction(0, 38, true) -- E key for respawn
                end

                SendNUIMessage({
                    action = 'updateDeathTimer',
                    timer = math.max(respawnTimer, 0),
                    state = 'dead',
                    canRespawn = respawnTimer <= 0,
                })

                if respawnTimer <= 0 and IsControlJustPressed(0, 38) then
                    OpenRespawnMenu()
                end
            end

            -- Update cooldowns
            if distressSignalCooldown > 0 then
                distressSignalCooldown = distressSignalCooldown - 1
            end
        end
    end)

    -- Animation thread
    CreateThread(function()
        while deathThread do
            Wait(0)
            local ped = PlayerPedId()

            if deathState == 'laststand' then
                if not IsEntityPlayingAnim(ped, 'combat@damage@writhe', 'writhe_loop', 3) then
                    lib.requestAnimDict('combat@damage@writhe')
                    TaskPlayAnim(ped, 'combat@damage@writhe', 'writhe_loop', 8.0, 8.0, -1, 1, 0, false, false, false)
                end
            elseif deathState == 'unconscious' or deathState == 'dead' then
                if not IsEntityPlayingAnim(ped, 'dead', 'dead_a', 3) then
                    lib.requestAnimDict('dead')
                    TaskPlayAnim(ped, 'dead', 'dead_a', 8.0, 8.0, -1, 1, 0, false, false, false)
                end
            end
        end
    end)
end

-----------------------------------------------------------
-- State Transitions
-----------------------------------------------------------
function EnterUnconsciousState()
    deathState = 'unconscious'
    deathTimer = Config.DeathSystem.unconsciousDuration
    crawlEnabled = false

    local ped = PlayerPedId()
    ClearPedTasks(ped)

    EMSUtils.Notify('You are unconscious. Only EMS can save you now.', 'error', 10000)
    TriggerServerEvent('imrp_ambulancejob:server:playerUnconcious')
end

function EnterDeadState()
    deathState = 'dead'
    respawnTimer = Config.DeathSystem.respawnTimer

    EMSUtils.Notify('You have died. Wait for respawn or EMS.', 'error', 10000)
    TriggerServerEvent('imrp_ambulancejob:server:playerDead')
end

-----------------------------------------------------------
-- Distress Signal
-----------------------------------------------------------
function SendDistressSignal()
    if not Config.DeathSystem.allowDistressSignal then return end
    if distressSignalCooldown > 0 then
        EMSUtils.Notify(string.format('Distress signal on cooldown (%ds)', distressSignalCooldown), 'error')
        return
    end

    distressSignalCooldown = Config.DeathSystem.distressSignalCooldown
    local coords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('imrp_ambulancejob:server:distressSignal', coords)
    EMSUtils.Notify('Distress signal sent to EMS!', 'success')
end

-----------------------------------------------------------
-- Toggle Crawl
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:client:toggleCrawl', function()
    if deathState == 'laststand' then
        crawlEnabled = not crawlEnabled
        EMSUtils.Notify(crawlEnabled and 'Crawling enabled' or 'Crawling disabled', 'info')
    end
end)

-----------------------------------------------------------
-- Respawn Menu
-----------------------------------------------------------
function OpenRespawnMenu()
    local options = {}

    for _, loc in ipairs(Hospitals.RespawnLocations) do
        table.insert(options, {
            title = loc.label,
            description = string.format('Respawn here (Cost: %s)', EMSUtils.FormatMoney(Config.DeathSystem.deathPenalty)),
            icon = 'fa-solid fa-hospital',
            onSelect = function()
                RespawnAtLocation(loc)
            end,
        })
    end

    table.insert(options, {
        title = 'Respawn at Morgue',
        description = 'Respawn at the city morgue (no cost)',
        icon = 'fa-solid fa-skull',
        onSelect = function()
            RespawnAtMorgue()
        end,
    })

    lib.registerContext({
        id = 'respawn_menu',
        title = 'Respawn Options',
        options = options,
    })
    lib.showContext('respawn_menu')
end

-----------------------------------------------------------
-- Respawn at Hospital
-----------------------------------------------------------
function RespawnAtLocation(location)
    TriggerServerEvent('imrp_ambulancejob:server:respawn', 'hospital')

    local ped = PlayerPedId()
    DoScreenFadeOut(1000)
    Wait(1500)

    SetEntityInvincible(ped, false)
    SetEntityCoords(ped, location.coords.x, location.coords.y, location.coords.z, false, false, false, true)
    SetEntityHeading(ped, location.heading)
    NetworkResurrectLocalPlayer(location.coords.x, location.coords.y, location.coords.z, location.heading, true, false)

    ClearDeathState()

    Wait(500)
    DoScreenFadeIn(1000)

    TriggerEvent('imrp_ambulancejob:client:healAll')
    EMSUtils.Notify('You have been treated at ' .. location.label, 'success')
end

-----------------------------------------------------------
-- Respawn at Morgue
-----------------------------------------------------------
function RespawnAtMorgue()
    TriggerServerEvent('imrp_ambulancejob:server:respawn', 'morgue')

    local ped = PlayerPedId()
    local morgue = Hospitals.Morgue

    DoScreenFadeOut(1000)
    Wait(1500)

    SetEntityInvincible(ped, false)
    SetEntityCoords(ped, morgue.coords.x, morgue.coords.y, morgue.coords.z, false, false, false, true)
    SetEntityHeading(ped, morgue.heading)
    NetworkResurrectLocalPlayer(morgue.coords.x, morgue.coords.y, morgue.coords.z, morgue.heading, true, false)

    ClearDeathState()

    Wait(500)
    DoScreenFadeIn(1000)

    TriggerEvent('imrp_ambulancejob:client:healAll')
    EMSUtils.Notify('You woke up at the morgue...', 'info')
end

-----------------------------------------------------------
-- EMS Revive
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:client:emsRevive', function()
    local ped = PlayerPedId()

    DoScreenFadeOut(500)
    Wait(1000)

    SetEntityInvincible(ped, false)
    NetworkResurrectLocalPlayer(
        GetEntityCoords(ped).x,
        GetEntityCoords(ped).y,
        GetEntityCoords(ped).z,
        GetEntityHeading(ped),
        true, false
    )

    ClearDeathState()

    Wait(500)
    DoScreenFadeIn(500)

    EMSUtils.Notify('You have been revived by EMS', 'success')
end)

-----------------------------------------------------------
-- Clear Death State
-----------------------------------------------------------
function ClearDeathState()
    deathState = 'alive'
    deathTimer = 0
    respawnTimer = 0
    deathThread = false
    crawlEnabled = false

    local ped = PlayerPedId()
    ClearPedTasks(ped)
    SetEntityInvincible(ped, false)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
    ResetPedMovementClipset(ped, 0.0)
    SetPedMoveRateOverride(ped, 1.0)

    SendNUIMessage({
        action = 'hideDeathScreen',
    })
end

-----------------------------------------------------------
-- Cleanup
-----------------------------------------------------------
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if deathState ~= 'alive' then
            ClearDeathState()
        end
    end
end)

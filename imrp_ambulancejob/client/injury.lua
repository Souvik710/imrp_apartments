-----------------------------------------------------------
-- IMRP Ambulance Job - Client Injury System
-- Advanced injury tracking with body zones, bleeding, pain
-----------------------------------------------------------

local playerInjuries = {}
local playerBleedLevel = 0
local playerPainLevel = 0
local playerBloodLevel = 100
local brokenBones = {}
local hasBullets = {}
local injuryThread = false
local bleedThread = false
local lastHealth = 200

-----------------------------------------------------------
-- Initialize injury state
-----------------------------------------------------------
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    ResetInjuries()
    StartInjuryMonitor()
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        ResetInjuries()
        StartInjuryMonitor()
    end
end)

-----------------------------------------------------------
-- Reset all injuries
-----------------------------------------------------------
function ResetInjuries()
    playerInjuries = {}
    playerBleedLevel = 0
    playerPainLevel = 0
    playerBloodLevel = 100
    brokenBones = {}
    hasBullets = {}
    lastHealth = GetEntityHealth(PlayerPedId())
end

-----------------------------------------------------------
-- Injury Monitor Thread
-----------------------------------------------------------
function StartInjuryMonitor()
    if injuryThread then return end
    injuryThread = true

    CreateThread(function()
        while injuryThread do
            local ped = PlayerPedId()
            local currentHealth = GetEntityHealth(ped)

            if currentHealth < lastHealth and currentHealth > 0 then
                local damage = lastHealth - currentHealth
                ProcessDamage(ped, damage)
            end

            lastHealth = currentHealth
            Wait(Config.InjuryCheckInterval)
        end
    end)
end

-----------------------------------------------------------
-- Process incoming damage
-----------------------------------------------------------
function ProcessDamage(ped, damage)
    local cause = DetermineDamageCause(ped)
    local zone = DetermineDamageZone(ped)

    local injuryType = Injuries.Types[zone]
    local injuryCause = Injuries.Causes[cause]

    if not injuryType or not injuryCause then return end

    local severity = math.min(damage * injuryType.severity_multiplier, 100)
    local painIncrease = injuryType.pain_base * injuryCause.pain_modifier * (severity / 50)

    local injury = {
        zone = zone,
        cause = cause,
        severity = severity,
        label = injuryCause.label,
        zone_label = injuryType.label,
        timestamp = GetGameTimer(),
        treated = false,
    }

    table.insert(playerInjuries, injury)

    -- Bleeding
    if injuryCause.bleed_level > 0 or math.random() < injuryType.bleed_chance then
        local newBleed = math.max(injuryCause.bleed_level, 1)
        playerBleedLevel = math.min(playerBleedLevel + newBleed, Config.InjurySystem.maxBleedLevel)
        StartBleedThread()
    end

    -- Pain
    playerPainLevel = math.min(playerPainLevel + painIncrease, Config.InjurySystem.maxPainLevel)

    -- Broken bones
    if injuryCause.bone_break_chance and math.random() < injuryCause.bone_break_chance then
        if not brokenBones[zone] then
            brokenBones[zone] = true
            EMSUtils.Notify('You feel a bone break in your ' .. injuryType.label:lower(), 'error')
        end
    end

    -- Bullets
    if injuryCause.requires_extraction then
        table.insert(hasBullets, { zone = zone, timestamp = GetGameTimer() })
    end

    ApplyInjuryEffects()
    SyncInjuriesToServer()

    if Config.Debug then
        print(string.format('[INJURY] Zone: %s | Cause: %s | Severity: %.1f | Bleed: %d | Pain: %.1f',
            zone, cause, severity, playerBleedLevel, playerPainLevel))
    end
end

-----------------------------------------------------------
-- Determine damage cause from weapon/context
-----------------------------------------------------------
function DetermineDamageCause(ped)
    local _, weaponHash = GetPedLastWeaponImpactCoord(ped)

    if HasPedBeenDamagedByWeapon(ped, 0, 2) then
        return 'melee'
    end

    if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        if GetEntitySpeed(vehicle) > 10.0 then
            return 'vehicle_crash'
        end
    end

    if IsPedFalling(ped) or GetPedLastDamageBone(ped) then
        local fallHeight = GetEntityHeightAboveGround(ped)
        if fallHeight > 3.0 then
            return 'fall'
        end
    end

    if HasPedBeenDamagedByWeapon(ped, 0, 1) then
        return 'bullet'
    end

    local _, boneIdx = GetPedLastDamageBone(ped)
    if boneIdx then
        return 'melee'
    end

    return 'melee'
end

-----------------------------------------------------------
-- Determine damage zone from bone
-----------------------------------------------------------
function DetermineDamageZone(ped)
    local hit, boneIdx = GetPedLastDamageBone(ped)

    if hit and boneIdx then
        local zone = Injuries.DamageZones[boneIdx]
        if zone then return zone end
    end

    local zones = { 'head', 'chest', 'arm_left', 'arm_right', 'leg_left', 'leg_right', 'torso' }
    return zones[math.random(#zones)]
end

-----------------------------------------------------------
-- Bleed Thread
-----------------------------------------------------------
function StartBleedThread()
    if bleedThread then return end
    bleedThread = true

    CreateThread(function()
        while bleedThread and playerBleedLevel > 0 do
            Wait(Config.InjurySystem.bleedTickInterval)

            if playerBleedLevel > 0 then
                local bloodLoss = Config.InjurySystem.bloodLossRate * playerBleedLevel
                playerBloodLevel = math.max(playerBloodLevel - bloodLoss, 0)

                if playerBloodLevel <= 0 then
                    TriggerEvent('imrp_ambulancejob:client:enterDeathState', 'bleedout')
                    bleedThread = false
                    return
                end

                if playerBloodLevel <= Config.InjurySystem.criticalBloodLevel then
                    EMSUtils.Notify('Critical blood loss! You need medical attention!', 'error')
                end

                ApplyInjuryEffects()
            end
        end
        bleedThread = false
    end)
end

-----------------------------------------------------------
-- Apply visual/gameplay effects based on injuries
-----------------------------------------------------------
function ApplyInjuryEffects()
    if not Config.DeathSystem.enableScreenEffects then return end

    local ped = PlayerPedId()

    -- Pain effects
    if playerPainLevel >= Config.InjurySystem.painEffectThreshold then
        local intensity = playerPainLevel / Config.InjurySystem.maxPainLevel

        if intensity > 0.7 then
            SetPedMotionBlur(ped, true)
            AnimpostfxPlay('DrugsMichaelAliensFight', 0, false)
        elseif intensity > 0.4 then
            AnimpostfxPlay('DrugsDrivingIn', 0, false)
        end
    else
        SetPedMotionBlur(ped, false)
        AnimpostfxStop('DrugsMichaelAliensFight')
        AnimpostfxStop('DrugsDrivingIn')
    end

    -- Blood loss effects
    if playerBloodLevel < 50 then
        local bloodIntensity = 1.0 - (playerBloodLevel / 50)
        SetPedMoveRateOverride(ped, math.max(0.5, 1.0 - (bloodIntensity * 0.5)))

        if playerBloodLevel < 30 then
            AnimpostfxPlay('Dying', 0, false)
        end
    else
        AnimpostfxStop('Dying')
    end

    -- Broken leg effects
    if brokenBones['leg_left'] or brokenBones['leg_right'] then
        SetPedMoveRateOverride(ped, 0.4)
        if not IsPedRagdoll(ped) and math.random() < 0.1 then
            SetPedToRagdoll(ped, 1000, 1000, 0, false, false, false)
        end
    end

    -- Broken arm effects
    if brokenBones['arm_left'] or brokenBones['arm_right'] then
        DisablePlayerFiring(PlayerId(), true)
    end
end

-----------------------------------------------------------
-- Sync injuries to server
-----------------------------------------------------------
function SyncInjuriesToServer()
    local data = {
        injuries = playerInjuries,
        bleedLevel = playerBleedLevel,
        painLevel = playerPainLevel,
        bloodLevel = playerBloodLevel,
        brokenBones = brokenBones,
        bullets = hasBullets,
    }
    TriggerServerEvent('imrp_ambulancejob:server:syncInjuries', data)
end

-----------------------------------------------------------
-- Treatment: Reduce bleed
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:client:reduceBleed', function(amount)
    playerBleedLevel = math.max(playerBleedLevel - amount, 0)
    if playerBleedLevel == 0 then
        bleedThread = false
    end
    ApplyInjuryEffects()
    EMSUtils.Notify('Bleeding reduced', 'success')
end)

-----------------------------------------------------------
-- Treatment: Reduce pain
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:client:reducePain', function(amount)
    playerPainLevel = math.max(playerPainLevel - amount, 0)
    ApplyInjuryEffects()
    EMSUtils.Notify('Pain reduced', 'success')
end)

-----------------------------------------------------------
-- Treatment: Restore blood
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:client:restoreBlood', function(amount)
    playerBloodLevel = math.min(playerBloodLevel + amount, Config.InjurySystem.maxBlood)
    ApplyInjuryEffects()
    EMSUtils.Notify('Blood level restored', 'success')
end)

-----------------------------------------------------------
-- Treatment: Fix broken bone
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:client:fixBone', function(zone)
    brokenBones[zone] = nil
    ApplyInjuryEffects()
    EMSUtils.Notify('Broken bone treated: ' .. (Injuries.Types[zone] and Injuries.Types[zone].label or zone), 'success')
end)

-----------------------------------------------------------
-- Treatment: Remove bullet
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:client:removeBullet', function(index)
    if hasBullets[index] then
        table.remove(hasBullets, index)
        EMSUtils.Notify('Bullet removed', 'success')
    end
end)

-----------------------------------------------------------
-- Treatment: Heal all (NPC doctor / full treatment)
-----------------------------------------------------------
RegisterNetEvent('imrp_ambulancejob:client:healAll', function()
    ResetInjuries()
    local ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
    ResetPedMovementClipset(ped, 0.0)
    SetPedMotionBlur(ped, false)
    AnimpostfxStop('DrugsMichaelAliensFight')
    AnimpostfxStop('DrugsDrivingIn')
    AnimpostfxStop('Dying')
    SetPedMoveRateOverride(ped, 1.0)
    EMSUtils.Notify('All injuries healed', 'success')
    SyncInjuriesToServer()
end)

-----------------------------------------------------------
-- Get injury data (for EMS inspection)
-----------------------------------------------------------
function GetPlayerInjuryData()
    return {
        injuries = playerInjuries,
        bleedLevel = playerBleedLevel,
        painLevel = playerPainLevel,
        bloodLevel = playerBloodLevel,
        brokenBones = brokenBones,
        bullets = hasBullets,
    }
end

exports('GetPlayerInjuryData', GetPlayerInjuryData)

-----------------------------------------------------------
-- Cleanup
-----------------------------------------------------------
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        injuryThread = false
        bleedThread = false
        local ped = PlayerPedId()
        SetPedMotionBlur(ped, false)
        AnimpostfxStop('DrugsMichaelAliensFight')
        AnimpostfxStop('DrugsDrivingIn')
        AnimpostfxStop('Dying')
        SetPedMoveRateOverride(ped, 1.0)
        ResetPedMovementClipset(ped, 0.0)
    end
end)

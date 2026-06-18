Config = {}

-----------------------------------------------------------
-- Framework & Dependencies
-----------------------------------------------------------
Config.Framework = 'qbx'
Config.UseOxInventory = true
Config.UseOxTarget = true
Config.UseOxLib = true

-----------------------------------------------------------
-- Debug Mode
-----------------------------------------------------------
Config.Debug = false

-----------------------------------------------------------
-- EMS Job Name (must match qbx_core job)
-----------------------------------------------------------
Config.JobName = 'ambulance'

-----------------------------------------------------------
-- Economy
-----------------------------------------------------------
Config.BankPayment = true
Config.DefaultCurrency = 'bank'

-----------------------------------------------------------
-- Death System
-----------------------------------------------------------
Config.DeathSystem = {
    lastStandDuration = 60,           -- seconds in last stand
    unconsciousDuration = 300,        -- seconds unconscious before dead
    respawnTimer = 300,               -- seconds before respawn available
    crawlSpeed = 0.5,                 -- movement speed while downed
    deathPenalty = 500,               -- money lost on hospital respawn
    allowDistressSignal = true,
    distressSignalCooldown = 30,      -- seconds between signals
    enableScreenEffects = true,
    bleedoutEnabled = true,
    bleedoutRate = 15,                -- seconds per bleed tick
}

-----------------------------------------------------------
-- Injury System
-----------------------------------------------------------
Config.InjurySystem = {
    maxBleedLevel = 5,
    bleedTickInterval = 10000,        -- ms between bleed ticks
    painEffectThreshold = 30,         -- pain level to start effects
    maxPainLevel = 100,
    bloodLossRate = 2,                -- per bleed tick per level
    maxBlood = 100,
    criticalBloodLevel = 30,
    autoHealThreshold = 10,           -- minor injuries below this auto-heal
    autoHealTime = 300,               -- seconds for minor auto-heal
}

-----------------------------------------------------------
-- Treatment Settings
-----------------------------------------------------------
Config.Treatment = {
    checkPulseTime = 3000,            -- ms
    checkBPTime = 3000,
    checkOxygenTime = 3000,
    diagnoseTime = 5000,
    removeBulletTime = 8000,
    stopBleedingTime = 5000,
    applyBandageTime = 4000,
    cprTime = 10000,
    defibrillatorTime = 8000,
    splintTime = 6000,
    administerMedicineTime = 3000,
    requiredMinRank = 0,              -- minimum rank index for basic treatment
}

-----------------------------------------------------------
-- Minigame Difficulty
-----------------------------------------------------------
Config.Minigames = {
    cpr = { keys = 5, speed = 1500 },
    surgery = { keys = 8, speed = 1200 },
    bulletExtraction = { keys = 6, speed = 1400 },
    stabilization = { keys = 4, speed = 1600 },
    defibrillator = { keys = 3, speed = 1000 },
}

-----------------------------------------------------------
-- Insurance System
-----------------------------------------------------------
Config.Insurance = {
    enabled = true,
    basicPrice = 5000,
    premiumPrice = 15000,
    vipPrice = 50000,
    basicDiscount = 25,               -- percentage
    premiumDiscount = 50,
    vipDiscount = 90,
    duration = 30,                    -- days
}

-----------------------------------------------------------
-- Hospital Billing
-----------------------------------------------------------
Config.Billing = {
    treatmentCost = 200,
    surgeryCost = 1000,
    icuCost = 500,
    pharmacyCost = 100,
    npcDoctorCost = 350,
    reviveCost = 500,
}

-----------------------------------------------------------
-- Hospital Bed System
-----------------------------------------------------------
Config.BedSystem = {
    healRate = 5,                     -- health per tick
    healInterval = 5000,              -- ms between heal ticks
    maxBeds = 10,
    icuBeds = 4,
}

-----------------------------------------------------------
-- Pharmacy Items
-----------------------------------------------------------
Config.Pharmacy = {
    { item = 'painkillers', label = 'Painkillers', price = 100, description = 'Reduces pain level' },
    { item = 'morphine', label = 'Morphine', price = 250, description = 'Strong painkiller' },
    { item = 'antibiotics', label = 'Antibiotics', price = 150, description = 'Prevents infection' },
    { item = 'adrenaline', label = 'Adrenaline Shot', price = 300, description = 'Emergency stimulant' },
    { item = 'blood_bag', label = 'Blood Bag', price = 500, description = 'Restores blood level' },
    { item = 'saline', label = 'Saline IV', price = 200, description = 'Hydration therapy' },
}

-----------------------------------------------------------
-- NPC Doctor
-----------------------------------------------------------
Config.NPCDoctor = {
    enabled = true,
    healAll = true,
    cost = 350,
    waitTime = 10000,                 -- ms
}

-----------------------------------------------------------
-- Performance
-----------------------------------------------------------
Config.UpdateInterval = 1000
Config.InjuryCheckInterval = 5000

-----------------------------------------------------------
-- Admin Permissions
-----------------------------------------------------------
Config.AdminPermissions = {
    'admin',
    'god'
}

-----------------------------------------------------------
-- Notification Settings
-----------------------------------------------------------
Config.Notification = {
    position = 'top-right',
    style = 'default'
}

-----------------------------------------------------------
-- Blip Settings
-----------------------------------------------------------
Config.HospitalBlip = {
    enabled = true,
    sprite = 61,
    color = 1,
    scale = 0.8,
    label = 'Pillbox Hill Medical Center'
}

Config.EMSBlip = {
    enabled = true,
    sprite = 153,
    color = 1,
    scale = 0.7
}

-----------------------------------------------------------
-- Duty Location
-----------------------------------------------------------
Config.DutyLocations = {
    {
        coords = vector3(311.69, -593.36, 43.28),
        label = 'EMS Clock In/Out',
        heading = 332.5
    }
}

-----------------------------------------------------------
-- EMS Cloakroom
-----------------------------------------------------------
Config.Cloakroom = {
    coords = vector3(309.52, -596.14, 43.28),
    label = 'EMS Locker Room',
}

-----------------------------------------------------------
-- Boss Menu Location
-----------------------------------------------------------
Config.BossMenu = {
    coords = vector3(307.21, -599.72, 43.28),
    label = 'EMS Management',
    minRank = 7,  -- Captain+
}

-----------------------------------------------------------
-- Stretcher / Wheelchair Settings
-----------------------------------------------------------
Config.Props = {
    stretcher = 'prop_ld_binbag_01',
    wheelchair = 'prop_wheelchair_01_s',
    bodybag = 'prop_bodybag_01',
    crutch = 'prop_cs_walking_stick',
}

-----------------------------------------------------------
-- Voice Radio Channel (pma-voice)
-----------------------------------------------------------
Config.RadioChannel = 2

-----------------------------------------------------------
-- Max EMS on Duty
-----------------------------------------------------------
Config.MaxOnDuty = 20

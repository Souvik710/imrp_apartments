local Utils = require 'shared.utils'

Config = {}

-- General Settings
Config.Framework = 'qbx_core'
Config.UseTarget = true

-- Apartment Configurations
Config.Apartments = {
    ['apartment_1'] = Utils.CreateApartment({
        name     = 'Vespucci Beach Apartment',
        price    = 50000,
        entrance = vector3(-1100.0, -1600.0, 4.0),
        blip     = { color = 2 },
    }),
    ['apartment_2'] = Utils.CreateApartment({
        name     = 'Del Perro Heights',
        price    = 75000,
        entrance = vector3(-1450.0, -550.0, 34.0),
        blip     = { color = 3 },
    }),
    ['apartment_3'] = Utils.CreateApartment({
        name         = 'Richards Majestic',
        price        = 100000,
        entrance     = vector3(-850.0, -1300.0, 5.0),
        stash_slots  = 70,
        stash_weight = 15000,
        blip         = { color = 4 },
    }),
}

-- NPC Configuration
Config.NPC = {
    model = 's_m_m_highsec_01',
    coords = vector4(-1100.0, -1600.0, 5.0, 180.0),
    label = 'Apartment Manager'
}

-- Admin Settings
Config.AdminPermissions = {
    'admin',
    'god'
}

-- Notification Settings
Config.Notification = {
    position = 'top-right',
    style = 'default'
}

-- Economy Settings
Config.BankPayment = true
Config.DefaultCurrency = 'cash'

-- Performance Settings
Config.UpdateInterval = 60000
Config.MaxApartmentsPerPlayer = 5

-- Appearance System
Config.AppearanceSystem = 'illenium-appearance'
Config.EnableWardrobe = true
Config.WardrobeOutfitLimit = 20

-- Locale Settings
Config.Locale = 'en'

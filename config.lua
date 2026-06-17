Config = {}

-- General Settings
Config.Framework = 'qbx_core'
Config.UseTarget = true

-- Apartment Configurations
Config.Apartments = {
    ['apartment_1'] = {
        name = 'Vespucci Beach Apartment',
        label = 'Vespucci Beach Apartment',
        price = 50000,
        rental_days = 7,
        rental_price = 5000,
        location = {
            entrance = vector3(-1100.0, -1600.0, 4.0),
            interior = vector3(-1100.0, -1600.0, 100.0),
            exit = vector3(-1100.0, -1600.0, 4.0),
            stash = vector3(-1100.5, -1600.5, 100.0),
            wardrobe = vector3(-1101.0, -1601.0, 100.0)
        },
        stash_slots = 50,
        stash_weight = 10000,
        blip = {
            enabled = true,
            sprite = 40,
            color = 2,
            scale = 0.7,
            label = 'Apartment'
        }
    },
    ['apartment_2'] = {
        name = 'Del Perro Heights',
        label = 'Del Perro Heights',
        price = 75000,
        rental_days = 7,
        rental_price = 7500,
        location = {
            entrance = vector3(-1450.0, -550.0, 34.0),
            interior = vector3(-1450.0, -550.0, 100.0),
            exit = vector3(-1450.0, -550.0, 34.0),
            stash = vector3(-1450.5, -550.5, 100.0),
            wardrobe = vector3(-1451.0, -551.0, 100.0)
        },
        stash_slots = 50,
        stash_weight = 10000,
        blip = {
            enabled = true,
            sprite = 40,
            color = 3,
            scale = 0.7,
            label = 'Apartment'
        }
    },
    ['apartment_3'] = {
        name = 'Richards Majestic',
        label = 'Richards Majestic',
        price = 100000,
        rental_days = 7,
        rental_price = 10000,
        location = {
            entrance = vector3(-850.0, -1300.0, 5.0),
            interior = vector3(-850.0, -1300.0, 100.0),
            exit = vector3(-850.0, -1300.0, 5.0),
            stash = vector3(-850.5, -1300.5, 100.0),
            wardrobe = vector3(-851.0, -1301.0, 100.0)
        },
        stash_slots = 70,
        stash_weight = 15000,
        blip = {
            enabled = true,
            sprite = 40,
            color = 4,
            scale = 0.7,
            label = 'Apartment'
        }
    }
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

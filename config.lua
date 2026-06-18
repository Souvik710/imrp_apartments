Config = {}

-----------------------------------------------------------
-- Framework & Dependencies
-----------------------------------------------------------
Config.Framework = 'qbx'
Config.UseOxInventory = true
Config.UseOxTarget = true
Config.UseOxLib = true
Config.UseRoutingBuckets = true
Config.UseGarage = true
Config.UseWardrobe = true
Config.UseKeys = true
Config.UseGuestSystem = true

-----------------------------------------------------------
-- Interior System: 'qbx' or 'motel'
-----------------------------------------------------------
Config.InteriorSystem = 'qbx'

-----------------------------------------------------------
-- Appearance System
-- Options: 'illenium-appearance', 'fivem-appearance', 'qb-clothing'
-----------------------------------------------------------
Config.AppearanceSystem = 'illenium-appearance'
Config.WardrobeOutfitLimit = 20

-----------------------------------------------------------
-- Economy
-----------------------------------------------------------
Config.BankPayment = true
Config.DefaultCurrency = 'bank'
Config.SellRefundPercent = 80

-----------------------------------------------------------
-- Apartment Limits & Expiry
-----------------------------------------------------------
Config.MaxApartments = 1
Config.ApartmentDuration = 7 -- days
Config.ClearStashOnExpire = true
Config.ExpiryCheckInterval = 1800000 -- 30 minutes in ms

-----------------------------------------------------------
-- Routing Bucket Settings
-----------------------------------------------------------
Config.BucketStart = 1001
Config.BucketPopulation = false
Config.BucketLockdown = 'strict'

-----------------------------------------------------------
-- Stash Defaults
-----------------------------------------------------------
Config.DefaultStashSlots = 75
Config.DefaultStashWeight = 150000

-----------------------------------------------------------
-- Performance
-----------------------------------------------------------
Config.UpdateInterval = 60000
Config.Debug = false -- NEVER enable in production; exposes internal state to console

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
Config.Blip = {
    enabled = true,
    sprite = 475,
    color = 3,
    scale = 0.7
}

-----------------------------------------------------------
-- NPC Configuration (Apartment Manager)
-----------------------------------------------------------
Config.NPCs = {
    {
        model = 's_m_m_highsec_01',
        coords = vector4(-1100.0, -1600.0, 5.0, 180.0),
        label = 'Apartment Manager'
    }
}

-----------------------------------------------------------
-- Apartment Types
-----------------------------------------------------------
Config.ApartmentTypes = {
    ['basic'] = {
        label = 'Basic Apartment',
        price = 25000,
        rental_price = 5000,
        stash_slots = 50,
        stash_weight = 100000,
        garage_slots = 1,
        interior = 'basic_interior'
    },
    ['modern'] = {
        label = 'Modern Apartment',
        price = 50000,
        rental_price = 10000,
        stash_slots = 75,
        stash_weight = 150000,
        garage_slots = 2,
        interior = 'modern_interior'
    },
    ['deluxe'] = {
        label = 'Deluxe Apartment',
        price = 75000,
        rental_price = 15000,
        stash_slots = 100,
        stash_weight = 200000,
        garage_slots = 3,
        interior = 'deluxe_interior'
    },
    ['luxury'] = {
        label = 'Luxury Apartment',
        price = 100000,
        rental_price = 20000,
        stash_slots = 125,
        stash_weight = 250000,
        garage_slots = 4,
        interior = 'luxury_interior'
    },
    ['penthouse'] = {
        label = 'Penthouse',
        price = 250000,
        rental_price = 50000,
        stash_slots = 150,
        stash_weight = 300000,
        garage_slots = 5,
        interior = 'penthouse_interior'
    },
    ['motel'] = {
        label = 'Motel Room',
        price = 15000,
        rental_price = 3000,
        stash_slots = 30,
        stash_weight = 50000,
        garage_slots = 1,
        interior = 'motel_interior'
    }
}

-----------------------------------------------------------
-- Apartment Locations (entrance coords)
-----------------------------------------------------------
Config.Apartments = {
    ['integrity_way'] = {
        label = 'Integrity Way',
        type = 'modern',
        entrance = vector3(-47.52, -585.93, 37.95),
        heading = 70.0,
        interior_coords = vector3(-18.07, -583.6, 90.11),
        interior_heading = 70.0,
        stash_offset = vector3(1.5, 1.0, 0.0),
        wardrobe_offset = vector3(-2.0, 3.0, 0.0),
        garage_spawn = vector4(-60.0, -600.0, 37.0, 70.0),
        blip_label = 'Integrity Way Apartments'
    },
    ['del_perro_heights'] = {
        label = 'Del Perro Heights',
        type = 'luxury',
        entrance = vector3(-1447.06, -537.69, 34.74),
        heading = 210.0,
        interior_coords = vector3(-1452.18, -540.78, 74.04),
        interior_heading = 35.0,
        stash_offset = vector3(2.0, -1.0, 0.0),
        wardrobe_offset = vector3(-1.5, 2.5, 0.0),
        garage_spawn = vector4(-1440.0, -530.0, 34.0, 210.0),
        blip_label = 'Del Perro Heights'
    },
    ['richards_majestic'] = {
        label = 'Richards Majestic',
        type = 'deluxe',
        entrance = vector3(-912.55, -365.57, 114.27),
        heading = 120.0,
        interior_coords = vector3(-915.0, -370.0, 150.0),
        interior_heading = 120.0,
        stash_offset = vector3(1.0, 2.0, 0.0),
        wardrobe_offset = vector3(-1.0, 3.0, 0.0),
        garage_spawn = vector4(-920.0, -360.0, 114.0, 120.0),
        blip_label = 'Richards Majestic'
    },
    ['vespucci_beach'] = {
        label = 'Vespucci Beach Apartment',
        type = 'basic',
        entrance = vector3(-1100.0, -1600.0, 4.0),
        heading = 180.0,
        interior_coords = vector3(-1100.0, -1600.0, 100.0),
        interior_heading = 180.0,
        stash_offset = vector3(0.5, 1.5, 0.0),
        wardrobe_offset = vector3(-1.5, 2.0, 0.0),
        garage_spawn = vector4(-1095.0, -1595.0, 4.0, 180.0),
        blip_label = 'Vespucci Beach Apartments'
    },
    ['south_rockford'] = {
        label = 'South Rockford Drive',
        type = 'penthouse',
        entrance = vector3(-667.02, -1082.25, 15.31),
        heading = 0.0,
        interior_coords = vector3(-670.0, -1085.0, 90.0),
        interior_heading = 0.0,
        stash_offset = vector3(2.0, 0.0, 0.0),
        wardrobe_offset = vector3(-2.0, 1.0, 0.0),
        garage_spawn = vector4(-665.0, -1080.0, 15.0, 0.0),
        blip_label = 'South Rockford Penthouse'
    },
    ['pink_cage_motel'] = {
        label = 'Pink Cage Motel',
        type = 'motel',
        entrance = vector3(324.21, -224.74, 54.22),
        heading = 160.0,
        interior_coords = vector3(325.0, -225.0, 100.0),
        interior_heading = 160.0,
        stash_offset = vector3(0.5, 0.5, 0.0),
        wardrobe_offset = vector3(-1.0, 1.0, 0.0),
        garage_spawn = vector4(330.0, -220.0, 54.0, 160.0),
        blip_label = 'Pink Cage Motel'
    }
}

-----------------------------------------------------------
-- Interiors (qbx_interiors compatible)
-----------------------------------------------------------
Config.Interiors = {
    ['basic_interior'] = {
        ipl = nil,
        shell = 'shell_basic_apartment',
        offset = vector3(0.0, 0.0, 0.0)
    },
    ['modern_interior'] = {
        ipl = nil,
        shell = 'shell_modern_apartment',
        offset = vector3(0.0, 0.0, 0.0)
    },
    ['deluxe_interior'] = {
        ipl = nil,
        shell = 'shell_deluxe_apartment',
        offset = vector3(0.0, 0.0, 0.0)
    },
    ['luxury_interior'] = {
        ipl = nil,
        shell = 'shell_luxury_apartment',
        offset = vector3(0.0, 0.0, 0.0)
    },
    ['penthouse_interior'] = {
        ipl = nil,
        shell = 'shell_penthouse',
        offset = vector3(0.0, 0.0, 0.0)
    },
    ['motel_interior'] = {
        ipl = nil,
        shell = 'shell_motel_room',
        offset = vector3(0.0, 0.0, 0.0)
    }
}

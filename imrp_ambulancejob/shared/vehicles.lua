-----------------------------------------------------------
-- EMS Vehicle System
-----------------------------------------------------------

EMSVehicles = {}

EMSVehicles.List = {
    ambulance = {
        label = 'Ambulance',
        model = 'ambulance',
        category = 'ground',
        min_rank = 0,
        livery = 0,
        extras = { 1, 2 },
        fuel = 100.0,
        price = 0,
    },
    ems_suv = {
        label = 'EMS SUV',
        model = 'fbi2',
        category = 'ground',
        min_rank = 2,
        livery = 0,
        extras = {},
        fuel = 100.0,
        price = 0,
    },
    ems_bike = {
        label = 'EMS Bike',
        model = 'policeb',
        category = 'ground',
        min_rank = 1,
        livery = 0,
        extras = {},
        fuel = 100.0,
        price = 0,
    },
    ems_helicopter = {
        label = 'EMS Helicopter',
        model = 'polmav',
        category = 'air',
        min_rank = 4,
        livery = 0,
        extras = {},
        fuel = 100.0,
        price = 0,
    },
}

-----------------------------------------------------------
-- Garage Locations
-----------------------------------------------------------
EMSVehicles.Garages = {
    {
        label = 'Pillbox EMS Garage',
        coords = vector3(294.41, -587.54, 43.18),
        heading = 160.0,
        spawn = vector4(296.52, -590.52, 43.18, 160.0),
        type = 'ground',
        blip = {
            sprite = 357,
            color = 1,
            scale = 0.6,
        },
        npc = {
            model = 's_m_y_xmech_02',
            coords = vector4(294.41, -587.54, 43.18, 340.0),
        },
    },
    {
        label = 'Pillbox Helipad',
        coords = vector3(351.69, -587.56, 74.16),
        heading = 160.0,
        spawn = vector4(351.69, -587.56, 74.16, 160.0),
        type = 'air',
        blip = {
            sprite = 360,
            color = 1,
            scale = 0.6,
        },
        npc = {
            model = 's_m_y_xmech_02',
            coords = vector4(351.69, -587.56, 74.16, 340.0),
        },
    },
}

-----------------------------------------------------------
-- Impound Location
-----------------------------------------------------------
EMSVehicles.Impound = {
    coords = vector3(409.98, -1623.09, 29.29),
    heading = 230.0,
    price = 250,
}

-----------------------------------------------------------
-- Livery Options
-----------------------------------------------------------
EMSVehicles.Liveries = {
    { label = 'Default', index = 0 },
    { label = 'IMRP EMS', index = 1 },
    { label = 'Paramedic', index = 2 },
    { label = 'Chief', index = 3 },
}

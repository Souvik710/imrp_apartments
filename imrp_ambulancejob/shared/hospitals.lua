-----------------------------------------------------------
-- Hospital Locations & Configuration
-----------------------------------------------------------

Hospitals = {}

Hospitals.Locations = {
    pillbox = {
        label = 'Pillbox Hill Medical Center',
        blip = {
            coords = vector3(311.69, -593.36, 43.28),
            sprite = 61,
            color = 1,
            scale = 0.8,
        },
        reception = {
            coords = vector3(308.19, -595.21, 43.28),
            heading = 340.0,
            npc = {
                model = 's_f_y_scrubs_01',
                coords = vector4(308.19, -595.21, 43.28, 160.0),
                label = 'Hospital Reception',
            },
        },
        npc_doctor = {
            coords = vector4(313.67, -592.25, 43.28, 60.0),
            model = 's_m_m_doctor_01',
            label = 'NPC Doctor',
        },
        beds = {
            { coords = vector3(310.53, -581.37, 43.28), heading = 0.0, occupied = false },
            { coords = vector3(313.37, -581.37, 43.28), heading = 0.0, occupied = false },
            { coords = vector3(316.21, -581.37, 43.28), heading = 0.0, occupied = false },
            { coords = vector3(319.05, -581.37, 43.28), heading = 0.0, occupied = false },
            { coords = vector3(321.89, -581.37, 43.28), heading = 0.0, occupied = false },
            { coords = vector3(310.53, -578.53, 43.28), heading = 180.0, occupied = false },
            { coords = vector3(313.37, -578.53, 43.28), heading = 180.0, occupied = false },
            { coords = vector3(316.21, -578.53, 43.28), heading = 180.0, occupied = false },
            { coords = vector3(319.05, -578.53, 43.28), heading = 180.0, occupied = false },
            { coords = vector3(321.89, -578.53, 43.28), heading = 180.0, occupied = false },
        },
        icu = {
            { coords = vector3(326.5, -584.3, 43.28), heading = 90.0, occupied = false },
            { coords = vector3(326.5, -587.3, 43.28), heading = 90.0, occupied = false },
            { coords = vector3(326.5, -590.3, 43.28), heading = 90.0, occupied = false },
            { coords = vector3(326.5, -593.3, 43.28), heading = 90.0, occupied = false },
        },
        surgery_room = {
            coords = vector3(330.0, -584.3, 43.28),
            heading = 90.0,
            label = 'Surgery Room',
        },
        pharmacy = {
            coords = vector3(305.64, -600.03, 43.28),
            heading = 250.0,
            npc = {
                model = 's_f_y_scrubs_01',
                coords = vector4(305.64, -600.03, 43.28, 70.0),
                label = 'Pharmacy',
            },
        },
        morgue = {
            coords = vector3(275.73, -1361.46, 24.54),
            heading = 50.0,
            label = 'City Morgue',
            respawn = vector3(275.73, -1361.46, 24.54),
        },
        respawn = {
            coords = vector3(311.69, -593.36, 43.28),
            heading = 332.5,
        },
        checkin = {
            coords = vector3(308.19, -595.21, 43.28),
            label = 'Check In',
        },
    },
}

-----------------------------------------------------------
-- Respawn Locations
-----------------------------------------------------------
Hospitals.RespawnLocations = {
    {
        label = 'Pillbox Hill Medical Center',
        coords = vector3(311.69, -593.36, 43.28),
        heading = 332.5,
    },
    {
        label = 'Mount Zonah Medical Center',
        coords = vector3(-449.67, -340.83, 34.50),
        heading = 270.0,
    },
    {
        label = 'Sandy Shores Medical Center',
        coords = vector3(1839.62, 3672.93, 34.28),
        heading = 210.0,
    },
    {
        label = 'Paleto Bay Medical Center',
        coords = vector3(-247.76, 6331.23, 32.43),
        heading = 225.0,
    },
}

-----------------------------------------------------------
-- Morgue Location
-----------------------------------------------------------
Hospitals.Morgue = {
    coords = vector3(275.73, -1361.46, 24.54),
    heading = 50.0,
    label = 'City Morgue',
}

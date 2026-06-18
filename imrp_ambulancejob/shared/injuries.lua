-----------------------------------------------------------
-- Injury Definitions
-----------------------------------------------------------

Injuries = {}

Injuries.Types = {
    head = {
        label = 'Head Injury',
        icon = 'fa-head-side-virus',
        severity_multiplier = 2.0,
        pain_base = 30,
        bleed_chance = 0.6,
        effects = { 'screen_blur', 'camera_shake' },
    },
    chest = {
        label = 'Chest Injury',
        icon = 'fa-lungs',
        severity_multiplier = 1.8,
        pain_base = 25,
        bleed_chance = 0.5,
        effects = { 'breathing_difficulty' },
    },
    arm_left = {
        label = 'Left Arm Injury',
        icon = 'fa-hand',
        severity_multiplier = 1.0,
        pain_base = 15,
        bleed_chance = 0.4,
        effects = { 'aim_penalty' },
    },
    arm_right = {
        label = 'Right Arm Injury',
        icon = 'fa-hand',
        severity_multiplier = 1.0,
        pain_base = 15,
        bleed_chance = 0.4,
        effects = { 'aim_penalty' },
    },
    leg_left = {
        label = 'Left Leg Injury',
        icon = 'fa-shoe-prints',
        severity_multiplier = 1.2,
        pain_base = 20,
        bleed_chance = 0.4,
        effects = { 'limp', 'speed_reduction' },
    },
    leg_right = {
        label = 'Right Leg Injury',
        icon = 'fa-shoe-prints',
        severity_multiplier = 1.2,
        pain_base = 20,
        bleed_chance = 0.4,
        effects = { 'limp', 'speed_reduction' },
    },
    torso = {
        label = 'Torso Injury',
        icon = 'fa-shirt',
        severity_multiplier = 1.5,
        pain_base = 20,
        bleed_chance = 0.5,
        effects = {},
    },
}

-----------------------------------------------------------
-- Injury Causes
-----------------------------------------------------------
Injuries.Causes = {
    bullet = {
        label = 'Bullet Wound',
        base_damage = 35,
        bleed_level = 3,
        requires_extraction = true,
        pain_modifier = 1.5,
    },
    burn = {
        label = 'Burn',
        base_damage = 20,
        bleed_level = 0,
        requires_extraction = false,
        pain_modifier = 2.0,
    },
    vehicle_crash = {
        label = 'Vehicle Crash Trauma',
        base_damage = 30,
        bleed_level = 2,
        requires_extraction = false,
        pain_modifier = 1.3,
        bone_break_chance = 0.4,
    },
    fall = {
        label = 'Fall Damage',
        base_damage = 25,
        bleed_level = 1,
        requires_extraction = false,
        pain_modifier = 1.2,
        bone_break_chance = 0.6,
    },
    melee = {
        label = 'Blunt Force Trauma',
        base_damage = 15,
        bleed_level = 1,
        requires_extraction = false,
        pain_modifier = 1.0,
        bone_break_chance = 0.2,
    },
    stab = {
        label = 'Stab Wound',
        base_damage = 25,
        bleed_level = 3,
        requires_extraction = false,
        pain_modifier = 1.4,
    },
    explosion = {
        label = 'Explosion Trauma',
        base_damage = 40,
        bleed_level = 4,
        requires_extraction = false,
        pain_modifier = 1.8,
        bone_break_chance = 0.5,
    },
}

-----------------------------------------------------------
-- Bleed Level Descriptions
-----------------------------------------------------------
Injuries.BleedLevels = {
    [1] = { label = 'Minor Bleeding', rate = 1, color = '#ffcc00' },
    [2] = { label = 'Light Bleeding', rate = 2, color = '#ff9900' },
    [3] = { label = 'Moderate Bleeding', rate = 3, color = '#ff6600' },
    [4] = { label = 'Heavy Bleeding', rate = 5, color = '#ff3300' },
    [5] = { label = 'Severe Bleeding', rate = 8, color = '#cc0000' },
}

-----------------------------------------------------------
-- Bone Groups (for fractures)
-----------------------------------------------------------
Injuries.BoneGroups = {
    head = { 'SKEL_Head' },
    chest = { 'SKEL_Spine3', 'SKEL_Spine2' },
    arm_left = { 'SKEL_L_UpperArm', 'SKEL_L_Forearm', 'SKEL_L_Hand' },
    arm_right = { 'SKEL_R_UpperArm', 'SKEL_R_Forearm', 'SKEL_R_Hand' },
    leg_left = { 'SKEL_L_Thigh', 'SKEL_L_Calf', 'SKEL_L_Foot' },
    leg_right = { 'SKEL_R_Thigh', 'SKEL_R_Calf', 'SKEL_R_Foot' },
    torso = { 'SKEL_Spine1', 'SKEL_Spine0', 'SKEL_Pelvis' },
}

-----------------------------------------------------------
-- Damage Zone Mapping (GTA bone to injury zone)
-----------------------------------------------------------
Injuries.DamageZones = {
    [31086] = 'head',       -- SKEL_Head
    [39317] = 'chest',      -- SKEL_Spine3
    [57597] = 'chest',      -- SKEL_Spine2
    [24818] = 'torso',      -- SKEL_Spine1
    [11816] = 'torso',      -- SKEL_Spine0
    [45509] = 'arm_left',   -- SKEL_L_UpperArm
    [61163] = 'arm_left',   -- SKEL_L_Forearm
    [18905] = 'arm_left',   -- SKEL_L_Hand
    [40269] = 'arm_right',  -- SKEL_R_UpperArm
    [28252] = 'arm_right',  -- SKEL_R_Forearm
    [57005] = 'arm_right',  -- SKEL_R_Hand
    [51826] = 'leg_left',   -- SKEL_L_Thigh
    [14201] = 'leg_left',   -- SKEL_L_Calf
    [52301] = 'leg_left',   -- SKEL_L_Foot
    [58271] = 'leg_right',  -- SKEL_R_Thigh
    [36864] = 'leg_right',  -- SKEL_R_Calf
    [20781] = 'leg_right',  -- SKEL_R_Foot
}

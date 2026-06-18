-----------------------------------------------------------
-- EMS Rank System
-----------------------------------------------------------

Ranks = {}

Ranks.List = {
    [0] = {
        name = 'trainee_emt',
        label = 'Trainee EMT',
        salary = 500,
        permissions = {
            billing = false,
            mdt_access = true,
            mdt_edit = false,
            garage_access = true,
            pharmacy_access = false,
            staff_management = false,
            boss_menu = false,
            storage_main = true,
            storage_pharmacy = false,
            storage_evidence = false,
            storage_personal = true,
            impound = false,
            helicopter = false,
        },
    },
    [1] = {
        name = 'emt',
        label = 'EMT',
        salary = 750,
        permissions = {
            billing = true,
            mdt_access = true,
            mdt_edit = false,
            garage_access = true,
            pharmacy_access = true,
            staff_management = false,
            boss_menu = false,
            storage_main = true,
            storage_pharmacy = true,
            storage_evidence = false,
            storage_personal = true,
            impound = false,
            helicopter = false,
        },
    },
    [2] = {
        name = 'advanced_emt',
        label = 'Advanced EMT',
        salary = 1000,
        permissions = {
            billing = true,
            mdt_access = true,
            mdt_edit = true,
            garage_access = true,
            pharmacy_access = true,
            staff_management = false,
            boss_menu = false,
            storage_main = true,
            storage_pharmacy = true,
            storage_evidence = false,
            storage_personal = true,
            impound = false,
            helicopter = false,
        },
    },
    [3] = {
        name = 'paramedic',
        label = 'Paramedic',
        salary = 1250,
        permissions = {
            billing = true,
            mdt_access = true,
            mdt_edit = true,
            garage_access = true,
            pharmacy_access = true,
            staff_management = false,
            boss_menu = false,
            storage_main = true,
            storage_pharmacy = true,
            storage_evidence = true,
            storage_personal = true,
            impound = true,
            helicopter = false,
        },
    },
    [4] = {
        name = 'senior_paramedic',
        label = 'Senior Paramedic',
        salary = 1500,
        permissions = {
            billing = true,
            mdt_access = true,
            mdt_edit = true,
            garage_access = true,
            pharmacy_access = true,
            staff_management = false,
            boss_menu = false,
            storage_main = true,
            storage_pharmacy = true,
            storage_evidence = true,
            storage_personal = true,
            impound = true,
            helicopter = true,
        },
    },
    [5] = {
        name = 'fto',
        label = 'Field Training Officer',
        salary = 1750,
        permissions = {
            billing = true,
            mdt_access = true,
            mdt_edit = true,
            garage_access = true,
            pharmacy_access = true,
            staff_management = false,
            boss_menu = false,
            storage_main = true,
            storage_pharmacy = true,
            storage_evidence = true,
            storage_personal = true,
            impound = true,
            helicopter = true,
        },
    },
    [6] = {
        name = 'lieutenant',
        label = 'Lieutenant',
        salary = 2000,
        permissions = {
            billing = true,
            mdt_access = true,
            mdt_edit = true,
            garage_access = true,
            pharmacy_access = true,
            staff_management = true,
            boss_menu = false,
            storage_main = true,
            storage_pharmacy = true,
            storage_evidence = true,
            storage_personal = true,
            impound = true,
            helicopter = true,
        },
    },
    [7] = {
        name = 'captain',
        label = 'Captain',
        salary = 2500,
        permissions = {
            billing = true,
            mdt_access = true,
            mdt_edit = true,
            garage_access = true,
            pharmacy_access = true,
            staff_management = true,
            boss_menu = true,
            storage_main = true,
            storage_pharmacy = true,
            storage_evidence = true,
            storage_personal = true,
            impound = true,
            helicopter = true,
        },
    },
    [8] = {
        name = 'deputy_chief',
        label = 'Deputy Chief',
        salary = 3000,
        permissions = {
            billing = true,
            mdt_access = true,
            mdt_edit = true,
            garage_access = true,
            pharmacy_access = true,
            staff_management = true,
            boss_menu = true,
            storage_main = true,
            storage_pharmacy = true,
            storage_evidence = true,
            storage_personal = true,
            impound = true,
            helicopter = true,
        },
    },
    [9] = {
        name = 'ems_chief',
        label = 'EMS Chief',
        salary = 4000,
        permissions = {
            billing = true,
            mdt_access = true,
            mdt_edit = true,
            garage_access = true,
            pharmacy_access = true,
            staff_management = true,
            boss_menu = true,
            storage_main = true,
            storage_pharmacy = true,
            storage_evidence = true,
            storage_personal = true,
            impound = true,
            helicopter = true,
        },
    },
}

-----------------------------------------------------------
-- Helper: Get rank data by grade
-----------------------------------------------------------
function Ranks.GetByGrade(grade)
    return Ranks.List[grade] or Ranks.List[0]
end

-----------------------------------------------------------
-- Helper: Check permission
-----------------------------------------------------------
function Ranks.HasPermission(grade, permission)
    local rank = Ranks.GetByGrade(grade)
    if not rank or not rank.permissions then return false end
    return rank.permissions[permission] == true
end

-----------------------------------------------------------
-- Helper: Get rank label
-----------------------------------------------------------
function Ranks.GetLabel(grade)
    local rank = Ranks.GetByGrade(grade)
    return rank and rank.label or 'Unknown'
end

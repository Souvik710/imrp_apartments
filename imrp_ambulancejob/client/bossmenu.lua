-----------------------------------------------------------
-- IMRP Ambulance Job - Client Boss Menu
-- Hire, Fire, Promote, Demote, Society, Salary, Logs
-----------------------------------------------------------

-----------------------------------------------------------
-- Boss Menu Target
-----------------------------------------------------------
CreateThread(function()
    Wait(3000)
    exports.ox_target:addSphereZone({
        coords = Config.BossMenu.coords,
        radius = 1.5,
        options = {
            {
                name = 'ems_boss_menu',
                label = Config.BossMenu.label,
                icon = 'fa-solid fa-briefcase',
                onSelect = function()
                    OpenBossMenu()
                end,
                canInteract = function()
                    if not EMSUtils.IsOnDuty() then return false end
                    return Ranks.HasPermission(EMSUtils.GetRank(), 'boss_menu')
                end,
            },
        },
    })
end)

-----------------------------------------------------------
-- Open Boss Menu
-----------------------------------------------------------
function OpenBossMenu()
    if not Ranks.HasPermission(EMSUtils.GetRank(), 'boss_menu') then
        EMSUtils.Notify('Insufficient rank for boss menu', 'error')
        return
    end

    local options = {
        {
            title = 'Employee Management',
            description = 'Hire, fire, promote, demote staff',
            icon = 'fa-solid fa-users-gear',
            onSelect = function()
                OpenEmployeeManagement()
            end,
        },
        {
            title = 'Society Account',
            description = 'View and manage society finances',
            icon = 'fa-solid fa-building-columns',
            onSelect = function()
                OpenSocietyAccount()
            end,
        },
        {
            title = 'Salary Management',
            description = 'View and adjust employee salaries',
            icon = 'fa-solid fa-money-check-dollar',
            onSelect = function()
                OpenSalaryManagement()
            end,
        },
        {
            title = 'Employee Logs',
            description = 'View duty and action logs',
            icon = 'fa-solid fa-clipboard-list',
            onSelect = function()
                OpenEmployeeLogs()
            end,
        },
        {
            title = 'Open MDT',
            description = 'Open the EMS MDT Tablet',
            icon = 'fa-solid fa-tablet-screen-button',
            onSelect = function()
                TriggerEvent('imrp_ambulancejob:client:openMDT')
            end,
        },
    }

    lib.registerContext({
        id = 'ems_boss_menu',
        title = 'EMS Management',
        options = options,
    })
    lib.showContext('ems_boss_menu')
end

-----------------------------------------------------------
-- Employee Management
-----------------------------------------------------------
function OpenEmployeeManagement()
    lib.callback('imrp_ambulancejob:server:getEmployees', false, function(employees)
        if not employees or #employees == 0 then
            EMSUtils.Notify('No employees found', 'info')
            return
        end

        local options = {}
        for _, emp in ipairs(employees) do
            table.insert(options, {
                title = emp.name,
                description = string.format('Rank: %s (Grade %d)', emp.rank_label, emp.grade),
                icon = 'fa-solid fa-user',
                onSelect = function()
                    OpenEmployeeActions(emp)
                end,
            })
        end

        -- Hire option
        table.insert(options, 1, {
            title = '➕ Hire New Employee',
            description = 'Hire a nearby player',
            icon = 'fa-solid fa-user-plus',
            onSelect = function()
                HireEmployee()
            end,
        })

        lib.registerContext({
            id = 'ems_employee_list',
            title = 'Employee Management',
            menu = 'ems_boss_menu',
            options = options,
        })
        lib.showContext('ems_employee_list')
    end)
end

-----------------------------------------------------------
-- Employee Actions (Promote/Demote/Fire)
-----------------------------------------------------------
function OpenEmployeeActions(employee)
    local options = {
        {
            title = 'Promote',
            description = string.format('Current: %s → Next: %s', employee.rank_label, Ranks.GetLabel(employee.grade + 1)),
            icon = 'fa-solid fa-arrow-up',
            disabled = employee.grade >= 9,
            onSelect = function()
                TriggerServerEvent('imrp_ambulancejob:server:promoteEmployee', employee.citizenid)
            end,
        },
        {
            title = 'Demote',
            description = string.format('Current: %s → Next: %s', employee.rank_label, Ranks.GetLabel(math.max(0, employee.grade - 1))),
            icon = 'fa-solid fa-arrow-down',
            disabled = employee.grade <= 0,
            onSelect = function()
                TriggerServerEvent('imrp_ambulancejob:server:demoteEmployee', employee.citizenid)
            end,
        },
        {
            title = 'Fire Employee',
            description = 'Remove from EMS',
            icon = 'fa-solid fa-user-xmark',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = 'Confirm Termination',
                    content = 'Are you sure you want to fire **' .. employee.name .. '**?',
                    centered = true,
                    cancel = true,
                })
                if confirm == 'confirm' then
                    TriggerServerEvent('imrp_ambulancejob:server:fireEmployee', employee.citizenid)
                end
            end,
        },
        {
            title = 'Set Callsign',
            description = 'Assign a callsign',
            icon = 'fa-solid fa-id-badge',
            onSelect = function()
                local input = lib.inputDialog('Set Callsign', {
                    { type = 'input', label = 'Callsign', placeholder = 'E-01', max = 10 },
                })
                if input and input[1] then
                    TriggerServerEvent('imrp_ambulancejob:server:setCallsign', employee.citizenid, input[1])
                end
            end,
        },
    }

    lib.registerContext({
        id = 'ems_employee_actions',
        title = employee.name .. ' - Actions',
        menu = 'ems_employee_list',
        options = options,
    })
    lib.showContext('ems_employee_actions')
end

-----------------------------------------------------------
-- Hire Employee
-----------------------------------------------------------
function HireEmployee()
    local coords = GetEntityCoords(PlayerPedId())
    local closestPlayer, dist = EMSUtils.GetClosestPlayer(coords, 5.0)

    if not closestPlayer then
        EMSUtils.Notify('No player nearby to hire', 'error')
        return
    end

    local confirm = lib.alertDialog({
        header = 'Hire Employee',
        content = 'Hire nearby player (ID: ' .. closestPlayer .. ') as Trainee EMT?',
        centered = true,
        cancel = true,
    })

    if confirm == 'confirm' then
        TriggerServerEvent('imrp_ambulancejob:server:hireEmployee', closestPlayer)
    end
end

-----------------------------------------------------------
-- Society Account
-----------------------------------------------------------
function OpenSocietyAccount()
    lib.callback('imrp_ambulancejob:server:getSocietyBalance', false, function(balance)
        local options = {
            {
                title = 'Balance: ' .. EMSUtils.FormatMoney(balance or 0),
                icon = 'fa-solid fa-wallet',
                disabled = true,
            },
            {
                title = 'Deposit',
                description = 'Deposit money into society account',
                icon = 'fa-solid fa-arrow-down',
                onSelect = function()
                    local input = lib.inputDialog('Deposit', {
                        { type = 'number', label = 'Amount', min = 1 },
                    })
                    if input and input[1] then
                        TriggerServerEvent('imrp_ambulancejob:server:societyDeposit', input[1])
                    end
                end,
            },
            {
                title = 'Withdraw',
                description = 'Withdraw money from society account',
                icon = 'fa-solid fa-arrow-up',
                onSelect = function()
                    local input = lib.inputDialog('Withdraw', {
                        { type = 'number', label = 'Amount', min = 1 },
                    })
                    if input and input[1] then
                        TriggerServerEvent('imrp_ambulancejob:server:societyWithdraw', input[1])
                    end
                end,
            },
        }

        lib.registerContext({
            id = 'ems_society_account',
            title = 'EMS Society Account',
            menu = 'ems_boss_menu',
            options = options,
        })
        lib.showContext('ems_society_account')
    end)
end

-----------------------------------------------------------
-- Salary Management
-----------------------------------------------------------
function OpenSalaryManagement()
    local options = {}
    for grade, rank in pairs(Ranks.List) do
        table.insert(options, {
            title = rank.label,
            description = string.format('Salary: %s', EMSUtils.FormatMoney(rank.salary)),
            icon = 'fa-solid fa-money-bill',
            disabled = true,
        })
    end

    lib.registerContext({
        id = 'ems_salary_menu',
        title = 'Salary Overview',
        menu = 'ems_boss_menu',
        options = options,
    })
    lib.showContext('ems_salary_menu')
end

-----------------------------------------------------------
-- Employee Logs
-----------------------------------------------------------
function OpenEmployeeLogs()
    lib.callback('imrp_ambulancejob:server:getEmployeeLogs', false, function(logs)
        if not logs or #logs == 0 then
            EMSUtils.Notify('No logs found', 'info')
            return
        end

        local options = {}
        for _, log in ipairs(logs) do
            table.insert(options, {
                title = log.name .. ' - ' .. log.action,
                description = log.details or 'No details',
                icon = 'fa-solid fa-clock',
                disabled = true,
            })
        end

        lib.registerContext({
            id = 'ems_logs_menu',
            title = 'Employee Logs (Recent)',
            menu = 'ems_boss_menu',
            options = options,
        })
        lib.showContext('ems_logs_menu')
    end)
end

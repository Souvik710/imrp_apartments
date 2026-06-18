-----------------------------------------------------------
-- IMRP Apartments - Shared Utilities
-- Author: Ragna | Immortal Roleplay
-----------------------------------------------------------

IMRP = IMRP or {}

-----------------------------------------------------------
-- Locale System
-----------------------------------------------------------
local Locales = {}

function IMRP.LoadLocale(lang)
    local file = LoadResourceFile(GetCurrentResourceName(), ('locales/%s.lua'):format(lang or 'en'))
    if file then
        local fn = load(file)
        if fn then
            fn()
        end
    end
end

function IMRP.SetLocales(data)
    Locales = data or {}
end

function IMRP.Locale(key, ...)
    local str = Locales[key]
    if not str then return key end
    if ... then
        return str:format(...)
    end
    return str
end

-----------------------------------------------------------
-- Generate Unique Apartment ID
-----------------------------------------------------------
function IMRP.GenerateApartmentId(apartmentKey, bucketId)
    return ('%s_%d'):format(apartmentKey, bucketId)
end

-----------------------------------------------------------
-- Generate Stash ID
-----------------------------------------------------------
function IMRP.GenerateStashId(apartmentId)
    return ('stash_%s'):format(apartmentId)
end

-----------------------------------------------------------
-- Format Currency
-----------------------------------------------------------
function IMRP.FormatCurrency(amount)
    if not amount then return '$0' end
    local formatted = tostring(math.floor(amount))
    local k
    while true do
        formatted, k = formatted:gsub('^(-?%d+)(%d%d%d)', '%1,%2')
        if k == 0 then break end
    end
    return '$' .. formatted
end

-----------------------------------------------------------
-- Format Date
-----------------------------------------------------------
function IMRP.FormatDate(timestamp)
    if not timestamp then return 'N/A' end
    return os.date('%Y-%m-%d %H:%M', timestamp)
end

-----------------------------------------------------------
-- Calculate Days Remaining
-----------------------------------------------------------
function IMRP.DaysRemaining(expireTimestamp)
    if not expireTimestamp then return 0 end
    local now = os.time()
    local diff = expireTimestamp - now
    if diff <= 0 then return 0 end
    return math.ceil(diff / 86400)
end

-----------------------------------------------------------
-- Validate Apartment Key
-----------------------------------------------------------
function IMRP.IsValidApartment(key)
    return Config.Apartments[key] ~= nil
end

-----------------------------------------------------------
-- Get Apartment Type Data
-----------------------------------------------------------
function IMRP.GetApartmentTypeData(key)
    local apartment = Config.Apartments[key]
    if not apartment then return nil end
    return Config.ApartmentTypes[apartment.type]
end

-----------------------------------------------------------
-- Get Price for Apartment
-----------------------------------------------------------
function IMRP.GetApartmentPrice(key)
    local typeData = IMRP.GetApartmentTypeData(key)
    if not typeData then return 0 end
    return typeData.price
end

-----------------------------------------------------------
-- Get Rental Price for Apartment
-----------------------------------------------------------
function IMRP.GetRentalPrice(key)
    local typeData = IMRP.GetApartmentTypeData(key)
    if not typeData then return 0 end
    return typeData.rental_price
end

-----------------------------------------------------------
-- Deep Copy Table
-----------------------------------------------------------
function IMRP.DeepCopy(orig)
    local copy = {}
    for k, v in pairs(orig) do
        if type(v) == 'table' then
            copy[k] = IMRP.DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-----------------------------------------------------------
-- Debug Print
-----------------------------------------------------------
Config.Debug = false

function IMRP.Debug(...)
    if Config.Debug then
        print('[IMRP_APARTMENTS]', ...)
    end
end

-----------------------------------------------------------
-- Shared Config Builders
-----------------------------------------------------------

local DEFAULT_INTERIOR = {
    ipl = nil,
    offset = vector3(0.0, 0.0, 0.0),
}

--- Create an interior definition from a shell name.
--- All interiors share `ipl = nil` and `offset = vec3(0,0,0)` by default;
--- pass `overrides` to change those or add extra fields.
---@param shell string
---@param overrides? table
---@return table interior
function IMRP.CreateInterior(shell, overrides)
    local interior = {
        ipl    = DEFAULT_INTERIOR.ipl,
        shell  = shell,
        offset = DEFAULT_INTERIOR.offset,
    }
    if overrides then
        for k, v in pairs(overrides) do
            interior[k] = v
        end
    end
    return interior
end

--- Create an apartment type definition with sensible defaults.
--- Required: `label`, `price`. Optional fields fall back to defaults
--- derived from Config.DefaultStashSlots / Config.DefaultStashWeight.
---@param data table
---@return table apartmentType
function IMRP.CreateApartmentType(data)
    assert(data.label, 'CreateApartmentType: label is required')
    assert(data.price, 'CreateApartmentType: price is required')

    return {
        label        = data.label,
        price        = data.price,
        rental_price = data.rental_price or math.floor(data.price * 0.2),
        stash_slots  = data.stash_slots or (Config and Config.DefaultStashSlots or 75),
        stash_weight = data.stash_weight or (Config and Config.DefaultStashWeight or 150000),
        garage_slots = data.garage_slots or 1,
        interior     = data.interior,
    }
end

-----------------------------------------------------------
-- Client Notification Helper
-----------------------------------------------------------
if not IsDuplicityVersion() then
    --- Show a notification with standard Apartments title and position.
    ---@param description string
    ---@param notifType string 'success'|'error'|'info'
    function IMRP.Notify(description, notifType)
        lib.notify({
            title = 'Apartments',
            description = description,
            type = notifType or 'info',
            position = Config.Notification.position,
        })
    end
end

-----------------------------------------------------------
-- Server-Side Helpers
-----------------------------------------------------------
if IsDuplicityVersion() then
    local QBX_EXPORT = exports['qbx_core']

    --- Get player and citizenid from source, or return nil + an error result table.
    ---@param source number
    ---@return table|nil player
    ---@return string|nil citizenid
    ---@return table|nil errorResult  (only set when player/citizenid is nil)
    function IMRP.GetPlayerOrFail(source)
        local player = QBX_EXPORT:GetPlayer(source)
        if not player then
            return nil, nil, { success = false, message = 'Player not found' }
        end
        return player, player.PlayerData.citizenid, nil
    end

    --- Look up a citizen's full name from the players table.
    ---@param citizenid string
    ---@return string name
    function IMRP.GetPlayerFullName(citizenid)
        local row = MySQL.single.await(
            'SELECT JSON_EXTRACT(charinfo, "$.firstname") as firstname, JSON_EXTRACT(charinfo, "$.lastname") as lastname FROM players WHERE citizenid = ?',
            { citizenid }
        )
        if not row then return 'Unknown' end
        local first = row.firstname and row.firstname:gsub('"', '') or 'Unknown'
        local last  = row.lastname  and row.lastname:gsub('"', '')  or ''
        return ('%s %s'):format(first, last)
    end

    --- Add a `.name` field to each row that has a `.citizenid`.
    ---@param rows table[]
    ---@return table[] rows  (mutated in-place)
    function IMRP.EnrichWithNames(rows)
        for i, row in ipairs(rows) do
            rows[i].name = IMRP.GetPlayerFullName(row.citizenid)
        end
        return rows
    end
end

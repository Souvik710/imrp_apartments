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
    local path = ('locales/%s.lua'):format(lang or 'en')
    local file = LoadResourceFile(GetCurrentResourceName(), path)
    if not file then
        print(('[imrp_apartments] Locale file not found: %s'):format(path))
        return
    end
    local fn, parseErr = load(file)
    if not fn then
        print(('[imrp_apartments] Failed to parse locale %s: %s'):format(path, tostring(parseErr)))
        return
    end
    local ok, runErr = pcall(fn)
    if not ok then
        print(('[imrp_apartments] Failed to execute locale %s: %s'):format(path, tostring(runErr)))
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
    if type(timestamp) == 'string' then return timestamp end
    local ok, result = pcall(os.date, '%Y-%m-%d %H:%M', timestamp)
    if not ok then return 'N/A' end
    return result
end

-----------------------------------------------------------
-- Calculate Days Remaining
-----------------------------------------------------------
function IMRP.DaysRemaining(expireTimestamp)
    if not expireTimestamp then return 0 end

    local expireTime = expireTimestamp
    if type(expireTimestamp) == 'string' then
        local y, mo, d, h, mi, s = expireTimestamp:match('(%d+)-(%d+)-(%d+)%s+(%d+):(%d+):(%d+)')
        if y then
            expireTime = os.time({year=tonumber(y), month=tonumber(mo), day=tonumber(d), hour=tonumber(h), min=tonumber(mi), sec=tonumber(s)})
        else
            return 0
        end
    end

    if type(expireTime) ~= 'number' then return 0 end
    local diff = expireTime - os.time()
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
    if type(orig) ~= 'table' then return orig end
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
if Config.Debug == nil then Config.Debug = false end

function IMRP.Debug(...)
    if Config.Debug then
        print('[IMRP_APARTMENTS]', ...)
    end
end

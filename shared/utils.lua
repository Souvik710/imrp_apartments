-- Shared utility functions for IMRP Apartments
-- Provides input validation and sanitization helpers

Utils = {}

--- Validate that a value is a non-empty string
--- @param value any
--- @return boolean
function Utils.IsValidString(value)
    return type(value) == 'string' and #value > 0 and #value < 256
end

--- Validate that a value is a positive number within a sane range
--- @param value any
--- @param max number|nil Optional maximum value
--- @return boolean
function Utils.IsValidNumber(value, max)
    if type(value) ~= 'number' then return false end
    if value ~= value then return false end -- NaN check
    if value < 0 then return false end
    if max and value > max then return false end
    return true
end

--- Validate that an apartment ID exists in the config
--- @param apartmentId string
--- @return boolean
function Utils.IsValidApartmentId(apartmentId)
    if not Utils.IsValidString(apartmentId) then return false end
    return Config.Apartments[apartmentId] ~= nil
end

--- Sanitize a string by removing potentially dangerous characters
--- Prevents injection in notifications and UI elements
--- @param input string
--- @return string
function Utils.SanitizeString(input)
    if type(input) ~= 'string' then return '' end
    -- Remove HTML/script tags and special chars that could be used for injection
    local sanitized = input:gsub('[<>\"\'&;%%]', '')
    -- Limit length
    if #sanitized > 128 then
        sanitized = sanitized:sub(1, 128)
    end
    return sanitized
end

--- Rate limiter table (server-side only, but defined shared for type safety)
--- @type table<string, number>
Utils.RateLimits = {}

--- Check if an action is rate-limited (server-side use)
--- @param identifier string Player identifier or source
--- @param action string Action name
--- @param cooldownMs number Cooldown in milliseconds
--- @return boolean true if rate-limited (should deny), false if allowed
function Utils.IsRateLimited(identifier, action, cooldownMs)
    local key = identifier .. ':' .. action
    local now = GetGameTimer()
    local lastAction = Utils.RateLimits[key]

    if lastAction and (now - lastAction) < cooldownMs then
        return true
    end

    Utils.RateLimits[key] = now
    return false
end

return Utils

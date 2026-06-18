local Utils = {}

local DEFAULT_INTERIOR_Z = 100.0
local DEFAULT_STASH_OFFSET = 0.5
local DEFAULT_WARDROBE_OFFSET = 1.0

local DEFAULT_BLIP = {
    enabled = true,
    sprite = 40,
    scale = 0.7,
    label = 'Apartment'
}

local DEFAULT_APARTMENT = {
    rental_days = 7,
    stash_slots = 50,
    stash_weight = 10000,
}

--- Build all five location vectors from an entrance point.
--- Interior, stash, and wardrobe are placed at `interiorZ` (default 100.0)
--- with fixed x/y offsets; exit mirrors the entrance.
---@param entrance vector3
---@param interiorZ? number
---@return table locations
function Utils.CreateLocations(entrance, interiorZ)
    local iz = interiorZ or DEFAULT_INTERIOR_Z
    return {
        entrance = entrance,
        interior = vector3(entrance.x, entrance.y, iz),
        exit     = vector3(entrance.x, entrance.y, entrance.z),
        stash    = vector3(entrance.x - DEFAULT_STASH_OFFSET, entrance.y - DEFAULT_STASH_OFFSET, iz),
        wardrobe = vector3(entrance.x - DEFAULT_WARDROBE_OFFSET, entrance.y - DEFAULT_WARDROBE_OFFSET, iz),
    }
end

--- Create a blip configuration, merging overrides into defaults.
---@param overrides? table
---@return table blip
function Utils.CreateBlip(overrides)
    local blip = {}
    for k, v in pairs(DEFAULT_BLIP) do
        blip[k] = v
    end
    if overrides then
        for k, v in pairs(overrides) do
            blip[k] = v
        end
    end
    return blip
end

--- Create a full apartment definition from minimal parameters.
--- `data` must contain `name`, `price`, and `entrance` (vector3).
--- Optional fields: `label`, `rental_days`, `rental_price`, `interiorZ`,
--- `stash_slots`, `stash_weight`, `blip` (table of overrides).
---@param data table
---@return table apartment
function Utils.CreateApartment(data)
    assert(data.name,     'CreateApartment: name is required')
    assert(data.price,    'CreateApartment: price is required')
    assert(data.entrance, 'CreateApartment: entrance is required')

    local rentalPrice = data.rental_price or math.floor(data.price * 0.1)

    return {
        name         = data.name,
        label        = data.label or data.name,
        price        = data.price,
        rental_days  = data.rental_days or DEFAULT_APARTMENT.rental_days,
        rental_price = rentalPrice,
        location     = Utils.CreateLocations(data.entrance, data.interiorZ),
        stash_slots  = data.stash_slots or DEFAULT_APARTMENT.stash_slots,
        stash_weight = data.stash_weight or DEFAULT_APARTMENT.stash_weight,
        blip         = Utils.CreateBlip(data.blip),
    }
end

return Utils

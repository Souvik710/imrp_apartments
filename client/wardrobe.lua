-----------------------------------------------------------
-- IMRP Apartments - Client Wardrobe
-- Author: Ragna | Immortal Roleplay
-----------------------------------------------------------

-----------------------------------------------------------
-- Open Wardrobe (compatible with multiple appearance systems)
-----------------------------------------------------------
function OpenWardrobe()
    if not Config.UseWardrobe then return end

    local currentApt = exports['imrp_apartments']:GetCurrentApartment()
    if not currentApt then
        IMRP.Notify(IMRP.Locale('not_in_apartment'), 'error')
        return
    end

    if Config.AppearanceSystem == 'illenium-appearance' then
        OpenIlleniumWardrobe()
    elseif Config.AppearanceSystem == 'fivem-appearance' then
        OpenFivemWardrobe()
    elseif Config.AppearanceSystem == 'qb-clothing' then
        OpenQBWardrobe()
    else
        IMRP.Notify(IMRP.Locale('wardrobe_not_configured'), 'error')
    end
end

-----------------------------------------------------------
-- illenium-appearance
-----------------------------------------------------------
function OpenIlleniumWardrobe()
    local currentApt = exports['imrp_apartments']:GetCurrentApartment()
    if not currentApt then return end

    TriggerEvent('illenium-appearance:client:openOutfitMenu')
end

-----------------------------------------------------------
-- fivem-appearance
-----------------------------------------------------------
function OpenFivemWardrobe()
    local currentApt = exports['imrp_apartments']:GetCurrentApartment()
    if not currentApt then return end

    TriggerEvent('fivem-appearance:client:openOutfitMenu')
end

-----------------------------------------------------------
-- qb-clothing
-----------------------------------------------------------
function OpenQBWardrobe()
    local currentApt = exports['imrp_apartments']:GetCurrentApartment()
    if not currentApt then return end

    TriggerEvent('qb-clothing:client:openOutfitMenu')
end

-----------------------------------------------------------
-- Wardrobe Menu (ox_lib context)
-----------------------------------------------------------
function OpenWardrobeMenu()
    if not Config.UseWardrobe then return end

    local options = {
        {
            title = IMRP.Locale('save_outfit'),
            description = IMRP.Locale('save_outfit_desc'),
            icon = 'save',
            onSelect = function()
                SaveOutfit()
            end
        },
        {
            title = IMRP.Locale('load_outfit'),
            description = IMRP.Locale('load_outfit_desc'),
            icon = 'tshirt',
            onSelect = function()
                LoadOutfit()
            end
        },
        {
            title = IMRP.Locale('delete_outfit'),
            description = IMRP.Locale('delete_outfit_desc'),
            icon = 'trash',
            onSelect = function()
                DeleteOutfit()
            end
        }
    }

    lib.registerContext({
        id = 'apartment_wardrobe_menu',
        title = IMRP.Locale('wardrobe'),
        menu = 'apartment_inside_menu',
        options = options
    })
    lib.showContext('apartment_wardrobe_menu')
end

-----------------------------------------------------------
-- Save Outfit
-----------------------------------------------------------
function SaveOutfit()
    local input = lib.inputDialog(IMRP.Locale('save_outfit'), {
        { type = 'input', label = IMRP.Locale('outfit_name'), required = true, max = 30 }
    })

    if not input then return end

    lib.callback('imrp_apartments:server:saveOutfit', false, function(result)
        if result and result.success then
            IMRP.Notify(IMRP.Locale('outfit_saved'), 'success')
        else
            IMRP.Notify(result and result.message or IMRP.Locale('outfit_save_failed'), 'error')
        end
    end, input[1])
end

-----------------------------------------------------------
-- Load Outfit
-----------------------------------------------------------
function LoadOutfit()
    lib.callback('imrp_apartments:server:getOutfits', false, function(outfits)
        if not outfits or #outfits == 0 then
            IMRP.Notify(IMRP.Locale('no_outfits'), 'info')
            return
        end

        local options = {}
        for _, outfit in ipairs(outfits) do
            options[#options + 1] = {
                title = outfit.name,
                icon = 'tshirt',
                onSelect = function()
                    lib.callback('imrp_apartments:server:loadOutfit', false, function(result)
                        if result and result.success and result.data then
                            TriggerEvent('illenium-appearance:client:loadOutfit', result.data)
                        end
                    end, outfit.id)
                end
            }
        end

        lib.registerContext({
            id = 'apartment_load_outfit',
            title = IMRP.Locale('load_outfit'),
            menu = 'apartment_wardrobe_menu',
            options = options
        })
        lib.showContext('apartment_load_outfit')
    end)
end

-----------------------------------------------------------
-- Delete Outfit
-----------------------------------------------------------
function DeleteOutfit()
    lib.callback('imrp_apartments:server:getOutfits', false, function(outfits)
        if not outfits or #outfits == 0 then
            IMRP.Notify(IMRP.Locale('no_outfits'), 'info')
            return
        end

        local options = {}
        for _, outfit in ipairs(outfits) do
            options[#options + 1] = {
                title = outfit.name,
                description = IMRP.Locale('click_to_delete'),
                icon = 'trash',
                onSelect = function()
                    local alert = lib.alertDialog({
                        header = IMRP.Locale('confirm_delete_outfit'),
                        content = IMRP.Locale('confirm_delete_outfit_desc', outfit.name),
                        centered = true,
                        cancel = true
                    })
                    if alert == 'confirm' then
                        lib.callback('imrp_apartments:server:deleteOutfit', false, function(result)
                            if result and result.success then
                                IMRP.Notify(IMRP.Locale('outfit_deleted'), 'success')
                            end
                        end, outfit.id)
                    end
                end
            }
        end

        lib.registerContext({
            id = 'apartment_delete_outfit',
            title = IMRP.Locale('delete_outfit'),
            menu = 'apartment_wardrobe_menu',
            options = options
        })
        lib.showContext('apartment_delete_outfit')
    end)
end

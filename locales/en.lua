local Translations = {
    error = {
        not_enough_money = 'You do not have enough money',
        not_owned = 'You do not own this apartment',
        already_owned = 'You already own this apartment',
        invalid_apartment = 'Invalid apartment',
        database_error = 'Database error occurred',
        permission_denied = 'You do not have permission to do this',
        player_not_found = 'Player not found',
        apartment_expired = 'Your apartment has expired',
        max_apartments = 'You have reached the maximum number of apartments'
    },
    success = {
        purchased = 'Apartment purchased successfully!',
        renewed = 'Apartment renewed successfully!',
        removed = 'Apartment removed successfully!'
    },
    info = {
        apartment_menu = 'Apartment Menu',
        available_apartments = 'Available Apartments',
        my_apartments = 'My Apartments',
        rent_info = 'Rent Information',
        apartment_options = 'Apartment Options',
        enter_apartment = 'Enter Apartment',
        renew_apartment = 'Renew Apartment',
        apartment_info = 'Apartment Information',
        days_remaining = 'Days remaining: %s',
        price = 'Price: $%s',
        rent = 'Rent: $%s/week'
    },
    command = {
        give_usage = '/apartmentgive [player_id] [apartment_id]',
        remove_usage = '/apartmentremove [citizenid]',
        reset_usage = '/apartmentreset'
    }
}

if Config.Locale == 'en' then
    return Translations
end
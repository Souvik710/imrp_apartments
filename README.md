# IMRP Apartments

A modern, production-ready apartment system for **QBX Core** (FiveM) featuring private routing bucket instancing.

**Author:** Ragna  
**Server:** Immortal Roleplay (IMRP)  
**Version:** 1.0.0

---

## Features

- **Private Instancing** — Each apartment uses unique routing buckets. Players never see each other inside.
- **Buy / Rent / Renew / Sell** — Full apartment lifecycle management.
- **ox_target Integration** — Interact with apartment entrances via target zones.
- **ox_inventory Stashes** — Unique stash per apartment instance.
- **Wardrobe System** — Compatible with illenium-appearance, fivem-appearance, and qb-clothing.
- **Key System** — Give, duplicate, and remove keys (permanent & temporary).
- **Guest System** — Invite/kick guests with separate access control.
- **Garage System** — Store and retrieve vehicles per apartment.
- **Door Lock** — Owner and key holders can lock/unlock.
- **Expiry System** — Automatic expiration with configurable duration and periodic checks.
- **Admin Commands** — Full admin toolset for managing apartments.
- **Modern NUI** — Dark glass UI with sky blue accents, IMRP branding.
- **Logout Point** — Character logout inside apartments (QBX multicharacter compatible).
- **Performance Optimized** — 0.00ms idle, no thread abuse.
- **Server-side Validation** — All actions validated server-side, anti-exploit.

---

## Dependencies

| Resource | Required |
|----------|----------|
| [qbx_core](https://github.com/Qbox-project/qbx_core) | Yes |
| [ox_lib](https://github.com/overextended/ox_lib) | Yes |
| [ox_target](https://github.com/overextended/ox_target) | Yes |
| [ox_inventory](https://github.com/overextended/ox_inventory) | Yes |
| [oxmysql](https://github.com/overextended/oxmysql) | Yes |
| [illenium-appearance](https://github.com/iLLeniumStudios/illenium-appearance) | Optional (wardrobe) |
| [fivem-appearance](https://github.com/pedr0fontoura/fivem-appearance) | Optional (wardrobe) |
| [qb-clothing](https://github.com/qbcore-framework/qb-clothing) | Optional (wardrobe) |

---

## Installation

1. **Download** and place `imrp_apartments` in your resources folder.

2. **Import SQL** — Run `sql/apartments.sql` in your database, or let the resource auto-create tables on first start.

3. **Configure** — Edit `config.lua` to match your server settings:
   - Apartment types, prices, locations
   - Interior system (`qbx` or `motel`)
   - Appearance system
   - Economy settings
   - Max apartments per player
   - Expiry duration

4. **Add to server.cfg**:
   ```
   ensure ox_lib
   ensure oxmysql
   ensure ox_inventory
   ensure ox_target
   ensure qbx_core
   ensure imrp_apartments
   ```

5. **Restart** your server.

---

## Apartment Types

| Type | Price | Rental | Stash Slots | Garage Slots |
|------|-------|--------|-------------|--------------|
| Basic | $25,000 | $5,000 | 50 | 1 |
| Modern | $50,000 | $10,000 | 75 | 2 |
| Deluxe | $75,000 | $15,000 | 100 | 3 |
| Luxury | $100,000 | $20,000 | 125 | 4 |
| Penthouse | $250,000 | $50,000 | 150 | 5 |
| Motel | $15,000 | $3,000 | 30 | 1 |

---

## Commands

### Player Commands

| Command | Description |
|---------|-------------|
| `/apartment` | Open the apartment menu |

### Admin Commands

| Command | Description |
|---------|-------------|
| `/giveapartment [id] [apartment_name]` | Give apartment to player |
| `/removeapartment [id] [apartment_name]` | Remove apartment from player |
| `/resetapartment [apartment_id]` | Reset apartment by ID |
| `/expireapartment [apartment_id]` | Force expire an apartment |
| `/apartmentlist` | List all active apartments |

---

## How Routing Buckets Work

```
Player A buys Integrity Way → Bucket 1001
Player B buys Integrity Way → Bucket 1002
Player C buys Integrity Way → Bucket 1003

All players enter from the same entrance.
Each player is teleported to the same interior coords.
But each is in their own routing bucket — completely isolated.
```

---

## Configuration

See `config.lua` for all configurable options including:

- `Config.MaxApartments` — Max apartments per player (default: 1)
- `Config.ApartmentDuration` — Lease duration in days (default: 7)
- `Config.SellRefundPercent` — Refund percentage when selling (default: 80%)
- `Config.ClearStashOnExpire` — Clear stash on expiry (default: true)
- `Config.UseRoutingBuckets` — Enable routing bucket instancing (default: true)
- `Config.AppearanceSystem` — Wardrobe system to use
- `Config.InteriorSystem` — Interior system (`qbx` or `motel`)

---

## File Structure

```
imrp_apartments/
├── fxmanifest.lua
├── config.lua
├── README.md
├── shared/
│   └── utils.lua
├── client/
│   ├── main.lua
│   ├── target.lua
│   ├── nui.lua
│   ├── wardrobe.lua
│   └── garage.lua
├── server/
│   ├── main.lua
│   ├── commands.lua
│   └── expiry.lua
├── html/
│   ├── index.html
│   ├── style.css
│   └── script.js
├── locales/
│   └── en.lua
└── sql/
    └── apartments.sql
```

---

## Security

- All purchases, sales, and key operations are validated server-side.
- Client cannot spoof ownership or access.
- Anti-exploit: bucket assignment is server-authoritative.
- No client-side trust for any economic or access action.

---

## Performance

- **0.00ms idle** — No active threads when not interacting.
- Optimized loops with proper `Wait()` usage.
- Target zones are static (no polling).
- Expiry checks run on configurable interval (default: 30 minutes).

---

## License

This resource is created for **Immortal Roleplay (IMRP)** by **Ragna**.

---

*Created By Ragna*

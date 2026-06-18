# IMRP Ambulance Job

A premium, production-ready EMS / Ambulance Job system for **QBX Core** (FiveM).

**Author:** Ragna
**Server:** Immortal Roleplay (IMRP)
**Version:** 1.0.0

---

## Features

### Advanced Injury System
- Body zone tracking (Head, Chest, Arms, Legs, Torso)
- Bleeding levels 1-5 with progressive blood loss
- Broken bones with movement penalties
- Bullet wounds requiring extraction
- Burns, vehicle crash trauma, fall damage
- Pain level system with screen effects
- Blood loss system with critical thresholds

### Death System
- Last Stand state (crawl, distress signal)
- Unconscious state (EMS-only revival)
- Dead state with respawn timer
- Hospital and Morgue respawn options
- Configurable death penalty

### Medical Equipment (ox_inventory)
- Bandage, Medkit, First Aid Kit
- Defibrillator, ECG Machine, Oxygen Tank
- Stretcher, Wheelchair, Crutches
- Medical Bag, Body Bag, Surgical Kit
- Painkillers, Morphine, Antibiotics, Adrenaline
- Blood Bag, Saline IV, Splint

### EMS Treatment System
- Check Pulse / Blood Pressure / Oxygen
- Diagnose Injuries, Remove Bullets, Stop Bleeding
- Apply Bandages, CPR, Defibrillation, Splinting
- Administer medications with ox_inventory integration
- Minigames: CPR, Surgery, Bullet Extraction, Stabilization, Defibrillator

### Hospital System
- Reception Check-In with NPC
- NPC Doctor (pay-to-heal)
- Insurance System (Basic/Premium/VIP)
- Hospital Billing with insurance discounts
- Bed Management (regular + ICU)
- Surgery Room (EMS rank-gated)
- Pharmacy (buy medications)

### EMS MDT Tablet
- Modern dark UI with sky blue accents
- Dashboard with live statistics
- Active Calls & Dispatch
- Patient Records & Medical History
- Insurance Records
- EMS Staff List
- Duty Logs & Reports
- Billing management
- Citizen Search

### EMS Dispatch System
- Auto-dispatch on player down
- GPS routing with blip markers
- Accept/Decline calls
- Responding units counter
- Call completion tracking

### EMS Vehicle System
- Ambulance, EMS SUV, EMS Bike, EMS Helicopter
- Rank-based vehicle access
- Livery selection
- Fuel support
- Vehicle extras
- Impound system

### EMS Storage (ox_inventory)
- Main Storage, Pharmacy Storage, Evidence Storage
- Personal Locker (per-player stash)
- Rank-based access control

### EMS Rank System (10 ranks)
1. Trainee EMT
2. EMT
3. Advanced EMT
4. Paramedic
5. Senior Paramedic
6. Field Training Officer
7. Lieutenant
8. Captain
9. Deputy Chief
10. EMS Chief

### Boss Menu
- Hire / Fire / Promote / Demote
- Society Account management
- Salary overview
- Employee logs
- Callsign assignment

---

## Dependencies

| Resource | Required |
|----------|----------|
| [qbx_core](https://github.com/Qbox-project/qbx_core) | Yes |
| [ox_lib](https://github.com/overextended/ox_lib) | Yes |
| [ox_target](https://github.com/overextended/ox_target) | Yes |
| [ox_inventory](https://github.com/overextended/ox_inventory) | Yes |
| [oxmysql](https://github.com/overextended/oxmysql) | Yes |
| [pma-voice](https://github.com/AvarianKnight/pma-voice) | Yes |

---

## Installation

1. Place `imrp_ambulancejob` in your resources folder.
2. Import `sql/ambulancejob.sql` or let auto-create on first start.
3. Add items from `shared/items.lua` to your `ox_inventory/data/items.lua`.
4. Add to `server.cfg`:
   ```
   ensure ox_lib
   ensure oxmysql
   ensure ox_inventory
   ensure ox_target
   ensure qbx_core
   ensure pma-voice
   ensure imrp_ambulancejob
   ```
5. Add the `ambulance` job to your QBX Core jobs config with grades 0-9.
6. Restart server.

---

## Commands

| Command | Description |
|---------|-------------|
| `/ems` | Open EMS menu |
| `/mdt` | Open MDT Tablet |
| `/checkpulse` | Check nearby player pulse |
| `/checkbp` | Check blood pressure |
| `/cpr` | Perform CPR |
| `/stretcher` | Deploy stretcher |
| `/wheelchair` | Deploy wheelchair |
| `/crutch` | Toggle crutches |
| `/bodybag` | Place body bag |

### Admin Commands
| Command | Description |
|---------|-------------|
| `/emsrevive [id]` | Force revive player |
| `/emsheal [id]` | Heal player |
| `/emssetrank [id] [grade]` | Set EMS rank |
| `/emsonduty` | Show on-duty count |
| `/emsclearcalls` | Clear all active calls |
| `/emsgiveitem [id] [item] [qty]` | Give EMS item |
| `/emsresetpatient [citizenid]` | Reset patient record |

---

## Database Tables
- `ems_patients` - Patient injury/medical records
- `ems_reports` - Medical reports
- `ems_calls` - Dispatch calls
- `ems_insurance` - Insurance records
- `ems_logs` - Activity/duty logs
- `ems_staff` - Staff roster
- `ems_billing` - Billing records

---

## Performance
- 0.00ms idle
- No memory leaks
- Server-side validation
- Secure event handling
- Production ready

---

## File Structure

```
imrp_ambulancejob/
├── fxmanifest.lua
├── README.md
├── shared/
│   ├── config.lua
│   ├── injuries.lua
│   ├── items.lua
│   ├── ranks.lua
│   ├── vehicles.lua
│   ├── hospitals.lua
│   └── utils.lua
├── client/
│   ├── main.lua
│   ├── injury.lua
│   ├── death.lua
│   ├── treatment.lua
│   ├── hospital.lua
│   ├── dispatch.lua
│   ├── vehicle.lua
│   ├── storage.lua
│   ├── bossmenu.lua
│   ├── commands.lua
│   └── nui.lua
├── server/
│   ├── main.lua
│   ├── injury.lua
│   ├── treatment.lua
│   ├── hospital.lua
│   ├── dispatch.lua
│   ├── mdt.lua
│   ├── billing.lua
│   ├── bossmenu.lua
│   └── commands.lua
├── html/
│   ├── index.html
│   ├── style.css
│   └── script.js
├── sql/
│   └── ambulancejob.sql
└── locales/
    └── en.lua
```

---

## License

All rights reserved. IMMORTAL ROLEPLAY.

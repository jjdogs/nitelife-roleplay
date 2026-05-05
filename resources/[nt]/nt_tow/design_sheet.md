# NiteLife Towing — Full System Design
*nt_tow + city_simulation · Last updated May 2026*

---

## NAVEED (NPC — Dispatch Contact)

- Talk to Naveed → Sign In → unlocks Phone App + Laptop App
- Rep drops → Naveed sends text message warning
- Lost remote → report to Naveed → fee + rep hit
- Don't return truck → remote locked until returned

### Rep System (city_simulation C#)
| Direction | Causes |
|---|---|
| Up | Complete jobs, return truck, good performance |
| Down | Deny jobs, damage truck, late returns, police incident |

### Rep Tiers
New Blood → Reliable → Trusted → Senior

---

## VEHICLES

### Progression
Phase 1 — Borrow Towtruck2 (hook truck)
→ Naveed loans on sign-in
→ Must return after shift
→ Damage / no return = rep hit
Phase 2 — Buy Towtruck2
→ Rep threshold met → purchase option unlocks
Phase 3 — Borrow Flatbed
→ Trusted enough → Naveed loans flatbed
Phase 4 — Buy Flatbed
→ Own it → full freelance unlocks

---

## APPS

### lb-phone — Truck Controls
- Usable inside OR outside truck
- Lower / Raise bed
- Winch controls
- Unlocks on Naveed sign-in

### av_laptop — Dispatch App
**Tab 1: Active Jobs**
- Regular jobs (random NPCs from city_simulation)
- Special NPC jobs (visually distinct, state-aware)
- Locked NPCs not shown
- Unlocked-but-not-met NPCs show "?" placeholder card

**Tab 2: History**
- Past completed jobs
- Repeat NPCs grouped with return count (e.g. "Towed John Smith × 4")
- Special NPCs pinned to top

**Tab 3: Stats**
- Total jobs completed
- Total earned
- Current rep tier

### lb-tablet (future)
- Combined view of both lb-phone and av_laptop
- Possibly tied to owning the truck

---

## JOB FLOW
Job arrives in Dispatch App (from city_simulation)
→ Vehicle model, plate, owner name, reason, pay, location
Accept → Blip + Marker appear on map
Arrive at location → Talk to NPC
├── Minor issue (flat tire etc.)
│   └── Fix option → animation + item consumed → paid
└── Major issue (engine failure etc.)
└── Tow option → flatbed mechanic → paid

### Solo Play
- Player handles everything themselves

### Grouped Play (av_groups)
- Driver → drives truck
- Operator → lb-phone controls bed/winch from inside or outside truck
- Pay split → higher rep gets 60%, lower rep gets 40%
- Equal rep → 50/50

---

## SPECIAL NPCs

### States

**State 1 — Locked (rep threshold not met)**
- Ped exists in world
- No interaction, no blip, nothing in app

**State 2 — Unlocked (tow requirement not met)**
- Shows in Dispatch App as "?" entry
- Location blip visible on map
- Walk up → brush-off dialog, no real interaction
- Must tow them 3–10x (randomised per player on first encounter)

**State 3 — Contact Unlocked**
- Added to av_contacts automatically
- Fixed world location
- Walk up → item check
  - Has item → full dialog, criminal pipeline opens
  - No item → "Come back with something for me"

### Special NPC Roster
| NPC Role | Pipeline | Required Item |
|---|---|---|
| Racer NPC | Racing content | TBD |
| Scrapper NPC | Car scrapping | TBD |
| Booster NPC | Vehicle boosting | TBD |

- Names, models, coords, items all configurable in `shared/config.lua`
- Rep thresholds mirrored in C# config
- Regular NPCs stay in Tow App history only
- Special NPCs appear in av_contacts after unlock

---

## FREELANCE MODE
*Unlocks after buying first truck*

### lb-phone Services App
- Post availability publicly
- Verified badge displayed under name

### Badge Tiers
[Tow]              → unrated / new
[🔧 Tow · ⭐ 4.2] → verified
[🔧 Tow · 🏆 4.8] → top tier, police jobs unlocked

### Flow
On Call toggle active
→ Players / Police post tow request
→ Notification sent to available freelancers
→ Accept → job details + blip
→ Deny → small rep hit (too many = tier drop)
→ Ignore → treated as deny after timeout

### Pay Formula
Base fee     → flat rate, scales with rep tier
Distance     → coords pickup to dropoff × rate per unit
Tier bonus   → multiplier based on rep tier

---

## CITY_SIMULATION (C# Backend)

### Services
- **VehicleSimulator** — virtual fleet, background condition degradation
- **JobGenerator** — breakdown jobs on 30s tick
  - `breakdown_minor` → fix job
  - `breakdown_major` → tow job
- **SpecialNPCTracker** — per player, per NPC
  - RepThresholdMet (bool)
  - TowsRequired (int, random 3–10 on first encounter)
  - TowsCompleted (int)
  - ContactUnlocked (bool)

### Events Exposed to Lua
| Event | Direction | Purpose |
|---|---|---|
| `citysim:requestJobs` | Lua → C# | Get available jobs |
| `citysim:acceptJob` | Lua → C# | Reserve a job |
| `citysim:completeJob` | Lua → C# | Complete, log, pay |
| `citysim:getNaveedRep` | Lua → C# | Get player rep |
| `citysim:getSpecialNPCStates` | Lua → C# | Get all NPC states |
| `citysim:getJobHistory` | Lua → C# | Get past jobs |
| `citysim:specialNPCContactUnlocked` | C# → Lua | NPC unlock trigger |

### Group Job Handling
- `citysim:completeJob` accepts optional second player identifier
- Checks both players' rep
- Higher rep → 60%, lower rep → 40%, equal → 50/50
- Both players get rep gain, higher rep gets slightly more

### Persistence
- MariaDB direct via Dapper
- Player rep per character
- Special NPC progress per character
- Job history per character

---

## BUILD ORDER
├── ✅ Phase 1 — Core mechanics (winch, flatbed, attach/detach)
├── ✅ Phase 1 — city_simulation foundation (fleet, jobs, events)
├── 🔄 Phase 1 — Polish flatbed mechanics
├── ⏳ Phase 1 — Fix vs Tow job split
│
├── ⏳ Phase 2 — Naveed sign-in flow
├── ⏳ Phase 2 — city_simulation DB persistence
│
├── ⏳ Phase 3 — lb-phone controls app UI (fully complete, no logic)
├── ⏳ Phase 3 — lb-phone controls app logic (wired to complete UI)
│
├── ⏳ Phase 4 — av_laptop dispatch app UI (fully complete, no logic)
├── ⏳ Phase 4 — av_laptop dispatch app logic (wired to complete UI)
│
├── ⏳ Phase 5 — Special NPC system
├── ⏳ Phase 5 — av_contacts integration
│
├── ⏳ Phase 6 — Vehicle progression UI (fully complete, no logic)
├── ⏳ Phase 6 — Vehicle progression logic
│
├── ⏳ Phase 7 — Freelance mode UI (fully complete, no logic)
├── ⏳ Phase 7 — Freelance mode logic
│
└── ⏳ Phase 8 — Group play (av_groups integration)

---

*UI ships complete before any logic is added.
Nothing gets built until the UI is agreed on and finished.*

*NiteLife Roleplay · Internal Development Document · May 2026*
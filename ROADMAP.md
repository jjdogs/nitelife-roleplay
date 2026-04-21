# NiteLife Roleplay — Development Roadmap
*Los Santos after dark · The city never sleeps.*

> Phases are numbered from scratch — previous numbering retired April 2026.
> Complete phases in full before moving on. Each phase builds on the last.

---

## Status Key
- `Complete` — fully done
- `In Progress` — actively being worked
- `Planned` — next up, not started
- `TBD` — future, scope not locked

---

## Phase 1 — Roleplay Basics `Complete`

Get the fundamental player-facing systems to a fully working, configured, and consistent state.
Players need a phone, shops to spend money at, somewhere to put their cars, and a unified UI theme.

### lb-phone ✓ Installed
- [x] Verify 100% configuration end-to-end — framework set to QBX, not QBCore legacy
- [x] Confirm phone item exists in ox_inventory and is given on character creation
- [x] Set up Fivemanage API keys for photo/video/audio uploads
- [x] Configure nolag_properties housing integration (lb-phone docs housing config page)
- [x] Plan add-on apps — document minimum required apps before adding any
  - Deferred apps (MDT, dispatch) — Phase 5, not added
- [x] Confirm all notifications route through ox_lib to match server theme

> **lb-phone decisions (locked):**
> - Framework: `qbox`
> - Inventory: `ox_inventory`, unique phones enabled
> - Logging: Fivemanage (all activity — calls, messages, wallet, services, crypto, uploads)
> - Housing: `nolag_properties` — custom integration files added to client and server
> - Apps: all apps enabled (core + Birdy, InstaPic, Trendy, Spark, DarkChat, Music, Marketplace, YellowPages, Crypto)
> - Notifications: route through lation_ui via ox_lib shim — no per-resource changes needed

### lation_ui ✓ Installed
- [x] Explore the full resource — document everything that IS and IS NOT configurable
- [x] Set up notifications, progress bars, and text UI to match NiteLife theme
- [x] This becomes the UI standard — every future resource must use lation_ui or ox_lib notifications
- [x] Write internal note on theme decisions made here (for reference when configuring future scripts)

> **lation_ui decisions (locked):**
> - Notification sounds: **off** globally — `play_sound = false`
> - Radial menu keybind: **MOUSE_MIDDLE** (default, no change)
> - Visual theme is **not configurable** — colors, fonts, and animations are baked into the compiled React bundle. There is no NiteLife theme to apply here.
> - lation_ui is the **UI component standard** for all future resources. Any script calling `lib.notify()`, `lib.progressBar()`, `lib.showTextUI()`, etc. routes through it automatically via the ox_lib shim in `init.lua` — no per-script changes needed.

### lation_shops ✓ Installed
- [x] Do NOT configure shop inventories yet — items and pricing come later
- [x] Plan and place shop locations across the map — markers/interactables only
  - 24/7s, liquor stores, clothing stores, hardware stores
  - Spread across the map, not clustered
- [x] Shops added "as we go" — this phase is location planning only

### jg-advancedgarages ✓ Installed
- [x] Verify players can park vehicles, retrieve vehicles, customization saves correctly
- [x] Civilian car garages only for now
- [x] Document future garage types (do NOT build yet):
  - Police garage (Phase 5 — Emergency Services)
  - Ambulance/EMS garage (Phase 5 — Emergency Services)
  - Boat garage
  - Airplane/helipad garage
  - Job-specific garages (mechanic, trucker, etc.)

> **jg-advancedgarages decisions (locked):**
> - Framework: `Qbox` | Fuel: `Renewed-Fuel` | Banking: `Renewed-Banking`
> - Vehicle keys: `qb-vehiclekeys` (qbx_vehiclekeys is compatible)
> - Job garages (Mechanic, Police) and impound commented out — Phase 5
> - Gang garages commented out — Phase 6
> - 11 civilian public garages active + boats + hangar

> **Phase 1 done when:** phone works end-to-end, UI theme is locked in, shop locations are placed (empty), and civilian car garages are fully functional.

---

## Phase 2 — Economy Foundation `Complete`

Start making the world feel alive. Fuel, banking, and early money flow give players something to interact with and spend on.

### Renewed-Fuel ✓ Installed
- [x] Set up exactly 3 gas stations, spread as evenly as possible
- [x] Planned locations (confirm in-game):
  - Strawberry Ave — Xero Gas
  - North Rockford Drive (RON Oil) OR Bay City Incline (Xero Gas)
  - Panorama Drive — Globe Oil
- [x] Manually place each station in-game — confirm each works before signing off

### Renewed-Banking ✓ Installed
- [x] Verify banking works correctly with QBX character money (JSON columns, not flat values)
- [x] Confirm ATMs work and bank accounts are per-character not per-license
- [x] "Work as we go" system — do not over-configure now
- [x] Document any money flow decisions (wage amounts, starting cash, etc.)

> **Phase 2 done when:** 3 gas stations working in-game and banking confirmed stable with QBX characters.

---

## Phase 3 — Economy Continued & Crafting `Complete`

Flesh out the economy and get crafting in a solid state. sd-crafting deserves dedicated attention.

### sd-crafting ✓ Installed ** Waiting until later phase(s)
- [x] Treat as standalone setup — do not rush into an earlier phase
- [ ] Plan crafting recipes and item tiers before configuring anything
- [ ] Crafting must feel intentional — tied to the economy, not a random item list
- [ ] Coordinate with lation_shops: buyable items should not be trivially craftable at same cost

### jg-dealerships ✓ Installed ** Waiting until later phases
- [ ] Economy must be working before dealerships are configured
- [ ] Plan dealership locations and vehicle categories
- [ ] Decide on finance/loan integration with Renewed-Banking
- [ ] Vehicle pricing balanced against in-game income sources

### ox_inventory — Items & Balancing ✓ Installed
- [x] First pass at item balancing — enough systems running by this phase
- [x] Review all items added so far, check for duplicates or unused entries
- [x] Establish pricing and weight conventions to hold through future phases

> **Phase 3 done when:** crafting fully configured with intentional recipes, dealerships live, ox_inventory has had its first balancing pass.

---

## Phase 4 — Civilian Roleplay & Flow `In-Progress`

Give civilians a full loop: legal jobs, an identity, and early on-ramps to the criminal world.
**Part 1 (Design) must be fully documented before Part 2 (Build) begins.**

### Part 1 — Design & Planning
- [ ] Map out the full civilian experience before building anything
- [ ] Define whitelisted vs unwhitelisted jobs:
  - **Unwhitelisted** — solo/duo grind jobs, slightly annoying but rewarding, subtle pathways into criminal side
  - **Whitelisted** — more interactive, more structured, for players living an honest life
- [ ] The flow between legal and illegal should feel organic — not a switch flip
- [ ] Document full job list split by whitelisted vs unwhitelisted before any scripting

### Part 2 — Build & Polish
- [ ] pug-businesscreator — whitelisted job businesses (and potentially unwhitelisted)
- [ ] QB-Trucker — unwhitelisted legal job, foundational grind
- [ ] Qb-Helijob — unwhitelisted, higher skill ceiling, better payout
- [ ] Qb-Securityjob — unwhitelisted, opens door to criminal awareness RP
- [ ] R1-Investments — passive income layer, ties into banking
- [ ] Each job needs:
  - Locker room integration via nt_appearance
  - A clear start/end location
  - A payout that makes sense relative to Phase 1–3 economy
- [ ] Overall flow as polished as nt_character and nt_appearance — no rough edges

> **Phase 4 done when:** civilian job list is documented and locked, all jobs built with full locker/location/payout integration.

---

## Phase 5 — Emergency Services & Flow `Planned`

Police and EMS only make sense once there is a functioning economy and civilian population.
**Do not start until Phase 4 is complete. Build Police first, EMS second. Neither goes live until both are complete and tested.**

### Police Department
- [ ] wasabi_bridge ✓ Installed — configure first, every wasabi script inherits from it
  - Framework: QBX | Notifications: ox_lib | Targets: ox_target
- [ ] wasabi_police — full replacement for qb-policejob-v2, do not run both
  - Define police job grades in QBX DB before touching the script
  - Armory loadouts per grade, station locations, locker room via nt_appearance
- [ ] Advanced Evidence System (snipe-evidence)
- [ ] Evidence System Props (snipe-crimeprops) ✓ Installed
- [ ] wasabi_mdt — MDT and dispatch system, wired to wasabi_police
- [ ] keep-harmony — anti-combat logging, ties into arrest/prison flow
- [ ] Prison system — decide: qb-prison or custom solution
- [ ] Full department must be complete before any officers go on duty — no partial rollouts

### EMS / Ambulance
- [ ] wasabi_ambulance_v2 — anchor for the entire EMS phase
- [ ] Hospital system and death/respawn flow
- [ ] EMS armory and garage
- [ ] ox_inventory injury UI fork (nt fork) — anatomical body panel, per-limb health, bleeding, ties into wasabi_ambulance_v2 exports
- [ ] EMS locker room via nt_appearance

> **Phase 5 done when:** Police and EMS are both complete, tested together, and ready to go live simultaneously.

---

## Phase 6 — Criminal Roleplay & Flow `Planned`

Criminal content only lands well when there is something to lose and someone to respond to it.
**Phase 5 must be live before this phase begins.**

### Drugs & Manufacturing
- [ ] av_drugs — core drug system
- [ ] BOII-WHITEWIDOW — drug-related content
- [ ] lation_shops integration for drug-related items/supplies
- [ ] sd-crafting ties in for processing/manufacturing

### Boosting & Theft
- [ ] av_boosting_v3 — vehicle boosting
- [ ] av_laptop_v3 — hacking/laptop jobs
- [ ] av_groups — criminal group/gang structure

### Heists & Organized Crime
- [ ] k4mb1-fleecas — Fleeca bank robberies
- [ ] pug-robberycreator — configurable robbery jobs
- [ ] pug-nuketown — larger scale event content
- [ ] All heists require police on duty — configure minimum officer requirements

### Mechanic (Chop Shop / Legit)
- [ ] jg-mechanic — legitimate job and front for criminal activity
- [ ] Should bridge legal and criminal worlds intentionally

> **Phase 6 done when:** full criminal ecosystem is live with police response requirements wired in.

---

## Phase 7 — Entertainment & Minigames `Planned`

Player retention content. Launch only after core economy, jobs, and crime systems are stable.
This phase is intentionally light — if any feel forced, cut them.

- [ ] nt_3dminiGames ✓ Installed — bagging table as proof-of-concept, place minigame type only
- [ ] pug-paintball
- [ ] av_cupcake_v3
- [ ] av_alphabet
- [ ] Grandma-Roams
- [ ] QB-Gifts

---

## Phase 8 — Polish & Launch Prep `Planned`

First impressions are everything. **Do not start until everything before it is stable and tested.**
Nothing in this phase should introduce new gameplay systems — purely polish, performance, and first-impressions.

- [ ] nt_loading — loading screen, finalize tagline and visuals
- [ ] nt_thumbgen ✓ Installed — character thumbnail generation
- [ ] QB-WelcomeBook — new player onboarding
- [ ] Performance audit — profile all resources, identify and fix any >0.05ms idle offenders
- [ ] Whitelist / application system
- [ ] Discord bot integration
- [ ] Staff training — document server rules, admin procedures, and job-specific guides

---

## Phase 9+ — Future Phases `TBD`

To be defined as earlier phases complete and the server's needs become clearer.

- Housing expansion — nolag_properties QOL improvements, more shell types, interior dressing with KQ Prop Placer
- Advanced business system — pug-businesscreator deeper config, business ownership economy
- Court & legal system — DOJ, lawyer job, MDT integration
- Additional phone apps — as server grows
- Server events — seasonal content, special events, one-off scenarios
- Community tools — forums, staff apps, player reporting

---

## Development Principles

- Complete phases in full before moving on — partial systems create compounding problems
- Plan before building — every phase has a design step, even if it's just a checklist
- UI theme is non-negotiable — every script must use ox_lib or lation_ui notifications, not its own
- QBX first — always check qbox.re and coxdocs.dev before assuming how something works
- One chat per resource in Claude Code — this planning document is the source of truth
- Money flows must be documented — any script that touches player money needs to be noted
- Debug config off by default — `Config.Debug.All = false` on all resources in production
- React resources need `npm run build` + txAdmin refresh after every change

---

*NiteLife Roleplay · Internal Development Document · April 2026*

# Kensington Drift — prototype

Old-school side-scrolling alley wanderer (no combat). ~17.5 min day cycle (5 phases × 3.5 min).

## Controls

| Key | Action |
|-----|--------|
| A/D | Walk |
| E | Pick up / door / vendor |
| U | Use first usable inventory item |
| T | Skip to next time phase (debug) |
| R | Reset scene |

## Content (data-driven)

All first-alley content lives in **`data/first_alley/*.json`** — see `data/first_alley/CONTENT.md`.

| Content | Count | File |
|---------|------:|------|
| Street pickups | 20 + 5 rare | `items.json` |
| Doors | 3 | `doors.json` |
| NPCs | 3 | `npcs.json` |
| Vendors / dealers | 3 | `vendors.json` |
| Money-only props | 5 | `money_interactions.json` |
| Time-locked events | 5 | `time_events.json` |
| Segment placement | — | `placements.json` |

Loader: `scripts/content/alley_content.gd`

## Systems

- **Endless segments** — PNG slices from `assets/segments/`
- **Time of day** — Late Night → Dawn → Morning → Afternoon → Evening
- **Street objects** — phase-gated spawns; luck/happiness tweak rates
- **NPCs** — Late Night, Dawn, Evening only
- **Doors** — time locks, money, or item (Folded Note)
- **Vendors** — bodega (morning/afternoon), night dealer (late night)
- **Money** — start $8; doors/vendors/danger cost cash
- **Inventory** — collect, use (U), sell to dealers
- **Danger** — rare cut-screen; respawn nearby, lose up to $3

## Debug tuning

Inspector on **GameClock**, **AlleyState** (on SegmentManager), **Wallet**, **DangerController**:
- `seconds_per_phase`, `luck`, `happiness`, `weather`
- `debug_pause_time` on GameClock freezes the cycle

## Try a 10-minute loop

1. **Late Night** — vacant lot dealer; payphone; siren event; rare spawns.
2. **Dawn** — pigeons event; Night Walker NPC; pill bottles.
3. **Morning** — bodega vendor; trash pickup event (+$1); cart wheel.
4. **Afternoon** — garage door ($3); pawn flip; sunbreak event (+$2).
5. **Evening** — boarded loft (needs folded note); block smoke event; beer cans.

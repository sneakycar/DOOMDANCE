# Philly Drift — Chapter 1 (friend playtest)

Static-screen point-and-click. **No movement.** The city is the character.

## Run

Godot 4.6+ → open `godot-philly-alley` → Play (`scenes/game/main.tscn`).

## HUD

- **Money** (start `$8`)
- **Time** (starts `11:00 PM`, +12 min per travel)
- **Inventory**
- **COLLECTIONS** — LIQUOR / ITEMS discovery (20 entries in `data/collectibles.json`)

Hover hotspots for labels. Fade transitions between screens.

## Screens (10)

| # | ID | Notes |
|---|-----|--------|
| 1 | `impound_lot` | Start. Gate → alley. Office locked. |
| 2 | `alley` | Hub: liquor, pawn, vacant, theater, WU, SEPTA, underpass, rowhouse stoop, **boarded mystery** |
| 3 | `liquor_store` | Beer $3, Whiskey $8, Old Crow $5, Steel Reserve $4, Evan Williams $6 |
| 4 | `pawn_shop` | Griffey card, rusty key |
| 5 | `vacant_lot` | Crushed beer can, matchbook |
| 6 | `septa` | Turnstile $2 → stub message; transit map pickup |
| 7 | `movie_theater` | Lottery ticket; door boarded |
| 8 | `western_union` | Receipt, photo |
| 9 | `rowhouse` | Chained basement (locked); newspaper |
| 10 | `underpass` | Neon flyer, liquor bottle |

## Panhandle (alley)

1. **Panhandle** → 5 **real** minutes (`panhandling_until` saved).
2. Explore freely while waiting.
3. **Collect Earnings** → $0–$4 or rare receipt / bus pass / beer can.

## Weird event

Between **2:36–2:39 AM**, return to the **alley**: a figure appears behind the fence (no interaction). He leaves after you witness him once.

Travel enough locations from 11 PM to reach ~2:37 AM (~16 moves at 12 min each).

## Locked mystery

**Boarded Rowhouse** hotspot on the alley — chained basement, cannot enter yet.

## Overlays

Per-screen `overlays` in `data/screens.json`: rain, light_flicker, puddle_shimmer, steam, drifting_trash, distant_light_sweep, fluorescent_flicker, neon_buzz, train_flash.

## Extend

- New screen → `data/screens.json` + background art path.
- New collectible → `data/collectibles.json` + hotspot `collectible_id` or `buy`.

## Reset

Delete Godot user data file `philly_drift_save.cfg` or run `GameState.reset_run()` from the debugger.

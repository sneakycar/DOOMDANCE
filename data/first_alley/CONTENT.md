# First alley — data-driven content

Edit JSON under `data/first_alley/`. Godot loads these at runtime via `AlleyContent` (`scripts/content/alley_content.gd`).

## Files

| File | Purpose |
|------|---------|
| `items.json` | 20 street pickups + 5 rare (`"rare": true`) + vendor-only rows (`"vendor_only": true`) |
| `doors.json` | 3 door definitions |
| `npcs.json` | 3 NPC silhouettes |
| `vendors.json` | 3 vendors/dealers |
| `money_interactions.json` | 5 pay-to-use props (no item required) |
| `time_events.json` | 5 phase-only interactables |
| `placements.json` | Which content spawns on which segment PNG |

## Phase names

`late_night`, `dawn`, `morning`, `afternoon`, `evening`

## Segment ids

Match segment PNG ids: `dumpster_alley`, `chainlink_fence`, `auto_garage`, `vacant_lot`, `loading_dock`, `graffiti_wall`, `septa_underpass`, `bodega_exterior`, `boarded_storefront`, `dead_end_alley`

## Adding a pickup

1. Add an object to `items.json` (`id`, `label`, `spawn_weight`, `spawn_phases`, `visual`, optional `sell` / `usable`).
2. Set `"rare": true` for low spawn rate.
3. No code change needed.

## Adding a door / vendor / event

1. Define in the matching `*.json` file.
2. Add a placement entry under `placements.json` → `segments` → `doors` / `vendors` / `money` / `time_events`.

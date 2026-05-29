# DOOM DANCE — Typography (locked)

Not an RPG. Not dialogue-driven. The city is the main character.

## Layers

| Layer | Font | Use |
|-------|------|-----|
| **System UI** | IBM Plex Mono | Money, time, inventory, collections, timers, notifications |
| **Location headers** | IBM Plex Sans Condensed Bold | Signage — `IMPOUND LOT`, `LIQUOR STORE`, etc. |
| **Observations** | IBM Plex Mono | All interaction results — 1–2 sentences max, fragments OK |

Haas Grotesk / Grot Haas on other platforms maps to **IBM Plex Sans Condensed** in this Godot build (OFL, web-export safe).

## Observation rules

- Write less.
- Implication over explanation.
- No NPC monologues, lore dumps, or “you pick up…” narration.
- Prefer: `LOCKED.` / `1989.` / `$120.` / `Three empty bottles.`

## Code

- `scripts/game/doom_typography.gd` — autoload `DoomTypography`
- `data/screens.json` — `header` + observation `text` fields
- `data/copy.json` — system strings (panhandle, affordance errors)

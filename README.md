# DOOM DANCE

Static-screen exploration — Chapter 1. Not an RPG. The city is the main character.

## Play (web)

After deploy: **`https://your-domain/`** (root serves the Godot HTML5 build).

## Develop

Open this folder in **Godot 4.3+** → Play `scenes/game/main.tscn`.

## Export for Vercel

```bash
./scripts/export-web.sh
```

Requires Godot with **Web** export templates. Output: `public/index.html` (+ wasm/pck).

## Docs

- `DOOM_DANCE.md` — living index (locations, items, rules)
- `LOCATION_DESIGN.md` — location system (LOCKED): one screen at a time
- `TYPOGRAPHY.md` / `WEIGHTED_REALISM.md` — design locks
- `DEPLOY.md` — Git + Vercel + DNS

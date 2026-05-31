# DOOM DANCE — iPhone web playtest (Vercel)

## EVOL (portrait web dev)

**https://doomdance.makeawesome.com/evol/** · add **`?dev`** for fast events + debug panel.

Portrait archive terminal with memory city background. See `public/evol/README.md`.

---

## DOOM DANCE (landscape Godot — root)

## Play URL

- **`https://<your-vercel-domain>/doom-dance/index.html`**
- Shortcut: **`https://<your-vercel-domain>/doom-dance`**

## iPhone (Safari)

1. Open the URL above in **landscape**.
2. Tap labeled hotspots (no hover needed).
3. Progress saves in **localStorage** (`doom_dance_save_v1`).
4. Optional: **Add to Home Screen** → fullscreen, name **DOOM DANCE**.

## Export locally

```bash
npm run export:doom-dance
# or: ./scripts/export-doom-dance.sh
```

Requires Godot **4.3+** with Web export templates (Editor → Manage Export Templates).

Output: `public/doom-dance/` (committed by CI on push to `main`).

## CI

`.github/workflows/doom-dance-web.yml` exports on changes under `godot-philly-alley/` and commits `public/doom-dance/`.

Enable **GitHub Actions write** permission for contents on the repo.

## Vercel

Root `vercel.json` serves `/doom-dance/*` with headers for Godot WASM. Old `/philly-drift/*` URLs redirect here.

## Reset save

```js
localStorage.removeItem('doom_dance_save_v1');
```

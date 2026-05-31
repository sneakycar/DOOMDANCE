# EVOL — portrait web devtest

Live dev build for the EVOL archive engine (portrait, memory city background).

## Play URL

**https://doomdance.makeawesome.com/evol/**

Add `?dev` for fast event timing and debug controls:

**https://doomdance.makeawesome.com/evol/?dev**

## iPhone (Safari)

1. Open the URL above in **portrait**.
2. Tap the red radar pulse when an unread event exists.
3. Progress saves in **localStorage** (`evol_archive_v1`).
4. Optional: **Add to Home Screen** for fullscreen.

## Local

```bash
cd public/evol
python3 -m http.server 8788
```

Open `http://localhost:8788` (portrait frame on desktop).

## Sync from iOS project

When JSON or city art changes in the standalone EVOL iOS repo:

```bash
./scripts/sync-evol-web-dev.sh
```

Sources: `/Users/dustyaltena/Documents/dev/EVOL/ReturnButDifferent/`

## Deploy

Committed under `public/evol/`. Push to `main` → Vercel redeploys `doomdance.makeawesome.com`.

## Reset save

```js
localStorage.removeItem('evol_archive_v1');
```

## Dev controls (`?dev`)

- **GENERATE EVENT** — instant test pulse
- **KILL LIFE** — force death + archive
- **RESET ALL** — wipe save

Production timing: ~1–4 hours between events. Dev timing: ~15–45 seconds.

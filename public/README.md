# DOOM DANCE

Portrait life-archive web game.

## Live

**https://doomdance.makeawesome.com/**

Dev tools: **`?dev`** (fast events + debug panel)

## Local

```bash
cd public
python3 -m http.server 8080
```

Open **http://localhost:8080/**

Progress saves in **localStorage** (`doomdance_archive_v1`).

## Deploy

Static files under `public/`. Push to `main` → Vercel redeploys `doomdance.makeawesome.com`.

Reset save in browser console:

```js
localStorage.removeItem('doomdance_archive_v1');
```

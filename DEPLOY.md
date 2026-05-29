# Deploy DOOM DANCE (Git + Vercel)

## Export web build (no Godot installed?)

```bash
./scripts/export-web.sh
```

The script downloads Godot **4.4.1** into `.cache/godot` on first run (~90MB). You still need **Web** export templates: open the project once in the Godot editor → **Editor → Manage Export Templates → Download and Install**, then re-run the script.

Or use **GitHub Actions**: push `.github/workflows/export-web.yml` (needs PAT `workflow` scope) and enable Actions **read/write** on the repo.

---

## 1. Create GitHub repo

Name: **`DOOMDANCE`** (or `doom-dance`) — **not** makeawesome-baseball.

```bash
cd /Users/dust/Downloads/dev/DOOMDANCE
git init
git add .
git commit -m "Initial DOOM DANCE Chapter 1"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/DOOMDANCE.git
git push -u origin main
```

## 2. Vercel

1. [vercel.com/new](https://vercel.com/new) → import **`YOUR_USERNAME/DOOMDANCE`**
2. Project name: **doomdance**
3. Framework: **Other** (uses `vercel.json`)
4. Deploy — Vercel serves the committed **`public/`** web build (no Godot on Vercel)

**Build flow:** push to `main` → GitHub Action exports Godot → commits `public/**` → Vercel redeploys static files.

To rebuild locally on Mac: `./scripts/export-web.sh` then commit `public/`.

Play at: **`https://doomdance.vercel.app`** (or your custom domain at repo root).

## 3. Custom domain

Vercel → Project → **Settings → Domains** → add `doomdance.com` or `play.doomdance.com` → add DNS records at your registrar (CNAME to Vercel).

## 4. GitHub Actions

Repo **Settings → Actions → General** → **Read and write** for workflow commits.

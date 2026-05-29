# Deploy DOOM DANCE (Git + Vercel)

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
4. Deploy

Play at: **`https://doomdance.vercel.app`** (or your custom domain at repo root).

## 3. Custom domain

Vercel → Project → **Settings → Domains** → add `doomdance.com` or `play.doomdance.com` → add DNS records at your registrar (CNAME to Vercel).

## 4. GitHub Actions

Repo **Settings → Actions → General** → **Read and write** for workflow commits.

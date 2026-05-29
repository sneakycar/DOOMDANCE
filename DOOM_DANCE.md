# DOOM DANCE

Living index for Chapter 1. **Update this file whenever you add or change a location, item, collection, mystery, rule, or note.**

---

## CORE LOOP

1. **Explore** — SEPTA, maze links, location hotspots (some rooms are expensive or gated)
2. **Find / buy** — items go into **inventory** (held now)
3. **Need money?** — **panhandle** (slow, free) or **sell** at pawn (anything) / record store (vinyl at a loss)
4. **Selling removes from inventory** — item stays in **seen** log only
5. **Die** — lose ~22–55% of inventory + money tax; seen log persists
6. **Win (THE END)** — grind, not a checklist:
   - Every location visited **5×** default (**12×** Japan Doll basement)
   - Every maze page **1×** minimum
   - **55%** of maze pages visited **3×**
   - Designed for **100+ hour** completion if anyone ever does

---

## ECONOMY

| Venue | Buy | Sell |
|-------|-----|------|
| Liquor store | shelf prices | — |
| Pawn shop | catalog (`data/pawn_catalog.json`) | anything sellable · `base × pawn_rate × luck` |
| Record store | retail vinyl | vinyl only · **55%** buyback |
| Panhandle | — | cash + tier drops |

**Hidden metrics** (off HUD): mood · luck · heat · intoxication · memory — affect prices, transit gates, death loss.

**Catalog:** `data/collectibles.json` (119 items, 7 categories) — rebuild with `python3 tools/build_collectibles.py`

**Collections UI:** **HELD** (inventory) + **SEEN** (encountered, not owned) + places progress `visits/required`

---

## LOCATIONS (15 screens)

| ID | Notes |
|----|--------|
| `impound_lot` | Start |
| `liquor_store` | 7+ liquor buys |
| `ozzy_basement` | wrong door → Japan Doll |
| `tv_alley` | invert page |
| `make_awesome_news` | newspaper |
| `tv_heaven` | baseball card |
| `movie_theater` | ground scores |
| `septa_allegheny` | turnstile · transit map |
| `el_bar` | matchbook · records |
| `mattress_lot` | vacant lot |
| `panhandle` | panhandle site |
| `pawn_shop` | buy catalog · **sell counter** |
| `underpass` | panhandle site |
| `record_store` | vinyl buy / sell at loss |
| `japan_doll_basement` | **hard** · random maze weave · $45 night SEPTA |

---

## CATEGORIES

Liquor · Drugs · Vinyl · Jackets · Cards · Guns · Items

---

## DEPLOY

Git / Vercel: **`docs/DOOMDANCE_DEPLOY.md`**  
Play: **`/doom-dance`**  
Re-export: `bash scripts/export-web.sh`

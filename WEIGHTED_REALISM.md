# DOOM DANCE — Weighted realism (locked)

The city should feel **predictable enough** that rare discoveries matter.

Do not make every screen chaotic. Most days look normal. Interesting events are valuable because they are **rare**.

## Distribution

| Tier | Weight | Role |
|------|--------|------|
| **Ordinary** | 85% | Default night. Rain, closed doors, small cash, empty lots. |
| **Uncommon** | 14% | A receipt, a can, a flicker worth noticing. |
| **Legendary** | 1% | One-in-a-run moments. Bus pass. Fence Man. |

Constants live in autoload `DoomRarity` (`scripts/game/doom_rarity.gd`).

## Screen atmosphere

- **Ordinary ambient** (most screens): 0–2 overlays — e.g. `rain`, `light_flicker`, `fluorescent_flicker`.
- **Uncommon flair** (sparingly): +1 overlay such as `steam`, `puddle_shimmer`, `neon_buzz`.
- **Legendary** (scripted, not stacked on every visit): timed world events (`Fence Man`), future one-shot scenes.

Avoid stacking 4+ effects on a hub screen. The alley is a map, not a carnival.

## Events (Chapter 1)

| Event | Tier | Notes |
|-------|------|--------|
| Panhandle cash $0–$4 | Ordinary | Default payout |
| Panhandle receipt / crushed can | Uncommon | 14% roll |
| Panhandle bus pass | Legendary | 1% roll |
| Fence Man (2:36–2:39 AM) | Legendary | Time-gated, once per run |

## When adding content

1. Tag new random outcomes as ordinary / uncommon / legendary.
2. Use `DoomRarity.roll_tier()` — do not hand-roll ad-hoc percentages.
3. Update `DOOM_DANCE.md` rules if player-facing odds change.

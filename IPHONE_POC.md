# iPhone POC — modular Philly alley

## Spec
- **480×270** landscape (iPhone internal resolution)
- **Modular tiles** + **spawned props** (vintage cartoon method)
- **7 segments** scroll (3 behind, current, 3 ahead)
- **Touch:** tap left/right half of screen to walk · **Hand** to interact
- **Desktop dev:** A/D walk, E interact, T skip time phase

## Run
Open `scenes/alley.tscn` → F6

## Data
- `data/props.json` — static props + pickups (weight, phases, luck)
- `data/npcs.json` — NPCs + time-gated dialogue lines

## Abandon City pack (OpenGameArt)
Full alley backdrops + props from `Abandon City Background -TheGameAssetsMine.com-/`.

Re-run after updating the source pack:

```bash
./tools/extract_abandon_city.sh
```

Set `USE_ABANDON_CITY` in `scripts/segment/segment_library.gd` to `false` to use hand-made tiles again.

See `assets/abandon_city/ATTRIBUTION.md` for credits.

## Black & white mode

Full grayscale without editing PNGs — see **[docs/GRAYSCALE.md](docs/GRAYSCALE.md)**.

Quick toggle: select **Alley** root in `scenes/alley.tscn` → **Grayscale World** in the Inspector.

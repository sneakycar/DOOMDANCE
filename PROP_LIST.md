# Props to generate (replace placeholders)

Generate **isolated objects only** — transparent PNG, side view, no ground, no scene.

## Tiles (repeat horizontally)
| File | Size | Notes |
|------|------|-------|
| `assets/tiles/wall_tile.png` | **64×96** | Brick or chain-link slice, seamless left/right |
| `assets/tiles/sidewalk_tile.png` | **64×48** | Concrete sidewalk, seamless |
| `assets/tiles/sky_strip.png` | **480×96** | Night sky gradient (one screen wide) |
| `assets/tiles/far_buildings.png` | **480×64** | Philly row-house silhouettes, dark |

## Static props (place on sidewalk)
| ID | Size | Prompt hint |
|----|------|-------------|
| `dumpster` | 48×36 | Green metal dumpster, side view |
| `trash_bags` | 32×24 | Two black trash bags |
| `street_lamp` | 16×64 | Thin pole + warm lamp head |
| `chain_link` | 56×48 | Fence section with post |
| `puddle` | 40×10 | Wet reflection oval |
| `fire_escape` | 32×80 | Metal stairs chunk on wall |
| `boarded_window` | 40×48 | Plywood over window |
| `shopping_cart` | 36×32 | Bent cart, side view |
| `crate_stack` | 28×28 | Wooden crates |

## Pickups (small, glow/readable)
| ID | Size |
|----|------|
| `beer_can` | 14×18 |
| `loose_change` | 16×12 |
| `folded_note` | 18×14 |
| `cig_pack` | 16×14 |
| `pill_bottle` | 14×20 |

## NPCs (silhouette cels)
| ID | Size | Notes |
|----|------|-------|
| `morning_smoker` | 22×48 | Hoodie, cigarette |
| `night_walker` | 22×50 | Dark coat, hunched |
| `alley_kid` | 20×40 | Kid on crate |

## Player (already have source)
| File | Notes |
|------|-------|
| `generated images/player_sprite_bg_matched.png` | 2-frame **side** walk, chroma bg → run `./tools/convert_pixel_art.sh` |

## Generation rules (every asset)
1. **Side view only** (Paperboy / Double Dragon)
2. **Transparent PNG** (real PNG, not JPEG)
3. **Feet/base at bottom** of sprite bounds
4. **No embedded ground** — sidewalk is a separate tile
5. **SNES-readable** at 480×270 — bold silhouette, 16–32 colors
6. One object per file unless walk cycle sheet (2 frames horizontal)

## Prompt template
> Single game sprite, [OBJECT], side view, Philadelphia alley, pixel art, transparent background, no floor, no shadow baked in, 32 colors, isolated on empty background

After generating, add entries to `data/props.json` or `data/npcs.json` with `"texture": "res://assets/props/dumpster.png"` (wire texture field in next pass).

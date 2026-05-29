# Endless segment corridor

PNG set pieces from `res://assets/segments/` stitch into an infinite Kensington/Fishtown drift.

## Runtime

- **`SegmentManager`** — spawns ahead, despawns behind, keeps **5–8** segments loaded
- **`AlleySegment`** — backdrop sprite + floor collider + optional pickup slot
- **`SegmentLibrary`** — weighted random choice (repeat penalty ÷4)

## Segment PNGs

| File | Weight |
|------|--------|
| `01_dumpster_alley.png` | 14 |
| `02_chainlink_fence.png` | 12 |
| `06_graffiti_wall.png` | 12 |
| `08_bodega_exterior.png` | 12 |
| `09_boarded_storefront.png` | 11 |
| `03_auto_garage.png` | 10 |
| `04_vacant_lot.png` | 10 |
| `05_loading_dock.png` | 10 |
| `07_septa_underpass.png` | 6 |
| `10_dead_end_alley.png` | 4 |

Widths vary (120–480px); segments abut at `left_edge` / `right_edge` for seamless joins.

## Debug HUD

`segs: N | x: position | segment name`

## Alley state (debug)

`AlleyState` on **SegmentManager** (`time_of_day`, `weather`, `luck`, `happiness`). Tweaks apply live while running:

| Variable | Influences |
|----------|------------|
| `time_of_day` | Darker segments / ambient; more graffiti & NPCs at night |
| `weather` | Rain/fog tints; vacant & fence bias in fog |
| `luck` | Rare street objects; SEPTA / dock segments |
| `happiness` | Bodega vs vacant lots; clutter & NPC rate |

HUD line: `t:0.28 rain | luck:0.50 happy:0.50`

## Street objects

Weighted procedural spawns per segment (`StreetObjectLibrary` + `SegmentObjectSpawner`):

- Common: trash bag, beer can, cigarette pack
- Uncommon: pill bottle, jacket, dead phone, folded note
- Rare: baseball card, record, shopping cart

~58% of segments get 1–3 objects at random floor positions. Objects are children of the segment and despawn with it. **E** → inventory.

## Files

```
scripts/segment/segment_manager.gd
scripts/segment/segment_library.gd
scripts/segment/alley_segment.gd
scripts/segment/street_object_library.gd
scripts/segment/segment_object_spawner.gd
scenes/segment/alley_segment.tscn
```

Legacy procedural `scripts/corridor/` is unused.

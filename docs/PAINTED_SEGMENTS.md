# Painted endless alley

The walkable world is built from **480×270 full-screen paintings**, not tiled bricks.

## Your workflow

1. Generate **wide night alley panos** in Leonardo (10+ images).
2. Drop them in:
   ```
   assets/segments/painted/incoming/night/
   ```
3. Run:
   ```bash
   cd godot-philly-alley
   chmod +x tools/import_painted_segments.sh
   ./tools/import_painted_segments.sh
   ```
4. **F5** in Godot — tap left/right to walk.

Wide images are **auto-sliced** every 480px. One 4800px-wide pano → 10 walkable screens.

## How endless walking works

- **7 segments** stay loaded (3 behind, you, 3 ahead).
- Each new segment picks a **random painting** from a shuffled deck.
- **No back-to-back repeats** of the same slice.
- Props (dumpster, lamp, papers) spawn **on top** of the painting.

## Day / night (later)

Drop day versions in `incoming/day/` → same script → `assets/segments/painted/day/`.

Morning/afternoon use day folder; evening/night use night.

## Files

| Path | Role |
|------|------|
| `scripts/segment/painted_segment_deck.gd` | Shuffle bag |
| `scripts/segment/segment_library.gd` | `BACKDROP_MODE = PAINTED` |
| `assets/segments/painted/night/*.png` | Game art |

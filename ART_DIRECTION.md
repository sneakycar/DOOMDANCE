# Art direction lock — Philly Alley Night

**No painted AI concept art in-game.** Sources in `generated images/` are reference only; ship `assets/pixel/` outputs.

## Target look

- Low-resolution **bitmap** scenes (native **480×270**)
- **32–64 color** palettes per scene
- **Visible dithering** on gradients (Floyd–Steinberg at half-res, then nearest upscale)
- **Nearest-neighbor** scaling only (Godot `texture_filter = Nearest`)
- **Crushed shadows** — detail that does not read at 480×270 is removed
- **Readable silhouettes** — shape over texture, mood over realism

## References

- *Death and Taxes* ferry / underworld sequences
- *Darkwood* atmosphere
- *Kentucky Route Zero* mood
- SNES / Genesis cinematic adventure games

## Readability rule

> If a detail cannot be understood at **480×270**, remove it.

## Pipeline

Sources (reference only):

- `generated images/player_sprite_bg_matched.png` — 2-frame walk sheet (chroma `#C6E2FF`)
- `generated images/kensington_alley_bg_bitmap_pass2.png` — alley skyline

```bash
./tools/convert_pixel_art.sh
```

Outputs:

| File | Role |
|------|------|
| `assets/pixel/alley_bg.png` | 480×270 skyline (parallax backdrop) |
| `assets/pixel/player_idle.png` | idle (= walk frame 0) |
| `assets/pixel/player_walk_0.png` / `player_walk_1.png` | walk cycle (flip_h for left) |
| `assets/pixel/palette_48.png` | Scene palette reference |

## Engine settings

- Viewport: **480×270**
- `textures/canvas_textures/default_texture_filter=0` (Nearest)
- Integer window upscale via stretch settings in `project.godot`

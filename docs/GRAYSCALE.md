# Black & white (grayscale) mode

The alley can run in **full grayscale** without editing any sprite or tile PNGs.

## How it works

```
Alley
├── SegmentManager + Player   ← normal 2D world (camera follows player)
├── GrayscalePost (CanvasLayer layer 1)
│   ├── BackBufferCopy
│   └── ColorRect + grayscale_screen.gdshader   ← full viewport pass
└── UI (CanvasLayer layer 2)   ← color HUD on top
```

**Do not wrap the world in `CanvasGroup` for grayscale.** A CanvasGroup merges the entire endless alley (thousands of pixels wide) into one texture, so the camera only shows a tiny cropped box in the middle of the window.

The fix is a **fullscreen post-process** that desaturates whatever the camera already sees.

## Toggle in the editor

1. Open **`scenes/alley.tscn`**
2. Select **`Alley`**
3. **Grayscale World** — on/off (default: on)
4. **Grayscale Ui** — optional HUD gray tint (default: off)

Or hide **`GrayscalePost`** in the scene tree.

## Toggle from code

```gdscript
set_grayscale(true)       # B&W world
set_grayscale(false)      # color
```

## Adjusting the look

Edit **`shaders/grayscale_screen.gdshader`** → `contrast` (default `1.08`).

## Related files

| File | Role |
|------|------|
| `scripts/alley.gd` | `grayscale_world`, `set_grayscale()` |
| `scenes/alley.tscn` | `GrayscalePost` layer |
| `shaders/grayscale_screen.gdshader` | Screen desaturation |

Legacy `shaders/grayscale_canvas.gdshader` is unused (CanvasGroup approach).

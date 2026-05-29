#!/usr/bin/env bash
# Player + alley bitmap pipeline.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_BG="$ROOT/generated images/kensington_alley_bg_bitmap_pass2.png"
SRC_SHEET="$ROOT/generated images/player_sprite_bg_matched.png"
OUT="$ROOT/assets/pixel"
TMP="$ROOT/generated images/.tmp_frames"

mkdir -p "$OUT" "$TMP"

ensure_png() {
  local f="$1"
  if file -b "$f" | grep -qi '^PNG '; then
    return 0
  fi
  echo "  converting to PNG: $(basename "$f")"
  magick "$f" "$f.conv.png" && mv "$f.conv.png" "$f"
}

chroma_key() {
  local src="$1" dst="$2"
  local corner
  corner=$(magick "$src" -format '%[pixel:p{6,6}]' info:)
  magick "$src" -alpha set \
    -fuzz 28% -transparent "$corner" \
    -fuzz 22% -transparent white \
    -fuzz 14% -transparent '#E8E8E8' \
    -fuzz 8% -transparent '#D8D8D8' \
    "$dst"
  magick "$dst" \( +clone -alpha extract -morphology erode Octagon:1 \) \
    -alpha off -compose CopyOpacity -composite "$dst"
}

# ~20% of 270p viewport (Rewinder-scale figure in a big world).
normalize_walk_frame() {
  local src="$1" dst="$2"
  chroma_key "$src" "$TMP/keyed.png"
  magick "$TMP/keyed.png" \
    -trim +repage \
    -filter point -resize x50 \
    -background none -gravity south -extent 28x52 \
    "$dst"
}

ensure_png "$SRC_BG"
ensure_png "$SRC_SHEET"

echo "== Alley background (1024x512) =="
magick "$SRC_BG" \
  -filter box -resize 240x135! \
  -level 10%,92%,0.88 \
  -modulate 100,72,102 \
  -posterize 6 \
  -dither FloydSteinberg -colors 48 \
  -filter point -resize 1024x512! \
  "$OUT/alley_bg.png"

echo "== Player walk sheet → 2 poses, 4-frame cycle =="
W=$(magick "$SRC_SHEET" -format '%w' info:)
H=$(magick "$SRC_SHEET" -format '%h' info:)
HALF=$((W / 2))

magick "$SRC_SHEET" -crop "${HALF}x${H}+0+0" +repage "$TMP/walk_a.png"
magick "$SRC_SHEET" -crop "${HALF}x${H}+${HALF}+0" +repage "$TMP/walk_b.png"

normalize_walk_frame "$TMP/walk_a.png" "$OUT/player_walk_0.png"
normalize_walk_frame "$TMP/walk_b.png" "$OUT/player_walk_1.png"
# 2D cycle: contact A → passing (squash) → contact B → passing
magick "$OUT/player_walk_0.png" -filter point -resize 100% \
  -gravity south -background none -extent 28x52 \
  "$OUT/player_walk_0.png"
magick "$OUT/player_walk_1.png" -filter point -resize 100% \
  -gravity south -background none -extent 28x52 \
  "$OUT/player_walk_1.png"
magick "$OUT/player_walk_0.png" -filter point -resize 94%x100% \
  -gravity south -background none -extent 28x52 \
  "$OUT/player_walk_2.png"
magick "$OUT/player_walk_1.png" -filter point -resize 94%x100% \
  -gravity south -background none -extent 28x52 \
  "$OUT/player_walk_3.png"
cp "$OUT/player_walk_0.png" "$OUT/player_idle.png"

magick -size 12x4 canvas:none \
  -fill '#181a28' -draw 'ellipse 6,2 5,1 0,360' \
  "$OUT/player_shadow.png"

echo "Done → $OUT (walk_0..3 + idle, 28x52 each)"

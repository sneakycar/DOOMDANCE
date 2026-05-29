#!/usr/bin/env bash
# Slice "Abandon City" OpenGameArt pack into Philly Alley assets.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$(cd "$ROOT/.." && pwd)"
PACK="$REPO/Abandon City Background -TheGameAssetsMine.com-"
SEAMLESS="$PACK/PNGs/Background city Seamless.png"
ELEMENTS="$PACK/PNGs/Elements"
OUT="$ROOT/assets/abandon_city"
BACK="$OUT/backdrops"
PROPS="$OUT/props"

if [[ ! -f "$SEAMLESS" ]]; then
  echo "Missing pack at: $SEAMLESS"
  exit 1
fi

mkdir -p "$BACK" "$PROPS"

echo "== Tiling seamless background (8 × 480 wide, 270 tall) =="
magick "$SEAMLESS" -virtual-pixel HorizontalTile -background none \
  \( -clone 0 \) +append \( -clone 0 \) +append +append \
  -filter point -resize 3840x270! "$OUT/_strip.png"

echo "== Segment backdrops 480x270 =="
for i in $(seq 0 7); do
  x=$((i * 480))
  magick "$OUT/_strip.png" -crop 480x270+${x}+0 +repage \
    "$BACK/segment_$(printf '%02d' "$i").png"
done

echo "== Street tile from backdrop bottom =="
magick "$BACK/segment_00.png" -crop 64x48+0+222 +repage \
  -filter point "$ROOT/assets/tiles/street_tile.png"

echo "== Props (scaled, point) =="
scale_prop() {
  local src="$1" dst="$2" w="$3" h="$4"
  magick "$src" -filter point -resize "${w}x${h}!" "$dst"
}

scale_prop "$ELEMENTS/Broken Window.png" "$PROPS/broken_window.png" 40 48
scale_prop "$ELEMENTS/plank.png" "$PROPS/plank.png" 56 24
scale_prop "$ELEMENTS/Damage 1.png" "$PROPS/damage_wall.png" 64 20
scale_prop "$ELEMENTS/Damage 2.png" "$PROPS/damage_ground.png" 40 12
scale_prop "$ELEMENTS/Poster 1.png" "$PROPS/poster_1.png" 24 48
scale_prop "$ELEMENTS/Poster 2.png" "$PROPS/poster_2.png" 28 52
scale_prop "$ELEMENTS/papers 1.png" "$PROPS/papers_1.png" 32 14
scale_prop "$ELEMENTS/papers 2.png" "$PROPS/papers_2.png" 40 12
scale_prop "$ELEMENTS/papers 3.png" "$PROPS/papers_3.png" 28 14

rm -f "$OUT/_strip.png"
echo "Done → $OUT"

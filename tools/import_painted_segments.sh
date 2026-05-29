#!/usr/bin/env bash
# Import Leonardo panos → 480×270 walkable segment PNGs.
#
# Drop raw files in:
#   assets/segments/painted/incoming/night/
#   assets/segments/painted/incoming/day/   (optional)
#
# Then run:
#   ./tools/import_painted_segments.sh
#
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SEG_W=480
SEG_H=270

import_one() {
  local src="$1"
  local out_dir="$2"
  local base
  base="$(basename "$src")"
  base="${base%.*}"
  mkdir -p "$out_dir"

  local w h
  w=$(magick "$src" -format '%w' info:)
  h=$(magick "$src" -format '%h' info:)

  # Scale to game height first, then slice every 480px (wide panos → many segments).
  local strip="$out_dir/.strip_${base}.png"
  magick "$src" -filter point -resize "x${SEG_H}" "$strip"
  w=$(magick "$strip" -format '%w' info:)

  if [[ "$w" -le "$((SEG_W + 8))" ]]; then
    magick "$strip" -filter point -resize "${SEG_W}x${SEG_H}!" \
      -gravity center -extent "${SEG_W}x${SEG_H}" \
      "$out_dir/${base}.png"
    echo "  → ${base}.png (single screen)"
  else
    local x=0
    local n=0
    while [[ "$x" -lt "$w" ]]; do
      n=$((n + 1))
      local remain=$((w - x))
      local crop_w=$SEG_W
      if [[ "$remain" -lt "$SEG_W" ]]; then
        crop_w=$remain
      fi
      magick "$strip" -crop "${crop_w}x${SEG_H}+${x}+0" +repage \
        -gravity east -background none -extent "${SEG_W}x${SEG_H}" \
        "$out_dir/${base}_$(printf '%02d' "$n").png"
      x=$((x + SEG_W))
    done
    echo "  → ${base}_01..${n} (${n} screens from ${w}px wide)"
  fi
  rm -f "$strip"
}

process_incoming() {
  local phase="$1"
  local incoming="$ROOT/assets/segments/painted/incoming/${phase}"
  local outgoing="$ROOT/assets/segments/painted/${phase}"
  mkdir -p "$incoming" "$outgoing"
  local files=()
  shopt -s nullglob nocaseglob
  for f in "$incoming"/*.png "$incoming"/*.jpg "$incoming"/*.jpeg; do
    [[ -f "$f" ]] && files+=("$f")
  done
  if [[ ${#files[@]} -eq 0 ]]; then
    echo "No files in $incoming"
    return
  fi
  echo "== Import ${phase} (${#files[@]} files) → $outgoing =="
  for f in "${files[@]}"; do
    echo "$(basename "$f")"
    import_one "$f" "$outgoing"
    rm -f "$f"
  done
}

process_incoming night
process_incoming day
echo ""
echo "Done. Reload Godot (F5). Segments: $(ls -1 "$ROOT/assets/segments/painted/night"/*.png 2>/dev/null | wc -l | tr -d ' ') night"

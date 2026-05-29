#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/public"
GODOT="${GODOT:-godot4}"
if ! command -v "$GODOT" &>/dev/null; then
  GODOT=godot
fi
mkdir -p "$OUT"
cd "$ROOT"
"$GODOT" --headless --import
"$GODOT" --headless --export-release "Web" "$OUT/index.html"
cp -f web/manifest.webmanifest "$OUT/manifest.webmanifest"
echo "Exported to $OUT"

#!/usr/bin/env bash
# Sync iOS dev assets → DOOM DANCE public web
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EVOL="${EVOL_ROOT:-/Users/dustyaltena/Documents/dev/EVOL/ReturnButDifferent/ReturnButDifferent}"
DEST="$ROOT/public"

if [[ ! -d "$EVOL/Data" ]]; then
  echo "Data not found at $EVOL/Data"
  echo "Set EVOL_ROOT to your ReturnButDifferent/ReturnButDifferent folder."
  exit 1
fi

mkdir -p "$DEST/data" "$DEST/assets"
cp "$EVOL/Data/"*.json "$DEST/data/"
cp "$EVOL/Assets.xcassets/memory_city_01.imageset/memory_city_01.png" "$DEST/assets/"
echo "Synced JSON + memory_city_01 → public/"
echo "Note: origins.json is curated — regenerate with scripts/generate-origins.py if needed."

#!/usr/bin/env bash
# Sync EVOL iOS dev assets → DOOMDANCE public/evol web devtest
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EVOL="${EVOL_ROOT:-/Users/dustyaltena/Documents/dev/EVOL/ReturnButDifferent/ReturnButDifferent}"
DEST="$ROOT/public/evol"

if [[ ! -d "$EVOL/Data" ]]; then
  echo "EVOL Data not found at $EVOL/Data"
  echo "Set EVOL_ROOT to your ReturnButDifferent/ReturnButDifferent folder."
  exit 1
fi

mkdir -p "$DEST/data" "$DEST/assets"
cp "$EVOL/Data/"*.json "$DEST/data/"
cp "$EVOL/Assets.xcassets/memory_city_01.imageset/memory_city_01.png" "$DEST/assets/"
echo "Synced JSON + memory_city_01 → public/evol/"

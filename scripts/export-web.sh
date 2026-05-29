#!/usr/bin/env bash
# Export DOOM DANCE to public/ for Vercel. Downloads Godot if not installed.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/public"
# 4.4.1+ has macos.universal zips on GitHub; CI uses the same.
GODOT_RELEASE="${GODOT_RELEASE:-4.4.1}"
GODOT_TAG="${GODOT_TAG:-${GODOT_RELEASE}-stable}"
GODOT_OS="${GODOT_OS:-macos.universal}"
GODOT_ZIP="Godot_v${GODOT_RELEASE}-stable_${GODOT_OS}.zip"
# Godot 4.3.x uses tag 4.3-stable (not 4.3.1-stable) for macOS builds.
if [[ "$GODOT_RELEASE" == 4.3* ]]; then
  GODOT_TAG="4.3-stable"
  GODOT_ZIP="Godot_v4.3-stable_${GODOT_OS}.zip"
fi

resolve_godot() {
  if [[ -n "${GODOT:-}" ]] && command -v "$GODOT" &>/dev/null; then
    return
  fi
  if command -v godot4 &>/dev/null; then
    GODOT=godot4
    return
  fi
  if command -v godot &>/dev/null; then
    GODOT=godot
    return
  fi
  local cache="$ROOT/.cache/godot"
  local url="https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/${GODOT_ZIP}"
  mkdir -p "$cache"
  if [[ -x "$cache/Godot.app/Contents/MacOS/Godot" ]]; then
    GODOT="$cache/Godot.app/Contents/MacOS/Godot"
    return
  fi
  local bin
  bin=$(find "$cache" -maxdepth 1 -type f -name "Godot*" 2>/dev/null | head -1)
  if [[ -n "$bin" && -x "$bin" ]]; then
    GODOT="$bin"
    return
  fi
  echo "Godot not found. Downloading ${GODOT_TAG} (${GODOT_ZIP})…"
  curl -fsSL "$url" -o "$cache/$GODOT_ZIP"
  unzip -qo "$cache/$GODOT_ZIP" -d "$cache"
  if [[ -x "$cache/Godot.app/Contents/MacOS/Godot" ]]; then
    GODOT="$cache/Godot.app/Contents/MacOS/Godot"
  else
    GODOT=$(find "$cache" -maxdepth 1 -type f -name "Godot*" | head -1)
  fi
}

resolve_godot
echo "Using Godot: $GODOT"

mkdir -p "$OUT"
cd "$ROOT"
"$GODOT" --headless --import
"$GODOT" --headless --export-release "Web" "$OUT/index.html"
cp -f web/manifest.webmanifest "$OUT/manifest.webmanifest"
echo "Exported to $OUT"

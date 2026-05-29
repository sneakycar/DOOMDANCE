#!/usr/bin/env bash
# Export DOOM DANCE to public/ for Vercel. Downloads Godot if not installed.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/public"
GODOT_RELEASE="${GODOT_RELEASE:-4.4.1}"
GODOT_TAG="${GODOT_TAG:-${GODOT_RELEASE}-stable}"

detect_godot_os() {
  if [[ -n "${GODOT_OS:-}" ]]; then
    echo "$GODOT_OS"
    return
  fi
  case "$(uname -s)" in
    Darwin) echo "macos.universal" ;;
    Linux) echo "linux.x86_64" ;;
    *)
      echo "Unsupported OS for auto Godot download: $(uname -s)" >&2
      exit 1
      ;;
  esac
}

GODOT_OS="$(detect_godot_os)"
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
  local cache="$ROOT/.cache/godot/${GODOT_OS}"
  local url="https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/${GODOT_ZIP}"
  mkdir -p "$cache"
  if [[ -x "$cache/Godot.app/Contents/MacOS/Godot" ]]; then
    GODOT="$cache/Godot.app/Contents/MacOS/Godot"
    return
  fi
  local bin
  bin=$(find "$cache" -maxdepth 1 -type f -name "Godot*" 2>/dev/null | head -1)
  if [[ -n "$bin" ]]; then
    chmod +x "$bin"
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
    if [[ -n "$GODOT" ]]; then
      chmod +x "$GODOT"
    fi
  fi
  if [[ -z "${GODOT:-}" || ! -x "$GODOT" ]]; then
    echo "Failed to locate Godot binary after download." >&2
    exit 1
  fi
}

ensure_export_templates() {
  local tpl_dir
  if [[ "$(uname -s)" == "Darwin" ]]; then
    tpl_dir="$HOME/Library/Application Support/Godot/export_templates/${GODOT_RELEASE}.stable"
  else
    tpl_dir="$HOME/.local/share/godot/export_templates/${GODOT_RELEASE}.stable"
  fi
  if [[ -f "$tpl_dir/web_release.zip" ]]; then
    return
  fi
  echo "Installing Godot ${GODOT_RELEASE} export templates…"
  mkdir -p "$tpl_dir"
  local tpz="$ROOT/.cache/godot/export_templates.tpz"
  mkdir -p "$(dirname "$tpz")"
  curl -fsSL -o "$tpz" \
    "https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/Godot_v${GODOT_RELEASE}-stable_export_templates.tpz"
  unzip -qo "$tpz" -d "$tpl_dir"
  if [[ -d "$tpl_dir/templates" ]]; then
    mv "$tpl_dir/templates/"*.zip "$tpl_dir/"
    rmdir "$tpl_dir/templates" 2>/dev/null || true
  fi
}

resolve_godot
ensure_export_templates
echo "Using Godot: $GODOT"

mkdir -p "$OUT"
cd "$ROOT"
"$GODOT" --headless --import
"$GODOT" --headless --export-release "Web" "$OUT/index.html"
cp -f web/manifest.webmanifest "$OUT/manifest.webmanifest"
echo "Exported to $OUT"

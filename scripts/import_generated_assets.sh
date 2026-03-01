#!/usr/bin/env bash
set -euo pipefail

# Import externally generated PNG assets (e.g., from ChatGPT image generator)
# into Godot's runtime-loaded generated asset folders.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IN_DIR="${1:-$ROOT_DIR/artifacts/generated_input}"
OUT_SYM="$ROOT_DIR/godot/assets/generated/symbols"
OUT_CHAR="$ROOT_DIR/godot/assets/generated/characters"

SYMBOLS=(10 J Q K A SWORD SHIELD HELMET DRAGON_EYE WILD SCATTER DRAGON)
CHARS=(dragon knight)

mkdir -p "$OUT_SYM" "$OUT_CHAR"

missing=0
for s in "${SYMBOLS[@]}"; do
  src="$IN_DIR/symbols/${s}.png"
  dst="$OUT_SYM/${s}.png"
  if [[ -f "$src" ]]; then
    cp "$src" "$dst"
  else
    echo "Missing symbol asset: $src"
    missing=1
  fi
done

for c in "${CHARS[@]}"; do
  src="$IN_DIR/characters/${c}.png"
  dst="$OUT_CHAR/${c}.png"
  if [[ -f "$src" ]]; then
    cp "$src" "$dst"
  else
    echo "Missing character asset: $src"
    missing=1
  fi
done

if [[ "$missing" -eq 1 ]]; then
  echo "Import completed with missing files."
  exit 2
fi

echo "Imported all symbol and character assets from: $IN_DIR"

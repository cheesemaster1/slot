#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="$ROOT_DIR/tools/godot"
VERSION="${1:-4.3-stable}"

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

ARCHIVE="Godot_v${VERSION}_linux.x86_64.zip"
URL="https://github.com/godotengine/godot/releases/download/${VERSION}/${ARCHIVE}"

if [[ ! -f "$ARCHIVE" ]]; then
  echo "Downloading $URL"
  curl -fL "$URL" -o "$ARCHIVE"
else
  echo "Using existing archive: $ARCHIVE"
fi

BIN_PATH="Godot_v${VERSION}_linux.x86_64"
if [[ ! -f "$BIN_PATH" ]]; then
  unzip -o "$ARCHIVE"
fi

chmod +x "$BIN_PATH"
ln -sfn "$BIN_PATH" godot4

echo "Godot installed: $INSTALL_DIR/godot4"
"$INSTALL_DIR/godot4" --version

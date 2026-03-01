#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/docs/screenshots"
TMP_DIR="/tmp/slot_screens"
mkdir -p "$OUT_DIR" "$TMP_DIR"

if [[ ! -x "$ROOT_DIR/tools/godot/godot4" ]]; then
  echo "Missing Godot binary at tools/godot/godot4. Run ./scripts/setup_godot4.sh first." >&2
  exit 1
fi

export DISPLAY=:99
export LIBGL_ALWAYS_SOFTWARE=1
Xvfb :99 -screen 0 1280x720x24 >/tmp/xvfb_slot.log 2>&1 &
XVFB_PID=$!
cleanup() {
  kill "${GODOT_PID:-}" 2>/dev/null || true
  kill "$XVFB_PID" 2>/dev/null || true
}
trap cleanup EXIT

sleep 1
"$ROOT_DIR/tools/godot/godot4" --display-driver x11 --rendering-driver opengl3 --path "$ROOT_DIR/godot" >/tmp/godot_slot.log 2>&1 &
GODOT_PID=$!

for _ in {1..60}; do
  WIN_ID=$(xdotool search --name "Dragon Knight Slot" 2>/dev/null | head -n1 || true)
  if [[ -n "${WIN_ID:-}" ]]; then
    break
  fi
  sleep 0.5
done

if [[ -z "${WIN_ID:-}" ]]; then
  echo "Could not find Godot window. Recent log:" >&2
  tail -n 80 /tmp/godot_slot.log >&2 || true
  exit 1
fi

sleep 1
import -window "$WIN_ID" "$TMP_DIR/godot_progress_1.png"

# Toggle bonus mode and spin several times so second screenshot is visibly different.
xdotool mousemove 262 24 click 1
for _ in 1 2 3 4; do
  xdotool mousemove 318 24 click 1
  sleep 0.4
done
sleep 1
import -window "$WIN_ID" "$TMP_DIR/godot_progress_2.png"

# Convert PNGs to JPEG for lighter embeds, then store as text SVG wrappers
convert "$TMP_DIR/godot_progress_1.png" -quality 85 "$TMP_DIR/godot_progress_1.jpg"
convert "$TMP_DIR/godot_progress_2.png" -quality 85 "$TMP_DIR/godot_progress_2.jpg"

B64_1=$(base64 -w0 "$TMP_DIR/godot_progress_1.jpg")
B64_2=$(base64 -w0 "$TMP_DIR/godot_progress_2.jpg")

cat > "$OUT_DIR/godot_progress_1.svg" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="720" viewBox="0 0 1280 720">
  <image width="1280" height="720" href="data:image/jpeg;base64,${B64_1}"/>
</svg>
SVG

cat > "$OUT_DIR/godot_progress_2.svg" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="720" viewBox="0 0 1280 720">
  <image width="1280" height="720" href="data:image/jpeg;base64,${B64_2}"/>
</svg>
SVG

AE=$(compare -metric AE "$TMP_DIR/godot_progress_1.png" "$TMP_DIR/godot_progress_2.png" null: 2>&1 || true)
if [[ "${AE:-0}" == "0" ]]; then
  echo "Warning: captures are identical (AE=0)." >&2
else
  echo "Captures created. Difference metric AE=$AE"
fi

echo "Saved text-based screenshots:"
echo "  $OUT_DIR/godot_progress_1.svg"
echo "  $OUT_DIR/godot_progress_2.svg"

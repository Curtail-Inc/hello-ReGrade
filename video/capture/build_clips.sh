#!/usr/bin/env bash
# ABOUTME: Builds one 1080p VHS clip per beat from scenes.sh into video/capture/NN-*.mp4.
# ABOUTME: Measures each scene's real runtime so the clip length covers its narration.
set -euo pipefail
cd "$(dirname "$0")/.."   # video/
export PATH="$HOME/.regrade-bin:$PATH"
mkdir -p capture/tapes

BEATS=(
  "01-cold-open:title"
  "02-setup:beat02_setup"
  "03-record:beat03_record"
  "04-replay:beat04_replay"
  "05-noise:beat05_noise"
  "06-map:beat06_map"
  "07-rereplay:beat07_rereplay"
  "08-payoff:beat08_payoff"
  "09-outro:outro"
)

for b in "${BEATS[@]}"; do
  name="${b%%:*}"; fn="${b##*:}"
  TIMEFORMAT='%R'
  dur=$( { time bash capture/scenes.sh "$fn" >/dev/null 2>&1; } 2>&1 )
  sleepms=$(awk -v d="$dur" 'BEGIN{printf "%d", (d+1.3)*1000}')
  tape="capture/tapes/${name}.tape"
  cat > "$tape" <<TAPE
Output capture/${name}.mp4
Set Width 1920
Set Height 1080
Set FontSize 32
Set Padding 70
Set Theme "Catppuccin Mocha"
Set Framerate 24
Hide
Type "bash $(pwd)/capture/scenes.sh ${fn}; sleep 20"
Enter
Sleep 400ms
Show
Sleep ${sleepms}ms
TAPE
  echo "→ ${name}: scene ${dur}s, clip $(awk -v m=$sleepms 'BEGIN{printf "%.1f", m/1000}')s"
  vhs "$tape" >/dev/null 2>&1
done

echo "=== clips ==="
for f in capture/0*.mp4; do
  d=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$f")
  printf "%s  %.1fs\n" "$f" "$d"
done

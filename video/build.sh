#!/usr/bin/env bash
# Build the demo video: TTS -> episode.json -> Remotion silent render -> ffmpeg mux VO.
set -euo pipefail
cd "$(dirname "$0")"
PY=.venv/bin/python
unset -f node npm npx nvm 2>/dev/null || true

echo "== 1. voiceover =="
"$PY" tts.py script.json capture/voiceover.mp3 capture/timestamps.json

echo "== 2. episode.json =="
"$PY" build_episode.py script.json capture/timestamps.json out/episode.json

echo "== 3. remotion silent render =="
( cd remotion && npx remotion render Video ../out/silent.mp4 \
    --props=../out/episode.json --public-dir=../capture --codec=h264 )

echo "== 4. mux voiceover =="
ffmpeg -y -i out/silent.mp4 -i capture/voiceover.mp3 \
  -map 0:v -map 1:a -vf "fps=24,format=yuv420p" \
  -c:v libx264 -preset medium -crf 20 -c:a aac -ac 2 -shortest \
  out/hello-regrade.mp4
echo "✓ out/hello-regrade.mp4"

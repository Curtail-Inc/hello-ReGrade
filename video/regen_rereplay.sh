#!/usr/bin/env bash
# Regenerate ONLY the rereplay beat's voiceover, then rebuild the video.
# Keeps the other nine reviewed ElevenLabs takes byte-identical (a full
# build.sh run would re-synthesize every beat and re-roll all takes).
#
# Usage: ELEVENLABS_API_KEY=... ./regen_rereplay.sh
set -euo pipefail
cd "$(dirname "$0")"
PY=.venv/bin/python
unset -f node npm npx nvm 2>/dev/null || true

: "${ELEVENLABS_API_KEY:?set ELEVENLABS_API_KEY (the previous key was revoked)}"

echo "== 1. re-synthesize the rereplay beat only =="
"$PY" - <<'EOF'
import json, os, subprocess, sys
sys.path.insert(0, os.getcwd())
from lib.script import load_script
from tts import _elevenlabs_beat, _ffprobe_duration

BEAT_ID = "rereplay"
beats = load_script("script.json")
ts = json.load(open("capture/timestamps.json"))
idx = next(i for i, b in enumerate(beats) if b.id == BEAT_ID)
mp3 = f"capture/vo_{idx:02d}_{BEAT_ID}.mp3"
words = _elevenlabs_beat(beats[idx].vo, mp3)
ts["beats"][BEAT_ID] = {"duration": _ffprobe_duration(mp3), "words": words}
json.dump(ts, open("capture/timestamps.json", "w"), indent=2)

# Re-concat every beat in script order (never glob: capture/ has stale
# mp3s from earlier script revisions under different indices)
mp3s = [f"capture/vo_{i:02d}_{b.id}.mp3" for i, b in enumerate(beats)]
missing = [m for m in mp3s if not os.path.exists(m)]
assert not missing, f"missing beat audio: {missing}"
open("capture/vo_list.txt", "w").write(
    "".join(f"file '{os.path.abspath(m)}'\n" for m in mp3s))
subprocess.run(["ffmpeg", "-y", "-f", "concat", "-safe", "0",
                "-i", "capture/vo_list.txt", "-c", "copy",
                "capture/voiceover.mp3"], check=True)
print("rereplay beat regenerated + voiceover re-concatenated")
EOF

echo "== 2. episode.json =="
"$PY" build_episode.py script.json capture/timestamps.json out/episode.json

echo "== 3. remotion silent render =="
( cd remotion && npx remotion render Video ../out/silent.mp4 \
    --props=../out/episode.json --public-dir=../capture --codec=h264 --crf=16 )

echo "== 4. normalize voiceover loudness (streaming target ~-16 LUFS) =="
ffmpeg -y -i capture/voiceover.mp3 -af loudnorm=I=-16:TP=-1.5:LRA=11 \
  -ar 44100 -c:a libmp3lame -q:a 2 capture/voiceover_norm.mp3

echo "== 5. mux voiceover (stream-copy video — no re-encode) =="
ffmpeg -y -i out/silent.mp4 -i capture/voiceover_norm.mp3 \
  -map 0:v -map 1:a -c:v copy -c:a aac -ac 2 -b:a 192k -shortest \
  out/hello-regrade.mp4
echo "✓ out/hello-regrade.mp4"

#!/usr/bin/env bash
# Mix the music bed under the voiceover and mux with the silent render.
# Music is sidechain-ducked by the voice, so it swells only in narration gaps.
# No Remotion re-render needed — video stream is copied untouched.
#
# Inputs:  out/silent.mp4  capture/voiceover_norm.mp3  capture/music.mp3
# Output:  out/hello-regrade.mp4
#
# Tuning knobs: volume=0.22 (bed level), ratio=6 (duck depth),
# release=600 (how fast music swells back after a phrase).
set -euo pipefail
cd "$(dirname "$0")"

ffmpeg -y -i out/silent.mp4 -i capture/voiceover_norm.mp3 -i capture/music.mp3 \
  -filter_complex "\
[2:a]aformat=channel_layouts=stereo,afade=t=in:d=2,afade=t=out:st=232.5:d=4,volume=0.22[mq];\
[1:a]aformat=channel_layouts=stereo,asplit=2[vo][sc];\
[mq][sc]sidechaincompress=threshold=0.02:ratio=6:attack=20:release=600[duck];\
[vo][duck]amix=inputs=2:duration=first:normalize=0[mix];\
[mix]alimiter=limit=0.97[out]" \
  -map 0:v -map "[out]" -c:v copy -c:a aac -ac 2 -b:a 192k -shortest \
  out/hello-regrade.mp4
echo "✓ out/hello-regrade.mp4 (with music bed)"

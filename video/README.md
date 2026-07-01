# hello-ReGrade demo video

Programmatic build (Remotion + ElevenLabs VO + ffmpeg) of the ~5-min demo walkthrough.

## Prerequisites
- `assets/make_placeholder.sh` needs `python3` + Pillow (`pip install pillow`) — this
  machine's ffmpeg is built without libfreetype, so the `drawtext` filter is unavailable
  and placeholder labels are rendered with Pillow instead.

## Build
1. `export ELEVENLABS_API_KEY=...` (only needed to (re)generate the voiceover)
2. Put screen-recording clips in `capture/` named `01-cold-open.mp4` … `09-outro.mp4`
   (or run `assets/make_placeholder.sh` to generate placeholders).
3. `./build.sh` → `out/hello-regrade.mp4`

The final footage requires a working end-to-end ReGrade run; until then the pipeline
renders against placeholder clips.

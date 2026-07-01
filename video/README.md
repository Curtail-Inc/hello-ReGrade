# hello-ReGrade demo video

Programmatic build (Remotion + ElevenLabs VO + ffmpeg) of the ~5-min demo walkthrough.

## Prerequisites

- **Node 22+** (the Remotion render requires it — matches the `engines` field in `remotion/package.json`).
- **Python 3**, with the venv `build.sh` expects (it invokes `.venv/bin/python` directly, so this exact path is required, not just "some python on PATH"):
  ```bash
  python3 -m venv .venv
  .venv/bin/pip install -r requirements.txt   # elevenlabs + edge-tts
  .venv/bin/pip install pillow                # placeholder-clip generator
  .venv/bin/pip install playwright && .venv/bin/playwright install chromium  # optional, web-UI capture
  ```
- Placeholder clips are auto-generated; real footage from a working end-to-end ReGrade demo is required for production.

## Workflow

### 1. Screen Recording (Capture)

Record native screen footage of each beat in the demo (terminal + Claude Code walkthrough). Name clips sequentially:
- `capture/01-cold-open.mp4`
- `capture/02-setup.mp4`
- `capture/03-record.mp4`
- `capture/04-replay.mp4`
- `capture/05-noise.mp4`
- `capture/06-map.mp4`
- `capture/07-rereplay.mp4`
- `capture/08-payoff.mp4`
- `capture/09-outro.mp4`

Record generously (the pipeline auto-trims and time-lapses to match the voiceover pacing).

**Optional: Web-UI Recording**

For supplementary footage of the ReGrade web-UI delta view, use the Playwright helper:
```bash
python capture/record_ui.py https://app.regrade.curtail.com/orgs/.../replays/... capture/web-ui.webm
```
(Requires `playwright` installed; records 1920×1080 as a `.webm`.)

### 2. Text-to-Speech (TTS)

The pipeline uses **ElevenLabs** for the voiceover (voice ID `Gfpl8Yo74Is0W6cPUWWT`). Set the API key:
```bash
export ELEVENLABS_API_KEY=<your-key>
```

The TTS step is **keyed to the script** (`script.json`). Each beat's duration is derived from the voiceover duration (in `build_episode.py`).

**Offline / Smoke Test Mode**

For CI smoke tests or local validation without the API key, disable TTS generation:
```bash
TTS_STUB=1 ./build.sh
```

This produces silent placeholder audio; captions still render, but with evenly-spaced timing rather than voice-aligned. Validates the entire render pipeline.

### 3. Build

Run the build script:
```bash
./build.sh
```

This orchestrates:
1. **TTS rendering** (`tts.py`) — generates `voiceover.mp3` + `timestamps.json` (with frame-accurate word timings)
2. **Episode schema** (`build_episode.py`) — structures clips, captions, and timing into a Remotion-friendly JSON schema
3. **Remotion render** (`remotion/`) — Composes clips, captions (with word-level animations), and voiceover into 1080p/24fps video
4. **FFmpeg post-processing** — finalizes the output

Result: `out/hello-regrade.mp4`

### 4. Committing the Voiceover (for Keyless Re-renders)

After a successful ElevenLabs build, commit the generated TTS artifacts:
```bash
git add -f capture/voiceover.mp3 capture/timestamps.json
git commit -m "build: commit TTS voiceover for keyless re-renders"
```

These files are normally `.gitignored` (to avoid cluttering the repo with intermediate scratch). Force-adding them once enables subsequent `TTS_STUB=1` builds to reuse the same voiceover without needing the API key — useful for CI pipelines and local iteration.

### 5. Production Gate

The final render requires **real screen footage** from a working, end-to-end ReGrade demo run. Until clips `01-…`..`09-…` are recorded and `ELEVENLABS_API_KEY` is set, the pipeline validates against placeholder footage, confirming the render chain works correctly.

Once real footage is available:
1. Record or copy clips into `capture/`.
2. Run `./build.sh` with `ELEVENLABS_API_KEY` set (generates voiceover via ElevenLabs + aligned captions).
3. Commit voiceover artifacts: `git add -f capture/voiceover.mp3 capture/timestamps.json`.
4. Subsequent re-renders use `./build.sh` (reuses committed voiceover without the API key).
5. Publish `out/hello-regrade.mp4` to Curtail hosting.

## Development

- **Placeholder clips**: Run `assets/make_placeholder.sh` to generate placeholder video.
- **Script changes**: Edit `script.json`, then run `build_episode.py` to update the schema.
- **Remotion project**: See `remotion/` for Composition code (timing, caption styling, overlays).
- **Tests**: `tests/` contains unit and integration tests for the build pipeline.

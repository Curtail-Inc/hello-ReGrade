import json
import pytest
import tempfile
from build_episode import words_to_frames, chunk_cues, build_episode


def test_words_to_frames_offsets_and_scales():
    words = [{"word": "hi", "start": 0.0, "end": 0.5}, {"word": "there", "start": 0.5, "end": 1.0}]
    wf = words_to_frames(words, fps=24, offset_sec=1.0)
    assert wf[0] == {"word": "hi", "startFrame": 24, "endFrame": 36}   # (0.0+1.0)*24 .. (0.5+1.0)*24
    assert wf[1] == {"word": "there", "startFrame": 36, "endFrame": 48}


def test_chunk_cues_groups_and_bridges_gaps():
    wf = [{"word": w, "startFrame": i * 10, "endFrame": i * 10 + 5} for i, w in enumerate("a b c d e f g h".split())]
    cues = chunk_cues(wf, fps=24, max_words=7)
    assert len(cues) == 2                       # 8 words -> 7 + 1
    assert cues[0]["words"][0]["word"] == "a"
    assert cues[0]["endFrame"] == cues[1]["startFrame"]   # no blank flicker between cues


def test_duration_frames_floored_at_one():
    # Minimal script + timestamps with a ~0 duration beat
    d = tempfile.mkdtemp()
    script_path = f"{d}/s.json"
    timestamps_path = f"{d}/t.json"

    json.dump({"beats": [{"id": "a", "clip": "a.mp4", "vo": "x"}]}, open(script_path, "w"))
    json.dump({"beats": {"a": {"duration": 0.0, "words": []}}}, open(timestamps_path, "w"))

    ep = build_episode(script_path, timestamps_path, fps=24)
    assert ep["beats"][0]["durationFrames"] == 1

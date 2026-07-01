from tts import words_from_alignment


def test_words_from_alignment_splits_on_space():
    # ElevenLabs returns per-character arrays
    alignment = {
        "characters": list("hi there"),
        "character_start_times_seconds": [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7],
        "character_end_times_seconds":   [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8],
    }
    words = words_from_alignment(alignment)
    assert [w["word"] for w in words] == ["hi", "there"]
    assert words[0]["start"] == 0.0 and words[0]["end"] == 0.2
    assert words[1]["start"] == 0.3 and words[1]["end"] == 0.8

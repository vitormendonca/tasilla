# Audio Generation — Quick Start

39 listening files, generated from the authored scripts in `assets/content/a1/`.

---

## 1. Get a real API key

The dashboard list shows key **IDs**. The key itself starts with `sk_` and is
shown **only once**, when you create or rotate it.

https://elevenlabs.io/app/settings/api-keys → **Create API Key**

Permissions needed:

| Endpoint | Setting |
|---|---|
| Text to Speech | **Access** |
| Voices (if listed) | **Read** — only needed for `--list-voices` |
| Everything else | No Access |

The script rejects a key that does not start with `sk_` before spending anything.

---

## 2. Confirm the voices exist on your account

```powershell
py generate_a1_audio.py --api-key sk_YOUR_KEY --list-voices
```

Prints every voice id you have. The script defaults to four stock voices —
Rachel, Elli (female) and Adam, Josh (male). If any id is missing from your
account, paste a replacement into the `VOICES` dict at the top of the script.

---

## 3. Smoke-test one file

Do this before the full run. `A1-T05-LIS` is a two-speaker dialogue, so it
exercises voice switching and turn-taking pauses:

```powershell
py generate_a1_audio.py --api-key sk_YOUR_KEY --only A1-T05-LIS
```

Listen to `assets/audio/a1/t05_listening_how_are_you_today.mp3` and check:

- Two clearly different voices, one male (Ivo) and one female (Lena)
- A short gap at each speaker change
- Slow enough for a beginner
- No stray words like "break" or "scene" read aloud

If the pacing is off, adjust `stability` in `VOICES`; if the gaps are wrong,
adjust `PAUSE_BETWEEN_SPEAKERS` / `PAUSE_AT_SCRIPT_MARKER`. Delete the mp3 and
re-run to regenerate.

---

## 4. Generate everything

```powershell
py generate_a1_audio.py --api-key sk_YOUR_KEY
```

Already-generated files are skipped, so this is safe to re-run after a failure.
Progress and any errors land in `audio_generation_log.json`.

Preview without spending credits at any time by adding `--dry-run`.

---

## 5. Verify

```cmd
dir assets\audio\a1\t*.mp3
dir assets\audio\a1\rev*.mp3
dir assets\audio\a1\checkpoint*.mp3
dir assets\audio\a1\finalexam*.mp3
```

39 new files should be present alongside the 28 older `a1_exp_*.mp3` files,
which are unused by the current content and can be removed separately.

---

## What gets generated

| Type | Files |
|---|---|
| Topic lessons T01–T20 | 20 |
| Review sets R1–R6 | 6 |
| Mixed reviews A–G | 7 |
| Checkpoints CP1–CP4 | 4 |
| Final skill test | 1 |
| Final exam | 1 |
| **Total** | **39** |

---

## Voice assignment

Voices are assigned from evidence in the scripts, not from the order speakers
appear. This matters because the comprehension questions test it — the final
exam asks *"How does **she** spell her name?"* about the monologue narrator and
*"What does the **man** order?"* about the dialogue.

- Single-speaker lessons use a female narrator by default. Four are male —
  T03 (Tiago), R1 (Tom), R6 (Tato), CP2 (Vito) — listed in `NARRATOR_GENDER`.
- Labelled speakers use `SPEAKER_GENDER`; `Man`/`Woman` are load-bearing.
- The final exam and final test each open with an unnamed monologue narrator
  (Zara, Sandra) who is a separate person from the dialogue speakers and gets
  their own voice — three distinct voices in those two files.
- Where the content gives no gender evidence, speakers alternate male/female so
  a beginner can always tell them apart.

To re-check the whole mapping without calling the API, run with `--dry-run`.

---

## Known content note

`A1-FT-LIS.json` declares `numberOfSpeakers: 2` but the script actually has
three people (Sandra, Igor, Nena). The script wins; the generator prints a note.
Worth correcting in the content file at some point.

---

## Troubleshooting

**`invalid_api_key` / `api_key_id_used_as_api_key`**
You used the key ID. Create a new key and copy the `sk_...` value shown once.

**`elevenlabs package not found`**
```powershell
py -m pip install elevenlabs
```

**A voice id 404s**
Run `--list-voices` and replace the id in the `VOICES` dict.

**Rerunning skips everything**
That is intentional. Delete the mp3 files you want rebuilt.

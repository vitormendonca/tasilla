#!/usr/bin/env python3
"""
TASILLA A1 Audio Generation — ElevenLabs Pro Pipeline

Generates production-quality listening exercise audio from authored scripts.
Optimized for pedagogical clarity and student comprehension at A1 level.

Usage:
    python3 generate_a1_audio.py --api-key YOUR_API_KEY [--dry-run]

Requires:
    pip install elevenlabs requests

ElevenLabs API docs: https://elevenlabs.io/docs/api/text-to-speech
"""

import json
import os
import re
import sys
import argparse
from pathlib import Path
from typing import Optional
import time

# The Windows console defaults to cp1252, which cannot encode the tick/cross
# marks below — without this, a failure crashes inside its own error handler
# and hides the real cause.
for _stream in (sys.stdout, sys.stderr):
    try:
        _stream.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, ValueError):
        pass

try:
    from elevenlabs.client import ElevenLabs
except ImportError:
    print("Error: elevenlabs package not found.")
    print("Install with: pip install elevenlabs")
    sys.exit(1)

# ============================================================================
# VOICE SELECTION — PREMIUM PRO VOICES
# ============================================================================
# Selected for: clarity, teaching tone, natural pacing, A1 appropriateness

# IMPORTANT: verify these ids against YOUR account before a full run:
#     py generate_a1_audio.py --api-key sk_... --list-voices
# That prints the real voice_id for every voice you have access to. Paste the
# ones you want here (or pass --voice-primary / --voice-a / --voice-b).
#
# The defaults below are ElevenLabs' stock library voices. They exist on every
# account, but pick deliberately — these are the voices your students hear for
# the entire A1 course.

# Cast by NAME. Ids are resolved from your account at startup, so nothing here
# is a guess — if a name is not on your account the run stops and says so.
#
# The original stock voices (Rachel, Adam, Josh, Elli) were rejected for
# sounding like the default AI narration heard everywhere; the recognition is
# of the timbre itself, which no parameter tuning can undo.

VOICES = {
    "female_1": {
        "name": "Nichalia - Gentle, Kind and Sweet",
        "voice_id": None,
        "description": "Narrator — warm, approachable, easy for non-natives. "
                       "Carries 12 of the 16 monologues.",
    },
    "female_2": {
        "name": "Alice - Clear, Engaging Educator",
        "voice_id": None,
        "description": "Second female — must contrast with the narrator; the "
                       "exam needs Zara and Woman tellable apart.",
    },
    "male_1": {
        "name": "Brian - Calm, Collected and Steady",
        "voice_id": None,
        "description": "Male dialogue. If this reads too narrator-like for "
                       "casual scenes, try Chris - Charming, Down-to-Earth or "
                       "Roger - Laid-Back, Casual, Resonant.",
    },
    "male_2": {
        "name": "Robert - Calm, Clear and Professional",
        "voice_id": None,
        "description": "Second male — calm and precise. Spare slot.",
    },
}

VOICE_POOL = {"f": ["female_1", "female_2"], "m": ["male_1", "male_2"]}

# Used when the content gives no gender evidence. Alternating sex maximises how
# easily a beginner can tell two speakers apart, which is the property that
# actually matters when nothing is testing gender.
NEUTRAL_ORDER = ["male_1", "female_2", "male_2", "female_1"]

# ---------------------------------------------------------------------------
# WHO IS SPEAKING — grounded in the scripts, not guessed from names.
#
# This matters because the comprehension questions test it. A1-EXAM asks "How
# does SHE spell her name?" about the monologue narrator and "What does the MAN
# order?" about the dialogue. If the voices do not match, the exam is not just
# odd-sounding, it is unanswerable. Assigning voices in first-appearance order
# got all three of the exam's speakers backwards.
#
# Only entries with actual evidence are listed. Everything else falls through
# to NEUTRAL_ORDER, which still guarantees distinct voices.
# ---------------------------------------------------------------------------

# Single-speaker lessons: the narrator's sex.  Default is female (Rachel).
NARRATOR_GENDER = {
    "A1-T01-LIS": "f",  # Ana        — asks "What is her name?"
    "A1-T03-LIS": "m",  # Tiago      — asks "What is his mother's name?"
    "A1-T07-LIS": "f",  # Selma
    "A1-R1-LIS":  "m",  # Tom        — asks "How does he spell his name?"
    "A1-R6-LIS":  "m",  # Tato       — asks "Does his sister swim?"
    "A1-MIX-A":   "f",  # Vera
    "A1-MIX-B":   "f",  # Iva
    "A1-MIX-C":   "f",  # Duna
    "A1-CP1":     "f",  # Alba       — asks "How does she spell her name?"
    "A1-CP2":     "m",  # Vito
}

# Unlabelled monologue blocks inside multi-part scripts, keyed (file, block).
BLOCK_NARRATOR_GENDER = {
    ("A1-EXAM", 1): "f",    # Zara   — asks "How does she spell her name?"
    ("A1-FT-LIS", 1): "f",  # Sandra — asks "How does she spell her name?"
}

# Labelled speakers. "Man"/"Woman" are self-evident and are load-bearing in the
# exam; the named characters follow the scripts they appear in.
SPEAKER_GENDER = {
    "Man": "m", "Woman": "f",
    "Ivo": "m", "Lena": "f",
    "Nico": "m", "Lila": "f",
    "Carla": "f", "Dana": "f", "Malu": "f", "Mira": "f",
    "Tom": "m", "Rico": "m", "Bel": "f",
    "Lala": "f", "Mila": "f", "Zeca": "m",
    "Zilda": "f", "Beto": "m",
    "Pipa": "f", "Ciro": "m",
    "Igor": "m", "Nena": "f",
}

# Silence inserted into the audio itself, via ElevenLabs break tags.
PAUSE_BETWEEN_SPEAKERS = "0.4s"   # turn-taking gap in a dialogue
PAUSE_AT_SCRIPT_MARKER = "0.5s"   # the "|" marks authored into the scripts

# ---------------------------------------------------------------------------
# HOW HUMAN IT SOUNDS
#
# stability is the dominant control and it is inverted from intuition:
#   HIGH (0.7-1.0) = consistent, flat, monotone — reads as robotic
#   LOW  (0.3-0.5) = varied pitch and pace — reads as human
# The first pass used 0.70, which is why it sounded synthetic.
#
# There is a real tension here for a language course: expressive delivery is
# more natural but less uniformly clear, and A1 listeners need clarity. These
# values aim just far enough toward natural to stop sounding like a machine.
# Override per run with --stability / --style / --similarity to taste.
# ---------------------------------------------------------------------------

DEFAULT_VOICE_SETTINGS = {
    "stability": 0.40,          # was 0.70 — the main cause of the robotic tone
    "similarity_boost": 0.75,   # was 0.85 — very high values add artifacts
    "style": 0.30,              # was unset (0) — 0 is deliberately expressionless
    "use_speaker_boost": True,  # was declared but never sent to the API
}

# eleven_multilingual_v2 is the dependable default. If your plan exposes a newer
# model, try it with --model; expressiveness improved a lot in later versions.
DEFAULT_MODEL = "eleven_multilingual_v2"


# ============================================================================
# CONTENT SPECIFICATIONS
# ============================================================================

CONTENT_DIR = Path(__file__).parent / "assets" / "content" / "a1"
AUDIO_OUTPUT_DIR = Path(__file__).parent / "assets" / "audio" / "a1"
METADATA_FILE = Path(__file__).parent / "audio_generation_log.json"

# All files that need generation
LISTENING_FILES = {
    # Topic lessons (T01–T20)
    "A1-T01-LIS.json": "t01_listening_hello_i_am_ana.mp3",
    "A1-T02-LIS.json": "t02_listening_where_are_you_from.mp3",
    "A1-T03-LIS.json": "t03_listening_my_family.mp3",
    "A1-T04-LIS.json": "t04_listening_my_best_friend.mp3",
    "A1-T05-LIS.json": "t05_listening_how_are_you_today.mp3",
    "A1-T06-LIS.json": "t06_listening_my_house.mp3",
    "A1-T07-LIS.json": "t07_listening_my_day.mp3",
    "A1-T08-LIS.json": "t08_listening_what_time_is_it.mp3",
    "A1-T09-LIS.json": "t09_listening_how_much_is_it.mp3",
    "A1-T10-LIS.json": "t10_listening_at_the_cafe.mp3",
    "A1-T11-LIS.json": "t11_listening_at_the_shop.mp3",
    "A1-T12-LIS.json": "t12_listening_where_is_the_bank.mp3",
    "A1-T13-LIS.json": "t13_listening_two_tickets_please.mp3",
    "A1-T14-LIS.json": "t14_listening_what_is_your_job.mp3",
    "A1-T15-LIS.json": "t15_listening_in_class.mp3",
    "A1-T16-LIS.json": "t16_listening_do_you_like_music.mp3",
    "A1-T17-LIS.json": "t17_listening_weather_call.mp3",
    "A1-T18-LIS.json": "t18_listening_at_the_party.mp3",
    "A1-T19-LIS.json": "t19_listening_i_am_sick.mp3",
    "A1-T20-LIS.json": "t20_listening_my_animals.mp3",
    # Reviews (R1–R6)
    "A1-R1-LIS.json": "rev1_listening_topics1-3.mp3",
    "A1-R2-LIS.json": "rev2_listening_topics4-6.mp3",
    "A1-R3-LIS.json": "rev3_listening_topics7-9.mp3",
    "A1-R4-LIS.json": "rev4_listening_topics10-12.mp3",
    "A1-R5-LIS.json": "rev5_listening_topics13-15.mp3",
    "A1-R6-LIS.json": "rev6_listening_topics16-20.mp3",
    # Mixed reviews (A–G)
    "A1-MIX-A.json": "mixrevA_listening.mp3",
    "A1-MIX-B.json": "mixrevB_listening.mp3",
    "A1-MIX-C.json": "mixrevC_listening.mp3",
    "A1-MIX-D.json": "mixrevD_listening.mp3",
    "A1-MIX-E.json": "mixrevE_listening.mp3",
    "A1-MIX-F.json": "mixrevF_listening.mp3",
    "A1-MIX-G.json": "mixrevG_listening.mp3",
    # Checkpoints
    "A1-CP1.json": "checkpoint1_listening.mp3",
    "A1-CP2.json": "checkpoint2_listening.mp3",
    "A1-CP3.json": "checkpoint3_listening.mp3",
    "A1-CP4.json": "checkpoint4_listening.mp3",
    # Final tests
    "A1-FT-LIS.json": "finaltest_listening_audio1.mp3",  # see MULTI_PART below
    # Final exam
    "A1-EXAM.json": "finalexam_listening.mp3",
}

# Lessons whose script is split across SEPARATE audio files, one per section.
#
# A1-FT-LIS is a two-part test: questions A-Q1..A-Q9 play audio1 (Sandra's
# monologue) and B-Q1..B-Q11 carry their own audioPath pointing at audio2 (the
# Igor/Nena dialogue). Rendering both sections into one file leaves Part B's
# eleven questions with no audio and lets Part A give away the second recording.
#
# The exam is deliberately NOT here: its two scenes share one file, which is
# what its content asks for.
MULTI_PART = {
    "A1-FT-LIS.json": [
        "finaltest_listening_audio1.mp3",
        "finaltest_listening_audio2.mp3",
    ],
}


# ============================================================================
# CORE GENERATION LOGIC
# ============================================================================

class A1AudioGenerator:
    def __init__(
        self,
        api_key: str,
        dry_run: bool = False,
        model: str = DEFAULT_MODEL,
        voice_settings: Optional[dict] = None,
        suffix: str = "",
    ):
        self.client = ElevenLabs(api_key=api_key)
        self.dry_run = dry_run
        self.model = model
        if not dry_run:
            resolve_voice_ids(self.client)
        self.voice_settings = voice_settings or dict(DEFAULT_VOICE_SETTINGS)
        self.suffix = suffix
        self.metadata = self._load_metadata()
        self.output_dir = AUDIO_OUTPUT_DIR
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def _load_metadata(self) -> dict:
        """Load or initialize generation log."""
        if METADATA_FILE.exists():
            with open(METADATA_FILE) as f:
                return json.load(f)
        return {"generated": {}, "failed": {}, "timestamp": None}

    def _save_metadata(self):
        """Save generation log."""
        with open(METADATA_FILE, "w") as f:
            self.metadata["timestamp"] = time.strftime("%Y-%m-%d %H:%M:%S")
            json.dump(self.metadata, f, indent=2)

    def _load_content(self, json_file: Path) -> dict:
        """Load and parse a content JSON file."""
        with open(json_file, encoding="utf-8") as f:
            return json.load(f)

    def _extract_listening_script(self, content: dict) -> Optional[tuple[str, int]]:
        """
        Extract audioScript and numberOfSpeakers from listening block.
        Returns: (script, num_speakers) or (None, 0)
        """
        listening_block = content.get("listeningBlock")
        if not listening_block:
            return None, 0

        script = listening_block.get("audioScript", "").strip()
        num_speakers = listening_block.get("numberOfSpeakers", 1)

        if not script:
            return None, 0

        return script, num_speakers

    @staticmethod
    def _apply_pause_markers(text: str) -> str:
        """
        The authored scripts use "|" to mark a natural thought pause. Sent to the
        API raw, the model reads it as a stray character. Convert it to a real
        break so the silence lands in the audio.
        """
        parts = [part.strip() for part in text.split("|")]
        parts = [part for part in parts if part]

        return f' <break time="{PAUSE_AT_SCRIPT_MARKER}" /> '.join(parts)

    @staticmethod
    def _is_stage_direction(line: str) -> bool:
        """
        "SCENE 1 (monologue):" / "AUDIO 2 (natural-pace dialogue):" are production
        notes for whoever records the audio. They are NOT speech — reading them
        aloud would tell a student "SCENE ONE MONOLOGUE" in the middle of the
        final exam. A header is a line that ends at the colon with nothing after.
        """
        return bool(re.match(r"^(scene|audio|part|track)\b[^:]*:\s*$", line, re.I))

    @staticmethod
    def _speaker_label(line: str) -> Optional[tuple[str, str]]:
        """
        Return (speaker, text) if the line opens with a real speaker label.

        The scripts also use ordinary mid-sentence colons — "My brother is sick:
        he has a headache" — which must not be mistaken for a speaker. A genuine
        label is short, one or two words, no digits, no sentence punctuation.
        """
        if ":" not in line:
            return None

        prefix, text = line.split(":", 1)
        prefix, text = prefix.strip(), text.strip()

        if not prefix or len(prefix) > 15 or len(prefix.split()) > 2:
            return None
        if any(char.isdigit() for char in prefix):
            return None
        if any(char in prefix for char in ".!?,;|"):
            return None

        return prefix, text

    def _prepare_dialogue(
        self, script: str, num_speakers: int, stem: str = ""
    ) -> list[tuple[str, str]]:
        """
        Parse a script into (voice_id, text) segments — one API call each,
        because a single call cannot switch voices mid-audio.

        Three shapes appear in the content and all three must work:

          1. Plain monologue (most topics) — one voice, no labels.
          2. Labelled dialogue ("Ivo: ..." / "Lena: ...") — a voice per name.
          3. Multi-part scripts (final exam, final test) — stage-direction
             headers separating an unlabelled monologue from a labelled
             dialogue. The monologue speaker has no name but is still a
             distinct person and gets their own voice.

        `num_speakers` from the content is advisory only: A1-FT-LIS declares 2
        but actually has three people (Sandra, Igor, Nena). The script itself is
        the source of truth.
        """
        lines = [line.strip() for line in script.split("\n")]
        lines = [line for line in lines if line]

        has_structure = any(
            self._is_stage_direction(line) or self._speaker_label(line)
            for line in lines
        )

        if not has_structure:
            gender = NARRATOR_GENDER.get(stem, "f")
            voice_key = VOICE_POOL[gender][0]
            return [(
                VOICES[voice_key]["voice_id"],
                self._apply_pause_markers(script),
                0,
            )]

        segments: list[tuple[str, str, int]] = []
        speaker_voices: dict[str, str] = {}
        taken: list[str] = []
        block = 0
        block_started = False  # has this section produced a segment yet?

        def voice_for(speaker: str, gender: Optional[str]) -> str:
            """Give each speaker a voice: right sex when known, always distinct."""
            if speaker in speaker_voices:
                return speaker_voices[speaker]

            candidates = VOICE_POOL.get(gender, []) if gender else []
            choice = next((key for key in candidates if key not in taken), None)

            if choice is None:
                choice = next((key for key in NEUTRAL_ORDER if key not in taken), None)
            if choice is None:
                raise ValueError(
                    f"Script needs more than {len(VOICES)} distinct voices. "
                    f"Add another entry to VOICES and VOICE_POOL."
                )

            taken.append(choice)
            speaker_voices[speaker] = VOICES[choice]["voice_id"]
            return speaker_voices[speaker]

        for line in lines:
            if self._is_stage_direction(line):
                # Not spoken. Starts a new section, so unlabelled speech that
                # follows belongs to a different person than the section before.
                block += 1
                block_started = False
                continue

            labelled = self._speaker_label(line)

            if labelled:
                speaker, text = labelled
                voice_id = voice_for(speaker, SPEAKER_GENDER.get(speaker))
                segments.append((voice_id, text, block))
                block_started = True
                continue

            # Unlabelled line. Once a section is under way this is a wrapped
            # continuation of the current turn ("...an apple,\nplease?"), NOT a
            # new person — treating it as one was handing a third voice to
            # every two-speaker dialogue.
            if block_started:
                voice_id, previous, seg_block = segments[-1]
                segments[-1] = (voice_id, f"{previous} {line}", seg_block)
                continue

            # A section that opens with unlabelled speech is a narrator
            # monologue (the final exam's Zara, the final test's Sandra) —
            # a real speaker who simply has no name prefix.
            narrator = f"__block{block}"
            gender = BLOCK_NARRATOR_GENDER.get((stem, block))
            segments.append((voice_for(narrator, gender), line, block))
            block_started = True

        if num_speakers and len(speaker_voices) != num_speakers:
            print(
                f"      note: script has {len(speaker_voices)} speakers, "
                f"content says {num_speakers} — using the script."
            )

        # Turn-taking silence, baked into the audio rather than left to chance.
        # No trailing break on the last turn of a section — a section may be the
        # end of its own file, and dead air at the end sounds like a fault.
        prepared = []
        for index, (voice_id, text, seg_block) in enumerate(segments):
            text = self._apply_pause_markers(text)
            last_of_block = (
                index == len(segments) - 1 or segments[index + 1][2] != seg_block
            )
            if not last_of_block:
                text = f'{text} <break time="{PAUSE_BETWEEN_SPEAKERS}" />'
            prepared.append((voice_id, text, seg_block))

        return prepared

    def _generate_audio_for_pair(
        self,
        voice_id: str,
        text: str,
        previous_text: Optional[str] = None,
        next_text: Optional[str] = None,
    ) -> bytes:
        """
        Render one speaker's turn.

        `previous_text` / `next_text` are what stop a dialogue sounding like
        five unrelated announcements stitched together. Each turn is a separate
        API call (a call cannot switch voices), so without them the model reads
        every line cold, with no idea it is answering a question or building on
        what came before. Feeding it the surrounding lines lets intonation carry
        across the conversation the way it does in real speech.
        """
        audio = self.client.text_to_speech.convert(
            text=text,
            voice_id=voice_id,
            model_id=self.model,
            voice_settings=self.voice_settings,
            previous_text=previous_text,
            next_text=next_text,
        )

        return b"".join(audio)

    def generate_file(self, json_file: str, output_mp3: str) -> bool:
        """
        Generate audio for a single listening lesson.
        Returns True if successful, False otherwise.
        """
        json_path = CONTENT_DIR / json_file

        # Most lessons are one file; a two-part test is several, one per section.
        outputs = MULTI_PART.get(json_file, [output_mp3])
        if self.suffix:
            outputs = [
                f"{name.rsplit('.', 1)[0]}__{self.suffix}.{name.rsplit('.', 1)[1]}"
                for name in outputs
            ]

        if all((self.output_dir / name).exists() for name in outputs):
            print(f"  ✓ {outputs[0]} (already exists, skipping)")
            return True

        try:
            content = self._load_content(json_path)
            script, num_speakers = self._extract_listening_script(content)

            if not script:
                print(f"  ✗ {outputs[0]} (no audioScript in listeningBlock)")
                self.metadata["failed"][outputs[0]] = "no_script"
                return False

            label = " + ".join(outputs) if len(outputs) > 1 else outputs[0]
            print(f"  → {label} ({num_speakers} speaker{'s' if num_speakers != 1 else ''})")

            pairs = self._prepare_dialogue(
                script, num_speakers, stem=json_file.replace(".json", "")
            )

            # Sections in first-appearance order, mapped onto the output files.
            block_order = list(dict.fromkeys(block for _, _, block in pairs))
            if len(outputs) > 1 and len(block_order) != len(outputs):
                print(f"      ✗ script has {len(block_order)} section(s) but "
                      f"{len(outputs)} audio files are expected")
                self.metadata["failed"][outputs[0]] = "section/file mismatch"
                return False

            if self.dry_run:
                print(f"      [DRY RUN] {len(pairs)} segment(s) across "
                      f"{len(block_order)} section(s)")
                print(f"      First segment: {pairs[0][1][:60]}...")
                return True

            # Strip break tags when passing a line as context — they are
            # directions for the renderer, not words the model should weigh.
            plain = [re.sub(r"<break[^>]*/>", " ", text).strip() for _, text, _ in pairs]

            rendered = []
            for index, (voice_id, text, block) in enumerate(pairs):
                audio_bytes = self._generate_audio_for_pair(
                    voice_id,
                    text,
                    previous_text=plain[index - 1] if index > 0 else None,
                    next_text=plain[index + 1] if index + 1 < len(plain) else None,
                )
                rendered.append((block, audio_bytes))
                time.sleep(0.1)  # be polite to the API between calls

            for position, block in enumerate(block_order):
                name = outputs[position] if len(outputs) > 1 else outputs[0]
                target = self.output_dir / name

                with open(target, "wb") as handle:
                    for seg_block, audio_bytes in rendered:
                        if len(outputs) == 1 or seg_block == block:
                            handle.write(audio_bytes)

                size_kb = target.stat().st_size / 1024
                self.metadata["generated"][name] = {
                    "size_kb": round(size_kb, 1),
                    "num_speakers": num_speakers,
                    "model": self.model,
                    "voice_settings": self.voice_settings,
                    "status": "success",
                }
                print(f"      ✓ {name} ({size_kb:.1f} KB)")

                if len(outputs) == 1:
                    break
            return True

        except Exception as e:
            print(f"  ✗ {output_mp3} (error: {str(e)})")
            self.metadata["failed"][output_mp3] = str(e)
            return False

    def generate_all(self):
        """Generate all 40 listening exercise audio files."""
        print("\n" + "=" * 70)
        print("TASILLA A1 Audio Generation")
        print(f"Mode: {'DRY RUN' if self.dry_run else 'GENERATE'}")
        print("=" * 70 + "\n")

        total = len(LISTENING_FILES)
        success = 0
        failed = 0

        for i, (json_file, mp3_file) in enumerate(LISTENING_FILES.items(), 1):
            print(f"[{i}/{total}]", end=" ")
            if self.generate_file(json_file, mp3_file):
                success += 1
            else:
                failed += 1
            time.sleep(0.5)  # Rate limiting — ElevenLabs API

        # Save metadata
        self._save_metadata()

        print("\n" + "=" * 70)
        print(f"Results: {success} generated, {failed} failed")
        print(f"Metadata saved to: {METADATA_FILE}")
        print("=" * 70 + "\n")

        return failed == 0


# ============================================================================
# CLI
# ============================================================================

def resolve_voice_ids(client: "ElevenLabs") -> None:
    """
    Fill in each cast member's voice_id by looking its name up on the account.

    Hardcoding ids invites exactly the failure this project already hit once —
    an id that looks plausible, belongs to a different voice, and is only caught
    by listening. Resolving by name means a wrong name fails loudly and
    immediately instead of quietly casting the wrong actor.
    """
    missing = {key: entry for key, entry in VOICES.items() if not entry["voice_id"]}
    if not missing:
        return

    try:
        available = client.voices.get_all().voices
    except Exception as error:
        if "voices_read" in str(error):
            print("\nThis API key cannot read your voice list, so names cannot")
            print("be resolved to ids. Either:")
            print("  1. add the 'Voices > Read' permission to the key, or")
            print("  2. paste the ids directly into VOICES in this script.")
            print("\nVoice ids are on each voice's page in the ElevenLabs app.\n")
            sys.exit(1)
        raise

    by_name = {voice.name.strip().lower(): voice for voice in available}

    problems = []
    for key, entry in missing.items():
        wanted = entry["name"].strip().lower()

        match = by_name.get(wanted)
        if match is None:
            # Library names usually carry a descriptive suffix, e.g.
            # "Nichalia - Gentle, Kind and Sweet". A bare first name is fine
            # when it is unique, but this account has two Brians and two Lilys,
            # so ambiguity must be reported rather than resolved by coin flip.
            candidates = [
                voice for name, voice in by_name.items() if name.startswith(wanted)
            ]
            if len(candidates) == 1:
                match = candidates[0]
            elif candidates:
                names = "; ".join(sorted(v.name for v in candidates))
                problems.append(f"{entry['name']!r} is ambiguous -> {names}")
                continue

        if match is None:
            problems.append(f"{entry['name']!r} is not on your account")
        else:
            entry["voice_id"] = match.voice_id
            entry["name"] = match.name

    if problems:
        print()
        for problem in problems:
            print(f"  {problem}")
        print("\nUse the full name exactly as it appears. Your voices:")
        for name in sorted(voice.name for voice in available):
            print(f"  {name}")
        print()
        sys.exit(1)

    print("cast: " + "  ".join(
        f"{key}={entry['name']}" for key, entry in VOICES.items()
    ))


# A real line from the course, not a generic sample. It carries a greeting, a
# self-introduction and a warm sign-off, so you hear range rather than one flat
# sentence — and you hear it saying what students will actually hear.
AUDITION_TEXT = (
    "Hello! Good morning. My name is Ana. "
    "I am your English teacher. Nice to meet you!"
)


def audition(generator: "A1AudioGenerator", voice_ids: list[str]) -> None:
    """
    Render the same line in several candidate voices so they can be compared
    back to back. Casting is the decision that most determines whether the
    course sounds like a person or like software; it deserves a real listen.
    """
    out_dir = AUDIO_OUTPUT_DIR / "_auditions"
    out_dir.mkdir(parents=True, exist_ok=True)

    print(f"\nAuditioning {len(voice_ids)} voice(s) -> {out_dir}\n")

    for voice_id in voice_ids:
        voice_id = voice_id.strip()
        if not voice_id:
            continue

        path = out_dir / f"{voice_id}.mp3"
        try:
            audio = generator.client.text_to_speech.convert(
                text=AUDITION_TEXT,
                voice_id=voice_id,
                model_id=generator.model,
                voice_settings=generator.voice_settings,
            )
            path.write_bytes(b"".join(audio))
            print(f"  ok    {voice_id}  ({path.stat().st_size / 1024:.0f} KB)")
        except Exception as error:
            print(f"  fail  {voice_id}  {error}")

    print(f"\nListen to them, then paste me the ids you want and where each "
          f"should sit (narrator / male / second female).\n")


def list_voices(api_key: str) -> None:
    """Print the real voice ids on this account — the only trustworthy source."""
    client = ElevenLabs(api_key=api_key)

    try:
        response = client.voices.get_all()
    except Exception as error:
        if "voices_read" in str(error):
            print("\nThis key cannot list voices — it lacks the 'voices_read'")
            print("permission. That is fine: listing is only a convenience.")
            print("\nEither add Voices > Read to the key, or skip it and go")
            print("straight to a smoke test, which validates the voice ids too:")
            print("\n    py generate_a1_audio.py --api-key sk_... --only A1-T05-LIS\n")
            sys.exit(1)
        raise

    print(f"\n{'VOICE ID':<26}  {'NAME':<22}  CATEGORY")
    print("-" * 70)
    for voice in response.voices:
        category = getattr(voice, "category", "") or ""
        print(f"{voice.voice_id:<26}  {voice.name:<22}  {category}")
    print(f"\n{len(response.voices)} voices available.")
    print("Paste the ids you want into the VOICES dict at the top of this file.\n")


def main():
    parser = argparse.ArgumentParser(
        description="Generate production-quality A1 listening audio with ElevenLabs"
    )
    parser.add_argument(
        "--api-key",
        help="ElevenLabs API key — starts with 'sk_'. "
             "Falls back to the ELEVENLABS_API_KEY env var.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview generation without making API calls",
    )
    parser.add_argument(
        "--list-voices",
        action="store_true",
        help="List the voice ids available on your account, then exit",
    )
    parser.add_argument(
        "--only",
        metavar="STEM",
        help="Generate a single lesson, e.g. --only A1-T05-LIS. Use this to "
             "check voice and pacing before committing to the full run.",
    )
    parser.add_argument(
        "--stability", type=float,
        help=f"0.0-1.0. LOW is more human, HIGH is more monotone. "
             f"Default {DEFAULT_VOICE_SETTINGS['stability']}. Try 0.3 for more life.",
    )
    parser.add_argument(
        "--style", type=float,
        help=f"0.0-1.0 expressiveness. Default {DEFAULT_VOICE_SETTINGS['style']}. "
             f"Higher is livelier but less uniformly clear.",
    )
    parser.add_argument(
        "--similarity", type=float,
        help=f"0.0-1.0. Default {DEFAULT_VOICE_SETTINGS['similarity_boost']}. "
             f"Very high values introduce artifacts.",
    )
    parser.add_argument(
        "--model", default=DEFAULT_MODEL,
        help=f"Model id. Default {DEFAULT_MODEL}.",
    )
    parser.add_argument(
        "--suffix", default="",
        help="Append a tag to output filenames so you can compare settings "
             "side by side, e.g. --suffix warm gives t05_..__warm.mp3",
    )
    parser.add_argument(
        "--audition", metavar="IDS",
        help="Comma-separated voice ids. Renders the same course line in each "
             "so you can compare candidates before casting the course.",
    )

    args = parser.parse_args()

    api_key = args.api_key or os.getenv("ELEVENLABS_API_KEY")
    if not api_key:
        print("Error: pass --api-key or set the ELEVENLABS_API_KEY env var.")
        sys.exit(1)

    # The dashboard list shows key IDs; the key itself is only revealed once,
    # when you create or rotate it. Catch the mix-up before burning 39 calls.
    if not api_key.startswith("sk_"):
        print("Error: that looks like an API key ID, not an API key.")
        print("Real keys start with 'sk_' and are shown only at creation/rotation.")
        print("Create one at: https://elevenlabs.io/app/settings/api-keys")
        sys.exit(1)

    if args.list_voices:
        list_voices(api_key)
        sys.exit(0)

    settings = dict(DEFAULT_VOICE_SETTINGS)
    if args.stability is not None:
        settings["stability"] = args.stability
    if args.style is not None:
        settings["style"] = args.style
    if args.similarity is not None:
        settings["similarity_boost"] = args.similarity

    print(f"model={args.model}  " + "  ".join(f"{k}={v}" for k, v in settings.items()))

    generator = A1AudioGenerator(
        api_key=api_key,
        dry_run=args.dry_run,
        model=args.model,
        voice_settings=settings,
        suffix=args.suffix,
    )

    if args.audition:
        audition(generator, args.audition.split(","))
        sys.exit(0)

    if args.only:
        key = args.only if args.only.endswith(".json") else f"{args.only}.json"
        if key not in LISTENING_FILES:
            print(f"Error: '{args.only}' is not a listening lesson.")
            print("Valid stems: " + ", ".join(
                name.replace(".json", "") for name in list(LISTENING_FILES)[:6]
            ) + ", ...")
            sys.exit(1)

        ok = generator.generate_file(key, LISTENING_FILES[key])
        generator._save_metadata()
        sys.exit(0 if ok else 1)

    success = generator.generate_all()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()

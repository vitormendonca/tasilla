#!/usr/bin/env python3
"""Generate TASILLA A1 audio files using the ElevenLabs API."""

import os
import io
import sys
import time
import requests

OUTPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "audio", "a1")

API_KEY = os.environ.get("ELEVENLABS_API_KEY")
if not API_KEY:
    print("ERROR: ELEVENLABS_API_KEY environment variable is not set.")
    sys.exit(1)

# ElevenLabs premade voice IDs
VOICES = {
    "ANNA":  "21m00Tcm4TlvDq8ikWAM",  # Rachel  – warm female
    "SARAH": "EXAVITQu4vr4xnSDxMaL",  # Sarah   – clear female / narrator
    "LEO":   "TxGEqnHWrfWFTfGW9XjX",  # Josh    – young male
    "TOM":   "nPczCjzI2devNBz1zQrb",  # Brian   – friendly male
}

API_URL = "https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
MODEL = "eleven_multilingual_v2"
VOICE_SETTINGS = {
    "stability": 0.5,
    "similarity_boost": 0.75,
    "speed": 0.9,
}

# ---------------------------------------------------------------------------
# Content definitions
# ---------------------------------------------------------------------------

SINGLES = [
    (
        "a1_exp_001_meeting_anna.mp3", "ANNA",
        "Hello! My name is Anna.\nI am from Canada.\nNice to meet you.",
    ),
    (
        "a1_exp_003_countries.mp3", "LEO",
        "Hi! I am Lucas.\nI am from Brazil.\nI am Brazilian.",
    ),
    (
        "a1_exp_004_numbers_age.mp3", "SARAH",
        "Hi! My name is Sarah.\nI am twenty-five years old.\nMy brother is thirty.",
    ),
    (
        "a1_exp_010_foundation_challenge.mp3", "TOM",
        "Hello. My name is Alex.\nI am twenty-eight years old.\nI am from Canada.\n"
        "I live in Toronto.\nMy sister lives in Vancouver.",
    ),
    (
        "a1_exp_011_my_family.mp3", "SARAH",
        "Hi, I'm Emma.\nThis is my family.\nMy mother is Ana.\nMy father is Mark.\n"
        "I have one brother.\nHis name is Leo. He is twelve.",
    ),
    (
        "a1_exp_012_describing_people.mp3", "ANNA",
        "This is Daniel.\nHe is my friend.\nHe is tall and kind.\nThis is Sofia.\n"
        "She is short and funny.\nShe is a student.",
    ),
    (
        "a1_exp_013_things_i_like.mp3", "SARAH",
        "Hi, I'm Maya.\nI like music and books.\nI love movies.\nI don't like coffee.\n"
        "My favorite sport is soccer.",
    ),
    (
        "a1_exp_014_daily_routine.mp3", "LEO",
        "My name is Leo.\nI wake up at seven.\nI eat breakfast at seven thirty.\n"
        "I work in the morning.\nI study English at night.\nI sleep at ten.",
    ),
    (
        "a1_exp_015.mp3", "TOM",
        "Hi, I'm Paulo.\nOn Monday, I have English class at seven.\n"
        "On Wednesday, I work in the morning.\nOn Saturday, I play soccer at six.\n"
        "On Sunday, I relax in the evening.",
    ),
    (
        "a1_exp_016_my_activities.mp3", "LEO",
        "I'm Bruno.\nI study English every day.\nI read at night.\n"
        "I sometimes watch movies.\nI play soccer on weekends.",
    ),
    (
        "a1_exp_018.mp3", "ANNA",
        "My name is Carla.\nI'm twenty-three years old.\nI live in Lima.\n"
        "I have one sister.\nI study English every day.\nI like books and music.",
    ),
    (
        "a1_exp_019_talking_about_someone.mp3", "SARAH",
        "This is Nina.\nShe lives in Quito.\nShe works in a school.\n"
        "She studies English at night.\nShe likes music.\nShe has one brother.",
    ),
    (
        "a1_exp_020_personal_life_challenge.mp3", "TOM",
        "My name is Rafael.\nI live in Bogota.\n"
        "I work in the morning and study English every day.\nI have one sister.\n"
        "Her name is Clara.\nShe is friendly and she likes music.\n"
        "On weekends, we play soccer.",
    ),
    (
        "a1_new_places_in_town.mp3", "SARAH",
        "This is my street.\nThe bank is next to the supermarket.\n"
        "The school is near the park.\nThe pharmacy is in front of the bus stop.\n"
        "I like my street.",
    ),
    (
        "a1_new_classroom_language.mp3", "ANNA",
        "Good morning, class.\nOpen your books, please.\nListen and repeat.\n"
        "Read the text.\nNow, answer the questions.\nVery good!",
    ),
    (
        "a1_new_short_message.mp3", "TOM",
        "Hi, Maria. This is Paulo.\nThe class is on Tuesday at seven.\n"
        "Please bring your book.\nSee you there. Bye!",
    ),
    (
        "a1_exp_028.mp3", "SARAH",
        "The bus to the city is at nine.\nThe station is near the bank.",
    ),
]

DIALOGUES = [
    ("a1_exp_002_first_conversation.mp3", [
        ("TOM",  "Good morning! How are you?"),
        ("ANNA", "I am fine, thank you. How are you?"),
        ("TOM",  "I am good. See you later!"),
        ("ANNA", "Goodbye!"),
    ]),
    ("a1_exp_006_basic_questions.mp3", [
        ("ANNA", "Hello! What is your name?"),
        ("LEO",  "My name is Leo."),
        ("ANNA", "Where are you from?"),
        ("LEO",  "I am from Brazil."),
        ("ANNA", "How old are you?"),
        ("LEO",  "I am twenty years old."),
    ]),
    ("a1_exp_009_simple_conversation.mp3", [
        ("TOM",   "Hi! What is your name?"),
        ("SARAH", "My name is Sofia."),
        ("TOM",   "Nice to meet you."),
        ("SARAH", "Nice to meet you too."),
        ("TOM",   "Where are you from?"),
        ("SARAH", "I am from Spain."),
    ]),
    ("a1_exp_017_present_questions.mp3", [
        ("ANNA", "Do you study English?"),
        ("LEO",  "Yes, I do."),
        ("ANNA", "Do you like music?"),
        ("LEO",  "Yes, I do."),
        ("ANNA", "Do you play soccer?"),
        ("LEO",  "No, I don't."),
    ]),
    ("a1_exp_023.mp3", [
        ("TOM",  "Good morning. How much is the coffee?"),
        ("ANNA", "It's five dollars."),
        ("TOM",  "And the sandwich?"),
        ("ANNA", "It's eight dollars."),
        ("TOM",  "One coffee, please."),
        ("ANNA", "Here you are. Thank you!"),
    ]),
    ("a1_exp_033.mp3", [
        ("ANNA", "Do you work?"),
        ("LEO",  "Yes, I work in an office."),
        ("ANNA", "When do you work?"),
        ("LEO",  "In the morning. I study English at night."),
    ]),
    ("a1_new_spelling_names.mp3", [
        ("ANNA", "What is your name, please?"),
        ("TOM",  "My name is Bradley."),
        ("ANNA", "Can you spell that?"),
        ("TOM",  "Yes. B-R-A-D-L-E-Y."),
        ("ANNA", "Thank you, Bradley."),
    ]),
    ("a1_new_phone_number.mp3", [
        ("ANNA",  "What is your phone number?"),
        ("SARAH", "It's nine, nine, four, five, two, one, eight, seven."),
        ("ANNA",  "Nine, nine, four, five, two, one, eight, seven?"),
        ("SARAH", "Yes, that's right."),
    ]),
    ("a1_new_telling_time.mp3", [
        ("LEO",   "What time is it?"),
        ("SARAH", "It's eight o'clock."),
        ("LEO",   "And what time is the English class?"),
        ("SARAH", "At eight thirty."),
        ("LEO",   "Thank you!"),
    ]),
    ("a1_exp_038.mp3", [
        ("SARAH", "Hi, I am Sofia. I study English."),
        ("TOM",   "Nice to meet you. I am Marco. I work in a store."),
    ]),
    ("a1_final_exam_listening.mp3", [
        ("ANNA", "Hi, I'm Anna. I'm from Canada. I'm twenty-six years old."),
        ("TOM",  "Nice to meet you. My name is Tom. I'm from Brazil."),
        ("ANNA", "What do you do, Tom?"),
        ("TOM",  "I work in a school. I study English at night."),
        ("ANNA", "I live in Toronto with my sister. We like music and coffee."),
        ("TOM",  "On Saturdays, I play soccer. See you later!"),
        ("ANNA", "Goodbye!"),
    ]),
]

DIALOGUE_PAUSE_MS = 400

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def tts(text: str, voice_key: str) -> bytes:
    """Call the ElevenLabs TTS endpoint and return raw MP3 bytes."""
    url = API_URL.format(voice_id=VOICES[voice_key])
    headers = {
        "xi-api-key": API_KEY,
        "Content-Type": "application/json",
    }
    payload = {
        "text": text,
        "model_id": MODEL,
        "voice_settings": VOICE_SETTINGS,
    }
    resp = requests.post(url, json=payload, headers=headers, timeout=60)
    resp.raise_for_status()
    return resp.content


def generate_single(filename: str, voice_key: str, text: str) -> int:
    """Generate a single-voice MP3. Returns character count (0 if skipped)."""
    path = os.path.join(OUTPUT_DIR, filename)
    if os.path.exists(path):
        print(f"  SKIP  {filename} (already exists)")
        return 0

    print(f"  GEN   {filename} [{voice_key}] ...", end=" ", flush=True)
    audio = tts(text, voice_key)
    with open(path, "wb") as f:
        f.write(audio)
    print(f"done ({len(audio):,} bytes)")
    return len(text)


def generate_dialogue(filename: str, lines: list) -> int:
    """Generate a dialogue MP3 by concatenating per-line audio. Returns char count."""
    try:
        from pydub import AudioSegment
    except ImportError:
        print("ERROR: pydub is not installed.")
        print("  Run: pip install pydub --break-system-packages")
        print("  Also ensure ffmpeg is on PATH.")
        sys.exit(1)

    path = os.path.join(OUTPUT_DIR, filename)
    if os.path.exists(path):
        print(f"  SKIP  {filename} (already exists)")
        return 0

    print(f"  GEN   {filename} [dialogue, {len(lines)} lines]")
    pause = AudioSegment.silent(duration=DIALOGUE_PAUSE_MS)
    combined = AudioSegment.empty()
    total_chars = 0

    for i, (speaker, text) in enumerate(lines):
        preview = text[:50].replace("\n", " ")
        print(f"         [{i+1}/{len(lines)}] {speaker}: {preview!r} ...", end=" ", flush=True)
        audio_bytes = tts(text, speaker)
        segment = AudioSegment.from_mp3(io.BytesIO(audio_bytes))
        if i > 0:
            combined += pause
        combined += segment
        total_chars += len(text)
        print("done")
        time.sleep(0.15)  # gentle rate-limit buffer between lines

    combined.export(path, format="mp3")
    duration_s = len(combined) / 1000
    print(f"         saved {filename} ({duration_s:.1f}s)")
    return total_chars


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    total_chars = 0
    total_generated = 0

    print(f"\n=== TASILLA A1 Audio Generation ===")
    print(f"Output directory : {OUTPUT_DIR}")
    print(f"Single files     : {len(SINGLES)}")
    print(f"Dialogue files   : {len(DIALOGUES)}")
    print()

    print("--- Single-voice files ---")
    for filename, voice, text in SINGLES:
        chars = generate_single(filename, voice, text)
        total_chars += chars
        if chars:
            total_generated += 1

    print()
    print("--- Dialogue files ---")
    for filename, lines in DIALOGUES:
        chars = generate_dialogue(filename, lines)
        total_chars += chars
        if chars:
            total_generated += 1

    print()
    print("=== Summary ===")
    print(f"Files generated  : {total_generated}")
    print(f"Total characters : {total_chars:,}")
    print("Done.")


if __name__ == "__main__":
    main()

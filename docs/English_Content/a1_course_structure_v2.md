# TASILLA — A1 Course Structure (v2, 20 topics)

**Standard:** full CEFR A1 coverage. The certificate means A1 — no gaps an employer or
school would notice.

**Product context:** TASILLA is a **tool for teachers**, not a standalone self-study
course. The 80–100 guided-learning hours CEFR A1 normally requires come from live
teaching. The app provides structured practice, the assessment engine, and the evidence
trail the teacher signs against.

**Decisions locked (yours):**
- One lesson = one skill. Habit-sized, one sitting.
- 20 topics × 5 theme skills + a separate structure-organized Grammar track.
- Reviews every 3 lessons within each skill path. **No reinforcements** (cut for MVP).
- Cross-skill mixed reviews in the roadmap.
- Skill Paths and Roadmap are two routes through the SAME lessons — completing a lesson
  in either marks it complete in both.
- **Writing is dual-mode: ~60% typed in-app, ~40% handwritten on paper and uploaded.**

---

## 1. The 20 topics

Grouped into 4 units of 5.

### UNIT 1 — Foundation
| # | Topic | Core can-do |
|---|---|---|
| 1 | **Introductions & Greetings** | Say hello, introduce yourself, basic courtesy |
| 2 | **Personal Information** | Name, age, nationality, phone, email, spelling aloud |
| 3 | **Family & Relationships** | Talk about family members |
| 4 | **Describing People** | Basic physical description and personality |
| 5 | **Feelings & States** | I'm tired / happy / hungry / cold |

### UNIT 2 — Everyday Life
| # | Topic | Core can-do |
|---|---|---|
| 6 | **Home & Where You Live** | Rooms, furniture, describe your home |
| 7 | **Daily Routine & Habits** | What you do every day, at what time |
| 8 | **Time, Days & Dates** | Tell the time, days, months, dates |
| 9 | **Numbers, Prices & Money** | Count, understand prices, handle money |
| 10 | **Food & Drink / Ordering** | Order in a café, food vocabulary |

### UNIT 3 — Out in the World
| # | Topic | Core can-do |
|---|---|---|
| 11 | **Shopping** | Buy things, ask prices, sizes, quantities |
| 12 | **Places in Town & Directions** | Identify places, ask for and follow directions |
| 13 | **Travel & Transport** | Transport, tickets, simple travel situations |
| 14 | **Work & Study** | Talk about your job or studies |
| 15 | **Classroom & Learning** | Open your book, How do you spell…?, What does ___ mean? |

### UNIT 4 — Wider World
| # | Topic | Core can-do |
|---|---|---|
| 16 | **Free Time & Preferences** | Hobbies, likes, dislikes |
| 17 | **Weather & Seasons** | Describe weather, seasons |
| 18 | **Clothes & Colours** | Name clothes and colours, describe what people wear |
| 19 | **Health & Body** | I have a headache, body parts, at the pharmacy |
| 20 | **Animals & Nature** | Pets, common animals, simple nature words |

---

## 2. The 5 theme skills

Each topic gets one lesson in each skill. **Cycle order** (receptive before productive):

```
Vocabulary → Listening → Reading → Speaking → Writing
```

**20 topics × 5 skills = 100 theme lessons.**

| Skill | Lesson shape |
|---|---|
| **Vocabulary** | Core words + use-of-English practice. Auto-graded. |
| **Listening** | Audio (dialogue or monologue) + comprehension questions. Auto-graded. |
| **Reading** | **Two texts**, 3 questions each. Auto-graded. *(Two, not one — a single passage is too easy to fluke for a skill gated at 70%. Reading is cheap to produce: no audio, no teacher grading.)* |
| **Speaking** | Recorded task. **Teacher-graded.** |
| **Writing** | Typed OR handwritten-and-uploaded. **Teacher-graded.** See §3. |

### Review cadence within each skill path
Every 3 lessons → 1 review mixing those 3.
20 lessons → **6 reviews** (last covers 2) → **final test**.

**Per skill path:** 20 lessons + 6 reviews + 1 final test = **27 steps**

---

## 3. Writing — dual mode

**Principle:** typing lets a student lean on autocorrect and hides spelling weakness.
Handwriting is where you find out whether they can actually *produce* the language.
A certificate that claims A1 writing should prove handwritten ability.

### Mode A — Typed in app (12 of 20 lessons, ~60%)
Student types into the app. Prompt + minimum requirements. Teacher reviews the text
in the teacher dashboard.

**Shape by stage:**
- **Topics 1–7 (scaffolded):** model text → gap-fill → write your own version.
  A beginner staring at an empty box freezes; the model gives them a shape to copy.
- **Topics 8–20 (prompted free-write):** prompt + minimum requirements only.
  Scaffold removed as competence grows.

### Mode B — Handwritten, photographed/scanned, uploaded (8 of 20 lessons, ~40%)
Student writes **by hand on paper**, then uploads a photo, scan, PDF, or DOCX.
Teacher opens the file and approves / requests redo.

**Which topics are paper-based** (chosen where handwriting is genuinely the point —
forms, notes, letters, lists, things people really write by hand):

| Topic | Paper task |
|---|---|
| 2 · Personal Information | Fill in a registration form by hand |
| 5 · Feelings & States | Write a short note to a friend |
| 8 · Time, Days & Dates | Write out a weekly schedule |
| 9 · Numbers, Prices & Money | Write a shopping list with prices |
| 12 · Places & Directions | Hand-write directions from A to B |
| 15 · Classroom & Learning | Copy and complete a set of class notes |
| 17 · Weather & Seasons | Write a short weather diary for 3 days |
| 20 · Animals & Nature | Describe a pet or animal, handwritten |

**Feature dependencies (NOT built yet — see §7):**
- Supabase Storage bucket + RLS policies
- `writing_submissions` table
- File picker + upload in Flutter
- Teacher review UI for uploaded files

---

## 4. Grammar path (by structure, not theme)

Grammar cuts across topics — each lesson drills one structure using vocabulary the
student already met in theme lessons.

| # | Structure | Recycles topics |
|---|---|---|
| **G1** | Verb *to be* (affirmative, negative, questions) | 1, 2, 3, 5 |
| **G2** | Subject pronouns + possessive adjectives + possessive 's | 2, 3, 4 |
| **G3** | Articles (a/an/the) + plural nouns | 6, 10, 11 |
| **G4** | This / that / these / those | 6, 11, 18 |
| **G5** | There is / there are (+ neg, questions) | 6, 12 |
| **G6** | Prepositions of place | 6, 12 |
| **G7** | Simple present — affirmative (incl. 3rd person -s) | 7, 14 |
| **G8** | Simple present — negative & questions (do/does) | 7, 16 |
| **G9** | Adverbs of frequency + time expressions | 7, 8 |
| **G10** | **Present continuous** (+ contrast with simple present) | 7, 17, 18 |
| **G11** | Can / can't (ability + polite requests) | 10, 11, 14 |
| **G12** | Imperatives + object pronouns | 12, 15 |

**12 lessons + 4 reviews (every 3) + 1 final test = 17 steps**

### On Present Continuous (G10)
Included. My earlier claim that it is A2 was **wrong** — basic present continuous for
*"what is happening now"* (*I'm eating. She's reading.*) is standard A1. What IS A2 is
present continuous for **future arrangements** (*"I'm meeting Ana tomorrow"*) — that use
is excluded here. The *contrast* (*I work every day* vs *I'm working now*) is the point
of G10 and is what separates a strong A1 from a shaky one.

### Deliberately excluded (A2 — listed so they don't creep in)
Past simple · comparatives/superlatives · countable-uncountable with some/any/much/many ·
going to / future forms · modals beyond *can* · present continuous for future

---

## 5. The Roadmap

Interleaves all six skills. Each topic runs its 5-skill cycle; grammar lessons appear
right after the topics that feed them.

### Cross-skill mixed reviews
Every 3 topics → 1 roadmap-only review integrating all skills across those topics.
**20 topics → 7 mixed reviews.**

Roadmap-only by design: their purpose is *integration*, which is what the roadmap exists
to do (certificate can-do #12: "Integrate core A1 skills in familiar situations").

### Unit structure & hard gates

```
UNIT 1 — Foundation           Topics 1–5     (+ G1, G2)
  → MIXED REVIEW A (topics 1–3)
  → MIXED REVIEW B (topics 4–5)
  → CHECKPOINT 1                          ← hard gate

UNIT 2 — Everyday Life        Topics 6–10    (+ G3, G4, G5, G6)
  → MIXED REVIEW C (topics 6–8)
  → MIXED REVIEW D (topics 9–10)
  → CHECKPOINT 2                          ← hard gate
  → PORTFOLIO TASK 1                      (teacher-graded speaking + writing)

UNIT 3 — Out in the World     Topics 11–15   (+ G7, G8, G9)
  → MIXED REVIEW E (topics 11–13)
  → MIXED REVIEW F (topics 14–15)
  → CHECKPOINT 3                          ← hard gate

UNIT 4 — Wider World          Topics 16–20   (+ G10, G11, G12)
  → MIXED REVIEW G (topics 16–20)
  → CHECKPOINT 4                          ← hard gate
  → PORTFOLIO TASK 2                      (teacher-graded speaking + writing)

  → FINAL EXAM                            (multi-format, supervised)
  → CERTIFICATE
```

### Roadmap totals

| Component | Count |
|---|---|
| Theme lessons (20 × 5) | 100 |
| Grammar lessons | 12 |
| Mixed cross-skill reviews | 7 |
| Checkpoints (hard gates) | 4 |
| Portfolio tasks | 2 |
| Final exam | 1 |
| **TOTAL ROADMAP STEPS** | **126** |

**Pace:** 1 lesson/day → ~4 months straight, ~6 months at 5 days/week. Alongside live
teacher lessons, a reasonable A1 arc.

---

## 6. How this satisfies the certification standard

| Requirement | Delivered by |
|---|---|
| 4 skills gated independently at 70% | Each lesson feeds exactly ONE skill's score. No averaging — the structure makes this natural. |
| 10 speaking submissions, teacher-approved | 20 speaking lessons + 2 portfolios = 22 opportunities |
| 10 writing submissions, teacher-approved | 20 writing lessons (12 typed + 8 handwritten) + 2 portfolios = 22 |
| Checkpoints are hard gates | 4, one per unit |
| Certificate lists proven can-dos | Each topic maps to specific can-dos, proven by its 5 skill lessons |
| Final exam multi-format, guessing-proof | Separate spec — next document |

---

## 7. What this needs that does not exist yet

**Content (the bulk of the work):**
- 100 theme lessons + 12 grammar lessons = **112 lessons**
- ~40 exist today; most need rework (the auto-generated listening/reading question blocks
  produce nonsense — e.g. EXP-001's reading question asks about a text featuring Lucas but
  offers only Anna/Maria/Julia as options)
- **≈ 75–85 lessons of genuinely new content**
- **20 new listening audio files** (one per topic)
- 7 mixed reviews + 6 reviews per skill path + checkpoints + portfolios + final exam

**Engineering:**
1. **Assessment engine** — half-built, paused. Steps 1–3 done (interactive quiz working);
   Steps 4–6 (score gating, persistence) remain. *Must land before content is gated.*
2. **Single-skill lesson rendering** — the step screen currently dumps all six skills into
   every lesson. Must render only the lesson's `primarySkill`.
3. **Real reviews** — today review content is templated; no logic pulls the actual
   preceding lessons' material in. Needs building.
4. **Writing upload (Mode B)** — Supabase Storage bucket, `writing_submissions` table,
   file picker, teacher review UI. **Designed here, built later.**
5. **Skill path wiring** — the 5 skill paths currently show placeholder text. Under this
   structure they become filtered views of the same lesson list, and the separate
   `listening_data.dart` / `vocabulary_data.dart` / etc. files are **deleted**.

---

## 8. Suggested build order

1. **Finish the assessment engine** (Steps 4–6) — nothing can be gated until this exists
2. **Single-skill rendering** — fixes the nonsense-question bug structurally
3. **Restructure existing 40 lessons** into the new topic/skill grid
4. **Write new content** topic by topic (each topic = 5 lessons + 1 audio file)
5. **Real review logic**
6. **Writing upload feature**
7. **Final exam + placement test**

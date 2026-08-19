# TASILLA — Gamification Spec

**Status:** Documented for later. Nothing built yet. Ships in phases AFTER core content + assessment engine exist.

**Goal:** Keep student consistency between live lessons; bring students back when consistency fails. Gamification covers the days *between* classes — the teacher covers the rest. This is Tasilla's structural advantage over Duolingo: we don't need psychological pressure to replace a teacher, because we have one.

---

## Phase 1 — MVP (streaks, XP, badges)

### Streaks
- 1 completed step/day keeps the streak alive; displayed prominently on home screen
- **Streak freeze:** earned (not bought) — e.g., 1 freeze per completed review; protects one missed day
- Breaking a streak is forgiving: friendly restart, no penalties
- Rationale: 7-day streak users are ~3.6x more likely to stay engaged long-term (Duolingo data)

### XP
| Action | XP |
|---|---|
| Vocabulary / Reading / Listening lesson passed (>=70%) | 10 |
| Speaking / Writing task submitted | 15 |
| Teacher approves a submission | +10 bonus |
| Review passed | 20 |
| Checkpoint passed | 40 |
| Daily streak bonus | +5 |
| Perfect score bonus | +5 |

- XP is the common currency feeding all later systems (leagues, store)
- Speaking/writing earn XP on **submission**, not approval — students are never blocked by teacher review time; approval adds the bonus afterwards
- Levels every ~100 XP — cosmetic only, never gates content

### Milestone badges (5-6 at MVP)
- First lesson / First 100 words / 7-day streak / Unit complete / 10 approved speaking submissions / Halfway there (Topic 10)
- Celebration moment on unlock (visual + sound)

### Re-engagement
- Day 2 missed: in-app nudge
- Day 3+: push/email — gentle tone, never shaming
- Comeback bonus: return after 3+ days -> 2x XP for 3 days
- **Do NOT:** spam notifications, penalize XP for absence, use guilt mechanics

---

## Phase 2 (V1.1) — Individual map-based leagues

### Structure
```
📍 REGIONAL — city/state    🏳️ COUNTRY    🌍 WORLD
```
- Individual competition; weekly XP, resets every Monday
- Map UI: student's pin, zoom city -> country -> world. Signature Tasilla feature
- Position shown across all tiers: "#4 in Bertioga / #212 in Brazil / #3,540 worldwide"

### Divisions
- Bronze -> Silver -> Gold -> Diamond, groups of ~30 similar-level students
- Top 10 promoted, bottom 5 demoted weekly
- Beginners compete against beginners — everyone has a winnable game

### Softeners (individual competition without demoralization)
- Show top 10 + own position only; never the full wall above you
- Emphasize movement ("up 45 this week"), not absolute rank
- Weekly reset = no permanent loser
- Opt-out toggle: hide from leagues, still earn XP

### Privacy (minors)
- Display name + school city only
- Never device location; school-level location only
- No exact ranks of other students beyond top 10

### Cold start
- Leagues need volume; if school base is small at launch, start with smaller scopes and unlock country/world tiers as population grows

---

## Phase 3 (V2) — Store, pets, teacher tools

### Pets as study partners
- Adopted from an in-app store, bought with XP/coins — **no real money** (school product)
- Pet grows with consistency: lessons feed it, streaks keep it happy, absence makes it *sad* (never dead — no Tamagotchi guilt)
- Appears in lessons as companion; celebrates correct answers
- Store: pets, accessories, themes/backgrounds
- Re-engagement hook: "Your pet missed you!" — warmer than a system notification

### Teacher-side gamification
- **Review streak/stats:** private quality metrics ("100% reviewed within 48h this month")
- **Class health dashboard:** class streak, weekly XP, at-risk students flagged (no activity 5+ days) -> teacher sends a personal nudge
- **Teacher-triggered rewards:** class milestone bonuses ("Unit 1 done — 2x XP Friday") — puts the teacher inside the game
- **Class/school recognition:** "top engaged classes" — schools can use for marketing

---

## Explicitly rejected
- No public full leaderboards exposing weak students
- No harsh penalties / XP loss
- No notification spam
- No real-money cosmetics
- No group/school-vs-school leagues (considered; decided individual)

## Dependencies
- XP/streak tracking needs the assessment engine finished (score gating = "passed" definition)
- Leagues need profiles location data + weekly aggregation
- Store/pets need a coin economy + asset work
- Build order unchanged: **content + engine first, gamification after**

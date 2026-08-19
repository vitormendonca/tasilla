# TASILLA — Teacher Fidelity & Belonging Spec

**Status:** Documented for later. Ships in phases alongside and after student gamification.

**Core principle:** Teachers are Tasilla's real customers and distribution channel. A teacher who feels the platform is *theirs* brings students, defends the tool, and stays. Fidelity comes from identity, recognition, ownership, and respect for their time — not points and badges.

---

## 1. Professional identity — Tasilla as part of their credential

### Teacher profile
- Verified profile: photo, bio, certifications, years teaching, languages taught
- Number of students certified through them, displayed publicly
- A shareable public teacher page with verification link ("Certified 34 students to A1 via Tasilla")
- Becomes something teachers put on their CV, LinkedIn, Instagram bio

### Name on every certificate
- Teacher name + signature printed on every student certificate they sign off
- Already required by the certification standard (section 7: "Issuing teacher name + signature") — zero extra engineering, enormous meaning
- Every certificate a student shows an employer carries the teacher's name permanently

---

## 2. Status through outcomes, not grinding

### Teacher tiers
```
🟢 Tasilla Teacher     -> default on joining
🔵 Senior Teacher      -> 20+ students certified, 90%+ review-within-48h rate
🟣 Mentor Teacher      -> 50+ students certified, invited to teacher council
```

- Tiers based on **real outcomes** (students certified, review quality, student retention) — never activity points
- Tier badge visible on their profile and on certificates they sign

### Tier perks (real, not cosmetic)
- **Senior:** early access to new content (A2 track), priority support
- **Mentor:** voice in content decisions, invited to beta features, credited in release notes

---

## 3. Ownership — let teachers shape the product

### Content feedback loop
- "Flag this exercise" button in the teacher dashboard on every lesson
- Teachers who report issues see their fix credited: "Improved thanks to Prof. Ana, Santos"
- Turns bug-reporting from complaint into contribution

### Teacher council (at scale)
- Beta group of Mentor-tier teachers for upcoming features
- Being *asked* is the strongest belonging signal — don't wait until the feature is done, ask during design
- Even 5 active teachers giving feedback creates deep loyalty

### Teacher-contributed content (future)
- Teachers can submit exercise variations, class-specific notes on lessons, or local-context examples
- Reviewed and credited if published — builds co-ownership of the platform

---

## 4. Community — teachers talking to teachers

### MVP (zero engineering)
- A WhatsApp or Discord group for Tasilla teachers — start this immediately, even before any feature ships
- Moderated by Tasilla team, teachers share how they use the app in their classrooms

### Content (low effort, high return)
- Monthly teacher spotlight: "How Prof. Carlos uses handwritten uploads in his classroom"
- Shared tips: pacing strategies, how to pair live lessons with app exercises
- This creates a network effect: leaving Tasilla means leaving the community

---

## 5. Celebrate teacher moments

### Student milestones reflected to teacher
- When a student earns a certificate -> **teacher gets the celebration too:** "Your 10th certified student!"
- When a class completes a unit -> teacher sees it first, gets to announce it

### End-of-semester recap (shareable)
- Students taught, hours of submissions reviewed, certificates issued, average student score improvement
- Designed to be **shareable** — LinkedIn post, Instagram story, school board presentation
- This is free marketing for Tasilla: every teacher sharing a recap is an ad

### Teaching milestones
- "100 submissions reviewed" / "First certified student" / "5 students with 30-day streaks"
- Private by default; teacher chooses what to share

---

## 6. Respect their time (the #1 fidelity feature)

**A teacher drowning in a review backlog on Sunday night will churn no matter how many badges they have.** The review experience IS the loyalty feature.

### Review UX priorities
- **Batch review:** select multiple similar submissions, approve/redo in bulk
- **Quick rubric taps:** one-tap per criterion (pass/not yet), optional comment — not a form to fill
- **Audio playback speed:** 1x, 1.25x, 1.5x for speaking submissions
- **Smart queue sorting:** urgent first (students blocked at checkpoints), then by date
- **Time estimate:** "12 submissions, ~15 min" — sets expectations, reduces dread

### Review stats (private, not performative)
- Average review turnaround time
- Submissions pending vs. completed this week
- Goal: teacher self-monitors, not Tasilla surveillance

---

## Priority order

| Priority | Feature | Depends on |
|---|---|---|
| 1 | Name + signature on certificate | Certificate feature (MVP spec piece 5) |
| 2 | Teacher profile (basic) | Profiles table (exists) |
| 3 | Great review experience | Teacher review flow (MVP spec piece 4) |
| 4 | Community group (WhatsApp/Discord) | Nothing — start anytime |
| 5 | Celebration moments + semester recap | Student progress data |
| 6 | Content feedback loop ("flag this exercise") | Teacher dashboard |
| 7 | Teacher tiers | Enough certified students to be meaningful |
| 8 | Teacher council + content contributions | Scale + community maturity |

---

## Explicitly rejected
- No teacher leaderboards ("best teacher in Sao Paulo") — toxic, creates wrong incentives
- No mandatory review SLAs with penalties — respect, not surveillance
- No gamification points/XP for teachers — they are professionals, not players; recognition through outcomes
- No paid tier perks — tiers reward quality teaching, never paywalled

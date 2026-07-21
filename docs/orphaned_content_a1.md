# Orphaned A1 content — flagged by single-skill separation (Spec v2)

**Generated:** 2026-07-20, while landing `single_skill_rendering_spec` v2 (full skill
separation). **Do not delete this content** — it is authored, correct language material
that simply lives on the wrong lesson. Relocate it when the 20-topic × 6-skill content
grid is built (Phase 3 / v2 restructure).

## What this is

Under full separation, a single-skill lesson renders only its own skill. Many launch
lessons were authored with a cross-skill audio script and/or reading passage baked into
their seed (`_CoreExperienceSeed.audioScript` / `.readingText`). Those blocks are no longer
built (`_listeningBlockFor` / `_readingBlockFor` return `null` for foreign skills), so the
content is retained in the seed but never surfaced. Each entry below belongs to a *future*
listening or reading lesson on the same topic.

## Orphaned audio scripts (belong to a future Listening lesson on that topic)

| Experience | Primary skill |
|---|---|
| A1-EXP-001 | speaking |
| A1-EXP-005 | reading |
| A1-EXP-006 | vocabulary/use-of-English |
| A1-EXP-009 | speaking |
| A1-EXP-011 | vocabulary/use-of-English |
| A1-EXP-012 | speaking |
| A1-EXP-013 | speaking |
| A1-EXP-015 | reading |
| A1-EXP-016 | writing |
| A1-EXP-017 | vocabulary/use-of-English |
| A1-EXP-027 | vocabulary/use-of-English |
| A1-EXP-034 | reading |

## Orphaned reading passages (belong to a future Reading lesson on that topic)

| Experience | Primary skill |
|---|---|
| A1-EXP-001 | speaking |
| A1-EXP-007 | vocabulary/use-of-English |
| A1-EXP-008 | writing |
| A1-EXP-011 | vocabulary/use-of-English |
| A1-EXP-012 | speaking |
| A1-EXP-013 | speaking |
| A1-EXP-014 | listening |
| A1-EXP-016 | writing |
| A1-EXP-017 | vocabulary/use-of-English |
| A1-EXP-019 | listening |

## How this list was produced

The two generators were temporarily instrumented to record any seed whose explicit
audio/reading content was suppressed by the new skill gate; the full experience set was
built once; the lists were captured and the instrumentation reverted. Re-run that method
if seeds change. Listening lessons keep their own audio and reading lessons keep their own
text; mixed lessons keep both — none of those appear here.

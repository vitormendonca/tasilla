-- =============================================================================
-- TASILLA — MVP Piece 5: Certificate gate for the A1 launch scope
-- =============================================================================
-- Run this AFTER mvp_piece1_submissions_schema.sql (which created the
-- certificates table).
--
-- Why this exists:
--   The launch course is lessons 001-020 only. Units 3-4 — and with them the
--   multi-format final exam — are hidden. So a launch A1 certificate cannot
--   carry a final-exam score: there is no exam to sit yet. It gates instead on
--   the four skills plus teacher-approved speaking and writing evidence.
--
--   Piece 1 created `certificates` with final_exam_score NOT NULL and a
--   final_exam_minimum (>= 0.75) check. This migration relaxes exactly those two
--   things, and nothing else. The four_skill_minimum (>= 0.70 each) stays — that
--   is the non-negotiable heart of the standard.
--
--   When Unit 4 + the real final exam ship, restore the constraint and make the
--   column NOT NULL again (the two statements are commented at the bottom).
--
-- Also adds a name snapshot so the public verification page can show who the
-- certificate belongs to without a login. A certificate should print the name as
-- it was at issue time, so this is captured, not joined.
--
-- Safe to run once; every statement is guarded with IF EXISTS / IF NOT EXISTS.
-- =============================================================================

-- 1. The launch certificate carries no final exam.
alter table public.certificates
  drop constraint if exists final_exam_minimum;

alter table public.certificates
  alter column final_exam_score drop not null;

-- 2. Name snapshot for anon verification.
alter table public.certificates
  add column if not exists student_name   text;

alter table public.certificates
  add column if not exists issued_by_name  text;


-- =============================================================================
-- When the real final exam ships (v2), restore the gate:
-- =============================================================================
--   update public.certificates set final_exam_score = 0.75 where final_exam_score is null;
--   alter table public.certificates alter column final_exam_score set not null;
--   alter table public.certificates
--     add constraint final_exam_minimum check (final_exam_score >= 0.75);
-- =============================================================================

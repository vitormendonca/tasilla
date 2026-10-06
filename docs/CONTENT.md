# TASILLA Content Standard

## Current launch scope

The commercial validation scope is A1. The certificate launch standard currently evaluates the first 20 core A1 experiences and requires evidence for all four skills.

Content is versioned in the repository and should not be duplicated as ad-hoc UI logic.

## Rules

- Keep content data separate from presentation.
- Every learning step has a stable identifier.
- Scores and completion state are persisted independently from content.
- Speaking and writing evidence require teacher review when marked as certification evidence.
- A content change that affects certification must update certification tests and documentation.
- Do not expand to A2/B1/B2 before the A1 teacher/school workflow is validated with real users.

## Quality gate

Before publishing content:

1. Validate identifiers and ordering.
2. Validate question structure and answer data.
3. Validate required evidence flags.
4. Run learning-path/content validation.
5. Run certification tests.
6. Verify the student and teacher flows against Supabase.
7. Update this document when the content contract changes.

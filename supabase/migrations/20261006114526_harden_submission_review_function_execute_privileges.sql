-- TASILLA: harden the submission review authority trigger function.
-- SECURITY DEFINER is intentional for trigger execution, but the function must
-- not be callable as a public API by anon/authenticated roles.

revoke execute on function public.enforce_submission_review_authority() from public;
revoke execute on function public.enforce_submission_review_authority() from anon, authenticated;
grant execute on function public.enforce_submission_review_authority() to service_role;

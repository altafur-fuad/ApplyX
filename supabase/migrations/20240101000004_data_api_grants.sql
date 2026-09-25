-- =========================
-- Data API Grants
-- =========================

GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.goals TO authenticated;
GRANT SELECT ON public.opportunities TO authenticated;
GRANT SELECT ON public.applications TO authenticated;

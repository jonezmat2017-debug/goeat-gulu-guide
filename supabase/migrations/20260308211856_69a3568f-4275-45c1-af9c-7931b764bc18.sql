
-- Tighten insert policies to require authentication
DROP POLICY IF EXISTS "Authenticated users can create notifications" ON public.notifications;
CREATE POLICY "Authenticated users can create notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated users can create activity logs" ON public.activity_logs;
CREATE POLICY "Authenticated users can create activity logs"
  ON public.activity_logs FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);


-- 1. Default user_roles.approved to true
ALTER TABLE public.user_roles ALTER COLUMN approved SET DEFAULT true;

-- 2. Default venues.approved to true
ALTER TABLE public.venues ALTER COLUMN approved SET DEFAULT true;

-- 3. Update existing unapproved roles to approved
UPDATE public.user_roles SET approved = true WHERE approved = false OR approved IS NULL;

-- 4. Update existing unapproved venues to approved
UPDATE public.venues SET approved = true WHERE approved = false OR approved IS NULL;

-- 5. Drop old venue insert policy that forced approved=false
DROP POLICY IF EXISTS "Users can submit venues" ON public.venues;
CREATE POLICY "Users can submit venues" ON public.venues FOR INSERT WITH CHECK (auth.uid() = submitted_by);

-- 6. Drop old venue update policy that required approved=false
DROP POLICY IF EXISTS "Owners can edit pending venues" ON public.venues;
CREATE POLICY "Owners can edit their venues" ON public.venues FOR UPDATE USING (auth.uid() = submitted_by);

-- 7. Update venue select policy to show all venues
DROP POLICY IF EXISTS "Approved venues are public" ON public.venues;
CREATE POLICY "Venues are public" ON public.venues FOR SELECT USING (true);

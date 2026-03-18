
-- Create a view for public review profiles (just name and avatar)
CREATE VIEW public.public_reviewer_profiles
WITH (security_invoker = on) AS
SELECT id, full_name, avatar_url
FROM public.profiles;

-- Allow everyone to read from profiles for review display
CREATE POLICY "Anyone can view profile names"
  ON public.profiles FOR SELECT
  USING (true);

-- Drop the old restrictive policy
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;

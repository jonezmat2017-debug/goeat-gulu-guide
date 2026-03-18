
-- Drop old restrictive policies for seller and venue_owner role requests
DROP POLICY IF EXISTS "Users can request seller role" ON public.user_roles;
DROP POLICY IF EXISTS "Users can request venue owner role" ON public.user_roles;

-- Recreate policies allowing approved = true on insert (auto-approved)
CREATE POLICY "Users can request seller role"
ON public.user_roles FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_id AND role = 'seller'::app_role
);

CREATE POLICY "Users can request venue owner role"
ON public.user_roles FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_id AND role = 'venue_owner'::app_role
);

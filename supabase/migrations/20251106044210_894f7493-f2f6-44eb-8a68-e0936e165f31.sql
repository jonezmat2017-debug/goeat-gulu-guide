-- Insert admin role for the user
INSERT INTO public.user_roles (user_id, role, approved, approved_at, approved_by)
VALUES (
  '8b1fd853-a6ab-4e27-9e27-9051a12ee309',
  'admin',
  true,
  now(),
  '8b1fd853-a6ab-4e27-9e27-9051a12ee309'
)
ON CONFLICT (user_id, role) DO NOTHING;

-- Add policy allowing admins to create admin roles
CREATE POLICY "Admins can create admin roles"
ON public.user_roles
FOR INSERT
TO authenticated
WITH CHECK (
  has_role(auth.uid(), 'admin') 
  AND role = 'admin'
  AND approved = true
);
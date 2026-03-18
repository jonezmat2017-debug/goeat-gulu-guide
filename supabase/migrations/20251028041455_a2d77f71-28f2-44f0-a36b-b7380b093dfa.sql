-- Fix 1: Restrict profiles table to protect PII (emails, phone numbers)
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON profiles;

-- Users can only view their own full profile
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

-- Fix 2: Add seller approval system
ALTER TABLE user_roles 
  ADD COLUMN IF NOT EXISTS approved BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ;

-- Update existing roles to be approved (for current users)
UPDATE user_roles SET approved = true WHERE approved IS NULL OR approved = false;

-- Drop old permissive policy
DROP POLICY IF EXISTS "Users can insert their own roles" ON user_roles;

-- Users can only add buyer role for themselves
CREATE POLICY "Users can add buyer role" ON user_roles
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND 
    role = 'buyer' AND
    approved = true
  );

-- Users can request seller role (pending approval)
CREATE POLICY "Users can request seller role" ON user_roles
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND 
    role = 'seller' AND
    approved = false
  );

-- Fix 3: Admin role management
CREATE POLICY "Admins can approve roles" ON user_roles
  FOR UPDATE USING (has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can revoke roles" ON user_roles
  FOR DELETE USING (has_role(auth.uid(), 'admin'));

-- Update has_role function to check approval status
CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role app_role)
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = _user_id
      AND role = _role
      AND approved = true
  )
$$;

-- Now create the public view AFTER the approved column exists
CREATE OR REPLACE VIEW public_seller_profiles AS 
  SELECT 
    p.id, 
    p.full_name, 
    p.avatar_url, 
    p.bio
  FROM profiles p
  INNER JOIN user_roles ur ON p.id = ur.user_id
  WHERE ur.role = 'seller' AND ur.approved = true;

-- Fix 4: Add venue submission system
ALTER TABLE venues
  ADD COLUMN IF NOT EXISTS submitted_by UUID REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS approved BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ;

-- Mark existing venues as approved
UPDATE venues SET approved = true WHERE approved IS NULL OR approved = false;

-- Drop old policy
DROP POLICY IF EXISTS "Venues are viewable by everyone" ON venues;

-- Public can only see approved venues
CREATE POLICY "Approved venues are public" ON venues
  FOR SELECT USING (approved = true OR auth.uid() = submitted_by);

-- Authenticated users can submit venues
CREATE POLICY "Users can submit venues" ON venues
  FOR INSERT WITH CHECK (
    auth.uid() = submitted_by AND
    approved = false
  );

-- Users can update their own pending venues
CREATE POLICY "Owners can edit pending venues" ON venues
  FOR UPDATE USING (
    auth.uid() = submitted_by AND
    approved = false
  );

-- Admins can manage all venues
CREATE POLICY "Admins manage venues" ON venues
  FOR ALL USING (has_role(auth.uid(), 'admin'));

-- Create storage bucket for venue images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('venue-images', 'venue-images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for venue images
DROP POLICY IF EXISTS "Venue images are publicly accessible" ON storage.objects;
CREATE POLICY "Venue images are publicly accessible" 
  ON storage.objects FOR SELECT 
  USING (bucket_id = 'venue-images');

DROP POLICY IF EXISTS "Authenticated users can upload venue images" ON storage.objects;
CREATE POLICY "Authenticated users can upload venue images" 
  ON storage.objects FOR INSERT 
  WITH CHECK (
    bucket_id = 'venue-images' AND 
    auth.uid()::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS "Users can update their own venue images" ON storage.objects;
CREATE POLICY "Users can update their own venue images" 
  ON storage.objects FOR UPDATE 
  USING (
    bucket_id = 'venue-images' AND 
    auth.uid()::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS "Users can delete their own venue images" ON storage.objects;
CREATE POLICY "Users can delete their own venue images" 
  ON storage.objects FOR DELETE 
  USING (
    bucket_id = 'venue-images' AND 
    auth.uid()::text = (storage.foldername(name))[1]
  );
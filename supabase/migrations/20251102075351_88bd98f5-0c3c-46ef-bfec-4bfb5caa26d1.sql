-- Add RLS policy for venue owner role requests
CREATE POLICY "Users can request venue owner role"
  ON user_roles
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND role = 'venue_owner'
    AND approved = false
  );
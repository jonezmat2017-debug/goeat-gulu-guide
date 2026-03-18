
-- Allow admins to delete venue reviews for moderation
CREATE POLICY "Admins can delete venue reviews"
  ON public.venue_reviews FOR DELETE
  USING (has_role(auth.uid(), 'admin'::app_role));

-- Allow admins to delete seller ratings for moderation
CREATE POLICY "Admins can delete seller ratings"
  ON public.seller_ratings FOR DELETE
  USING (has_role(auth.uid(), 'admin'::app_role));

-- Allow admins to view all venue reviews
CREATE POLICY "Admins can view all venue reviews"
  ON public.venue_reviews FOR SELECT
  USING (has_role(auth.uid(), 'admin'::app_role));

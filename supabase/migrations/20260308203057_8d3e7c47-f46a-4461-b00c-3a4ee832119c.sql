
-- Create venue_reviews table
CREATE TABLE public.venue_reviews (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  venue_id UUID NOT NULL REFERENCES public.venues(id) ON DELETE CASCADE,
  reviewer_id UUID NOT NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review_text TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(venue_id, reviewer_id)
);

-- Enable RLS
ALTER TABLE public.venue_reviews ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY "Venue reviews are viewable by everyone"
  ON public.venue_reviews FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can create venue reviews"
  ON public.venue_reviews FOR INSERT
  WITH CHECK (auth.uid() = reviewer_id);

CREATE POLICY "Users can update their own venue reviews"
  ON public.venue_reviews FOR UPDATE
  USING (auth.uid() = reviewer_id);

CREATE POLICY "Users can delete their own venue reviews"
  ON public.venue_reviews FOR DELETE
  USING (auth.uid() = reviewer_id);

-- Function to update venue rating stats
CREATE OR REPLACE FUNCTION public.update_venue_rating_stats()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    UPDATE public.venues
    SET rating = COALESCE((SELECT AVG(rating) FROM public.venue_reviews WHERE venue_id = OLD.venue_id), 0),
        review_count = (SELECT COUNT(*) FROM public.venue_reviews WHERE venue_id = OLD.venue_id),
        updated_at = now()
    WHERE id = OLD.venue_id;
    RETURN OLD;
  ELSE
    UPDATE public.venues
    SET rating = COALESCE((SELECT AVG(rating) FROM public.venue_reviews WHERE venue_id = NEW.venue_id), 0),
        review_count = (SELECT COUNT(*) FROM public.venue_reviews WHERE venue_id = NEW.venue_id),
        updated_at = now()
    WHERE id = NEW.venue_id;
    RETURN NEW;
  END IF;
END;
$$;

-- Trigger to auto-update venue ratings
CREATE TRIGGER update_venue_ratings
  AFTER INSERT OR UPDATE OR DELETE ON public.venue_reviews
  FOR EACH ROW
  EXECUTE FUNCTION public.update_venue_rating_stats();

-- Add updated_at trigger
CREATE TRIGGER update_venue_reviews_updated_at
  BEFORE UPDATE ON public.venue_reviews
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

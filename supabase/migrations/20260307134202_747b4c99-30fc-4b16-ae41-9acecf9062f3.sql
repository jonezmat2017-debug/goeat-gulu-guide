
-- Add condition enum
CREATE TYPE public.product_condition AS ENUM ('brand_new', 'refurbished', 'used');

-- Add condition column to products
ALTER TABLE public.products ADD COLUMN condition public.product_condition DEFAULT 'brand_new';

-- Create seller_ratings table
CREATE TABLE public.seller_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id UUID NOT NULL,
  reviewer_id UUID NOT NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review_text TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (seller_id, reviewer_id)
);

ALTER TABLE public.seller_ratings ENABLE ROW LEVEL SECURITY;

-- Everyone can view ratings
CREATE POLICY "Ratings are viewable by everyone"
  ON public.seller_ratings FOR SELECT
  USING (true);

-- Authenticated users can create ratings
CREATE POLICY "Users can create ratings"
  ON public.seller_ratings FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = reviewer_id AND auth.uid() != seller_id);

-- Users can update their own ratings
CREATE POLICY "Users can update their own ratings"
  ON public.seller_ratings FOR UPDATE
  TO authenticated
  USING (auth.uid() = reviewer_id);

-- Users can delete their own ratings
CREATE POLICY "Users can delete their own ratings"
  ON public.seller_ratings FOR DELETE
  TO authenticated
  USING (auth.uid() = reviewer_id);

-- Create a view for seller average ratings
CREATE OR REPLACE VIEW public.seller_rating_summary AS
SELECT 
  seller_id,
  ROUND(AVG(rating)::numeric, 1) as avg_rating,
  COUNT(*) as review_count
FROM public.seller_ratings
GROUP BY seller_id;

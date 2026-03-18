-- Create venues table for restaurants and nightlife spots in Gulu
CREATE TABLE public.venues (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  description TEXT,
  rating NUMERIC(2,1) NOT NULL DEFAULT 0 CHECK (rating >= 0 AND rating <= 5),
  review_count INTEGER NOT NULL DEFAULT 0,
  location TEXT NOT NULL,
  address TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  price_level INTEGER NOT NULL DEFAULT 1 CHECK (price_level >= 1 AND price_level <= 4),
  is_open BOOLEAN NOT NULL DEFAULT true,
  featured BOOLEAN NOT NULL DEFAULT false,
  image_url TEXT,
  opening_hours TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.venues ENABLE ROW LEVEL SECURITY;

-- Allow public read access to venues
CREATE POLICY "Venues are viewable by everyone" 
ON public.venues 
FOR SELECT 
USING (true);

-- Create trigger for automatic timestamp updates
CREATE TRIGGER update_venues_updated_at
BEFORE UPDATE ON public.venues
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Create index for better performance on queries
CREATE INDEX idx_venues_rating ON public.venues(rating DESC);
CREATE INDEX idx_venues_category ON public.venues(category);
CREATE INDEX idx_venues_featured ON public.venues(featured) WHERE featured = true;

-- Insert sample venues in Gulu
INSERT INTO public.venues (name, category, description, rating, review_count, location, address, phone, price_level, is_open, featured, image_url, opening_hours) VALUES
('The Boma Hotel Restaurant', 'Fine Dining', 'Upscale dining with international and local cuisine in a historic colonial setting', 4.5, 156, 'Gulu City Center', 'Coronation Rd, Gulu', '+256 471 432093', 3, true, true, 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800&q=80', 'Mon-Sun: 7:00 AM - 10:30 PM'),
('Acholi Inn Restaurant', 'Ugandan Cuisine', 'Authentic Northern Ugandan dishes in a traditional setting', 4.3, 203, 'Pece', 'Olanya Rd, Gulu', '+256 392 945678', 2, true, true, 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800&q=80', 'Mon-Sun: 11:00 AM - 10:00 PM'),
('Club Dacca Lounge', 'Nightclub', 'Premier nightlife destination with live DJs and modern atmosphere', 4.4, 287, 'Pece Stadium Area', 'Stadium Rd, Gulu', '+256 772 834567', 3, true, true, 'https://images.unsplash.com/photo-1566737236500-c8ac43014a67?w=800&q=80', 'Thu-Sun: 8:00 PM - 4:00 AM'),
('Pearl Garden Restaurant', 'Asian Fusion', 'Chinese and Asian cuisine with local influences', 4.2, 134, 'Layibi', 'Layibi Rd, Gulu', '+256 471 432156', 2, true, false, 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=80', 'Mon-Sun: 12:00 PM - 10:00 PM'),
('Kaunda Grounds Bar', 'Sports Bar', 'Popular sports bar with large screens and cold drinks', 4.1, 298, 'Kaunda Grounds', 'Kaunda Grounds, Gulu', '+256 782 567890', 1, true, false, 'https://images.unsplash.com/photo-1572116469696-31de0f17cc34?w=800&q=80', 'Mon-Sun: 4:00 PM - 12:00 AM'),
('Bambu Lounge', 'Cocktail Bar', 'Trendy lounge with craft cocktails and live music', 4.6, 189, 'Gulu City Center', 'Churchill Rd, Gulu', '+256 773 445566', 3, true, true, 'https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=800&q=80', 'Wed-Sun: 6:00 PM - 2:00 AM'),
('Cafe Larem', 'Cafe', 'Cozy cafe with excellent coffee and pastries', 4.4, 167, 'Pece', 'Acholi Rd, Gulu', '+256 392 876543', 2, true, false, 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800&q=80', 'Mon-Sat: 7:00 AM - 8:00 PM'),
('Nyeko Bar & Grill', 'BBQ Restaurant', 'Outdoor grills with fresh meats and local beers', 4.0, 221, 'Layibi', 'Layibi Shopping Center, Gulu', '+256 701 234567', 2, true, false, 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&q=80', 'Mon-Sun: 5:00 PM - 11:00 PM'),
('Imperial Golf View Hotel Restaurant', 'Hotel Restaurant', 'Elegant dining with golf course views', 4.3, 142, 'Near Gulu Golf Club', 'Golf Course Rd, Gulu', '+256 471 432007', 3, true, false, 'https://images.unsplash.com/photo-1552566626-52f8b828add9?w=800&q=80', 'Mon-Sun: 6:30 AM - 10:00 PM'),
('Pulse Nightclub', 'Nightclub', 'Energetic nightclub with top DJs and VIP lounges', 4.2, 312, 'Gulu Main Street', 'Main St, Gulu', '+256 775 998877', 2, true, false, 'https://images.unsplash.com/photo-1571266028243-d220c6fa6e8c?w=800&q=80', 'Fri-Sat: 9:00 PM - 5:00 AM');

-- Add clearance fields to products table
ALTER TABLE public.products 
  ADD COLUMN IF NOT EXISTS discount_percentage integer DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_clearance boolean DEFAULT false;

-- Create auctions table
CREATE TABLE public.auctions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
  seller_id uuid NOT NULL,
  start_price numeric NOT NULL,
  buy_now_price numeric,
  current_highest_bid numeric DEFAULT 0,
  highest_bidder_id uuid,
  end_time timestamp with time zone NOT NULL,
  status text NOT NULL DEFAULT 'active',
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Create bids table
CREATE TABLE public.bids (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auction_id uuid REFERENCES public.auctions(id) ON DELETE CASCADE NOT NULL,
  bidder_id uuid NOT NULL,
  amount numeric NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.auctions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bids ENABLE ROW LEVEL SECURITY;

-- Auction policies
CREATE POLICY "Auctions are viewable by everyone" ON public.auctions FOR SELECT USING (true);
CREATE POLICY "Sellers can create auctions" ON public.auctions FOR INSERT TO authenticated WITH CHECK (auth.uid() = seller_id);
CREATE POLICY "Sellers can update their auctions" ON public.auctions FOR UPDATE TO authenticated USING (auth.uid() = seller_id);
CREATE POLICY "Sellers can delete their auctions" ON public.auctions FOR DELETE TO authenticated USING (auth.uid() = seller_id);

-- Bid policies
CREATE POLICY "Bids are viewable by everyone" ON public.bids FOR SELECT USING (true);
CREATE POLICY "Authenticated users can place bids" ON public.bids FOR INSERT TO authenticated WITH CHECK (auth.uid() = bidder_id);

-- Enable realtime for bids
ALTER PUBLICATION supabase_realtime ADD TABLE public.bids;
ALTER PUBLICATION supabase_realtime ADD TABLE public.auctions;

-- Function to update auction highest bid
CREATE OR REPLACE FUNCTION public.update_auction_highest_bid()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.auctions
  SET current_highest_bid = NEW.amount,
      highest_bidder_id = NEW.bidder_id,
      updated_at = now()
  WHERE id = NEW.auction_id
    AND (current_highest_bid IS NULL OR NEW.amount > current_highest_bid);
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_new_bid
  AFTER INSERT ON public.bids
  FOR EACH ROW
  EXECUTE FUNCTION public.update_auction_highest_bid();

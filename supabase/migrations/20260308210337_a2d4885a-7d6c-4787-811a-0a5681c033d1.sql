
-- Create menu_items table
CREATE TABLE public.menu_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id uuid NOT NULL REFERENCES public.venues(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  price numeric NOT NULL,
  category text,
  image_url text,
  is_available boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Create venue_order_status enum
CREATE TYPE public.venue_order_status AS ENUM ('pending', 'approved', 'rejected', 'completed', 'cancelled');

-- Create venue_orders table
CREATE TABLE public.venue_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id uuid NOT NULL REFERENCES public.venues(id) ON DELETE CASCADE,
  customer_id uuid NOT NULL,
  customer_name text NOT NULL,
  customer_phone text NOT NULL,
  status public.venue_order_status NOT NULL DEFAULT 'pending',
  notes text,
  total_amount numeric NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Create venue_order_items table
CREATE TABLE public.venue_order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.venue_orders(id) ON DELETE CASCADE,
  menu_item_id uuid NOT NULL REFERENCES public.menu_items(id) ON DELETE CASCADE,
  quantity integer NOT NULL DEFAULT 1,
  price_at_order numeric NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.venue_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.venue_order_items ENABLE ROW LEVEL SECURITY;

-- menu_items policies
CREATE POLICY "Menu items are viewable by everyone" ON public.menu_items FOR SELECT USING (true);
CREATE POLICY "Venue owners can manage their menu items" ON public.menu_items FOR ALL USING (
  EXISTS (SELECT 1 FROM public.venues WHERE venues.id = menu_items.venue_id AND venues.submitted_by = auth.uid())
);

-- venue_orders policies
CREATE POLICY "Customers can create orders" ON public.venue_orders FOR INSERT WITH CHECK (auth.uid() = customer_id);
CREATE POLICY "Customers can view their own orders" ON public.venue_orders FOR SELECT USING (auth.uid() = customer_id);
CREATE POLICY "Venue owners can view orders for their venues" ON public.venue_orders FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.venues WHERE venues.id = venue_orders.venue_id AND venues.submitted_by = auth.uid())
);
CREATE POLICY "Venue owners can update order status" ON public.venue_orders FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.venues WHERE venues.id = venue_orders.venue_id AND venues.submitted_by = auth.uid())
);

-- venue_order_items policies
CREATE POLICY "Order items viewable by order owner" ON public.venue_order_items FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.venue_orders WHERE venue_orders.id = venue_order_items.order_id AND venue_orders.customer_id = auth.uid())
);
CREATE POLICY "Order items viewable by venue owner" ON public.venue_order_items FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.venue_orders vo
    JOIN public.venues v ON v.id = vo.venue_id
    WHERE vo.id = venue_order_items.order_id AND v.submitted_by = auth.uid()
  )
);
CREATE POLICY "Customers can create order items" ON public.venue_order_items FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.venue_orders WHERE venue_orders.id = venue_order_items.order_id AND venue_orders.customer_id = auth.uid())
);

-- Updated_at triggers
CREATE TRIGGER update_menu_items_updated_at BEFORE UPDATE ON public.menu_items FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_venue_orders_updated_at BEFORE UPDATE ON public.venue_orders FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

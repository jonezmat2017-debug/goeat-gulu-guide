-- Fix infinite recursion in orders/order_items RLS policies
-- Create security definer functions to break the circular dependency

-- Function to check if user is buyer of an order
CREATE OR REPLACE FUNCTION public.is_order_buyer(_user_id uuid, _order_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.orders
    WHERE id = _order_id
      AND buyer_id = _user_id
  )
$$;

-- Function to check if user is seller in an order
CREATE OR REPLACE FUNCTION public.is_order_seller(_user_id uuid, _order_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.order_items
    WHERE order_id = _order_id
      AND seller_id = _user_id
  )
$$;

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Buyers can view their order items" ON public.order_items;
DROP POLICY IF EXISTS "Sellers can view their order items" ON public.order_items;
DROP POLICY IF EXISTS "Sellers can view orders containing their products" ON public.orders;

-- Recreate order_items policies using security definer functions
CREATE POLICY "Buyers can view their order items"
ON public.order_items
FOR SELECT
USING (public.is_order_buyer(auth.uid(), order_id));

CREATE POLICY "Sellers can view their order items"
ON public.order_items
FOR SELECT
USING (auth.uid() = seller_id);

-- Recreate orders policy using direct seller_id check without recursion
CREATE POLICY "Sellers can view orders containing their products"
ON public.orders
FOR SELECT
USING (public.is_order_seller(auth.uid(), id));
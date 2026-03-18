
-- Allow sellers to update orders containing their products (for approval flow)
CREATE POLICY "Sellers can update orders for their products"
ON public.orders FOR UPDATE USING (
  is_order_seller(auth.uid(), id)
);

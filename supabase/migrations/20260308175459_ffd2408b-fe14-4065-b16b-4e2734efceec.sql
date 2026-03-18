
CREATE TABLE public.payment_gateway_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  gateway_type text NOT NULL CHECK (gateway_type IN ('iotec', 'mtn_momo', 'airtel_money')),
  currency text NOT NULL DEFAULT 'UGX',
  is_active boolean NOT NULL DEFAULT false,
  gateway_config jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  UNIQUE (user_id, gateway_type)
);

ALTER TABLE public.payment_gateway_settings ENABLE ROW LEVEL SECURITY;

-- Users can view their own settings
CREATE POLICY "Users can view own payment settings"
ON public.payment_gateway_settings FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Users with seller or venue_owner role can insert
CREATE POLICY "Partners can create payment settings"
ON public.payment_gateway_settings FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_id AND (
    has_role(auth.uid(), 'seller'::app_role) OR 
    has_role(auth.uid(), 'venue_owner'::app_role)
  )
);

-- Partners can update their own settings
CREATE POLICY "Partners can update payment settings"
ON public.payment_gateway_settings FOR UPDATE
TO authenticated
USING (
  auth.uid() = user_id AND (
    has_role(auth.uid(), 'seller'::app_role) OR 
    has_role(auth.uid(), 'venue_owner'::app_role)
  )
);

-- Partners can delete their own settings
CREATE POLICY "Partners can delete payment settings"
ON public.payment_gateway_settings FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- Admins can view all payment settings
CREATE POLICY "Admins can view all payment settings"
ON public.payment_gateway_settings FOR SELECT
TO authenticated
USING (has_role(auth.uid(), 'admin'::app_role));

-- Admins can manage all payment settings
CREATE POLICY "Admins can manage all payment settings"
ON public.payment_gateway_settings FOR ALL
TO authenticated
USING (has_role(auth.uid(), 'admin'::app_role));

-- Updated at trigger
CREATE TRIGGER update_payment_gateway_updated_at
  BEFORE UPDATE ON public.payment_gateway_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Add site settings table for CMS
CREATE TABLE IF NOT EXISTS public.site_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  site_name text NOT NULL DEFAULT 'Gulu Market',
  logo_url text,
  primary_color text DEFAULT '#000000',
  secondary_color text DEFAULT '#666666',
  accent_color text DEFAULT '#0EA5E9',
  contact_email text,
  contact_phone text,
  address text,
  about_text text,
  updated_at timestamp with time zone DEFAULT now(),
  updated_by uuid REFERENCES auth.users(id)
);

-- Enable RLS
ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;

-- Everyone can view site settings
CREATE POLICY "Site settings are viewable by everyone"
ON public.site_settings
FOR SELECT
USING (true);

-- Only admins can update site settings
CREATE POLICY "Admins can update site settings"
ON public.site_settings
FOR UPDATE
USING (has_role(auth.uid(), 'admin'));

-- Only admins can insert site settings
CREATE POLICY "Admins can insert site settings"
ON public.site_settings
FOR INSERT
WITH CHECK (has_role(auth.uid(), 'admin'));

-- Insert default site settings
INSERT INTO public.site_settings (site_name, about_text)
VALUES ('Gulu Market', 'Your one-stop marketplace for local products and services in Gulu')
ON CONFLICT DO NOTHING;

-- Add trigger for updated_at
CREATE TRIGGER update_site_settings_updated_at
BEFORE UPDATE ON public.site_settings
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();
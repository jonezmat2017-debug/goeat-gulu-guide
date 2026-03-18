import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { userId, userPreferences } = await req.json();
    const LOVABLE_API_KEY = Deno.env.get('LOVABLE_API_KEY');

    if (!LOVABLE_API_KEY) {
      throw new Error('LOVABLE_API_KEY is not configured');
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Fetch available products and venues
    const { data: products } = await supabase
      .from('products')
      .select('id, name, description, category, price')
      .limit(20);

    const { data: venues } = await supabase
      .from('venues')
      .select('id, name, description, category')
      .limit(20);

    const prompt = `Based on the following available products and venues, recommend the top 5 items that would be most appealing to a new user${userPreferences ? ` with these preferences: ${userPreferences}` : ''}.

Available Products:
${products?.map(p => `- ${p.name} (${p.category}): ${p.description}`).join('\n')}

Available Venues:
${venues?.map(v => `- ${v.name} (${v.category}): ${v.description}`).join('\n')}

Provide recommendations in JSON format with this structure:
{
  "products": [{"id": "...", "reason": "why recommend"}],
  "venues": [{"id": "...", "reason": "why recommend"}]
}`;

    const response = await fetch('https://ai.gateway.lovable.dev/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${LOVABLE_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'google/gemini-2.5-flash',
        messages: [
          { role: 'system', content: 'You are a helpful recommendation assistant. Always respond with valid JSON only.' },
          { role: 'user', content: prompt }
        ],
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error('AI gateway error:', response.status, error);
      throw new Error('Failed to generate recommendations');
    }

    const data = await response.json();
    const content = data.choices[0].message.content;
    
    // Parse the JSON from the response
    const jsonMatch = content.match(/\{[\s\S]*\}/);
    const recommendations = jsonMatch ? JSON.parse(jsonMatch[0]) : { products: [], venues: [] };

    return new Response(
      JSON.stringify({ recommendations }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error in ai-recommendations function:', error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : 'Unknown error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});

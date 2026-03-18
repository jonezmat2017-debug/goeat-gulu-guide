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
    const { productId, venueId } = await req.json();
    const LOVABLE_API_KEY = Deno.env.get('LOVABLE_API_KEY');

    if (!LOVABLE_API_KEY) {
      throw new Error('LOVABLE_API_KEY is not configured');
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Fetch reviews
    const query = supabase.from('reviews').select('rating, comment, created_at');
    
    if (productId) {
      query.eq('product_id', productId);
    } else if (venueId) {
      query.eq('venue_id', venueId);
    }

    const { data: reviews } = await query.limit(50);

    if (!reviews || reviews.length === 0) {
      return new Response(
        JSON.stringify({ summary: 'No reviews available yet', sentiment: 'neutral', keyThemes: [] }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const prompt = `Analyze the following customer reviews and provide:
1. Overall sentiment (positive/negative/neutral)
2. Key themes and topics mentioned
3. A brief summary of customer feedback
4. Suggestions for improvement

Reviews:
${reviews.map((r, i) => `Review ${i + 1} (Rating: ${r.rating}/5):\n${r.comment}`).join('\n\n')}

Respond in JSON format:
{
  "sentiment": "positive|negative|neutral",
  "summary": "brief summary",
  "keyThemes": ["theme1", "theme2"],
  "suggestions": ["suggestion1", "suggestion2"]
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
          { role: 'system', content: 'You are an expert at analyzing customer feedback. Always respond with valid JSON only.' },
          { role: 'user', content: prompt }
        ],
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error('AI gateway error:', response.status, error);
      throw new Error('Failed to analyze reviews');
    }

    const data = await response.json();
    const content = data.choices[0].message.content;
    
    const jsonMatch = content.match(/\{[\s\S]*\}/);
    const analysis = jsonMatch ? JSON.parse(jsonMatch[0]) : { sentiment: 'neutral', summary: '', keyThemes: [], suggestions: [] };

    return new Response(
      JSON.stringify({ analysis }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error in analyze-reviews function:', error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : 'Unknown error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { location, placeType } = await req.json();
    const GOOGLE_API_KEY = Deno.env.get("GOOGLE_PLACES_API_KEY");

    if (!GOOGLE_API_KEY) {
      throw new Error("Google Places API key not configured");
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Get user from auth header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      throw new Error("No authorization header");
    }

    const { data: { user }, error: authError } = await supabase.auth.getUser(
      authHeader.replace("Bearer ", "")
    );

    if (authError || !user) {
      throw new Error("Unauthorized");
    }

    // Verify user is admin
    const { data: roles } = await supabase
      .from("user_roles")
      .select("role")
      .eq("user_id", user.id)
      .eq("role", "admin")
      .eq("approved", true);

    if (!roles || roles.length === 0) {
      throw new Error("Admin access required");
    }

    console.log(`Searching for ${placeType} in ${location}`);

    // Search for places using Google Places API (Text Search)
    const searchUrl = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${encodeURIComponent(
      `${placeType} in ${location}`
    )}&key=${GOOGLE_API_KEY}`;

    const searchResponse = await fetch(searchUrl);
    const searchData = await searchResponse.json();

    if (searchData.status !== "OK" && searchData.status !== "ZERO_RESULTS") {
      console.error("Google API Error:", searchData);
      throw new Error(`Google Places API error: ${searchData.status}`);
    }

    const places = searchData.results || [];
    console.log(`Found ${places.length} places`);

    // Map place types to our categories
    const categoryMap: Record<string, string> = {
      restaurant: "Eating Places",
      night_club: "Night Spots",
      bar: "Night Spots",
      cafe: "Eating Places",
    };

    const category = categoryMap[placeType] || "Eating Places";
    let importedCount = 0;

    // Import each place
    for (const place of places.slice(0, 20)) {
      try {
        const venueData = {
          name: place.name,
          category: category,
          location: place.vicinity || place.formatted_address || location,
          address: place.formatted_address || place.vicinity || "",
          rating: place.rating || 0,
          review_count: place.user_ratings_total || 0,
          price_level: place.price_level || 1,
          is_open: place.opening_hours?.open_now ?? true,
          description: place.types?.join(", ") || null,
          phone: null,
          email: null,
          image_url: place.photos?.[0]?.photo_reference
            ? `https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=${place.photos[0].photo_reference}&key=${GOOGLE_API_KEY}`
            : null,
          featured: false,
          approved: true,
          approved_by: user.id,
          approved_at: new Date().toISOString(),
          submitted_by: user.id,
        };

        // Check if venue already exists
        const { data: existing } = await supabase
          .from("venues")
          .select("id")
          .eq("name", venueData.name)
          .eq("location", venueData.location)
          .limit(1)
          .maybeSingle();

        if (!existing) {
          const { error: insertError } = await supabase
            .from("venues")
            .insert(venueData);

          if (insertError) {
            console.error(`Error importing ${place.name}:`, insertError);
          } else {
            importedCount++;
            console.log(`Imported: ${place.name}`);
          }
        } else {
          console.log(`Skipped duplicate: ${place.name}`);
        }
      } catch (error) {
        console.error(`Error processing place ${place.name}:`, error);
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        places: places.slice(0, 20).map((p: any) => ({
          name: p.name,
          address: p.formatted_address || p.vicinity,
          rating: p.rating,
          priceLevel: p.price_level,
        })),
        imported: importedCount,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Function error:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : "Unknown error occurred",
      }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

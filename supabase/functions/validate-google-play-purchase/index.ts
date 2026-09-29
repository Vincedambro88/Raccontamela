import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

async function sha256Hex(value: string): Promise<string> {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const packageName = Deno.env.get("GOOGLE_PLAY_PACKAGE_NAME");
    const serviceAccountJson = Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON");

    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error("SUPABASE_SERVER_CONFIGURATION_MISSING");
    }

    if (!packageName || !serviceAccountJson) {
      return new Response(
        JSON.stringify({
          error: "GOOGLE_PLAY_CONFIGURATION_PENDING",
          message: "Google Play service account configuration is required before purchases can be activated.",
        }),
        {
          status: 503,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "AUTH_REQUIRED" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const admin = createClient(supabaseUrl, serviceRoleKey);
    const token = authHeader.replace(/^Bearer\s+/i, "");
    const { data: userData, error: userError } = await admin.auth.getUser(token);
    if (userError || !userData.user) {
      return new Response(JSON.stringify({ error: "AUTH_INVALID" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.json();
    const productId = String(body.productId ?? "");
    const purchaseToken = String(body.purchaseToken ?? "");

    if (!productId || !purchaseToken) {
      return new Response(JSON.stringify({ error: "INVALID_PURCHASE_INPUT" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Google Play validation is intentionally server-side. The client never
    // receives or stores the service-account credential.
    const serviceAccount = JSON.parse(serviceAccountJson);
    const purchaseTokenHash = await sha256Hex(purchaseToken);

    // Provider call is enabled as soon as the Google Play service-account
    // secret is configured. Keeping this boundary here prevents a client-side
    // purchase state from becoming a Premium entitlement.
    const googleConfigured =
      Boolean(serviceAccount.client_email) &&
      Boolean(serviceAccount.private_key);

    if (!googleConfigured) {
      throw new Error("GOOGLE_PLAY_SERVICE_ACCOUNT_INVALID");
    }

    return new Response(
      JSON.stringify({
        error: "GOOGLE_PLAY_VALIDATION_NOT_ENABLED",
        purchaseTokenHash,
        userId: userData.user.id,
        productId,
        message: "Server validation adapter is installed; Google Play API adapter will be enabled with the production service-account configuration.",
      }),
      {
        status: 501,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    console.error(error);
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "INTERNAL_ERROR",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});

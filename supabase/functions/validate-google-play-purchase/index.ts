import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const b64url = (bytes: Uint8Array) =>
  btoa(String.fromCharCode(...bytes))
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");

const utf8 = (value: string) => new TextEncoder().encode(value);

function pemToDer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replaceAll(/\s/g, "");
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

async function signServiceAccountJwt(
  clientEmail: string,
  privateKeyPem: string,
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(utf8(JSON.stringify({ alg: "RS256", typ: "JWT" })));
  const payload = b64url(
    utf8(
      JSON.stringify({
        iss: clientEmail,
        scope: "https://www.googleapis.com/auth/androidpublisher",
        aud: "https://oauth2.googleapis.com/token",
        iat: now,
        exp: now + 3600,
      }),
    ),
  );
  const unsigned = `${header}.${payload}`;

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(privateKeyPem),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      key,
      utf8(unsigned),
    ),
  );

  return `${unsigned}.${b64url(signature)}`;
}

async function getGoogleAccessToken(
  clientEmail: string,
  privateKeyPem: string,
): Promise<string> {
  const assertion = await signServiceAccountJwt(clientEmail, privateKeyPem);
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });

  if (!response.ok) {
    throw new Error(`GOOGLE_OAUTH_FAILED_${response.status}`);
  }

  const data = await response.json();
  if (!data.access_token) throw new Error("GOOGLE_OAUTH_TOKEN_MISSING");
  return data.access_token;
}

async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", utf8(value));
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
        JSON.stringify({ error: "GOOGLE_PLAY_CONFIGURATION_PENDING" }),
        { status: 503, headers: { ...corsHeaders, "Content-Type": "application/json" } },
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

    const serviceAccount = JSON.parse(serviceAccountJson);
    if (!serviceAccount.client_email || !serviceAccount.private_key) {
      throw new Error("GOOGLE_PLAY_SERVICE_ACCOUNT_INVALID");
    }

    const accessToken = await getGoogleAccessToken(
      serviceAccount.client_email,
      serviceAccount.private_key,
    );

    const purchaseUrl =
      "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/" +
      encodeURIComponent(packageName) +
      "/purchases/products/" +
      encodeURIComponent(productId) +
      "/tokens/" +
      encodeURIComponent(purchaseToken);

    const purchaseResponse = await fetch(purchaseUrl, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });

    if (!purchaseResponse.ok) {
      return new Response(
        JSON.stringify({ error: `GOOGLE_PURCHASE_LOOKUP_FAILED_${purchaseResponse.status}` }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const purchase = await purchaseResponse.json();
    const purchaseState = Number(purchase.purchaseState);
    const acknowledgementState = Number(purchase.acknowledgementState);

    if (![0, 1, 2].includes(purchaseState)) {
      throw new Error("GOOGLE_PURCHASE_STATE_UNKNOWN");
    }

    if (purchaseState === 0 && acknowledgementState === 0) {
      const acknowledgeUrl =
        purchaseUrl + ":acknowledge";
      const acknowledgeResponse = await fetch(acknowledgeUrl, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({}),
      });
      if (!acknowledgeResponse.ok && acknowledgeResponse.status !== 409) {
        throw new Error(`GOOGLE_ACKNOWLEDGE_FAILED_${acknowledgeResponse.status}`);
      }
    }

    const status =
      purchaseState === 0 ? "active" :
      purchaseState === 2 ? "pending" :
      "revoked";

    const purchaseTokenHash = await sha256Hex(purchaseToken);

    await admin.from("premium_entitlements").upsert({
      user_id: userData.user.id,
      product_id: productId,
      purchase_token_hash: purchaseTokenHash,
      status,
      expires_at: null,
      last_validated_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    });

    return new Response(
      JSON.stringify({
        status,
        productId,
        orderId: purchase.orderId ?? null,
      }),
      {
        status: 200,
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

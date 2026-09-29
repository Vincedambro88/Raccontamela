import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type Body = {
  story: {
    title: string;
    protagonistName: string;
    setting: string;
    city: string;
    scenes: Array<{ index: number; text: string }>;
  };
  storyId?: string | null;
  mediaToken?: string;
};

async function openAi(body: unknown, key: string) {
  const response = await fetch("https://api.openai.com/v1/images/generations", {
    method: "POST",
    headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!response.ok) throw new Error(`Provider error ${response.status}: ${await response.text()}`);
  return response.json();
}

async function verifyMediaToken(story: unknown, token: string, serviceKey: string) {
  const parts = token.split(".");
  if (parts.length !== 3) return false;
  const exp = Number(parts[1]);
  if (!Number.isFinite(exp) || exp < Math.floor(Date.now() / 1000)) return false;
  const fingerprintBytes = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(JSON.stringify(story)));
  const fingerprint = Array.from(new Uint8Array(fingerprintBytes)).map((b) => b.toString(16).padStart(2, "0")).join("");
  if (parts[0] !== fingerprint) return false;
  const payload = `${parts[0]}.${parts[1]}`;
  const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(serviceKey), { name: "HMAC", hash: "SHA-256" }, false, ["verify"]);
  const sig = Uint8Array.from(atob(parts[2].replace(/-/g, "+").replace(/_/g, "/") + "=".repeat((4 - parts[2].length % 4) % 4)), (c) => c.charCodeAt(0));
  return crypto.subtle.verify("HMAC", key, sig, new TextEncoder().encode(payload));
}

function b64ToBytes(value: string) {
  const raw = atob(value);
  const bytes = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) bytes[i] = raw.charCodeAt(i);
  return bytes;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405, headers: { ...cors, "Content-Type": "application/json" } });

  try {
    const key = Deno.env.get("OPENAI_API_KEY");
    if (!key) throw new Error("Media provider is not configured");
    const body = await req.json() as Body;
    if (!body.story?.title || !Array.isArray(body.story.scenes) || !body.story.scenes.length) throw new Error("Invalid story payload");

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const admin = createClient(supabaseUrl, serviceKey, { auth: { persistSession: false } });

    let prefix = `anonymous/${crypto.randomUUID()}`;
    let persistentStoryId: string | null = null;

    const auth = req.headers.get("Authorization");
    if (body.storyId) {
      if (!auth?.startsWith("Bearer ")) throw new Error("Authentication required");
      const { data: userData, error: authError } = await admin.auth.getUser(auth.slice(7));
      if (authError || !userData.user) throw new Error("Authentication required");

      const { data: entitlement } = await admin.from("premium_entitlements")
        .select("status,expires_at").eq("user_id", userData.user.id).maybeSingle();
      const active = entitlement?.status === "active" &&
        (!entitlement.expires_at || new Date(entitlement.expires_at) > new Date());
      if (!active) throw new Error("Premium entitlement required");

      const { data: ownedStory } = await admin.from("stories")
        .select("id").eq("id", body.storyId).eq("user_id", userData.user.id).maybeSingle();
      if (!ownedStory) throw new Error("Story not found");
      persistentStoryId = body.storyId;
      prefix = `${userData.user.id}/${body.storyId}`;
    } else {
      if (typeof body.mediaToken !== "string" || !await verifyMediaToken(body.story, body.mediaToken, serviceKey)) {
        throw new Error("Invalid or expired media token");
      }
    }
    const model = Deno.env.get("OPENAI_IMAGE_MODEL") || "gpt-image-2";
    const results: unknown[] = [];

    for (const scene of body.story.scenes) {
      try {
        const json = await openAi({
          model,
          prompt: `Full-color children's storybook illustration, warm whimsical style, clear friendly characters, age-appropriate, no text and no captions. Story: "${body.story.title}". Setting: ${body.story.setting}. City: ${body.story.city}. Protagonist: ${body.story.protagonistName}. Scene: ${scene.text}`,
          size: "1024x1024",
        }, key);
        const image = json.data?.[0]?.b64_json;
        if (!image) throw new Error("Image provider returned no image");
        const path = `${prefix}/scene-${scene.index}-color.png`;
        const { error } = await admin.storage.from("story-assets").upload(path, b64ToBytes(image), { contentType: "image/png", upsert: true });
        if (error) throw error;
        if (persistentStoryId) {
          const { data: sceneRow } = await admin.from("story_scenes")
            .select("id").eq("story_id", persistentStoryId).eq("scene_index", scene.index).maybeSingle();
          if (sceneRow) {
            await admin.from("story_scenes").update({ color_image_path: path }).eq("id", sceneRow.id);
          }
        }
        const { data: signed, error: signedError } = await admin.storage.from("story-assets").createSignedUrl(path, 60 * 60);
        if (signedError) throw signedError;
        results.push({ sceneIndex: scene.index, colorImageUrl: signed.signedUrl });
      } catch (error) {
        results.push({ sceneIndex: scene.index, error: error instanceof Error ? error.message : String(error) });
      }
    }

    return new Response(JSON.stringify({ results }), { headers: { ...cors, "Content-Type": "application/json" } });
  } catch (error) {
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : String(error) }), { status: 400, headers: { ...cors, "Content-Type": "application/json" } });
  }
});

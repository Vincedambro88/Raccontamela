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
    if (!body.story?.title || !Array.isArray(body.story.scenes) || !body.story.scenes.length || typeof (body as any).mediaToken !== "string") throw new Error("Invalid story payload");

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const admin = createClient(supabaseUrl, serviceKey, { auth: { persistSession: false } });
    if (!await verifyMediaToken(body.story, (body as any).mediaToken, serviceKey)) throw new Error("Invalid or expired media token");
    const prefix = `anonymous/${crypto.randomUUID()}`;
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
        const path = `${prefix}/scene-${scene.index}.png`;
        const { error } = await admin.storage.from("story-assets").upload(path, b64ToBytes(image), { contentType: "image/png", upsert: false });
        if (error) throw error;
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

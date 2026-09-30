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
    city?: string;
    animalFriends?: string[];
    friends?: string[];
    visualBible?: string;
    sceneVisuals?: Record<string, string>;
    scenes: Array<{ index: number; text: string }>;
  };
  storyId?: string | null;
  mediaToken?: string;
};

async function generateImage(prompt: string, model: string) {
  const url = `https://image.pollinations.ai/prompt/${encodeURIComponent(prompt)}?model=${encodeURIComponent(model)}&width=1024&height=1024&nologo=true`;
  const response = await fetch(url);
  if (!response.ok) throw new Error(`Pollinations error ${response.status}: ${await response.text()}`);
  return new Uint8Array(await response.arrayBuffer());
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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405, headers: { ...cors, "Content-Type": "application/json" } });

  try {
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
    const model = "flux";
    const results: unknown[] = [];


    const generateScene = async (scene: { index: number; text: string }) => {
      try {
        const visualAction = body.story.sceneVisuals?.[String(scene.index)] || scene.text;
        const prompt = `Full-color children's picture-book page illustration for Raccontamela. Warm, cinematic, whimsical, age-appropriate, consistent children's picture-book style. This is one exact page of a continuous 8-page story, so preserve the same characters, animal anatomy and location from page to page.

CHARACTER AND LOCATION CONTINUITY BIBLE:
${body.story.visualBible || "Keep all named characters visually consistent."}

HUMAN FRIENDS: ${body.story.friends?.join(", ") || "none"}.
ANIMAL COMPANIONS: ${body.story.animalFriends?.join(", ") || "none"}. Every animal remains a real or fantastical animal with animal anatomy and natural animal behavior; never humanized.

PLACE: ${body.story.setting}. Treat it as the physical place where the action occurs, not as a generic background and not as a person.

EXACT VISUAL ACTION FOR THIS PAGE:
${visualAction}

EXACT PAGE TEXT:
${scene.text}

Show the main action from this page clearly. Keep important objects and clues consistent with the story. Do not add unrelated characters, locations or events. Do not include any text, letters, speech bubbles, captions or page numbers in the image because the app renders the page text above the illustration.`;
        const imageBytes = await generateImage(prompt, model);

        const path = `${prefix}/scene-${scene.index}-color.png`;
        const { error } = await admin.storage.from("story-assets").upload(
          path,
          imageBytes,
          { contentType: "image/png", upsert: true },
        );
        if (error) throw error;

        if (persistentStoryId) {
          const { data: sceneRow } = await admin.from("story_scenes")
            .select("id").eq("story_id", persistentStoryId).eq("scene_index", scene.index).maybeSingle();
          if (sceneRow) {
            const { error: updateError } = await admin.from("story_scenes")
              .update({ color_image_path: path }).eq("id", sceneRow.id);
            if (updateError) throw updateError;
          }
        }

        const { data: signed, error: signedError } =
          await admin.storage.from("story-assets").createSignedUrl(path, 60 * 60);
        if (signedError) throw signedError;
        return { sceneIndex: scene.index, colorImageUrl: signed.signedUrl };
      } catch (error) {
        console.error("Color media generation failed", {
          sceneIndex: scene.index,
          error: error instanceof Error ? error.message : String(error),
        });
        return {
          sceneIndex: scene.index,
          error: error instanceof Error ? error.message : String(error),
        };
      }
    };

    // Generate several pages in parallel so eight illustrations do not hit the
    // Edge Function request timeout. Keep concurrency bounded to avoid provider throttling.
    for (let offset = 0; offset < body.story.scenes.length; offset += 4) {
      const batch = body.story.scenes.slice(offset, offset + 4);
      const batchResults = await Promise.all(batch.map(generateScene));
      results.push(...batchResults);
    }


    return new Response(JSON.stringify({ results }), { headers: { ...cors, "Content-Type": "application/json" } });
  } catch (error) {
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : String(error) }), { status: 400, headers: { ...cors, "Content-Type": "application/json" } });
  }
});

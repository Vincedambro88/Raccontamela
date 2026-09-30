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

async function generateImage(prompt: string, _model: string, seed: number) {
  const host = "https://black-forest-labs-flux-1-schnell.hf.space";
  let lastError = "unknown error";

  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const submit = await fetch(host + "/gradio_api/call/infer", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ data: [prompt, seed, false, 1024, 1344, 4] }),
      });

      if (!submit.ok) {
        throw new Error("Hugging Face submit error " + submit.status + ": " + await submit.text());
      }

      const submitted = await submit.json() as { event_id?: string };
      if (!submitted.event_id) throw new Error("No Hugging Face event id");

      const resultResponse = await fetch(host + "/gradio_api/call/infer/" + submitted.event_id);
      if (!resultResponse.ok) {
        throw new Error("Hugging Face result error " + resultResponse.status + ": " + await resultResponse.text());
      }

      const stream = await resultResponse.text();
      const blocks = stream.split(/(?=event: )/g);
      const completeBlock = blocks.reverse().find((block) => block.includes("event: complete"));
      if (!completeBlock) throw new Error("Hugging Face generation did not complete");

      const dataLine = completeBlock.split("\n").find((line) => line.startsWith("data: "));
      if (!dataLine) throw new Error("Hugging Face completion contained no data");

      let data: unknown;
      try {
        data = JSON.parse(dataLine.slice(6));
      } catch {
        throw new Error("Invalid Hugging Face completion data");
      }

      const findImageUrl = (value: unknown): string | null => {
        if (typeof value !== "string") return null;
        if (value.startsWith("https://") || value.startsWith("http://")) return value;
        if (value.startsWith("/file=")) return host + value;
        if (value.startsWith("file=")) return host + "/" + value;
        if (value.includes("/tmp/") || value.endsWith(".png") || value.endsWith(".jpg") || value.endsWith(".webp")) {
          return host + "/file=" + value.replace(/^\\/+/, "");
        }
        return null;
      };

      const walk = (value: unknown): string | null => {
        const direct = findImageUrl(value);
        if (direct) return direct;
        if (Array.isArray(value)) {
          for (const item of value) {
            const found = walk(item);
            if (found) return found;
          }
        } else if (value && typeof value === "object") {
          for (const item of Object.values(value as Record<string, unknown>)) {
            const found = walk(item);
            if (found) return found;
          }
        }
        return null;
      };

      const imageUrl = walk(data);
      if (!imageUrl) throw new Error("Hugging Face completion returned no image URL");

      const imageResponse = await fetch(imageUrl);
      if (!imageResponse.ok) {
        throw new Error("Hugging Face image download error " + imageResponse.status);
      }
      const bytes = new Uint8Array(await imageResponse.arrayBuffer());
      if (bytes.length < 10000) throw new Error("Generated image is unexpectedly small");
      return bytes;
    } catch (error) {
      lastError = error instanceof Error ? error.message : String(error);
      if (attempt < 2) await new Promise((resolve) => setTimeout(resolve, 2500));
    }
  }

  throw new Error(lastError);
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
        const prompt = `Create ONE polished full-page illustration for a real children's picture book called "Raccontamela".

ART DIRECTION:
- hand-painted modern picture-book illustration, charming and emotionally expressive
- sophisticated children's publishing quality, not a generic AI fantasy image
- warm natural lighting, rich but believable colors, soft painterly textures
- clear silhouettes, readable facial expressions, appealing child-friendly anatomy
- visually simple enough that the story remains the focus
- no collage, no comic panels, no borders, no frames, no photorealism, no 3D render, no text

THIS IMAGE IS THE BACKGROUND OF THE STORY PAGE:
- vertical full-page portrait composition
- fill the entire page edge-to-edge
- reserve the lower 30-35% as a calm, visually quieter area with simple shapes and uncluttered background so the app can place the story text over it
- do NOT draw a white text box, parchment, speech bubble, letters or words
- keep important character faces and the main action in the upper/middle area
- do not place critical objects exactly behind the text area

CONTINUITY IS MANDATORY:
This is page ${scene.index + 1} of one continuous 8-page story. Reuse the SAME protagonist appearance, clothing, hair, age, animal appearance, friends and location established in the continuity bible. Do not redesign them between pages.
Never introduce a new character or object unless the page action explicitly requires it.

CHARACTER AND LOCATION CONTINUITY BIBLE:
${body.story.visualBible || "Keep all named characters visually consistent."}

HUMAN FRIENDS:
${body.story.friends?.join(", ") || "none"}

ANIMAL COMPANIONS:
${body.story.animalFriends?.join(", ") || "none"}. Animals must retain correct animal anatomy and natural animal behavior; never turn them into people.

STORY LOCATION:
${body.story.setting}. Make this specific place clearly recognizable and use its physical features as part of the scene.

EXACT ACTION TO ILLUSTRATE:
${visualAction}

PAGE TEXT FOR CONTEXT ONLY:
${scene.text}

The page text is supplied only to understand the scene. NEVER render the text in the image. Illustrate the concrete action, emotion and setting described above. Keep the composition coherent with the previous and next pages.`;

        const imageBytes = await generateImage(prompt, model, 7000 + scene.index);
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

    // Two at a time reduces throttling from the free image endpoint while
    // keeping the request inside the Edge Function execution window.
    for (let offset = 0; offset < body.story.scenes.length; offset += 2) {
      const batch = body.story.scenes.slice(offset, offset + 2);
      const batchResults = await Promise.all(batch.map(generateScene));
      results.push(...batchResults);
    }

    return new Response(JSON.stringify({ results }), { headers: { ...cors, "Content-Type": "application/json" } });
  } catch (error) {
    console.error("generate-color-media fatal", error instanceof Error ? error.message : String(error));
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : String(error) }), { status: 400, headers: { ...cors, "Content-Type": "application/json" } });
  }
});

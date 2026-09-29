import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type Body = {
  storyId: string;
  voiceId?: string;
  kinds?: Array<"color_image" | "bw_image" | "narration">;
};

const b64ToBytes = (value: string) => {
  const raw = atob(value);
  const bytes = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) bytes[i] = raw.charCodeAt(i);
  return bytes;
};

async function openAi(path: string, body: unknown, key: string) {
  const response = await fetch("https://api.openai.com/v1/" + path, {
    method: "POST",
    headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!response.ok) throw new Error(`Provider error ${response.status}: ${await response.text()}`);
  return response;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405, headers: { ...cors, "Content-Type": "application/json" } });

  try {
    const auth = req.headers.get("Authorization");
    if (!auth?.startsWith("Bearer ")) throw new Error("Authentication required");

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const openAiKey = Deno.env.get("OPENAI_API_KEY");
    if (!openAiKey) throw new Error("Media provider is not configured");

    const admin = createClient(supabaseUrl, serviceKey, { auth: { persistSession: false } });
    const { data: userData, error: authError } = await admin.auth.getUser(auth.slice(7));
    if (authError || !userData.user) throw new Error("Authentication required");

    const body = await req.json() as Body;
    if (!body.storyId) throw new Error("storyId is required");

    const { data: entitlement } = await admin.from("premium_entitlements")
      .select("status,expires_at").eq("user_id", userData.user.id).maybeSingle();
    const active = entitlement?.status === "active" &&
      (!entitlement.expires_at || new Date(entitlement.expires_at) > new Date());
    if (!active) throw new Error("Premium entitlement required");

    const { data: story, error: storyError } = await admin.from("stories")
      .select("id,title,protagonist_name,setting,story_city,friends,animal_friends,story_scenes(id,scene_index,text)")
      .eq("id", body.storyId).eq("user_id", userData.user.id).single();
    if (storyError || !story) throw new Error("Story not found");

    const kinds = body.kinds?.length ? body.kinds : ["color_image", "bw_image", "narration"];
    const voice = body.voiceId || Deno.env.get("DEFAULT_TTS_VOICE") || "alloy";
    const imageModel = Deno.env.get("OPENAI_IMAGE_MODEL") || "gpt-image-2";
    const ttsModel = Deno.env.get("OPENAI_TTS_MODEL") || "gpt-4o-mini-tts";

    const results: unknown[] = [];
    for (const scene of story.story_scenes as Array<{id:string;scene_index:number;text:string}>) {
      for (const kind of kinds) {
        const { data: job } = await admin.from("story_media_jobs").upsert({
          story_id: story.id, scene_id: scene.id, kind, status: "processing",
          provider: "openai", voice_id: kind === "narration" ? voice : null,
        }, { onConflict: "story_id,scene_id,kind" }).select("id").single();

        try {
          let bytes: Uint8Array;
          let contentType: string;
          let extension: string;

          if (kind === "narration") {
            const prompt = `Read this children's story scene in a warm, calm, expressive voice. Do not add words: ${scene.text}`;
            const response = await openAi("audio/speech", {
              model: ttsModel, voice, input: prompt, response_format: "mp3",
            }, openAiKey);
            bytes = new Uint8Array(await response.arrayBuffer());
            contentType = "audio/mpeg";
            extension = "mp3";
          } else {
            const mode = kind === "bw_image"
              ? "black and white children's coloring page, clean bold outlines, no shading, printable, friendly, simple composition"
              : "full color children's storybook illustration, warm whimsical style, clear characters, friendly and age-appropriate";
            const response = await openAi("images/generations", {
              model: imageModel,
              prompt: `${mode}. Scene from "${story.title}". Location: ${story.setting}. Protagonist: ${story.protagonist_name}. Human friends: ${(story.friends ?? []).join(", ") || "none"}. Animals: ${(story.animal_friends ?? []).join(", ") || "none"}. Treat animals as real animals, never as human characters. Scene: ${scene.text}`,
              size: "1024x1024",
            }, openAiKey);
            const json = await response.json();
            const image = json.data?.[0]?.b64_json;
            if (!image) throw new Error("Image provider returned no image");
            bytes = b64ToBytes(image);
            contentType = "image/png";
            extension = "png";
          }

          const path = `${userData.user.id}/${story.id}/scene-${scene.scene_index}-${kind}.${extension}`;
          const { error: uploadError } = await admin.storage.from("story-assets").upload(path, bytes, { contentType, upsert: true });
          if (uploadError) throw uploadError;

          const field = kind === "color_image" ? "color_image_path" : kind === "bw_image" ? "bw_image_path" : "narration_path";
          const { error: sceneError } = await admin.from("story_scenes").update({ [field]: path }).eq("id", scene.id);
          if (sceneError) throw sceneError;

          await admin.from("story_media_jobs").update({ status: "ready", storage_path: path, updated_at: new Date().toISOString() }).eq("id", job!.id);
          results.push({ sceneIndex: scene.scene_index, kind, status: "ready", path });
        } catch (error) {
          const message = error instanceof Error ? error.message : String(error);
          if (job?.id) await admin.from("story_media_jobs").update({ status: "failed", error_message: message, updated_at: new Date().toISOString() }).eq("id", job.id);
          results.push({ sceneIndex: scene.scene_index, kind, status: "failed", error: message });
        }
      }
    }

    return new Response(JSON.stringify({ storyId: story.id, results }), { headers: { ...cors, "Content-Type": "application/json" } });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ error: message }), { status: 400, headers: { ...cors, "Content-Type": "application/json" } });
  }
});

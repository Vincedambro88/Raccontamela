import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import catalog from "./story_masters_500_runtime.json" with { type: "json" };
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type StoryRequest = {
  protagonistName: string;
  setting: string;
  city?: string;
  friends?: string[];
  animalFriends?: string[];
  animal?: string;
  locale?: string;
};

type MasterStory = {
  id: string;
  title: string;
  setting: string;
  animal: string;
  pages: string[];
  status?: string;
};

const masters = (catalog as { stories: MasterStory[] }).stories;
const allowedLocales = new Set(["it", "en", "fr", "es", "de"]);
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const cleanList = (value: unknown, max: number) =>
  Array.isArray(value) ? value.map(String).map((v) => v.trim()).filter(Boolean).slice(0, max) : [];

function randomItem<T>(items: T[]): T {
  const random = new Uint32Array(1);
  crypto.getRandomValues(random);
  return items[random[0] % items.length];
}

function selectMaster(setting: string, animal: string): MasterStory {
  const normalizedSetting = setting.trim().toLowerCase();
  const normalizedAnimal = animal.trim().toLowerCase();
  const bySetting = masters.filter((m) => m.setting.trim().toLowerCase() === normalizedSetting);
  const settingPool = bySetting.length ? bySetting : masters;
  const byAnimal = settingPool.filter((m) => m.animal.trim().toLowerCase() === normalizedAnimal);
  return randomItem(byAnimal.length ? byAnimal : settingPool);
}

function replaceVariables(
  master: MasterStory,
  protagonistName: string,
  setting: string,
  friends: string[],
  animal: string,
) {
  const animalText = animal.includes(":") ? animal.split(":")[0].trim() : animal;
  const friendText = friends.length
    ? friends.length === 1
      ? friends[0]
      : friends.slice(0, -1).join(", ") + " e " + friends[friends.length - 1]
    : "";

  const pages = master.pages.map((page) =>
    page
      .replaceAll("{{PROTAGONISTA}}", protagonistName)
      .replaceAll("{{ANIMALE}}", animalText)
      .replaceAll("{{LUOGO}}", setting)
      .replaceAll("{{AMICI}}", friendText),
  );

  // The editorial masters currently use explicit protagonist/animal placeholders.
  // Friends are a runtime variable too: introduce their names once, without
  // changing the master plot or adding a new event.
  if (friendText && pages.length) {
    const marker = protagonistName + " era insieme a " + friendText + ". ";
    pages[0] = pages[0].replace(protagonistName, marker + protagonistName);
  }

  const title = master.title
    .replaceAll(master.setting, setting)
    .replaceAll("{{PROTAGONISTA}}", protagonistName)
    .replaceAll("{{ANIMALE}}", animalText);

  return { title, pages };
}

function buildVisualBible(protagonistName: string, setting: string, friends: string[], animal: string) {
  return [
    `Protagonista: ${protagonistName}. Mantieni età infantile, aspetto e abbigliamento coerenti in tutte le 8 pagine.`,
    `Luogo: ${setting}. Mantieni la stessa ambientazione fisica e la stessa continuità geografica in tutte le pagine.`,
    `Amici umani: ${friends.length ? friends.join(", ") : "nessuno"}.`,
    `Animale protagonista: ${animal}. Deve restare la stessa specie e avere anatomia e comportamento naturali.`,
    "Stile: illustrazione verticale da libro illustrato per bambini, coerente tra tutte le pagine, senza testo nell'immagine.",
  ].join(" ");
}

async function mediaTokenFor(story: unknown, serviceKey: string) {
  const bytes = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(JSON.stringify(story)),
  );
  const fingerprint = Array.from(new Uint8Array(bytes))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  const exp = Math.floor(Date.now() / 1000) + 30 * 60;
  const payload = `${fingerprint}.${exp}`;
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(serviceKey),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(payload),
  );
  const sig = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  return `${payload}.${sig}`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const body = await req.json() as StoryRequest;
    const protagonistName = String(body.protagonistName ?? "").trim();
    const setting = String(body.setting ?? body.city ?? "").trim();
    const locale = String(body.locale ?? "it").slice(0, 2).toLowerCase();
    const friends = cleanList(body.friends, 4);
    const animalFriends = cleanList(body.animalFriends, 10);
    const animal = String(body.animal ?? animalFriends[0] ?? "").trim();

    if (!protagonistName || !setting || !animal) {
      return new Response(JSON.stringify({
        error: "Missing required fields: protagonist, setting and animal are required",
      }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }
    if (friends.length > 4) {
      return new Response(JSON.stringify({ error: "A maximum of 4 protagonist friends is allowed" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    if (!allowedLocales.has(locale)) {
      return new Response(JSON.stringify({ error: "Unsupported locale" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const master = selectMaster(setting, animal);
    const resolved = replaceVariables(master, protagonistName, setting, friends, animal);
    const scenes = resolved.pages.map((text, index) => ({ index, text }));
    const storyText = scenes.map((s) => s.text).join("\n\n");
    const wordCount = storyText.trim().split(/\s+/).filter(Boolean).length;
    const visualBible = buildVisualBible(protagonistName, setting, friends, animal);

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    let saved = false;
    let storyId: string | null = null;

    if (supabaseUrl && serviceRoleKey) {
      const admin = createClient(supabaseUrl, serviceRoleKey, { auth: { persistSession: false } });
      const authHeader = req.headers.get("Authorization");
      if (authHeader?.startsWith("Bearer ")) {
        const { data: userData } = await admin.auth.getUser(authHeader.slice(7));
        if (userData.user) {
          const { data: entitlement } = await admin
            .from("premium_entitlements")
            .select("status,expires_at")
            .eq("user_id", userData.user.id)
            .maybeSingle();
          const active = entitlement?.status === "active" &&
            (!entitlement.expires_at || new Date(entitlement.expires_at) > new Date());

          if (active) {
            const { data: inserted, error } = await admin.from("stories").insert({
              user_id: userData.user.id,
              locale,
              title: resolved.title,
              protagonist_name: protagonistName,
              setting,
              story_city: body.city?.trim() || setting,
              friends,
              animal_friends: [animal, ...animalFriends.filter((v) => v !== animal)],
              story_text: storyText,
              duration_seconds: Math.round((wordCount / 135) * 60),
              status: "ready",
              is_premium_story: true,
            }).select("id").single();
            if (error) throw error;
            storyId = inserted.id;

            const { error: sceneError } = await admin.from("story_scenes").insert(
              scenes.map((scene) => ({
                story_id: storyId,
                scene_index: scene.index,
                text: scene.text,
              })),
            );
            if (sceneError) throw sceneError;
            saved = true;
          }
        }
      }
    }

    const mediaPayload = {
      title: resolved.title,
      masterStoryId: master.id,
      protagonistName,
      setting,
      city: body.city?.trim() || setting,
      friends,
      animal,
      animalFriends: [animal],
      scenes,
      visualBible,
    };
    const mediaToken = serviceRoleKey
      ? await mediaTokenFor(mediaPayload, serviceRoleKey)
      : null;

    return new Response(JSON.stringify({
      masterStoryId: master.id,
      title: resolved.title,
      protagonistName,
      setting,
      city: body.city?.trim() || setting,
      friends,
      animalFriends: [animal],
      scenes,
      text: storyText,
      durationSeconds: Math.round((wordCount / 135) * 60),
      wordCount,
      visualBible,
      sceneVisuals: Object.fromEntries(
        scenes.map((scene) => [String(scene.index), scene.text]),
      ),
      saved,
      storyId,
      mediaToken,
    }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("generate-story failed", error);
    return new Response(JSON.stringify({ error: "Story generation failed" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

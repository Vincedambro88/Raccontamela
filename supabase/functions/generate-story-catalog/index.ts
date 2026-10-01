import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type Scene = { index: number; text: string };
type Master = {
  id: string;
  title: string;
  setting: string;
  animal: string;
  pages: string[];
};

type Body = {
  masters: Master[];
  start?: number;
  count?: number;
  dryRun?: boolean;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return new Response(JSON.stringify({ error: "Method not allowed" }), {
    status: 405, headers: { ...cors, "Content-Type": "application/json" },
  });

  try {
    const body = await req.json() as Body;
    if (!Array.isArray(body.masters) || body.masters.length !== 500) {
      throw new Error("Expected exactly 500 master stories");
    }

    const start = Math.max(0, Math.min(499, body.start ?? 0));
    const count = Math.max(1, Math.min(10, body.count ?? 1));
    const selected = body.masters.slice(start, start + count);

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const admin = createClient(supabaseUrl, serviceKey, { auth: { persistSession: false } });

    const results: Array<{ id: string; status: string; scenes: number; missing: number[] }> = [];

    for (const master of selected) {
      if (!master.id || !Array.isArray(master.pages) || master.pages.length !== 8) {
        throw new Error(`Invalid master ${master.id}: expected 8 pages`);
      }

      const missing: number[] = [];
      for (let i = 1; i <= 8; i++) {
        const path = `catalog/${master.id}/page-${String(i).padStart(2, "0")}.png`;
        const { data } = await admin.storage.from("story-assets").list(`catalog/${master.id}`, {
          search: `page-${String(i).padStart(2, "0")}.png`,
          limit: 1,
        });
        if (!data?.some((x) => x.name === `page-${String(i).padStart(2, "0")}.png`)) missing.push(i);
      }

      results.push({
        id: master.id,
        status: missing.length === 0 ? "complete" : (body.dryRun ? "missing" : "ready"),
        scenes: 8,
        missing,
      });
    }

    return new Response(JSON.stringify({
      start,
      count: selected.length,
      results,
      nextStart: start + selected.length < 500 ? start + selected.length : null,
    }), { headers: { ...cors, "Content-Type": "application/json" } });
  } catch (error) {
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : String(error) }), {
      status: 400, headers: { ...cors, "Content-Type": "application/json" },
    });
  }
});

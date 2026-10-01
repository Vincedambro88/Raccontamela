import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const WORKER =
  "https://psbdgeeknuxmdbvblvrx.supabase.co/functions/v1/generate-story-catalog-worker";
const CATALOG =
  "https://raw.githubusercontent.com/Vincedambro88/Raccontamela/main/assets/stories/master_stories.json";

type Master = {
  id: string;
  title: string;
  setting: string;
  animal: string;
  pages: string[];
};
type Payload = { cursor?: number };

async function runPage(cursor: number) {
  const catalogRes = await fetch(CATALOG);
  if (!catalogRes.ok) {
    throw new Error("Catalog download failed: " + catalogRes.status);
  }

  const catalog = (await catalogRes.json()) as { stories: Master[] };
  if (!Array.isArray(catalog.stories) || catalog.stories.length !== 500) {
    throw new Error("Catalog must contain 500 stories");
  }

  if (cursor >= 4000) {
    return { ok: true, done: true, cursor, nextCursor: 4000 };
  }

  const masterIndex = Math.floor(cursor / 8);
  const page = (cursor % 8) + 1;
  const master = catalog.stories[masterIndex];

  const workerRes = await fetch(WORKER, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ master, startPage: page }),
  });
  const workerText = await workerRes.text();

  let workerData: unknown;
  try {
    workerData = JSON.parse(workerText);
  } catch {
    workerData = { raw: workerText };
  }

  if (!workerRes.ok) {
    throw new Error("Worker failed: " + workerText);
  }

  return {
    ok: true,
    done: cursor + 1 >= 4000,
    cursor,
    masterId: master.id,
    page,
    nextCursor: cursor + 1,
    worker: workerData,
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ ok: false, error: "POST required" }), {
      status: 405,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }

  try {
    const body = (await req.json().catch(() => ({}))) as Payload;
    const cursor = Math.max(0, Math.min(4000, body.cursor ?? 0));
    const result = await runPage(cursor);

    return new Response(JSON.stringify(result), {
      headers: { ...cors, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(
      JSON.stringify({
        ok: false,
        error: e instanceof Error ? e.message : String(e),
      }),
      {
        status: 400,
        headers: { ...cors, "Content-Type": "application/json" },
      },
    );
  }
});

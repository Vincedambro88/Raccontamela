import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS"};

type Master={id:string;title:string;setting:string;animal:string;pages:string[]};

async function generateImage(prompt:string, seed:number):Promise<Uint8Array>{
  const host="https://black-forest-labs-flux-1-schnell.hf.space";
  let last="unknown";
  for(let attempt=0;attempt<3;attempt++){
    try{
      const submit=await fetch(host+"/gradio_api/call/infer",{method:"POST",headers:{"Content-Type":"application/json","Accept":"application/json"},body:JSON.stringify({data:[prompt,seed,false,1024,1344,4]})});
      if(!submit.ok) throw new Error("submit "+submit.status);
      const {event_id}=await submit.json() as {event_id?:string};
      if(!event_id) throw new Error("missing event id");
      const res=await fetch(host+"/gradio_api/call/infer/"+event_id,{headers:{"Accept":"text/event-stream"}});
      if(!res.body) throw new Error("no event stream");
      const reader=res.body.getReader(), decoder=new TextDecoder(); let buffer="";
      const extract=(v:unknown):string|null=>{
        if(typeof v==="string"){
          if(/^https?:\/\//.test(v)) return v;
          if(v.startsWith("/file=")) return host+v;
          if(v.startsWith("file=")) return host+"/"+v;
          if(v.includes("/tmp/")) return host+"/file="+v.replace(/^\/+/,"");
        }
        if(Array.isArray(v)) for(const x of v){const r=extract(x);if(r)return r;}
        if(v&&typeof v==="object") for(const x of Object.values(v as Record<string,unknown>)){const r=extract(x);if(r)return r;}
        return null;
      };
      while(true){
        const {value,done}=await reader.read(); if(done) break;
        buffer+=decoder.decode(value,{stream:true});
        let p=buffer.indexOf("\n\n");
        while(p>=0){
          const block=buffer.slice(0,p); buffer=buffer.slice(p+2); p=buffer.indexOf("\n\n");
          const ev=block.split("\n").find(x=>x.startsWith("event: "))?.slice(7).trim();
          const dl=block.split("\n").find(x=>x.startsWith("data: "))?.slice(6);
          if(ev==="error") throw new Error(dl||"HF error");
          if(ev==="complete"){
            let data:unknown; try{data=JSON.parse(dl||"null")}catch{data=dl}
            const url=extract(data); if(!url) throw new Error("no image URL");
            const img=await fetch(url); if(!img.ok) throw new Error("download "+img.status);
            const bytes=new Uint8Array(await img.arrayBuffer()); if(bytes.length<10000) throw new Error("image too small");
            return bytes;
          }
        }
      }
      throw new Error("generation incomplete");
    }catch(e){last=e instanceof Error?e.message:String(e); await new Promise(r=>setTimeout(r,2000));}
  }
  throw new Error(last);
}

function promptFor(m:Master,page:number):string{
  return `Create ONE polished full-page illustration for an Italian children's picture book.
Style: hand-painted modern picture-book illustration, warm natural lighting, rich believable colors, soft painterly textures, child-friendly anatomy, expressive faces. No photorealism, no 3D, no collage, no panels, no borders.
Vertical portrait 1024x1344, edge-to-edge. Keep the lower 30-35% calm and visually simple for app-overlaid story text. NEVER draw text, letters, numbers, symbols, signs, speech bubbles or pseudo-writing anywhere.
CONTINUITY: this is page ${page} of the SAME story. Keep protagonist, animal, friends and location visually consistent.
PROTAGONIST: a child named {{PROTAGONISTA}}.
ANIMAL: ${m.animal}.
LOCATION: ${m.setting}.
PAGE ACTION: ${m.pages[page-1]}.
Illustrate only the concrete action and emotion. Keep important faces and action in the upper/middle area. The supplied page text is context only and must never appear in the image.`;
}

Deno.serve(async(req)=>{
  if(req.method==="OPTIONS") return new Response("ok",{headers:cors});
  try{
    const body=await req.json() as {master:Master; protagonist?:string; startPage?:number};
    const m=body.master;
    if(!m?.id||!Array.isArray(m.pages)||m.pages.length!==8) throw new Error("Invalid master");
    const page=Math.max(1,Math.min(8,body.startPage??1));
    const sb=createClient(Deno.env.get("SUPABASE_URL")!,Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    const path=`catalog/${m.id}/page-${String(page).padStart(2,"0")}.png`;
    const existing=await sb.storage.from("story-assets").list(`catalog/${m.id}`,{search:`page-${String(page).padStart(2,"0")}.png`,limit:1});
    if(existing.data?.some(x=>x.name===`page-${String(page).padStart(2,"0")}.png`)){
      return new Response(JSON.stringify({status:"exists",masterId:m.id,page,path,nextPage:page<8?page+1:null}),{headers:{...cors,"Content-Type":"application/json"}});
    }
    const bytes=await generateImage(promptFor(m,page),700000+page);
    const up=await sb.storage.from("story-assets").upload(path,bytes,{contentType:"image/png",upsert:true});
    if(up.error) throw up.error;
    return new Response(JSON.stringify({status:"generated",masterId:m.id,page,path,nextPage:page<8?page+1:null,size:bytes.length}),{headers:{...cors,"Content-Type":"application/json"}});
  }catch(e){
    return new Response(JSON.stringify({status:"error",error:e instanceof Error?e.message:String(e)}),{status:400,headers:{...cors,"Content-Type":"application/json"}});
  }
});
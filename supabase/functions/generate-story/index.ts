import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type StoryRequest = {
  protagonistName: string;
  setting: string;
  city?: string;
  friends?: string[];
  animalFriends?: string[];
  locale?: string;
};

const allowedLocales = new Set(["it", "en", "fr", "es", "de"]);
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const cleanList = (value: unknown, max: number) =>
  Array.isArray(value) ? value.map(String).map((v) => v.trim()).filter(Boolean).slice(0, max) : [];

function buildStory(input: {
  protagonistName: string;
  setting: string;
  locale: string;
  friends: string[];
  animalFriends: string[];
}) {
  const { protagonistName: n, setting: s, locale: l, friends, animalFriends } = input;
  const human = friends.length ? friends.join(", ") : ({
    it: "un nuovo amico", en: "a new friend", fr: "un nouvel ami",
    es: "un nuevo amigo", de: "ein neuer Freund",
  } as Record<string, string>)[l] ?? "a new friend";
  const animal = animalFriends.length === 1
    ? animalFriends[0]
    : animalFriends.length > 1
      ? animalFriends.join(", ")
      : ({
        it: "un piccolo animale curioso", en: "a curious little animal", fr: "un petit animal curieux",
        es: "un pequeño animal curioso", de: "ein neugieriges kleines Tier",
      } as Record<string, string>)[l] ?? "a curious little animal";
  const hasAnimals = animalFriends.length > 0;

  const stories: Record<string, string[]> = {
    it: [
      `Una mattina luminosa, ${n} scoprì una piccola luce dorata all’ingresso di ${s}. Si muoveva lentamente tra alberi, porte o rocce, come se volesse indicare la strada. ${n} decise di seguirla e invitò ${human} a venire con lui.`,
      hasAnimals
        ? `${n} arrivò in un angolo tranquillo di ${s} dove aspettava ${animal}. L’animale annusò il terreno, ascoltò con attenzione e poi trotterellò verso la luce. ${n} lo seguì osservandolo esplorare il luogo a modo suo.`
        : `${n} arrivò in un angolo tranquillo di ${s} dove la traccia spariva. Insieme a ${human} cercò con attenzione, finché notò piccole impronte dorate.`,
      `Le impronte conducevano a un sentiero nascosto. Lungo il cammino, ${n} e ${human} trovarono una piuma blu, una campanella d’argento e una piccola chiave di legno. Ogni indizio rivelava qualcosa di nuovo su ${s}: un passaggio segreto, un piccolo ponte e una porta nascosta tra le foglie.`,
      hasAnimals
        ? `Sul ponte, ${animal} corse avanti. L’animale si fermò accanto a una pietra spostata e guardò ${n}. Sotto la pietra c’era la chiave che mancava. ${n} accarezzò piano l’animale e inserì la chiave nella serratura.`
        : `Sul ponte, ${n} notò una pietra spostata. Sotto c’era la chiave che mancava. ${human} tenne la lanterna mentre ${n} inseriva la chiave nella serratura.`,
      `La porta nascosta si aprì sul luogo più bello di ${s}: un giardino pieno di luci calde, musica dolce e fiori colorati. Al centro c’era un piccolo uccellino meccanico che non riusciva più a muovere le ali.`,
      hasAnimals
        ? `${n} ascoltò l’uccellino mentre ${animal} osservava dall’erba. Quando un minuscolo ingranaggio rotolò via, l’animale lo seguì e si fermò accanto a lui. ${n} raccolse l’ingranaggio, lo rimise al suo posto e le ali ripresero a muoversi.`
        : `${n} ascoltò con attenzione mentre ${human} cercava nei dintorni. Trovarono un minuscolo ingranaggio, lo rimisero al suo posto e le ali ripresero a muoversi.`,
      `La luce dorata salì sopra ${s} e si trasformò in centinaia di piccole stelle. ${n} capì che l’avventura non consisteva nel trovare un tesoro, ma nell’esplorare, osservare e scoprire che ogni persona e ogni animale può avere un ruolo speciale in un’avventura condivisa.`,
    ],
    en: [
      `One bright morning, ${n} discovered a tiny golden light at the entrance to ${s}. It moved slowly between trees, doors or rocks, as if it wanted to show the way. ${n} decided to follow it and invited ${human} to come along.`,
      hasAnimals
        ? `${n} reached a quiet corner of ${s} where ${animal} was waiting. The animal sniffed the ground, listened carefully and then trotted toward the glowing trail. ${n} followed, watching the animal explore the place in its own way.`
        : `${n} reached a quiet corner of ${s} where the trail suddenly disappeared. Together with ${human}, they looked carefully until they noticed tiny golden footprints.`,
      `The footprints led to a hidden path. Along the way, ${n} and ${human} found a blue feather, a silver bell and a little wooden key. Each clue revealed something about ${s}: a secret passage, a small bridge and a door hidden behind leaves.`,
      hasAnimals
        ? `At the bridge, ${animal} ran ahead. The animal stopped beside a loose stone and looked back at ${n}. Under the stone was the missing key. ${n} gently stroked the animal and placed the key in the lock.`
        : `At the bridge, ${n} noticed a loose stone. Under it was the missing key. ${human} held the lantern while ${n} placed the key in the lock.`,
      `The hidden door opened onto the most beautiful part of ${s}: a garden filled with warm lights, soft music and colorful flowers. At its center stood a small mechanical bird that could no longer move its wings.`,
      hasAnimals
        ? `${n} listened to the bird while ${animal} watched from the grass. When a tiny gear rolled away, the animal followed it and stopped beside it. ${n} picked up the gear, fitted it back into the bird and the wings began to move again.`
        : `${n} listened carefully while ${human} searched nearby. They found a tiny gear, fitted it back into the bird and the wings began to move again.`,
      `The golden light rose above ${s} and turned into hundreds of little stars. ${n} understood that the adventure had not been about finding a treasure. It was about exploring, paying attention and discovering how every person and every animal can have a special part in a shared adventure.`,
    ],
    fr: [
      `Un matin lumineux, ${n} découvrit une petite lumière dorée à l’entrée de ${s}. Elle avançait doucement entre les arbres, les portes ou les rochers, comme pour montrer le chemin. ${n} décida de la suivre et invita ${human} à venir.`,
      hasAnimals
        ? `${n} arriva dans un coin tranquille de ${s} où ${animal} attendait. L’animal renifla le sol, écouta attentivement puis trottina vers la lumière. ${n} le suivit en le regardant explorer le lieu à sa manière.`
        : `${n} arriva dans un coin tranquille de ${s} où la piste avait disparu. Avec ${human}, ils cherchèrent attentivement et remarquèrent de petites empreintes dorées.`,
      `Les empreintes conduisirent à un passage secret. En chemin, ${n} et ${human} trouvèrent une plume bleue, une clochette argentée et une petite clé en bois. Chaque indice révélait quelque chose sur ${s} : un passage caché, un petit pont et une porte derrière les feuilles.`,
      hasAnimals
        ? `Au pont, ${animal} s’agita et partit devant. L’animal s’arrêta près d’une pierre déplacée et regarda ${n}. Sous la pierre se trouvait la clé manquante. ${n} caressa doucement l’animal puis plaça la clé dans la serrure.`
        : `Au pont, ${n} remarqua une pierre déplacée. Sous celle-ci se trouvait la clé manquante. ${human} tint la lanterne pendant que ${n} plaça la clé dans la serrure.`,
      `La porte cachée s’ouvrit sur le plus bel endroit de ${s} : un jardin rempli de lumières douces, de musique et de fleurs colorées. Au centre se trouvait un petit oiseau mécanique qui ne pouvait plus bouger ses ailes.`,
      hasAnimals
        ? `${n} écouta l’oiseau tandis que ${animal} observait depuis l’herbe. Lorsqu’une minuscule roue roula au loin, l’animal la suivit et s’arrêta à côté d’elle. ${n} récupéra la roue et la remit en place : les ailes recommencèrent à bouger.`
        : `${n} écouta attentivement pendant que ${human} cherchait autour d’eux. Ils trouvèrent une minuscule roue, la remirent en place et les ailes recommencèrent à bouger.`,
      `La lumière dorée monta au-dessus de ${s} et se transforma en centaines de petites étoiles. ${n} comprit que l’aventure ne consistait pas à trouver un trésor, mais à explorer, observer et découvrir que chaque personne et chaque animal peut avoir une place spéciale dans une aventure partagée.`,
    ],
    es: [
      `Una mañana luminosa, ${n} descubrió una pequeña luz dorada en la entrada de ${s}. Avanzaba lentamente entre árboles, puertas o rocas, como si quisiera mostrar el camino. ${n} decidió seguirla e invitó a ${human} a acompañarle.`,
      hasAnimals
        ? `${n} llegó a un rincón tranquilo de ${s} donde esperaba ${animal}. El animal olfateó el suelo, escuchó con atención y después trotó hacia la luz. ${n} lo siguió mientras exploraba el lugar a su manera.`
        : `${n} llegó a un rincón tranquilo de ${s} donde el rastro desaparecía. Junto a ${human}, buscó con cuidado hasta descubrir pequeñas huellas doradas.`,
      `Las huellas llevaron a un camino escondido. Por el camino, ${n} y ${human} encontraron una pluma azul, una campanita de plata y una pequeña llave de madera. Cada pista revelaba algo sobre ${s}: un pasadizo secreto, un pequeño puente y una puerta escondida entre las hojas.`,
      hasAnimals
        ? `En el puente, ${animal} se adelantó. El animal se detuvo junto a una piedra suelta y miró a ${n}. Debajo estaba la llave que faltaba. ${n} acarició suavemente al animal y colocó la llave en la cerradura.`
        : `En el puente, ${n} vio una piedra suelta. Debajo estaba la llave que faltaba. ${human} sostuvo la linterna mientras ${n} colocaba la llave en la cerradura.`,
      `La puerta escondida se abrió hacia el lugar más bonito de ${s}: un jardín lleno de luces cálidas, música suave y flores de colores. En el centro había un pequeño pájaro mecánico que ya no podía mover las alas.`,
      hasAnimals
        ? `${n} escuchó al pájaro mientras ${animal} observaba desde la hierba. Cuando una diminuta pieza rodó lejos, el animal la siguió y se detuvo junto a ella. ${n} recogió la pieza, la colocó en el pájaro y las alas volvieron a moverse.`
        : `${n} escuchó con atención mientras ${human} buscaba cerca. Encontraron una pequeña pieza, la colocaron en el pájaro y las alas volvieron a moverse.`,
      `La luz dorada subió sobre ${s} y se convirtió en cientos de pequeñas estrellas. ${n} comprendió que la aventura no consistía en encontrar un tesoro, sino en explorar, observar y descubrir que cada persona y cada animal puede tener un papel especial en una aventura compartida.`,
    ],
    de: [
      `An einem hellen Morgen entdeckte ${n} am Eingang von ${s} ein kleines goldenes Licht. Es bewegte sich langsam zwischen Bäumen, Türen oder Felsen, als wollte es den Weg zeigen. ${n} beschloss, ihm zu folgen, und lud ${human} ein mitzukommen.`,
      hasAnimals
        ? `${n} erreichte eine ruhige Ecke von ${s}, wo ${animal} wartete. Das Tier schnupperte am Boden, lauschte aufmerksam und trottete dann dem Licht hinterher. ${n} folgte und beobachtete, wie das Tier den Ort auf seine eigene Art erkundete.`
        : `${n} erreichte eine ruhige Ecke von ${s}, wo die Spur plötzlich endete. Zusammen mit ${human} entdeckte ${n} kleine goldene Fußspuren.`,
      `Die Spuren führten zu einem versteckten Weg. Unterwegs fanden ${n} und ${human} eine blaue Feder, eine silberne Glocke und einen kleinen Holzschlüssel. Jeder Hinweis zeigte etwas Neues über ${s}: einen geheimen Durchgang, eine kleine Brücke und eine Tür hinter den Blättern.`,
      hasAnimals
        ? `Auf der Brücke lief ${animal} voraus. Das Tier blieb neben einem lockeren Stein stehen und sah zu ${n} zurück. Darunter lag der fehlende Schlüssel. ${n} streichelte das Tier sanft und steckte den Schlüssel ins Schloss.`
        : `Auf der Brücke bemerkte ${n} einen lockeren Stein. Darunter lag der fehlende Schlüssel. ${human} hielt die Laterne, während ${n} den Schlüssel ins Schloss steckte.`,
      `Die versteckte Tür öffnete sich zum schönsten Teil von ${s}: ein Garten voller warmer Lichter, leiser Musik und bunter Blumen. In der Mitte stand ein kleiner mechanischer Vogel, der seine Flügel nicht mehr bewegen konnte.`,
      hasAnimals
        ? `${n} lauschte dem Vogel, während ${animal} im Gras beobachtete. Als ein winziges Zahnrad davonrollte, folgte das Tier ihm und blieb daneben stehen. ${n} hob das Zahnrad auf und setzte es wieder ein. Die Flügel bewegten sich erneut.`
        : `${n} hörte aufmerksam zu, während ${human} in der Nähe suchte. Sie fanden ein winziges Zahnrad, setzten es wieder ein und die Flügel bewegten sich erneut.`,
      `Das goldene Licht stieg über ${s} auf und wurde zu Hunderten kleiner Sterne. ${n} verstand, dass es bei dem Abenteuer nicht um einen Schatz ging, sondern darum, zu erkunden, aufmerksam zu sein und zu entdecken, dass jeder Mensch und jedes Tier einen besonderen Platz in einem gemeinsamen Abenteuer haben kann.`,
    ],
  };

  const scenes = stories[l] ?? stories.en;
  const text = scenes.join("\n\n");
  const wordCount = text.trim().split(/\s+/).length;
  return {
    title: ({ it: `L’avventura di ${n}`, en: `The adventure of ${n}`, fr: `L’aventure de ${n}`, es: `La aventura de ${n}`, de: `Das Abenteuer von ${n}` } as Record<string, string>)[l],
    scenes: scenes.map((text, index) => ({ index, text })),
    text,
    durationSeconds: Math.round((wordCount / 145) * 60),
    wordCount,
  };
}
async function mediaTokenFor(story: unknown, serviceKey: string) {
  const fingerprintBytes = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(JSON.stringify(story)));
  const fingerprint = Array.from(new Uint8Array(fingerprintBytes)).map((b) => b.toString(16).padStart(2, "0")).join("");
  const exp = Math.floor(Date.now() / 1000) + 15 * 60;
  const payload = `${fingerprint}.${exp}`;
  const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(serviceKey), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const signature = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(payload));
  const sig = btoa(String.fromCharCode(...new Uint8Array(signature))).replace(/\\+/g, "-").replace(/\\//g, "_").replace(/=+$/, "");
  return `${payload}.${sig}`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  try {
    const body = (await req.json()) as StoryRequest;
    const protagonistName = String(body.protagonistName ?? "").trim();
    const setting = String(body.setting ?? "").trim();
    const setting = String(body.setting ?? body.city ?? "").trim();
    const locale = String(body.locale ?? "it").slice(0, 2).toLowerCase();
    const friends = cleanList(body.friends, 4);
    const animalFriends = cleanList(body.animalFriends, 10);
    if (!protagonistName || !setting) return new Response(JSON.stringify({ error: "Missing required fields" }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    if (Array.isArray(body.friends) && body.friends.length > 4) return new Response(JSON.stringify({ error: "A maximum of 4 protagonist friends is allowed" }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    if (!allowedLocales.has(locale)) return new Response(JSON.stringify({ error: "Unsupported locale" }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });

    const story = buildStory({ protagonistName, setting, locale, friends, animalFriends });
    let saved = false;
    let storyId: string | null = null;
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (supabaseUrl && serviceRoleKey) {
      const admin = createClient(supabaseUrl, serviceRoleKey, { auth: { persistSession: false } });
      const authHeader = req.headers.get("Authorization");
      if (authHeader?.startsWith("Bearer ")) {
        const { data } = await admin.auth.getUser(authHeader.slice(7));
        if (data.user) {
          const { data: entitlement } = await admin.from("premium_entitlements").select("status,expires_at").eq("user_id", data.user.id).maybeSingle();
          const active = entitlement?.status === "active" && (!entitlement.expires_at || new Date(entitlement.expires_at) > new Date());
          if (active) {
            const { data: inserted, error } = await admin.from("stories").insert({
              user_id: data.user.id, locale, title: story.title, protagonist_name: protagonistName,
              setting, story_city: setting, friends, animal_friends: animalFriends, story_text: story.text,
              duration_seconds: story.durationSeconds, status: "ready", is_premium_story: true,
            }).select("id").single();
            if (error) throw error;
            storyId = inserted.id;
            const { error: sceneError } = await admin.from("story_scenes").insert(story.scenes.map((scene) => ({ story_id: storyId, scene_index: scene.index, text: scene.text })));
            if (sceneError) throw sceneError;
            saved = true;
          }
        }
      }
    }
    const mediaToken = serviceRoleKey ? await mediaTokenFor({
      title: story.title,
      protagonistName,
      setting,
      city: setting,
      animalFriends,
      scenes: story.scenes,
    }, serviceRoleKey) : null;
    return new Response(JSON.stringify({ ...story, saved, storyId, mediaToken }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: "Story generation failed" }), { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }
});

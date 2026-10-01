import "jsr:@supabase/functions-js/edge-runtime.d.ts";
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
  animal?: string;
}) {
  const { protagonistName: n, setting: s, locale: l, friends, animalFriends } = input;
  const human = friends.length ? friends.join(", ") : ({
    it: "un nuovo amico", en: "a new friend", fr: "un nouvel ami",
    es: "un nuevo amigo", de: "ein neuer Freund",
  } as Record<string, string>)[l] ?? "a new friend";
  const animalRaw = input.animal?.trim() || animalFriends[0] || "";
  const animal = animalRaw.includes(":")
    ? (() => {
        const [species, ...rest] = animalRaw.split(":");
        const animalName = rest.join(":").trim();
        return animalName ? `${species.trim()} ${animalName}` : species.trim();
      })()
    : (animalRaw || ({
        it: "un piccolo animale curioso", en: "a curious little animal", fr: "un petit animal curieux",
        es: "un pequeño animal curioso", de: "ein neugieriges kleines Tier",
      } as Record<string, string>)[l] || "a curious little animal");

  const templates: Record<string, string[]> = {
    it: [
      `Una mattina luminosa, ${n} entrò in ${s} e si accorse subito che quel luogo nascondeva un segreto. Una luce dorata avanzava tra alberi, muri, barche o rocce senza trasformare nulla. ${n} invitò ${human} a seguirla. L’avventura cominciò proprio dentro quel luogo, con i suoi sentieri, i suoi suoni, i suoi angoli e le sue sorprese.`,
      `${n} e ${human} seguirono la luce più in profondità dentro ${s}. Il sentiero mostrò un piccolo ruscello, un vecchio cancello di legno e un gruppo di fiori che si muoveva anche senza vento. Poco lontano osservava ${animal}. L’animale annusò il terreno, ascoltò e poi trotterellò verso la luce. Era un vero animale che esplorava il luogo, non una persona travestita.`,
      `Il sentiero portò tutti in una parte tranquilla di ${s}, dove trovarono tre indizi: una piuma blu, una campanella d’argento e una piccola chiave di legno. Ogni indizio sembrava appartenere proprio a quel luogo. Seguendo il suono della campanella passarono accanto a un ponte e scoprirono una porta nascosta tra le foglie. ${n} capì che l’avventura stava nascendo dal luogo stesso.`,
      `Prima di aprire la porta, l’animale corse avanti. Annusò una pietra, raschiò il terreno con una zampa e guardò ${n}. Sotto la pietra c’era una piccola mappa. ${n} la raccolse mentre ${human} teneva la lanterna. La mappa mostrava un percorso verso il cuore di ${s} e disegnava proprio gli alberi, le rocce e i sentieri che avevano appena attraversato.`,
      `La mappa condusse il gruppo in una zona bellissima di ${s}. C’erano luci calde, piante colorate e un piccolo uccellino meccanico appoggiato su una panca. Le sue ali erano bloccate. ${n} lo osservò con attenzione. L’animale rimase a terra, guardando e annusando intorno alla panca. Quando un minuscolo ingranaggio rotolò nell’erba, lo seguì e si fermò accanto a lui.`,
      `${n} raccolse l’ingranaggio e riparò l’uccellino. Le ali tornarono a muoversi e una musica dolce riempì l’aria. Lungo il sentiero comparvero piccole luci, i fiori si aprirono e dietro la panca apparve una porta segreta. L’animale esplorò per primo il nuovo passaggio, trotterellando avanti e voltandosi ogni tanto per controllare che i bambini fossero ancora lì.`,
      `L’ultimo sentiero portò tutti in un punto speciale di ${s}. Da lì ${n} riconobbe il ponte, il ruscello, il cancello, i fiori e la porta nascosta che avevano incontrato. La luce dorata salì dal terreno e diventò un sentiero di stelle sopra il luogo. ${s} rimase esattamente ciò che era: un luogo reale o di fantasia nel quale l’avventura aveva preso vita.`,
      `Alla fine ${n} capì che una storia può nascere da qualsiasi luogo: una spiaggia, una foresta, un museo, un giardino, un castello o un mondo completamente fantastico. Basta osservare bene e lasciare che il luogo guidi l’avventura. L’animale compagno si sistemò vicino ai bambini, sempre un vero animale, mentre le ultime stelle svanivano sopra ${s}. Quella storia apparteneva a quel luogo.`,
    ],
    en: [
      `One bright morning, ${n} entered ${s} and immediately noticed that the place seemed to hide a secret. A golden light moved between its trees, walls, boats or rocks without changing them. ${n} invited ${human} to follow it. The adventure began inside this particular place, with its own paths, sounds, corners and surprises.`,
      `${n} and ${human} followed the light deeper into ${s}. The path revealed a small stream, an old wooden gate and flowers moving even though there was no wind. Nearby, ${animal} watched. The animal sniffed the ground, listened carefully and trotted toward the light. It remained an animal exploring the place, never a person in disguise.`,
      `The trail reached a quiet part of ${s}, where they found a blue feather, a silver bell and a wooden key. Every clue seemed to belong to the place. The bell led them past a bridge to a hidden door covered with leaves. ${n} realized that the adventure was being created by the location itself.`,
      `Before opening the door, the animal ran ahead. It sniffed a stone, pawed the ground and looked back at ${n}. Under the stone was a little map. ${n} picked it up while ${human} held the lantern. The map showed a route toward the heart of ${s}, with the same trees, rocks and paths they had just crossed.`,
      `The map led them to a beautiful central area of ${s}. Warm lights surrounded colorful plants and a small mechanical bird resting on a bench. Its wings were stuck. ${n} examined it carefully while the animal stayed on the ground. When a tiny gear rolled into the grass, the animal followed it and stopped beside it.`,
      `${n} repaired the bird with the gear. Its wings moved again and soft music filled the air. Lights appeared along the path, flowers opened and a secret door became visible behind the bench. The animal explored first, trotting ahead and occasionally turning back to check that the children were following.`,
      `The final path brought everyone to a special viewpoint inside ${s}. From there, ${n} could recognize the bridge, stream, gate, flowers and hidden door. The golden light rose from the ground and became a trail of stars above the place. ${s} remained exactly what it was: the real or imaginary place where the adventure happened.`,
      `At the end, ${n} understood that a story can grow from any place: a beach, forest, museum, garden, castle or imaginary world. The important thing is to observe and let the place guide the adventure. The animal companion settled beside the children, still a real animal, while the last stars faded above ${s}. The story belonged to that place.`,
    ],
    fr: [
      `Un matin lumineux, ${n} entra dans ${s} et remarqua aussitôt que ce lieu cachait un secret. Une lumière dorée avançait entre les arbres, les murs, les bateaux ou les rochers sans changer le lieu. ${n} invita ${human} à la suivre. L’aventure commença dans ce lieu précis, avec ses chemins, ses sons, ses recoins et ses surprises.`,
      `${n} et ${human} suivirent la lumière dans ${s}. Le chemin révéla un petit ruisseau, une vieille porte en bois et des fleurs qui bougeaient sans vent. Près de l’herbe, ${animal} observait. L’animal renifla le sol, écouta puis trottina vers la lumière. Il restait un véritable animal explorant le lieu, jamais une personne déguisée.`,
      `Le chemin mena à une partie calme de ${s}, où ils trouvèrent une plume bleue, une clochette argentée et une clé en bois. Chaque indice semblait appartenir au lieu. La clochette les conduisit près d’un pont puis vers une porte cachée sous les feuilles. ${n} comprit que l’aventure naissait du lieu lui-même.`,
      `Avant d’ouvrir la porte, l’animal partit devant. Il renifla une pierre, gratta le sol et regarda ${n}. Sous la pierre se trouvait une petite carte. ${n} la prit pendant que ${human} tenait la lanterne. La carte montrait un chemin vers le cœur de ${s}, avec les mêmes arbres, rochers et sentiers.`,
      `La carte conduisit le groupe vers un bel endroit au centre de ${s}. Des lumières chaudes éclairaient des plantes colorées et un petit oiseau mécanique posé sur un banc. Ses ailes étaient bloquées. ${n} l’examina pendant que l’animal restait au sol. Une minuscule roue roula dans l’herbe ; l’animal la suivit et s’arrêta à côté d’elle.`,
      `${n} remit la roue en place et répara l’oiseau. Ses ailes bougèrent et une musique douce résonna. Des lumières apparurent sur le chemin, les fleurs s’ouvrirent et une porte secrète devint visible. L’animal explora le passage en premier, trottinant puis se retournant pour vérifier que les enfants suivaient.`,
      `Le dernier chemin mena à un point spécial de ${s}. De là, ${n} reconnut le pont, le ruisseau, la porte, les fleurs et le passage caché. La lumière dorée monta du sol et devint un chemin d’étoiles au-dessus du lieu. ${s} resta exactement ce qu’il était : le lieu réel ou imaginaire où l’aventure avait eu lieu.`,
      `À la fin, ${n} comprit qu’une histoire peut naître de n’importe quel lieu : une plage, une forêt, un musée, un jardin, un château ou un monde imaginaire. Il suffit d’observer et de laisser le lieu guider l’aventure. L’animal compagnon resta près des enfants, toujours un véritable animal, tandis que les dernières étoiles disparaissaient au-dessus de ${s}.`,
    ],
    es: [
      `Una mañana luminosa, ${n} entró en ${s} y notó que aquel lugar escondía un secreto. Una luz dorada avanzaba entre árboles, paredes, barcos o rocas sin cambiar el lugar. ${n} invitó a ${human} a seguirla. La aventura comenzó dentro de ese lugar concreto, con sus caminos, sonidos, rincones y sorpresas.`,
      `${n} y ${human} siguieron la luz por ${s}. El camino mostró un pequeño arroyo, una vieja puerta de madera y flores que se movían sin viento. Cerca de la hierba, ${animal} observaba. El animal olfateó el suelo, escuchó y trotó hacia la luz. Seguía siendo un animal explorando el lugar, nunca una persona disfrazada.`,
      `El sendero llegó a una zona tranquila de ${s}, donde encontraron una pluma azul, una campanita de plata y una llave de madera. Cada pista parecía pertenecer al lugar. El sonido de la campana los llevó junto a un puente y una puerta escondida entre hojas. ${n} comprendió que la aventura nacía del propio lugar.`,
      `Antes de abrir la puerta, el animal se adelantó. Olfateó una piedra, arañó el suelo y miró a ${n}. Debajo había un pequeño mapa. ${n} lo recogió mientras ${human} sostenía la linterna. El mapa mostraba un camino hacia el corazón de ${s}, con los mismos árboles, rocas y senderos.`,
      `El mapa los llevó a una zona hermosa de ${s}. Había luces cálidas, plantas de colores y un pequeño pájaro mecánico sobre un banco. Sus alas estaban bloqueadas. ${n} lo examinó mientras el animal permanecía en el suelo. Una pieza rodó por la hierba; el animal la siguió y se detuvo junto a ella.`,
      `${n} colocó la pieza y reparó el pájaro. Sus alas volvieron a moverse y sonó una música suave. Aparecieron luces en el camino, las flores se abrieron y una puerta secreta se hizo visible. El animal exploró primero el nuevo camino, trotando y mirando hacia atrás para comprobar que los niños seguían allí.`,
      `El último sendero llevó a un punto especial de ${s}. Desde allí, ${n} reconoció el puente, el arroyo, la puerta, las flores y el pasadizo secreto. La luz dorada subió del suelo y se convirtió en un camino de estrellas. ${s} siguió siendo exactamente lo que era: el lugar real o imaginario donde ocurrió la aventura.`,
      `Al final, ${n} entendió que una historia puede nacer en cualquier lugar: una playa, un bosque, un museo, un jardín, un castillo o un mundo imaginario. Solo hay que observar y dejar que el lugar guíe la aventura. El animal compañero se quedó junto a los niños, siempre como un animal real, mientras las últimas estrellas desaparecían sobre ${s}.`,
    ],
    de: [
      `An einem hellen Morgen betrat ${n} ${s} und bemerkte sofort, dass dieser Ort ein Geheimnis verbarg. Ein goldenes Licht bewegte sich zwischen Bäumen, Mauern, Booten oder Felsen, ohne den Ort zu verändern. ${n} lud ${human} ein, ihm zu folgen. Das Abenteuer begann an diesem besonderen Ort mit seinen Wegen, Geräuschen, Ecken und Überraschungen.`,
      `${n} und ${human} folgten dem Licht durch ${s}. Der Weg führte zu einem kleinen Bach, einem alten Holztor und Blumen, die sich ohne Wind bewegten. Im Gras beobachtete ${animal} alles. Das Tier schnupperte, lauschte und trottete zum Licht. Es blieb ein echtes Tier, das den Ort erkundete, niemals eine verkleidete Person.`,
      `Der Weg führte zu einem ruhigen Teil von ${s}. Dort fanden sie eine blaue Feder, eine silberne Glocke und einen Holzschlüssel. Jeder Hinweis schien zum Ort zu gehören. Der Klang der Glocke führte über eine Brücke zu einer versteckten Tür. ${n} verstand, dass die Geschichte aus den Besonderheiten von ${s} entstand.`,
      `Bevor sie die Tür öffneten, lief das Tier voraus. Es schnupperte an einem Stein, scharrte im Boden und sah zu ${n}. Unter dem Stein lag eine kleine Karte. ${n} hob sie auf, während ${human} die Laterne hielt. Die Karte zeigte einen Weg zum Herzen von ${s} und zeichnete die gleichen Bäume, Felsen und Wege.`,
      `Die Karte führte zu einem schönen Bereich im Zentrum von ${s}. Warme Lichter beleuchteten bunte Pflanzen und einen kleinen mechanischen Vogel auf einer Bank. Seine Flügel waren blockiert. ${n} untersuchte ihn, während das Tier am Boden blieb. Ein winziges Zahnrad rollte ins Gras; das Tier folgte ihm und blieb daneben stehen.`,
      `${n} setzte das Zahnrad ein und reparierte den Vogel. Seine Flügel bewegten sich wieder und leise Musik erklang. Lichter erschienen am Weg, Blumen öffneten sich und eine geheime Tür wurde sichtbar. Das Tier erkundete den Weg zuerst und sah manchmal zurück, ob die Kinder folgten.`,
      `Der letzte Weg führte zu einem besonderen Punkt von ${s}. Von dort erkannte ${n} die Brücke, den Bach, die Tür, die Blumen und den geheimen Durchgang. Das goldene Licht stieg vom Boden auf und wurde zu einem Sternenweg über dem Ort. ${s} blieb genau das, was es war: der reale oder erfundene Ort des Abenteuers.`,
      `Am Ende verstand ${n}, dass eine Geschichte überall entstehen kann: an einem Strand, in einem Wald, einem Museum, einem Garten, einem Schloss oder in einer Fantasiewelt. Man muss nur genau beobachten und den Ort die Geschichte führen lassen. Das tierische Wesen blieb bei den Kindern, immer ein echtes Tier, während die letzten Sterne über ${s} verblassten.`,
    ],
  };

  let scenes = templates[l] ?? templates.it;
  if (l === "it") {
    const details = [
      "Mentre avanzavano, il luogo sembrava raccontare qualcosa attraverso i suoi rumori: l’acqua che scorreva, le foglie che frusciavano e i piccoli suoni dell’ambiente. Ogni dettaglio dava a quella pagina un’atmosfera diversa e aiutava i bambini a immaginare dove si trovavano.",
      "L’animale continuava a comportarsi come un vero compagno di esplorazione: annusava, ascoltava, si fermava quando qualcosa attirava la sua attenzione e poi ripartiva. I bambini lo seguivano senza comandarlo, imparando a osservare il luogo anche dal suo modo naturale di esplorarlo.",
      "Ogni indizio aveva un legame con ciò che li circondava. La piuma ricordava gli uccelli del luogo, la campanella richiamava un vecchio passaggio e la chiave sembrava appartenere proprio alla porta nascosta. Così la storia cresceva pagina dopo pagina partendo dall’ambientazione scelta.",
      "La scoperta fece fermare tutti per qualche istante. Guardarono la mappa, confrontarono i disegni con il paesaggio e riconobbero dettagli già incontrati. L’animale annusò ancora il terreno e seguì una traccia, confermando con il suo comportamento che il percorso continuava davvero.",
      "Intorno a loro il luogo sembrava più vivo che mai. La luce filtrava tra le foglie, le ombre si spostavano lentamente e i colori cambiavano con il passaggio delle nuvole. Persino il piccolo animale sembrava curioso di ogni nuovo rumore e movimento.",
      "Quando la musica iniziò, tutti rimasero in silenzio ad ascoltare. L’animale si avvicinò con cautela, annusò il terreno e poi si mise a osservare. Nessuno lo trasformò in un personaggio umano: il suo modo di partecipare era quello naturale di un animale curioso.",
      "Da quel punto potevano finalmente vedere il percorso compiuto. Ogni elemento dell’ambientazione aveva avuto un ruolo: il ponte aveva guidato la ricerca, il ruscello aveva indicato la direzione e il giardino aveva custodito il segreto. Il luogo non era uno sfondo, ma parte della storia.",
      "Prima di tornare indietro, i bambini si fermarono a ricordare ogni tappa dell’avventura. Il luogo poteva essere reale oppure fantastico, ma era stato descritto e vissuto come un vero posto da esplorare. L’animale rimase accanto a loro, pronto a seguire il sentiero di casa."
    ];
    scenes = scenes.map((scene, index) => scene + " " + details[index % details.length]);
  }
  const text = scenes.join("\n\n");
  const wordCount = text.trim().split(/\s+/).length;
  return {
    title: ({ it: `L’avventura di ${n}`, en: `The adventure of ${n}`, fr: `L’aventure de ${n}`, es: `La aventura de ${n}`, de: `Das Abenteuer von ${n}` } as Record<string, string>)[l] ?? `L’avventura di ${n}`,
    scenes: scenes.map((text, index) => ({ index, text })),
    text,
    durationSeconds: Math.round((wordCount / 135) * 60),
    wordCount,
  };
}

async function generateAiStory(input: {
  protagonistName: string;
  setting: string;
  locale: string;
  friends: string[];
  animalFriends: string[];
  animal?: string;
}) {
  const key = Deno.env.get("OPENAI_API_KEY");
  if (!key) throw new Error("OPENAI_API_KEY not configured");

  const languageNames: Record<string, string> = {
    it: "Italian",
    en: "English",
    fr: "French",
    es: "Spanish",
    de: "German",
  };

  const schema = {
    type: "object",
    properties: {
      title: { type: "string" },
      visualBible: { type: "string" },
      scenes: {
        type: "array",
        items: {
          type: "object",
          properties: {
            index: { type: "integer" },
            text: { type: "string" },
            visual: { type: "string" },
          },
          required: ["index", "text", "visual"],
          additionalProperties: false,
        },
      },
    },
    required: ["title", "visualBible", "scenes"],
    additionalProperties: false,
  };

  const instructions = [
    "You are the lead children's fiction writer and developmental editor for a real picture-book publisher. Write as if this story will be published, read aloud by a parent, and illustrated page by page. The result must feel authored, intentional, emotionally warm and narratively satisfying, never like an AI-generated sequence of prompts.",
    `Write the story in ${languageNames[input.locale] ?? "Italian"}.`,
    "Return ONLY the requested structured JSON; never add commentary.",
    "Create exactly 8 consecutive picture-book pages. Build one complete story, not eight mini-scenes. The story must have a strong opening hook, a single central desire/question/problem, rising complications, a meaningful turning point, a clear resolution and a gentle closing image.",
    "Before writing, silently plan the whole plot: identify the protagonist's goal, the setting-specific opportunity or problem, the role of each friend and animal, the central object/clue, the escalation, and the ending. Then write the pages from that plan so every event has a reason.",
    "CAUSE AND EFFECT IS MANDATORY: each page must be the direct consequence of what happened before. The protagonist must make choices, those choices must create consequences, and those consequences must drive the next page. Never introduce a new unrelated mystery, object, location or challenge merely to fill a page.",
    "SETTING IS A STORY ENGINE, NOT A LABEL. Use the exact place chosen by the user and its real or fantastical characteristics. A beach should involve sand, tides, shells, waves, wind, dunes or boats; a forest should involve paths, trees, light, sounds, plants and woodland details; a castle should involve rooms, towers, courtyards, gates, stairs or legends; a museum should involve exhibits, galleries and rules; a space station should involve modules, windows, zero gravity and technology. If the user's setting is unusual, invent details that are coherent with its meaning. Do not replace the chosen setting with a generic forest/castle/magical place.",
    "The setting must remain geographically and physically coherent. Characters should move from one plausible part of the place to another, and previously established locations and objects must remain consistent. Do not teleport characters or suddenly change the environment.",
    "CHARACTERIZATION MATTERS: the protagonist must have a recognizable personality expressed through choices, observations, feelings and actions. Do not repeatedly call the protagonist brave, curious or special; demonstrate those qualities through the story. Human friends must have distinct useful roles and affect the outcome instead of being name-only cameos.",
    "ANIMALS MUST MATTER TO THE PLOT. Parse entries such as 'cane: Milo' as a dog named Milo. Keep every animal faithful to its species and temperament. Dogs may sniff, hear, run, fetch and follow trails; cats may observe, climb, stalk and squeeze into spaces; birds may fly, perch and notice things from above; rabbits may hop and sniff; horses may trot and carry a rider when appropriate; fish may swim; reptiles and insects must use species-appropriate behavior. Animals never speak human language, use human tools as people do, become human-like characters or solve problems through impossible abilities. Give each selected animal at least one consequential natural action that helps the plot.",
    "Use every supplied protagonist name, human friend and animal friend meaningfully. Do not force all characters into every paragraph; give them natural moments and let their actions affect the story.",
    "Use concrete sensory writing suitable for children: sounds, textures, smells, light, movement and small discoveries. Prefer specific verbs and vivid nouns over generic adjectives such as magical, amazing, wonderful, mysterious and beautiful. Use figurative language sparingly and naturally.",
    "Write like a polished read-aloud story for children: clear sentences, varied rhythm, dialogue only when it genuinely advances the scene, gentle humor where appropriate, emotional warmth and an ending that feels earned. Avoid moralizing, explaining the lesson, talking about 'the story', addressing the reader, or summarizing the adventure at the end.",
    "DO NOT use generic AI filler such as 'the adventure began', 'they knew something magical was about to happen', 'anything was possible', 'with a little courage', or repetitive statements about how special the place was. Show the adventure instead of explaining it.",
    "DO NOT use a chain of arbitrary fantasy props (random keys, feathers, bells, maps, doors, mechanical birds, golden lights, stars) unless each object is genuinely appropriate to the chosen setting and necessary to the central plot. One coherent set of clues is better than many unrelated magical objects.",
    "Keep the story internally consistent with the user's choices. Never silently substitute a different protagonist, place, animal species or companion. The selected animal is a first-class story parameter: it must appear naturally from the opening pages, remain the same species throughout, and have a consequential species-appropriate action. Never replace it with another animal.",
    "For the 8 pages, target 85-105 words per page in Italian/English/French/Spanish/German, for roughly 680-840 words total and a 5-6 minute read at a child-friendly read-aloud pace.",
    "Avoid filler and repeated descriptions. Each page should contain a concrete action, a consequence and either a new piece of information or an emotional beat that moves the same plot forward.",
    "The final page must resolve the central problem or goal, show what changed because of the characters' actions, and end on a calm, memorable image rooted in the chosen setting.",
    "visualBible must be a concise stable description of the protagonist, human friends, animal companions and the physical setting. It is used by an image generator to keep characters and place consistent across pages.",
    "Each scene.visual must describe the MAIN VISUAL ACTION of that exact page, including who is present, what they are doing, the important object/clue, and the relevant part of the setting. It must be suitable as an image prompt and must match scene.text exactly.",
    "Do not put text, captions, letters or page numbers into scene.visual.",
  ].join(" ");

  const userInput = JSON.stringify({
    protagonistName: input.protagonistName,
    setting: input.setting,
    friends: input.friends,
    animal: input.animal,
    animalFriends: input.animalFriends,
    locale: input.locale,
  });

  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: Deno.env.get("OPENAI_TEXT_MODEL") || "gpt-6-luna",
      instructions,
      input: userInput,
      store: false,
      text: {
        format: {
          type: "json_schema",
          name: "raccontamela_story",
          schema,
          strict: true,
        },
      },
    }),
  });

  if (!response.ok) {
    throw new Error(`Story AI provider error ${response.status}: ${await response.text()}`);
  }

  const payload = await response.json();
  const outputText = payload.output_text ??
    payload.output?.flatMap((item: any) => item.content ?? [])
      .find((item: any) => item.type === "output_text")?.text;
  if (!outputText) throw new Error("Story AI returned no text");

  const parsed = JSON.parse(outputText);
  if (!Array.isArray(parsed.scenes) || parsed.scenes.length !== 8) {
    throw new Error("Story AI returned an invalid page count");
  }

  const scenes = parsed.scenes.map((scene: any, index: number) => ({
    index,
    text: String(scene.text).trim(),
  }));
  const sceneVisuals: Record<string, string> = {};
  parsed.scenes.forEach((scene: any, index: number) => {
    sceneVisuals[String(index)] = String(scene.visual).trim();
  });

  const text = scenes.map((scene) => scene.text).join("\n\n");
  const wordCount = text.trim().split(/\s+/).filter(Boolean).length;
  if (wordCount < 620 || wordCount > 900) {
    throw new Error(`Story AI word count out of range: ${wordCount}`);
  }

  return {
    title: String(parsed.title).trim(),
    visualBible: String(parsed.visualBible).trim(),
    scenes,
    sceneVisuals,
    text,
    durationSeconds: Math.round((wordCount / 135) * 60),
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
  const sig = btoa(String.fromCharCode(...new Uint8Array(signature))).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  return `${payload}.${sig}`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  try {
    const body = (await req.json()) as StoryRequest;
    const protagonistName = String(body.protagonistName ?? "").trim();
    const setting = String(body.setting ?? body.city ?? "").trim();
    const locale = String(body.locale ?? "it").slice(0, 2).toLowerCase();
    const friends = cleanList(body.friends, 4);
    const animalFriends = cleanList(body.animalFriends, 10);
    const animal = String(body.animal ?? animalFriends[0] ?? "").trim();
    if (!protagonistName || !setting || !animal) return new Response(JSON.stringify({ error: "Missing required fields: protagonist, setting and animal are required" }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    if (Array.isArray(body.friends) && body.friends.length > 4) return new Response(JSON.stringify({ error: "A maximum of 4 protagonist friends is allowed" }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    if (!allowedLocales.has(locale)) return new Response(JSON.stringify({ error: "Unsupported locale" }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });

    let story: any;
    let visualBible = "";
    let sceneVisuals: Record<string, string> = {};
    try {
      const generated = await generateAiStory({ protagonistName, setting, locale, friends, animalFriends, animal });
      story = generated;
      visualBible = generated.visualBible;
      sceneVisuals = generated.sceneVisuals;
    } catch (error) {
      console.error("AI story generation failed, using deterministic fallback", error);
      story = buildStory({ protagonistName, setting, locale, friends, animalFriends, animal });
    }
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
              setting, story_city: setting, friends, animal_friends: [animal, ...animalFriends.filter((v) => v !== animal)], story_text: story.text,
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
      friends,
      animal,
      animalFriends,
      scenes: story.scenes,
      visualBible,
      sceneVisuals,
    }, serviceRoleKey) : null;
    return new Response(JSON.stringify({ ...story, visualBible, sceneVisuals, saved, storyId, mediaToken }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: "Story generation failed" }), { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }
});

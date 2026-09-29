import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type StoryRequest = {
  protagonistName: string;
  setting: string;
  city: string;
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

function buildStory(input: { protagonistName: string; setting: string; city: string; locale: string; friends: string[]; animalFriends: string[] }) {
  const { protagonistName: n, setting: s, city: c, locale: l, friends, animalFriends } = input;
  const friend = [...friends, ...animalFriends].join(", ") || ({
    it: "una piccola volpe curiosa", en: "a curious little fox", fr: "un petit renard curieux",
    es: "un pequeño zorro curioso", de: "ein neugieriger kleiner Fuchs",
  } as Record<string, string>)[l];

  const stories: Record<string, string[]> = {
    it: [
      `Era una mattina speciale quando ${n} si svegliò con la sensazione che qualcosa di straordinario stesse per accadere. Dalla finestra arrivava una luce dorata e, in mezzo alla strada, brillava una piccola stella. A ${c}, vicino a ${s}, tutto sembrava più silenzioso del solito. ${n} prese lo zainetto, chiamò ${friend} e uscì. La stella si mosse lentamente, lasciando una scia luminosa. Non sembrava pericolosa: sembrava piuttosto un invito. ${n} decise di seguirla, promettendo di tornare prima di sera.`,
      `La scia attraversò ${s} e arrivò davanti a un vecchio cancello coperto di foglie. Dietro il cancello c’era un giardino che ${n} non aveva mai visto. C’erano fiori enormi, lanterne colorate e un piccolo ruscello che cantava tra le pietre. Su una panchina comparve una busta con il nome di ${n}. Dentro c’era una mappa e un messaggio: “La città ha bisogno di qualcuno che sappia osservare, ascoltare e aiutare.” ${n} guardò ${friend}. Non servivano altre spiegazioni: l’avventura era appena cominciata.`,
      `La mappa li condusse fino al ruscello. Lungo il cammino trovarono tre indizi: una piuma blu, una campanella d’argento e un piccolo bottone rosso. Ogni volta che ${n} ascoltava con attenzione, la mappa mostrava una nuova freccia. Quando invece correva senza guardare, le frecce sparivano. Così ${n} imparò a rallentare. Insieme a ${friend}, arrivò a un ponte di legno. Sotto il ponte l’acqua rifletteva le stelle anche se era ancora giorno. Dall’altra parte si sentiva una musica molto delicata.`,
      `La musica portò ${n} su una collina dalla quale si vedevano tutti i tetti di ${c}. In cima c’era una piccola torre con una porta rotonda. La piuma aprì una prima serratura, la campanella ne aprì una seconda e il bottone fece comparire una scala. ${n} salì insieme a ${friend}. Nella stanza più alta trovarono un piccolo uccello meccanico con le ali ferme. Sul petto aveva scritto: “Non ho bisogno di un eroe. Ho bisogno di un amico che non si arrenda.” ${n} sorrise e si mise subito al lavoro.`,
      `L’uccellino aveva perso la sua musica. ${n} controllò con calma ogni parte, mentre ${friend} cercava sotto il tavolo. Alla fine trovarono una minuscola rotellina incastrata in una scatola. Non bastava prenderla: bisognava capire dove inserirla. ${n} osservò i segni sulla scatola, ascoltò il rumore degli ingranaggi e provò una posizione alla volta. Quando finalmente la rotellina entrò al suo posto, l’uccellino aprì un’ala. Poi l’altra. Una melodia riempì la stanza e scese dalla torre come una cascata di note.`,
      `La musica arrivò fino alle strade di ${c}. Le finestre si aprirono e le persone uscirono per ascoltare. Nessuno sapeva da dove provenisse quella melodia, ma tutti sorridevano. ${n} avrebbe potuto raccontare tutto, ma prima aiutò l’uccellino a sistemare la torre. Ogni piccolo dettaglio contava. ${friend} trovò persino un vecchio campanello che poteva essere riparato. Insieme lavorarono finché il sole cominciò a scendere. La torre non era più silenziosa: sembrava respirare insieme alla città.`,
      `Prima di tornare a casa, l’uccellino regalò a ${n} la piccola chiave del cancello. “Non apre una porta”, sembrava dire la targhetta. “Ricorda ciò che hai imparato.” ${n} capì che la chiave rappresentava attenzione, pazienza e amicizia. Il viaggio di ritorno fu tranquillo. La stella dorata li accompagnò fino a ${s}, poi salì nel cielo. ${n} salutò ${friend} e guardò ${c}: la città era la stessa, ma sembrava diversa perché ora ${n} sapeva che anche un gesto piccolo può rendere speciale una giornata.`,
      `Quella sera ${n} raccontò l’avventura a casa. La storia dell’uccellino, della torre e della musica sembrava quasi un sogno, ma la piccola chiave era lì, sul comodino. Prima di addormentarsi, ${n} sentì una melodia lontana arrivare dalla finestra. Forse l’uccellino stava suonando ancora. Forse la stella sarebbe tornata un’altra mattina. ${n} sorrise, pensando che le avventure più belle non iniziano sempre con un grande rumore. A volte iniziano con una luce piccolissima e con la scelta di seguirla insieme a qualcuno di cui ti fidi.`,
    ],
    en: [
      `It was a special morning when ${n} woke up with the feeling that something extraordinary was about to happen. A golden light shone through the window and, in the middle of the street, a tiny star was glowing. In ${c}, near ${s}, everything seemed quieter than usual. ${n} grabbed a small backpack, called ${friend}, and went outside. The star moved slowly, leaving a bright trail behind it. It did not look dangerous; it looked like an invitation. ${n} decided to follow it, promising to be home before evening.`,
      `The trail crossed ${s} and stopped at an old gate covered with leaves. Behind it was a garden ${n} had never seen before. There were enormous flowers, colorful lanterns, and a little stream singing between the stones. On a bench, an envelope appeared with ${n}'s name on it. Inside was a map and a message: “The city needs someone who can notice, listen, and help.” ${n} looked at ${friend}. No more explanation was needed. The adventure had begun.`,
      `The map led them to the stream. Along the way they found three clues: a blue feather, a silver bell, and a little red button. Whenever ${n} listened carefully, the map revealed a new arrow. Whenever ${n} rushed without looking, the arrows disappeared. So ${n} learned to slow down. Together with ${friend}, ${n} reached a wooden bridge. Beneath it, the water reflected stars even though it was still daytime. On the other side came a very gentle melody.`,
      `The melody led ${n} to a hill overlooking all the rooftops of ${c}. At the top stood a small tower with a round door. The feather opened the first lock, the bell opened the second, and the button revealed a staircase. ${n} climbed with ${friend}. In the highest room they found a tiny mechanical bird with still wings. On its chest were the words: “I do not need a hero. I need a friend who will not give up.” ${n} smiled and got to work.`,
      `The little bird had lost its music. ${n} carefully checked every part while ${friend} searched under the table. At last they found a tiny wheel stuck inside a box. Finding it was not enough; they had to discover where it belonged. ${n} studied the marks on the box, listened to the gears, and tried one position at a time. When the wheel finally clicked into place, the bird opened one wing. Then the other. Music filled the room and flowed down the tower like a waterfall of notes.`,
      `The music reached the streets of ${c}. Windows opened and people stepped outside to listen. Nobody knew where the melody came from, but everyone smiled. ${n} could have told them everything, but first helped the bird repair the tower. Every tiny detail mattered. ${friend} even found an old bell that could be repaired. They worked together until the sun began to set. The tower was no longer silent; it seemed to breathe together with the city.`,
      `Before going home, the bird gave ${n} the little gate key. A tag seemed to explain its meaning: “It does not open a door. It remembers what you learned.” ${n} understood that the key stood for attention, patience, and friendship. The walk home was peaceful. The golden star followed them to ${s}, then climbed into the sky. ${n} said goodbye to ${friend} and looked at ${c}. The city was the same, but it felt different because ${n} now knew that even a small action can make a whole day special.`,
      `That evening ${n} told the story at home. The tale of the bird, the tower, and the music sounded almost like a dream, but the little key was real on the bedside table. Before falling asleep, ${n} heard a distant melody through the window. Perhaps the bird was still playing. Perhaps the star would return another morning. ${n} smiled, realizing that the best adventures do not always begin with a loud sound. Sometimes they begin with a tiny light and the choice to follow it with someone you trust.`,
    ],
    fr: [
      `C’était un matin particulier lorsque ${n} se réveilla avec l’impression que quelque chose d’extraordinaire allait arriver. Une lumière dorée entrait par la fenêtre et une petite étoile brillait au milieu de la rue. À ${c}, près de ${s}, tout semblait plus calme que d’habitude. ${n} prit son petit sac, appela ${friend} et sortit. L’étoile avançait lentement en laissant une trace lumineuse. Elle ne semblait pas dangereuse : elle ressemblait à une invitation. ${n} décida de la suivre, en promettant de rentrer avant le soir.`,
      `La trace traversa ${s} et s’arrêta devant une vieille grille couverte de feuilles. Derrière, il y avait un jardin que ${n} n’avait jamais vu. Des fleurs immenses, des lanternes colorées et un petit ruisseau chantaient entre les pierres. Sur un banc apparut une enveloppe portant le nom de ${n}. À l’intérieur se trouvaient une carte et un message : « La ville a besoin de quelqu’un qui sache observer, écouter et aider. » ${n} regarda ${friend}. Il n’y avait rien d’autre à expliquer : l’aventure commençait.`,
      `La carte les conduisit vers le ruisseau. En chemin, ils trouvèrent trois indices : une plume bleue, une clochette d’argent et un petit bouton rouge. Quand ${n} écoutait attentivement, la carte révélait une nouvelle flèche. Quand ${n} allait trop vite sans regarder, les flèches disparaissaient. ${n} apprit donc à ralentir. Avec ${friend}, ${n} arriva à un pont en bois. Sous le pont, l’eau reflétait les étoiles alors qu’il faisait encore jour. De l’autre côté, une douce mélodie se faisait entendre.`,
      `La mélodie conduisit ${n} vers une colline qui dominait les toits de ${c}. Au sommet se trouvait une petite tour avec une porte ronde. La plume ouvrit la première serrure, la clochette la deuxième et le bouton fit apparaître un escalier. ${n} monta avec ${friend}. Dans la pièce la plus haute, ils trouvèrent un petit oiseau mécanique aux ailes immobiles. Sur son ventre était écrit : « Je n’ai pas besoin d’un héros. J’ai besoin d’un ami qui n’abandonne pas. » ${n} sourit et se mit au travail.`,
      `L’oiseau avait perdu sa musique. ${n} vérifia calmement chaque pièce pendant que ${friend} cherchait sous la table. Enfin, ils trouvèrent une minuscule roue coincée dans une boîte. Il fallait maintenant comprendre où la placer. ${n} observa les marques, écouta les engrenages et essaya une position après l’autre. Lorsque la roue entra enfin à sa place, l’oiseau ouvrit une aile, puis l’autre. La musique remplit la pièce et descendit de la tour comme une cascade de notes.`,
      `La musique arriva dans les rues de ${c}. Les fenêtres s’ouvrirent et les habitants sortirent pour écouter. Personne ne savait d’où venait la mélodie, mais tout le monde souriait. ${n} aurait pu tout raconter, mais commença par aider l’oiseau à réparer la tour. Chaque petit détail comptait. ${friend} trouva même une vieille cloche qui pouvait être réparée. Ils travaillèrent ensemble jusqu’au coucher du soleil. La tour n’était plus silencieuse : elle semblait respirer avec la ville.`,
      `Avant de rentrer, l’oiseau donna à ${n} la petite clé de la grille. Une étiquette semblait expliquer son secret : « Elle n’ouvre pas une porte. Elle rappelle ce que tu as appris. » ${n} comprit que la clé représentait l’attention, la patience et l’amitié. Le chemin du retour fut paisible. L’étoile dorée les accompagna jusqu’à ${s}, puis monta dans le ciel. ${n} salua ${friend} et regarda ${c}. La ville était la même, mais elle semblait différente, car ${n} savait maintenant qu’un petit geste peut rendre une journée entière spéciale.`,
      `Le soir, ${n} raconta l’aventure à la maison. L’histoire de l’oiseau, de la tour et de la musique ressemblait presque à un rêve, mais la petite clé était bien réelle sur la table de nuit. Avant de s’endormir, ${n} entendit une mélodie lointaine par la fenêtre. Peut-être que l’oiseau jouait encore. Peut-être que l’étoile reviendrait un autre matin. ${n} sourit en comprenant que les plus belles aventures ne commencent pas toujours par un grand bruit. Parfois, elles commencent par une toute petite lumière et le choix de la suivre avec quelqu’un en qui l’on a confiance.`,
    ],
    es: [
      `Era una mañana especial cuando ${n} se despertó con la sensación de que algo extraordinario estaba a punto de suceder. Una luz dorada entraba por la ventana y una pequeña estrella brillaba en medio de la calle. En ${c}, cerca de ${s}, todo parecía más tranquilo de lo normal. ${n} tomó una pequeña mochila, llamó a ${friend} y salió. La estrella avanzó lentamente dejando un rastro luminoso. No parecía peligrosa; parecía una invitación. ${n} decidió seguirla, prometiendo regresar antes de que anocheciera.`,
      `El rastro cruzó ${s} y llegó hasta una vieja puerta cubierta de hojas. Detrás había un jardín que ${n} nunca había visto. Había flores enormes, faroles de colores y un pequeño arroyo que cantaba entre las piedras. Sobre un banco apareció un sobre con el nombre de ${n}. Dentro había un mapa y un mensaje: «La ciudad necesita a alguien que sepa observar, escuchar y ayudar». ${n} miró a ${friend}. No hacía falta explicar nada más. La aventura acababa de comenzar.`,
      `El mapa los llevó hasta el arroyo. Por el camino encontraron tres pistas: una pluma azul, una campanita de plata y un pequeño botón rojo. Cuando ${n} escuchaba con atención, el mapa mostraba una nueva flecha. Cuando corría sin mirar, las flechas desaparecían. Así ${n} aprendió a ir más despacio. Junto a ${friend}, llegó a un puente de madera. Debajo, el agua reflejaba las estrellas aunque todavía era de día. Al otro lado se escuchaba una melodía muy suave.`,
      `La melodía llevó a ${n} hasta una colina desde la que se veían todos los tejados de ${c}. Arriba había una pequeña torre con una puerta redonda. La pluma abrió la primera cerradura, la campanita la segunda y el botón hizo aparecer una escalera. ${n} subió con ${friend}. En la habitación más alta encontraron un pequeño pájaro mecánico con las alas quietas. En su pecho decía: «No necesito un héroe. Necesito un amigo que no se rinda». ${n} sonrió y comenzó a trabajar.`,
      `El pajarito había perdido su música. ${n} revisó con calma cada pieza mientras ${friend} buscaba debajo de la mesa. Al final encontraron una diminuta rueda atrapada dentro de una caja. Encontrarla no era suficiente; tenían que descubrir dónde encajaba. ${n} estudió las marcas, escuchó los engranajes y probó una posición cada vez. Cuando la rueda entró en su sitio, el pájaro abrió un ala y luego la otra. La música llenó la habitación y bajó por la torre como una cascada de notas.`,
      `La música llegó hasta las calles de ${c}. Las ventanas se abrieron y la gente salió a escuchar. Nadie sabía de dónde venía la melodía, pero todos sonreían. ${n} podría haber contado todo, pero primero ayudó al pájaro a reparar la torre. Cada pequeño detalle importaba. ${friend} incluso encontró una vieja campana que podía arreglarse. Trabajaron juntos hasta que el sol empezó a bajar. La torre ya no estaba en silencio: parecía respirar junto con la ciudad.`,
      `Antes de volver a casa, el pájaro regaló a ${n} la pequeña llave de la puerta. Una etiqueta parecía explicar su significado: «No abre una puerta. Recuerda lo que aprendiste». ${n} comprendió que la llave representaba atención, paciencia y amistad. El camino de regreso fue tranquilo. La estrella dorada los acompañó hasta ${s} y después subió al cielo. ${n} se despidió de ${friend} y miró ${c}. La ciudad era la misma, pero se sentía diferente porque ${n} sabía que incluso una pequeña acción puede hacer especial todo un día.`,
      `Esa noche ${n} contó la aventura en casa. La historia del pájaro, la torre y la música parecía casi un sueño, pero la pequeña llave estaba de verdad sobre la mesita. Antes de dormirse, ${n} escuchó una melodía lejana por la ventana. Quizá el pájaro seguía tocando. Quizá la estrella regresaría otra mañana. ${n} sonrió al comprender que las mejores aventuras no siempre comienzan con un gran ruido. A veces comienzan con una luz diminuta y con la decisión de seguirla junto a alguien en quien confías.`,
    ],
    de: [
      `Es war ein besonderer Morgen, als ${n} aufwachte und das Gefühl hatte, dass etwas Außergewöhnliches passieren würde. Goldenes Licht fiel durch das Fenster, und mitten auf der Straße leuchtete ein kleiner Stern. In ${c}, nahe bei ${s}, war alles ungewöhnlich still. ${n} nahm einen kleinen Rucksack, rief ${friend} und ging hinaus. Der Stern bewegte sich langsam und hinterließ eine helle Spur. Er sah nicht gefährlich aus, sondern wie eine Einladung. ${n} beschloss, ihm zu folgen, und versprach, vor dem Abend zurück zu sein.`,
      `Die Spur führte durch ${s} zu einem alten Tor, das von Blättern bedeckt war. Dahinter lag ein Garten, den ${n} noch nie gesehen hatte. Riesige Blumen, bunte Laternen und ein kleiner Bach glitzerten zwischen den Steinen. Auf einer Bank erschien ein Umschlag mit ${n}s Namen. Darin lagen eine Karte und eine Nachricht: „Die Stadt braucht jemanden, der beobachten, zuhören und helfen kann.“ ${n} sah ${friend} an. Mehr musste niemand erklären. Das Abenteuer hatte begonnen.`,
      `Die Karte führte zum Bach. Unterwegs fanden sie drei Hinweise: eine blaue Feder, eine silberne Glocke und einen kleinen roten Knopf. Wenn ${n} aufmerksam zuhörte, zeigte die Karte einen neuen Pfeil. Wenn ${n} zu schnell lief, verschwanden die Pfeile. Also lernte ${n}, langsamer zu werden. Zusammen mit ${friend} erreichte ${n} eine Holzbrücke. Unter ihnen spiegelte das Wasser Sterne, obwohl es noch Tag war. Auf der anderen Seite war eine leise Melodie zu hören.`,
      `Die Melodie führte ${n} auf einen Hügel mit Blick über die Dächer von ${c}. Oben stand ein kleiner Turm mit einer runden Tür. Die Feder öffnete das erste Schloss, die Glocke das zweite und der Knopf ließ eine Treppe erscheinen. ${n} stieg mit ${friend} hinauf. Im höchsten Raum fanden sie einen kleinen mechanischen Vogel mit stillen Flügeln. Auf seiner Brust stand: „Ich brauche keinen Helden. Ich brauche einen Freund, der nicht aufgibt.“ ${n} lächelte und begann zu helfen.`,
      `Der kleine Vogel hatte seine Musik verloren. ${n} überprüfte ruhig jedes Teil, während ${friend} unter dem Tisch suchte. Schließlich fanden sie ein winziges Rädchen, das in einer Schachtel feststeckte. Es zu finden war nicht genug; sie mussten herausfinden, wohin es gehörte. ${n} betrachtete die Zeichen, lauschte den Zahnrädern und probierte eine Stelle nach der anderen. Als das Rädchen endlich einrastete, öffnete der Vogel einen Flügel. Dann den anderen. Musik erfüllte den Raum und floss wie ein Wasserfall aus Tönen den Turm hinunter.`,
      `Die Musik erreichte die Straßen von ${c}. Fenster gingen auf und Menschen kamen heraus, um zuzuhören. Niemand wusste, woher die Melodie kam, aber alle lächelten. ${n} hätte alles erzählen können, half aber zuerst dem Vogel, den Turm zu reparieren. Jedes kleine Detail war wichtig. ${friend} fand sogar eine alte Glocke, die repariert werden konnte. Gemeinsam arbeiteten sie, bis die Sonne unterging. Der Turm war nicht mehr still; er schien gemeinsam mit der Stadt zu atmen.`,
      `Bevor ${n} nach Hause ging, schenkte der Vogel ihm den kleinen Torschlüssel. Ein Schild erklärte: „Sie öffnet keine Tür. Sie erinnert dich daran, was du gelernt hast.“ ${n} verstand, dass der Schlüssel für Aufmerksamkeit, Geduld und Freundschaft stand. Der Heimweg war ruhig. Der goldene Stern begleitete sie bis ${s} und stieg dann in den Himmel. ${n} verabschiedete sich von ${friend} und blickte auf ${c}. Die Stadt war dieselbe, aber sie fühlte sich anders an, weil ${n} nun wusste, dass schon eine kleine Tat einen ganzen Tag besonders machen kann.`,
      `Am Abend erzählte ${n} zu Hause vom Abenteuer. Die Geschichte vom Vogel, vom Turm und von der Musik klang fast wie ein Traum, aber der kleine Schlüssel lag wirklich auf dem Nachttisch. Vor dem Einschlafen hörte ${n} durch das Fenster eine ferne Melodie. Vielleicht spielte der Vogel noch immer. Vielleicht würde der Stern an einem anderen Morgen zurückkehren. ${n} lächelte und dachte daran, dass die schönsten Abenteuer nicht immer mit einem lauten Knall beginnen. Manchmal beginnen sie mit einem winzigen Licht und mit der Entscheidung, ihm gemeinsam mit jemandem zu folgen, dem man vertraut.`,
    ],
  };

    const baseScenes = stories[l] ?? stories.en;
    const epilogue = ({
      it: `Nei giorni successivi, ogni volta che ${n} passava vicino a ${s}, cercava la piccola luce nel cielo. A volte non vedeva nulla, eppure ricordava la lezione dell’avventura: non tutte le cose importanti fanno rumore. ${friend} continuava a giocare con la chiave e ${n} la osservava brillare al sole. Un pomeriggio arrivò un nuovo messaggio, questa volta senza mappa: “Quando qualcuno ha bisogno di te, non aspettare che sia tutto perfetto. Inizia da un piccolo gesto.” ${n} sorrise. Forse quella era la vera magia che la stella aveva voluto insegnare.`,
      en: `In the days that followed, whenever ${n} passed near ${s}, they looked for the little light in the sky. Sometimes there was nothing to see, yet the lesson remained: not everything important makes a loud sound. ${friend} kept playing with the key while ${n} watched it shine in the sunlight. One afternoon another message arrived, this time without a map: “When someone needs you, do not wait for everything to be perfect. Begin with one small action.” ${n} smiled. Perhaps that was the real magic the star had wanted to teach them.`,
      fr: `Dans les jours qui suivirent, chaque fois que ${n} passait près de ${s}, ${n} cherchait la petite lumière dans le ciel. Parfois elle n’apparaissait pas, mais la leçon restait : tout ce qui est important ne fait pas forcément de bruit. ${friend} jouait encore avec la clé et ${n} la regardait briller au soleil. Un après-midi, un nouveau message arriva, sans carte cette fois : « Quand quelqu’un a besoin de toi, n’attends pas que tout soit parfait. Commence par un petit geste. » ${n} sourit. C’était peut-être la vraie magie de l’étoile.`,
      es: `Durante los días siguientes, cada vez que ${n} pasaba cerca de ${s}, buscaba la pequeña luz en el cielo. A veces no aparecía, pero la lección permanecía: no todo lo importante hace ruido. ${friend} seguía jugando con la llave y ${n} la veía brillar bajo el sol. Una tarde llegó otro mensaje, esta vez sin mapa: «Cuando alguien te necesite, no esperes a que todo sea perfecto. Empieza con un pequeño gesto». ${n} sonrió. Tal vez esa era la verdadera magia que la estrella quería enseñar.`,
      de: `In den folgenden Tagen suchte ${n} jedes Mal nach dem kleinen Licht am Himmel, wenn ${n} an ${s} vorbeikam. Manchmal war nichts zu sehen, doch die Lehre blieb: Nicht alles Wichtige macht ein lautes Geräusch. ${friend} spielte weiter mit dem Schlüssel, während ${n} ihn im Sonnenlicht glänzen sah. Eines Nachmittags kam eine neue Nachricht, diesmal ohne Karte: „Wenn jemand dich braucht, warte nicht, bis alles perfekt ist. Beginne mit einer kleinen Tat.“ ${n} lächelte. Vielleicht war das die wahre Magie, die der Stern zeigen wollte.`,
    })[l] ?? `When someone needs you, begin with one small action.`;
    const scenes = [...baseScenes, epilogue];
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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  try {
    const body = (await req.json()) as StoryRequest;
    const protagonistName = String(body.protagonistName ?? "").trim();
    const setting = String(body.setting ?? "").trim();
    const city = String(body.city ?? "").trim();
    const locale = String(body.locale ?? "it").slice(0, 2).toLowerCase();
    const friends = cleanList(body.friends, 4);
    const animalFriends = cleanList(body.animalFriends, 10);
    if (!protagonistName || !setting || !city) return new Response(JSON.stringify({ error: "Missing required fields" }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    if (Array.isArray(body.friends) && body.friends.length > 4) return new Response(JSON.stringify({ error: "A maximum of 4 protagonist friends is allowed" }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    if (!allowedLocales.has(locale)) return new Response(JSON.stringify({ error: "Unsupported locale" }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });

    const story = buildStory({ protagonistName, setting, city, locale, friends, animalFriends });
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
              setting, story_city: city, friends, animal_friends: animalFriends, story_text: story.text,
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
    return new Response(JSON.stringify({ ...story, saved, storyId }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: "Story generation failed" }), { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }
});

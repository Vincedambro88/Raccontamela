import '../domain/story.dart';

class StoryRequest {
  const StoryRequest({
    required this.protagonistName,
    required this.setting,
    required this.city,
    required this.friends,
    required this.animalFriends,
    required this.locale,
  });

  final String protagonistName;
  final String setting;
  final String city;
  final List<String> friends;
  final List<String> animalFriends;
  final String locale;
}

class StoryGenerator {
  Future<Story> generate(StoryRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    final name = request.protagonistName.trim();
    final setting = request.setting.trim();
    final scenesText = _expandForReading(
      request.locale,
      _paragraphs(request.locale, name, setting, request.friends, request.animalFriends),
    );
    final scenes = List.generate(
      scenesText.length,
      (index) => StoryScene(index: index, text: scenesText[index]),
    );
    final words = scenes
        .map((scene) => scene.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length)
        .fold<int>(0, (a, b) => a + b);

    return Story(
      title: _title(request.locale, name),
      protagonistName: name,
      setting: setting,
      city: setting,
      friends: request.friends,
      animalFriends: request.animalFriends,
      scenes: scenes,
      durationSeconds: ((words / 140) * 60).round(),
    );
  }

  String _title(String locale, String name) => switch (locale) {
        'en' => 'The adventure of $name',
        'fr' => "L'aventure de $name",
        'es' => 'La aventura de $name',
        'de' => 'Das Abenteuer von $name',
        _ => 'L’avventura di $name',
      };

  List<String> _expandForReading(String locale, List<String> scenes) {
    if (locale != 'it') return scenes;
    const details = [
      'Mentre avanzavano, il luogo sembrava raccontare qualcosa attraverso i suoi rumori: l’acqua che scorreva, le foglie che frusciavano e i piccoli suoni dell’ambiente. Ogni dettaglio dava a quella pagina un’atmosfera diversa e aiutava i bambini a immaginare dove si trovavano.',
      'L’animale continuava a comportarsi come un vero compagno di esplorazione: annusava, ascoltava, si fermava quando qualcosa attirava la sua attenzione e poi ripartiva. I bambini lo seguivano senza comandarlo, imparando a osservare il luogo anche dal suo modo naturale di esplorarlo.',
      'Ogni indizio aveva un legame con ciò che li circondava. La piuma ricordava gli uccelli del luogo, la campanella richiamava un vecchio passaggio e la chiave sembrava appartenere proprio alla porta nascosta. Così la storia cresceva pagina dopo pagina partendo dall’ambientazione scelta.',
      'La scoperta fece fermare tutti per qualche istante. Guardarono la mappa, confrontarono i disegni con il paesaggio e riconobbero dettagli già incontrati. L’animale annusò ancora il terreno e seguì una traccia, confermando con il suo comportamento che il percorso continuava davvero.',
      'Intorno a loro il luogo sembrava più vivo che mai. La luce filtrava tra le foglie, le ombre si spostavano lentamente e i colori cambiavano con il passaggio delle nuvole. Persino il piccolo animale sembrava curioso di ogni nuovo rumore e movimento.',
      'Quando la musica iniziò, tutti rimasero in silenzio ad ascoltare. L’animale si avvicinò con cautela, annusò il terreno e poi si mise a osservare. Nessuno lo trasformò in un personaggio umano: il suo modo di partecipare era quello naturale di un animale curioso.',
      'Da quel punto potevano finalmente vedere il percorso compiuto. Ogni elemento dell’ambientazione aveva avuto un ruolo: il ponte aveva guidato la ricerca, il ruscello aveva indicato la direzione e il giardino aveva custodito il segreto. Il luogo non era uno sfondo, ma parte della storia.',
      'Prima di tornare indietro, i bambini si fermarono a ricordare ogni tappa dell’avventura. Il luogo poteva essere reale oppure fantastico, ma era stato descritto e vissuto come un vero posto da esplorare. L’animale rimase accanto a loro, pronto a seguire il sentiero di casa.'
    ];
    return List.generate(scenes.length, (i) => scenes[i] + ' ' + details[i % details.length]);
  }

  String _animalPhrase(List<String> animals, String locale) {
    if (animals.isEmpty) {
      return ({
        'it': 'un piccolo animale curioso',
        'en': 'a curious little animal',
        'fr': 'un petit animal curieux',
        'es': 'un pequeño animal curioso',
        'de': 'ein neugieriges kleines Tier',
      }[locale] ?? 'a curious little animal');
    }
    final value = animals.first.trim();
    if (value.contains(':')) {
      final parts = value.split(':');
      final species = parts.first.trim();
      final name = parts.skip(1).join(':').trim();
      if (name.isNotEmpty) {
        return switch (locale) {
          'en' => 'the $species named $name',
          'fr' => 'le $species appelé $name',
          'es' => 'el $species llamado $name',
          'de' => 'das $species namens $name',
          _ => 'il $species $name',
        };
      }
    }
    return switch (locale) {
      'en' => 'the animal companion called $value',
      'fr' => "l’animal compagnon appelé $value",
      'es' => 'el animal compañero llamado $value',
      'de' => 'das Tier namens $value',
      _ => 'l’animale compagno chiamato $value',
    };
  }

  List<String> _paragraphs(
    String locale,
    String name,
    String setting,
    List<String> friends,
    List<String> animals,
  ) {
    final human = friends.isEmpty
        ? ({
            'it': 'un nuovo amico',
            'en': 'a new friend',
            'fr': 'un nouvel ami',
            'es': 'un nuevo amigo',
            'de': 'ein neuer Freund',
          }[locale] ?? 'a new friend')
        : friends.join(', ');
    final animal = _animalPhrase(animals, locale);

    switch (locale) {
      case 'en':
        return [
          'One bright morning, $name entered $setting and immediately noticed that the place seemed to be hiding a secret. A warm golden light moved between the real details of the place, turning around trees, walls, boats or rocks without changing them. $name invited $human to follow it. The adventure began not in a city, but inside this particular place, with its own paths, sounds, corners and surprises.',
          '$name and $human followed the light deeper into $setting. The path became narrower and revealed a little stream, an old wooden gate and a patch of flowers that moved even though there was no wind. Nearby, $animal watched from the grass. The animal sniffed the ground, listened, then trotted toward the light. It was clearly an animal exploring the place, not a person in disguise.',
          'The trail led the group to a quiet part of $setting where they found three clues: a blue feather, a silver bell and a wooden key. Each clue belonged to the place itself. They followed the sound of the bell past a bridge and discovered a hidden door covered with leaves. $name realized that the story was unfolding through the location, not simply happening in front of a generic background.',
          'Before opening the door, the animal companion ran ahead and stopped beside a loose stone. It sniffed the stone, pawed the ground and looked back at $name. Underneath was a tiny map. $name picked it up while $human held the lantern. The map showed a path leading to the heart of $setting, with drawings of the same trees, rocks and paths they had just crossed.',
          'The map led them to a beautiful central area inside $setting. There were warm lights, colorful plants and a small mechanical bird resting on a wooden bench. Its wings were stuck. $name examined it carefully. The animal stayed on the ground, watching and sniffing around the bench. When a tiny metal gear rolled away, the animal followed it across the grass and stopped beside it.',
          '$name picked up the gear and repaired the little bird. The bird moved its wings and released a soft musical sound. That sound changed the place around them: lights appeared along the path, flowers opened and the hidden door behind the bench became visible. The animal explored the new path first, trotting ahead and occasionally turning back to check where the children were.',
          'The final path brought everyone to a viewpoint inside $setting. From there, $name could recognize the details that had made the adventure possible: the bridge, the stream, the gate, the flowers and the hidden door. The golden light rose from the ground and became a trail of stars above the place. Nothing about the location had to become a city or a character; it remained the real or imagined place where the adventure happened.',
          'At the end, $name understood that an adventure can be created from any place: a real beach, a forest, a museum, a garden, a castle or an entirely imaginary world. The important thing was to look closely and let the place guide the story. The animal companion settled beside the children, still a real animal, while the last golden stars faded above $setting. Everyone went home with a story that belonged to that place.'
        ];
      case 'fr':
        return [
          'Un matin lumineux, $name entra dans $setting et remarqua aussitôt que le lieu semblait cacher un secret. Une lumière dorée avançait entre les éléments du lieu, autour des arbres, des murs, des bateaux ou des rochers, sans les transformer. $name invita $human à la suivre. L’aventure commença dans ce lieu précis, avec ses chemins, ses bruits, ses recoins et ses surprises.',
          '$name et $human suivirent la lumière plus profondément dans $setting. Le chemin révéla un petit ruisseau, une vieille porte en bois et des fleurs qui bougeaient sans vent. Près de l’herbe, $animal observait. L’animal renifla le sol, écouta puis trottina vers la lumière. Il restait un véritable animal qui explorait le lieu, jamais une personne déguisée.',
          'Le chemin mena à un endroit calme de $setting où ils trouvèrent trois indices : une plume bleue, une clochette argentée et une clé en bois. Chaque indice semblait appartenir au lieu. Le son de la clochette les conduisit jusqu’à un pont puis à une porte cachée sous les feuilles. $name comprit que l’histoire se construisait à partir de $setting lui-même.',
          'Avant d’ouvrir la porte, l’animal partit devant. Il renifla une pierre, gratta le sol et regarda $name. Sous la pierre se trouvait une petite carte. $name la prit pendant que $human tenait la lanterne. La carte montrait un chemin vers le cœur de $setting et dessinait les arbres, les rochers et les chemins qu’ils venaient de traverser.',
          'La carte conduisit le groupe vers un bel endroit au centre de $setting. Des lumières chaudes éclairaient des plantes colorées et un petit oiseau mécanique posé sur un banc. Ses ailes étaient bloquées. $name l’examina attentivement. L’animal resta au sol, observant et reniflant autour du banc. Quand une minuscule roue roula dans l’herbe, il la suivit et s’arrêta à côté d’elle.',
          '$name récupéra la roue et répara le petit oiseau. Ses ailes bougèrent et une douce musique résonna. Des lumières apparurent alors sur le chemin, les fleurs s’ouvrirent et une porte cachée devint visible derrière le banc. L’animal explora le nouveau passage en premier, trottinant puis se retournant parfois pour vérifier que les enfants suivaient.',
          'Le dernier chemin mena à un point élevé de $setting. De là, $name reconnaissait les éléments de l’aventure : le pont, le ruisseau, la porte, les fleurs et le passage secret. La lumière dorée monta du sol et devint un chemin d’étoiles au-dessus du lieu. $setting resta exactement ce qu’il était : le lieu réel ou imaginaire où l’aventure avait pris vie.',
          'À la fin, $name comprit qu’une aventure peut naître de n’importe quel lieu : une plage, une forêt, un musée, un jardin, un château ou un monde imaginaire. Il suffit de regarder attentivement et de laisser le lieu guider l’histoire. L’animal compagnon s’installa près des enfants, toujours un véritable animal, tandis que les dernières étoiles disparaissaient au-dessus de $setting.'
        ];
      case 'es':
        return [
          'Una mañana luminosa, $name entró en $setting y notó que aquel lugar escondía un secreto. Una luz dorada avanzaba entre árboles, paredes, barcos o rocas sin cambiar el lugar. $name invitó a $human a seguirla. La aventura comenzó dentro de ese lugar concreto, con sus caminos, sonidos, rincones y sorpresas.',
          '$name y $human siguieron la luz por $setting. El camino mostró un pequeño arroyo, una vieja puerta de madera y unas flores que se movían sin viento. Cerca de la hierba, $animal observaba. El animal olfateó el suelo, escuchó y trotó hacia la luz. Era un animal que exploraba el lugar, nunca una persona disfrazada.',
          'El camino llevó a una zona tranquila de $setting donde encontraron tres pistas: una pluma azul, una campanita de plata y una llave de madera. Cada pista parecía pertenecer al lugar. Siguieron el sonido de la campana hasta un puente y una puerta escondida entre las hojas. $name comprendió que la aventura nacía del propio lugar.',
          'Antes de abrir la puerta, el animal se adelantó. Olfateó una piedra, arañó el suelo y miró a $name. Debajo había un pequeño mapa. $name lo recogió mientras $human sostenía la linterna. El mapa mostraba un camino hacia el corazón de $setting y dibujaba los árboles, las rocas y los senderos que habían recorrido.',
          'El mapa los llevó a una zona hermosa en el centro de $setting. Había luces cálidas, plantas de colores y un pequeño pájaro mecánico sobre un banco. Sus alas estaban bloqueadas. $name lo examinó. El animal permaneció en el suelo, observando y olfateando. Cuando una pequeña pieza rodó por la hierba, la siguió y se detuvo junto a ella.',
          '$name recogió la pieza y reparó el pájaro. Las alas volvieron a moverse y sonó una música suave. Aparecieron luces en el camino, las flores se abrieron y una puerta escondida se hizo visible detrás del banco. El animal exploró primero el nuevo camino, trotando y mirando de vez en cuando hacia atrás para comprobar que los niños lo seguían.',
          'El último sendero llevó a un lugar elevado de $setting. Desde allí, $name reconoció el puente, el arroyo, la puerta, las flores y el pasadizo secreto. La luz dorada subió del suelo y se convirtió en un camino de estrellas. $setting siguió siendo exactamente lo que era: el lugar real o imaginario donde había ocurrido la aventura.',
          'Al final, $name entendió que una aventura puede nacer en cualquier lugar: una playa, un bosque, un museo, un jardín, un castillo o un mundo imaginario. Solo hay que observar y dejar que el lugar guíe la historia. El animal compañero se quedó junto a los niños, siempre como un animal real, mientras las últimas estrellas desaparecían sobre $setting.'
        ];
      case 'de':
        return [
          'An einem hellen Morgen betrat $name $setting und bemerkte sofort, dass dieser Ort ein Geheimnis verbarg. Ein goldenes Licht bewegte sich zwischen Bäumen, Mauern, Booten oder Felsen, ohne den Ort zu verändern. $name lud $human ein, ihm zu folgen. Das Abenteuer begann an diesem besonderen Ort mit seinen Wegen, Geräuschen, Ecken und Überraschungen.',
          '$name und $human folgten dem Licht tiefer in $setting. Der Weg führte zu einem kleinen Bach, einem alten Holztor und Blumen, die sich ohne Wind bewegten. Im Gras beobachtete $animal alles. Das Tier schnupperte am Boden, lauschte und trottete zum Licht. Es blieb ein echtes Tier, das den Ort erkundete, niemals eine verkleidete Person.',
          'Der Weg führte zu einem ruhigen Teil von $setting. Dort fanden sie drei Hinweise: eine blaue Feder, eine silberne Glocke und einen Holzschlüssel. Jeder Hinweis schien zum Ort zu gehören. Der Klang der Glocke führte über eine Brücke zu einer versteckten Tür. $name verstand, dass die Geschichte aus den Besonderheiten von $setting entstand.',
          'Bevor sie die Tür öffneten, lief das Tier voraus. Es schnupperte an einem Stein, scharrte im Boden und sah zu $name zurück. Unter dem Stein lag eine kleine Karte. $name hob sie auf, während $human die Laterne hielt. Die Karte zeigte einen Weg zum Herzen von $setting und zeichnete die Bäume, Felsen und Wege ein, die sie gerade gesehen hatten.',
          'Die Karte führte zu einem schönen Bereich im Zentrum von $setting. Warme Lichter beleuchteten bunte Pflanzen und einen kleinen mechanischen Vogel auf einer Bank. Seine Flügel waren blockiert. $name untersuchte ihn. Das Tier blieb am Boden, beobachtete und schnupperte. Als ein winziges Zahnrad ins Gras rollte, folgte es ihm und blieb daneben stehen.',
          '$name hob das Zahnrad auf und reparierte den Vogel. Seine Flügel bewegten sich wieder und leise Musik erklang. Lichter erschienen am Weg, Blumen öffneten sich und hinter der Bank wurde eine geheime Tür sichtbar. Das Tier erkundete den neuen Weg zuerst, trottete voraus und sah manchmal zurück, ob die Kinder folgten.',
          'Der letzte Weg führte zu einem erhöhten Punkt von $setting. Von dort erkannte $name die Brücke, den Bach, die Tür, die Blumen und den geheimen Durchgang. Das goldene Licht stieg vom Boden auf und wurde zu einem Sternenweg über dem Ort. $setting blieb genau das, was es war: der reale oder erfundene Ort, an dem das Abenteuer geschah.',
          'Am Ende verstand $name, dass ein Abenteuer überall entstehen kann: an einem Strand, in einem Wald, einem Museum, einem Garten, einem Schloss oder in einer Fantasiewelt. Man muss nur genau hinsehen und den Ort die Geschichte führen lassen. Das tierische Wesen blieb bei den Kindern, immer ein echtes Tier, während die letzten Sterne über $setting verblassten.'
        ];
      default:
        return [
          'Una mattina luminosa, $name entrò in $setting e si accorse subito che quel luogo nascondeva un segreto. Una luce dorata avanzava tra alberi, muri, barche o rocce senza trasformare nulla. $name invitò $human a seguirla. L’avventura cominciò proprio dentro quel luogo, con i suoi sentieri, i suoi suoni, i suoi angoli e le sue sorprese.',
          '$name e $human seguirono la luce più in profondità dentro $setting. Il sentiero mostrò un piccolo ruscello, un vecchio cancello di legno e un gruppo di fiori che si muoveva anche senza vento. Poco lontano osservava $animal. L’animale annusò il terreno, ascoltò e poi trotterellò verso la luce. Era un vero animale che esplorava il luogo, non una persona travestita.',
          'Il sentiero portò tutti in una parte tranquilla di $setting, dove trovarono tre indizi: una piuma blu, una campanella d’argento e una piccola chiave di legno. Ogni indizio sembrava appartenere proprio a quel luogo. Seguendo il suono della campanella passarono accanto a un ponte e scoprirono una porta nascosta tra le foglie. $name capì che l’avventura stava nascendo dal luogo stesso.',
          'Prima di aprire la porta, l’animale corse avanti. Annusò una pietra, raschiò il terreno con una zampa e guardò $name. Sotto la pietra c’era una piccola mappa. $name la raccolse mentre $human teneva la lanterna. La mappa mostrava un percorso verso il cuore di $setting e disegnava proprio gli alberi, le rocce e i sentieri che avevano appena attraversato.',
          'La mappa condusse il gruppo in una zona bellissima di $setting. C’erano luci calde, piante colorate e un piccolo uccellino meccanico appoggiato su una panca. Le sue ali erano bloccate. $name lo osservò con attenzione. L’animale rimase a terra, guardando e annusando intorno alla panca. Quando un minuscolo ingranaggio rotolò nell’erba, lo seguì e si fermò accanto a lui.',
          '$name raccolse l’ingranaggio e riparò l’uccellino. Le ali tornarono a muoversi e una musica dolce riempì l’aria. Lungo il sentiero comparvero piccole luci, i fiori si aprirono e dietro la panca apparve una porta segreta. L’animale esplorò per primo il nuovo passaggio, trotterellando avanti e voltandosi ogni tanto per controllare che i bambini fossero ancora lì.',
          'L’ultimo sentiero portò tutti in un punto speciale di $setting. Da lì $name riconobbe il ponte, il ruscello, il cancello, i fiori e la porta nascosta che avevano incontrato. La luce dorata salì dal terreno e diventò un sentiero di stelle sopra il luogo. $setting rimase esattamente ciò che era: un luogo reale o di fantasia nel quale l’avventura aveva preso vita.',
          'Alla fine $name capì che una storia può nascere da qualsiasi luogo: una spiaggia, una foresta, un museo, un giardino, un castello o un mondo completamente fantastico. Basta osservare bene e lasciare che il luogo guidi l’avventura. L’animale compagno si sistemò vicino ai bambini, sempre un vero animale, mentre le ultime stelle svanivano sopra $setting. Quella storia apparteneva a quel luogo.'
        ];
    }
  }
}

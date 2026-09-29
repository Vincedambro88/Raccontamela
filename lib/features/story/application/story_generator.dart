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
  // Kept for compatibility with the existing API/database contract.
  // The value now represents the story location, not a city.
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
    final humanFriends = request.friends;
    final animals = request.animalFriends;

    final paragraphs = _paragraphs(
      request.locale,
      name,
      setting,
      humanFriends,
      animals,
    );
    final scenes = List.generate(
      paragraphs.length,
      (index) => StoryScene(index: index, text: paragraphs[index]),
    );
    final words = scenes
        .map((scene) => scene.text.split(RegExp(r'\s+')).length)
        .fold<int>(0, (a, b) => a + b);

    return Story(
      title: _title(request.locale, name),
      protagonistName: name,
      setting: setting,
      city: setting,
      friends: humanFriends,
      animalFriends: animals,
      scenes: scenes,
      durationSeconds: ((words / 145) * 60).round(),
    );
  }

  String _title(String locale, String name) => switch (locale) {
        'en' => 'The adventure of $name',
        'fr' => "L'aventure de $name",
        'es' => 'La aventura de $name',
        'de' => 'Das Abenteuer von $name',
        _ => 'L’avventura di $name',
      };

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

    final animal = animals.isEmpty
        ? ({
            'it': 'un piccolo animale curioso',
            'en': 'a curious little animal',
            'fr': 'un petit animal curieux',
            'es': 'un pequeño animal curioso',
            'de': 'ein neugieriges kleines Tier',
          }[locale] ?? 'a curious little animal')
        : animals.length == 1
            ? animals.first
            : animals.join(', ');

    final hasAnimals = animals.isNotEmpty;

    switch (locale) {
      case 'en':
        return [
          'One bright morning, $name discovered a tiny golden light at the entrance to $setting. It moved slowly between the trees, doors or rocks, as if it wanted to show the way. $name decided to follow it and invited $human to come along.',
          hasAnimals
              ? '$name reached a quiet corner of $setting where $animal was waiting. The animal sniffed the ground, listened carefully and then trotted toward the glowing trail. $name followed, watching the animal explore the place in its own way.'
              : '$name reached a quiet corner of $setting where the trail suddenly disappeared. Together with $human, they looked carefully until they noticed tiny golden footprints.',
          'The footprints led to a hidden path. Along the way, $name and $human found a blue feather, a silver bell and a little wooden key. Each clue revealed something about $setting: a secret passage, a small bridge and a door hidden behind leaves.',
          hasAnimals
              ? 'At the bridge, $animal became excited and ran ahead. The animal stopped beside a loose stone and looked back at $name. Under the stone was the missing key. $name thanked the animal with a gentle stroke and placed the key in the lock.'
              : 'At the bridge, $name noticed a loose stone. Under it was the missing key. $human helped hold the lantern while $name placed the key in the lock.',
          'The hidden door opened onto the most beautiful part of $setting: a garden filled with warm lights, soft music and colorful flowers. At its center stood a small mechanical bird that could no longer move its wings.',
          hasAnimals
              ? '$name listened to the bird while $animal watched from the grass. When a tiny gear rolled away, the animal followed it and stopped beside it. $name picked up the gear, fitted it back into the bird and the wings began to move again.'
              : '$name listened carefully while $human searched nearby. They found a tiny gear, fitted it back into the bird and the wings began to move again.',
          'The golden light rose above $setting and turned into hundreds of little stars. $name understood that the adventure had not been about finding a treasure. It was about exploring, paying attention and discovering how every person and every animal can have a special part in a shared adventure.',
        ];
      case 'fr':
        return [
          'Un matin lumineux, $name découvrit une petite lumière dorée à l’entrée de $setting. Elle avançait doucement entre les arbres, les portes ou les rochers, comme pour montrer le chemin. $name décida de la suivre et invita $human à venir.',
          hasAnimals
              ? '$name arriva dans un coin tranquille de $setting où $animal attendait. L’animal renifla le sol, écouta attentivement puis trottina vers la lumière. $name le suivit en le regardant explorer le lieu à sa manière.'
              : '$name arriva dans un coin tranquille de $setting où la piste avait disparu. Avec $human, ils cherchèrent attentivement et remarquèrent de petites empreintes dorées.',
          'Les empreintes conduisirent à un passage secret. En chemin, $name et $human trouvèrent une plume bleue, une clochette argentée et une petite clé en bois. Chaque indice révélait quelque chose sur $setting : un passage caché, un petit pont et une porte derrière les feuilles.',
          hasAnimals
              ? 'Au pont, $animal s’agita et partit devant. L’animal s’arrêta près d’une pierre déplacée et regarda $name. Sous la pierre se trouvait la clé manquante. $name caressa doucement l’animal puis plaça la clé dans la serrure.'
              : 'Au pont, $name remarqua une pierre déplacée. Sous celle-ci se trouvait la clé manquante. $human tint la lanterne pendant que $name plaça la clé dans la serrure.',
          'La porte cachée s’ouvrit sur le plus bel endroit de $setting : un jardin rempli de lumières douces, de musique et de fleurs colorées. Au centre se trouvait un petit oiseau mécanique qui ne pouvait plus bouger ses ailes.',
          hasAnimals
              ? '$name écouta l’oiseau tandis que $animal observait depuis l’herbe. Lorsqu’une minuscule roue roula au loin, l’animal la suivit et s’arrêta à côté d’elle. $name récupéra la roue et la remit en place : les ailes recommencèrent à bouger.'
              : '$name écouta attentivement pendant que $human cherchait autour d’eux. Ils trouvèrent une minuscule roue, la remirent en place et les ailes recommencèrent à bouger.',
          'La lumière dorée monta au-dessus de $setting et se transforma en centaines de petites étoiles. $name comprit que l’aventure ne consistait pas à trouver un trésor, mais à explorer, observer et découvrir que chaque personne et chaque animal peut avoir une place spéciale dans une aventure partagée.',
        ];
      case 'es':
        return [
          'Una mañana luminosa, $name descubrió una pequeña luz dorada en la entrada de $setting. Avanzaba lentamente entre árboles, puertas o rocas, como si quisiera mostrar el camino. $name decidió seguirla e invitó a $human a acompañarle.',
          hasAnimals
              ? '$name llegó a un rincón tranquilo de $setting donde esperaba $animal. El animal olfateó el suelo, escuchó con atención y después trotó hacia la luz. $name lo siguió mientras exploraba el lugar a su manera.'
              : '$name llegó a un rincón tranquilo de $setting donde el rastro desaparecía. Junto a $human, buscó con cuidado hasta descubrir pequeñas huellas doradas.',
          'Las huellas llevaron a un camino escondido. Por el camino, $name y $human encontraron una pluma azul, una campanita de plata y una pequeña llave de madera. Cada pista revelaba algo sobre $setting: un pasadizo secreto, un pequeño puente y una puerta escondida entre las hojas.',
          hasAnimals
              ? 'En el puente, $animal se adelantó. El animal se detuvo junto a una piedra suelta y miró a $name. Debajo estaba la llave que faltaba. $name acarició suavemente al animal y colocó la llave en la cerradura.'
              : 'En el puente, $name vio una piedra suelta. Debajo estaba la llave que faltaba. $human sostuvo la linterna mientras $name colocaba la llave en la cerradura.',
          'La puerta escondida se abrió hacia el lugar más bonito de $setting: un jardín lleno de luces cálidas, música suave y flores de colores. En el centro había un pequeño pájaro mecánico que ya no podía mover las alas.',
          hasAnimals
              ? '$name escuchó al pájaro mientras $animal observaba desde la hierba. Cuando una diminuta pieza rodó lejos, el animal la siguió y se detuvo junto a ella. $name recogió la pieza, la colocó en el pájaro y las alas volvieron a moverse.'
              : '$name escuchó con atención mientras $human buscaba cerca. Encontraron una pequeña pieza, la colocaron en el pájaro y las alas volvieron a moverse.',
          'La luz dorada subió sobre $setting y se convirtió en cientos de pequeñas estrellas. $name comprendió que la aventura no consistía en encontrar un tesoro, sino en explorar, observar y descubrir que cada persona y cada animal puede tener un papel especial en una aventura compartida.',
        ];
      case 'de':
        return [
          'An einem hellen Morgen entdeckte $name am Eingang von $setting ein kleines goldenes Licht. Es bewegte sich langsam zwischen Bäumen, Türen oder Felsen, als wollte es den Weg zeigen. $name beschloss, ihm zu folgen, und lud $human ein mitzukommen.',
          hasAnimals
              ? '$name erreichte eine ruhige Ecke von $setting, wo $animal wartete. Das Tier schnupperte am Boden, lauschte aufmerksam und trottete dann dem Licht hinterher. $name folgte und beobachtete, wie das Tier den Ort auf seine eigene Art erkundete.'
              : '$name erreichte eine ruhige Ecke von $setting, wo die Spur plötzlich endete. Zusammen mit $human entdeckte $name kleine goldene Fußspuren.',
          'Die Spuren führten zu einem versteckten Weg. Unterwegs fanden $name und $human eine blaue Feder, eine silberne Glocke und einen kleinen Holzschlüssel. Jeder Hinweis zeigte etwas Neues über $setting: einen geheimen Durchgang, eine kleine Brücke und eine Tür hinter den Blättern.',
          hasAnimals
              ? 'Auf der Brücke lief $animal voraus. Das Tier blieb neben einem lockeren Stein stehen und sah zu $name zurück. Darunter lag der fehlende Schlüssel. $name streichelte das Tier sanft und steckte den Schlüssel ins Schloss.'
              : 'Auf der Brücke bemerkte $name einen lockeren Stein. Darunter lag der fehlende Schlüssel. $human hielt die Laterne, während $name den Schlüssel ins Schloss steckte.',
          'Die versteckte Tür öffnete sich zum schönsten Teil von $setting: ein Garten voller warmer Lichter, leiser Musik und bunter Blumen. In der Mitte stand ein kleiner mechanischer Vogel, der seine Flügel nicht mehr bewegen konnte.',
          hasAnimals
              ? '$name lauschte dem Vogel, während $animal im Gras beobachtete. Als ein winziges Zahnrad davonrollte, folgte das Tier ihm und blieb daneben stehen. $name hob das Zahnrad auf und setzte es wieder ein. Die Flügel bewegten sich erneut.'
              : '$name hörte aufmerksam zu, während $human in der Nähe suchte. Sie fanden ein winziges Zahnrad, setzten es wieder ein und die Flügel bewegten sich erneut.',
          'Das goldene Licht stieg über $setting auf und wurde zu Hunderten kleiner Sterne. $name verstand, dass es bei dem Abenteuer nicht um einen Schatz ging, sondern darum, zu erkunden, aufmerksam zu sein und zu entdecken, dass jeder Mensch und jedes Tier einen besonderen Platz in einem gemeinsamen Abenteuer haben kann.',
        ];
      default:
        return [
          'Una mattina luminosa, $name scoprì una piccola luce dorata all’ingresso di $setting. Si muoveva lentamente tra alberi, porte o rocce, come se volesse indicare la strada. $name decise di seguirla e invitò $human a venire con lui.',
          hasAnimals
              ? '$name arrivò in un angolo tranquillo di $setting dove aspettava $animal. L’animale annusò il terreno, ascoltò con attenzione e poi trotterellò verso la luce. $name lo seguì osservandolo esplorare il luogo a modo suo.'
              : '$name arrivò in un angolo tranquillo di $setting dove la traccia spariva. Insieme a $human cercò con attenzione, finché notò piccole impronte dorate.',
          'Le impronte conducevano a un sentiero nascosto. Lungo il cammino, $name e $human trovarono una piuma blu, una campanella d’argento e una piccola chiave di legno. Ogni indizio rivelava qualcosa di nuovo su $setting: un passaggio segreto, un piccolo ponte e una porta nascosta tra le foglie.',
          hasAnimals
              ? 'Sul ponte, $animal corse avanti. L’animale si fermò accanto a una pietra spostata e guardò $name. Sotto la pietra c’era la chiave che mancava. $name accarezzò piano l’animale e inserì la chiave nella serratura.'
              : 'Sul ponte, $name notò una pietra spostata. Sotto c’era la chiave che mancava. $human tenne la lanterna mentre $name inseriva la chiave nella serratura.',
          'La porta nascosta si aprì sul luogo più bello di $setting: un giardino pieno di luci calde, musica dolce e fiori colorati. Al centro c’era un piccolo uccellino meccanico che non riusciva più a muovere le ali.',
          hasAnimals
              ? '$name ascoltò l’uccellino mentre $animal osservava dall’erba. Quando un minuscolo ingranaggio rotolò via, l’animale lo seguì e si fermò accanto a lui. $name raccolse l’ingranaggio, lo rimise al suo posto e le ali ripresero a muoversi.'
              : '$name ascoltò con attenzione mentre $human cercava nei dintorni. Trovarono un minuscolo ingranaggio, lo rimisero al suo posto e le ali ripresero a muoversi.',
          'La luce dorata salì sopra $setting e si trasformò in centinaia di piccole stelle. $name capì che l’avventura non consisteva nel trovare un tesoro, ma nell’esplorare, osservare e scoprire che ogni persona e ogni animale può avere un ruolo speciale in un’avventura condivisa.',
        ];
    }
  }
}

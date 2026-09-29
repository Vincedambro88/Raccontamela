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
    final city = request.city.trim();
    final allCompanions = [...request.friends, ...request.animalFriends];
    final companion = allCompanions.isEmpty
        ? _fallbackCompanion(request.locale)
        : allCompanions.join(', ');
    final paragraphs = _paragraphs(
      request.locale,
      name,
      setting,
      city,
      companion,
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
      city: city,
      friends: request.friends,
      animalFriends: request.animalFriends,
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

  String _fallbackCompanion(String locale) => switch (locale) {
        'en' => 'a curious little fox',
        'fr' => 'un petit renard curieux',
        'es' => 'un pequeño zorro curioso',
        'de' => 'ein neugieriger kleiner Fuchs',
        _ => 'una piccola volpe curiosa',
      };

  List<String> _paragraphs(
    String locale,
    String name,
    String setting,
    String city,
    String companion,
  ) {
    final data = switch (locale) {
      'en' => [
        'One bright morning, $name discovered a tiny golden star near the window. In $city, the area around $setting was unusually quiet. The star shimmered and pointed toward the door. With $companion nearby, $name decided to follow it.',
        'The trail crossed $setting and led to an old wooden gate. Behind it was a secret garden filled with lanterns, giant flowers and a little stream. On a stone table was a message: “The city needs someone who knows how to listen.” $name looked at $companion and smiled.',
        'They followed the stream and found a silver bell, a blue feather and a red button. Together the clues formed a map to the rooftops of $city. The wind carried a soft melody. $name understood that the adventure was not about treasure. Someone was waiting for a friend.',
        'On the highest roof they found a small mechanical bird. Its wings were still and its music box had stopped. $name placed the three clues beside it. Nothing happened until $companion gave a gentle nudge. Click! Music filled the sky and the bird opened its wings.',
        'When $name returned home, the golden stars had disappeared, but the adventure remained. People in $city talked about the mysterious music. $name kept the little gate key as a reminder: stop, listen, look carefully and remember that even a small act of kindness can change an entire day.',
      ],
      'fr' => [
        'Un matin lumineux, $name découvrit une petite étoile dorée près de la fenêtre. À $city, les alentours de $setting étaient étonnamment calmes. L’étoile scintilla et indiqua la porte. Avec $companion tout près, $name décida de la suivre.',
        'La piste traversa $setting et mena à une vieille porte en bois. Derrière se trouvait un jardin secret avec des lanternes, des fleurs géantes et un ruisseau. Sur une table de pierre, un message disait : « La ville a besoin de quelqu’un qui sache écouter. » $name regarda $companion et sourit.',
        'Ils suivirent le ruisseau et trouvèrent une clochette, une plume bleue et un bouton rouge. Ensemble, les indices formaient une carte vers les toits de $city. Le vent apporta une douce mélodie. $name comprit que l’aventure ne concernait pas un trésor. Quelqu’un attendait un ami.',
        'Sur le toit le plus haut, ils trouvèrent un petit oiseau mécanique. Ses ailes étaient immobiles. $name plaça les trois indices près de lui. Rien ne se passa jusqu’à ce que $companion donne un petit coup de museau. Clic ! La musique remplit le ciel et l’oiseau ouvrit ses ailes.',
        'Quand $name rentra chez lui, les étoiles dorées avaient disparu, mais l’aventure restait dans son cœur. Les habitants de $city parlèrent de la musique mystérieuse. $name garda la clé en souvenir : s’arrêter, écouter, regarder attentivement et se rappeler qu’un petit geste de gentillesse peut changer une journée.',
      ],
      'es' => [
        'Una mañana luminosa, $name descubrió una pequeña estrella dorada junto a la ventana. En $city, los alrededores de $setting estaban extrañamente tranquilos. La estrella brilló y señaló la puerta. Con $companion cerca, $name decidió seguirla.',
        'El rastro cruzó $setting y llegó a una vieja puerta de madera. Detrás había un jardín secreto con faroles, flores enormes y un arroyo. Sobre una mesa de piedra había un mensaje: «La ciudad necesita a alguien que sepa escuchar». $name miró a $companion y sonrió.',
        'Siguieron el arroyo y encontraron una campanita, una pluma azul y un botón rojo. Juntos formaban un mapa hacia los tejados de $city. El viento llevó una melodía suave. $name comprendió que la aventura no trataba de un tesoro. Alguien esperaba a un amigo.',
        'En el tejado más alto encontraron un pequeño pájaro mecánico. Sus alas estaban quietas. $name colocó las tres pistas junto a él. Nada ocurrió hasta que $companion le dio un pequeño empujón. ¡Clic! La música llenó el cielo y el pájaro abrió sus alas.',
        'Cuando $name volvió a casa, las estrellas doradas habían desaparecido, pero la aventura seguía en su corazón. La gente de $city habló de la música misteriosa. $name guardó la llave como recuerdo: detenerse, escuchar, mirar con atención y recordar que un pequeño gesto de bondad puede cambiar un día.',
      ],
      'de' => [
        'An einem hellen Morgen entdeckte $name einen kleinen goldenen Stern am Fenster. In $city war es rund um $setting ungewöhnlich still. Der Stern glitzerte und zeigte zur Tür. Mit $companion an seiner Seite beschloss $name, ihm zu folgen.',
        'Die Spur führte durch $setting zu einem alten Holztor. Dahinter lag ein geheimer Garten mit Laternen, riesigen Blumen und einem kleinen Bach. Auf einem Steintisch stand: „Die Stadt braucht jemanden, der zuhören kann.“ $name sah $companion an und lächelte.',
        'Sie folgten dem Bach und fanden eine silberne Glocke, eine blaue Feder und einen roten Knopf. Zusammen ergaben sie eine Karte zu den Dächern von $city. Der Wind trug eine leise Melodie heran. $name verstand: Es ging nicht um einen Schatz. Jemand wartete auf einen Freund.',
        'Auf dem höchsten Dach fanden sie einen kleinen mechanischen Vogel. Seine Flügel waren still. $name legte die drei Hinweise daneben. Nichts geschah, bis $companion ihn sanft anstupste. Klick! Musik erfüllte den Himmel und der Vogel öffnete seine Flügel.',
        'Als $name nach Hause kam, waren die goldenen Sterne verschwunden, aber das Abenteuer blieb. Die Menschen in $city erzählten von der geheimnisvollen Musik. $name bewahrte den Schlüssel auf: innehalten, zuhören, genau hinsehen und nie vergessen, dass eine kleine freundliche Tat einen ganzen Tag verändern kann.',
      ],
      _ => [
        'Una mattina luminosa, $name scoprì una piccola stella dorata vicino alla finestra. A $city, intorno a $setting, c’era un silenzio insolito. La stella brillò e indicò la porta. Con $companion vicino, $name decise di seguirla.',
        'La traccia attraversò $setting e arrivò davanti a un vecchio cancello di legno. Dietro c’era un giardino segreto pieno di lanterne, fiori enormi e un ruscello. Su un tavolo di pietra c’era un messaggio: «La città ha bisogno di qualcuno che sappia ascoltare». $name guardò $companion e sorrise.',
        'Seguirono il ruscello e trovarono una campanella d’argento, una piuma blu e un bottone rosso. Insieme formavano una mappa verso i tetti di $city. Il vento portò una melodia dolce. $name capì che l’avventura non riguardava un tesoro. Qualcuno stava aspettando un amico.',
        'Sul tetto più alto trovarono un piccolo uccellino meccanico. Le sue ali erano ferme. $name mise i tre indizi accanto a lui. Non accadde nulla finché $companion non gli diede un piccolo colpetto. Clic! La musica riempì il cielo e l’uccellino aprì le ali.',
        'Quando $name tornò a casa, le stelle dorate erano scomparse, ma l’avventura era rimasta. Gli abitanti di $city raccontarono della musica misteriosa. $name conservò la chiave come ricordo: fermarsi, ascoltare, guardare con attenzione e ricordare che anche un piccolo gesto di gentilezza può cambiare un’intera giornata.',
      ],
    };
    return data;
  }
}

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:raccontamela/features/story/application/story_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates an eight-page story lasting at least five minutes', () async {
    final story = await StoryGenerator(
      imageLoader: (_) async => Uint8List.fromList(const [
        137, 80, 78, 71, 13, 10, 26, 10,
      ]),
    ).generate(
      const StoryRequest(
        protagonistName: 'Luca',
        setting: 'un castello incantato',
        city: 'Rimini',
        friends: ['Anna', 'Marco'],
        animalFriends: ['Milo'],
        animal: 'cane',
        locale: 'it',
      ),
    );

    expect(story.protagonistName, 'Luca');
    expect(story.city, 'Rimini');
    expect(story.setting, 'un castello incantato');
    expect(story.friends, contains('Anna'));
    expect(story.animalFriends, contains('cane'));
    expect(story.scenes, hasLength(8));
    expect(story.wordCount, greaterThanOrEqualTo(675));
    expect(story.durationSeconds, greaterThanOrEqualTo(300));
    expect(story.scenes.every((scene) => scene.text.contains('Luca')), isTrue);
    expect(
      story.scenes.every(
        (scene) =>
            !scene.text.contains('{{PROTAGONISTA}}') &&
            !scene.text.contains('{{ANIMALE}}') &&
            !scene.text.contains('{{LUOGO}}') &&
            !scene.text.contains('{{AMICO}}'),
      ),
      isTrue,
    );
  });
}

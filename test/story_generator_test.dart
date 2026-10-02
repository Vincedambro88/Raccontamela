import 'package:flutter_test/flutter_test.dart';
import 'package:raccontamela/features/story/application/story_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates an eight-page story with the requested inputs', () async {
    final story = await StoryGenerator().generate(
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
    expect(story.wordCount, greaterThan(200));
    expect(story.durationSeconds, greaterThan(0));
    expect(
      story.scenes.every((scene) => scene.text.contains('Luca')),
      isTrue,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:raccontamela/features/story/application/story_generator.dart';

void main() {
  test('generates a five-scene story with the requested inputs', () async {
    final story = await StoryGenerator().generate(
      const StoryRequest(
        protagonistName: 'Luca',
        setting: 'un castello incantato',
        city: 'Rimini',
        friends: ['Anna', 'Marco'],
        animalFriends: ['Milo'],
        locale: 'it',
      ),
    );

    expect(story.protagonistName, 'Luca');
    expect(story.city, 'un castello incantato');
    expect(story.setting, 'un castello incantato');
    expect(story.friends, contains('Anna'));
    expect(story.animalFriends, contains('Milo'));
    expect(story.scenes, hasLength(7));
    expect(story.wordCount, greaterThan(200));
    expect(story.durationSeconds, greaterThan(90));
  });
}

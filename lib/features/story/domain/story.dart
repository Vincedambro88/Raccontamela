class StoryScene {
  const StoryScene({required this.index, required this.text});
  final int index;
  final String text;
}

class Story {
  const Story({
    required this.title,
    required this.protagonistName,
    required this.setting,
    required this.city,
    required this.friends,
    required this.animalFriends,
    required this.scenes,
    required this.durationSeconds,
  });

  final String title;
  final String protagonistName;
  final String setting;
  final String city;
  final List<String> friends;
  final List<String> animalFriends;
  final List<StoryScene> scenes;
  final int durationSeconds;

  String get text => scenes.map((scene) => scene.text).join('\n\n');
  int get wordCount => text.trim().split(RegExp(r'\s+')).length;
}

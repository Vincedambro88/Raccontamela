import 'dart:typed_data';

class StoryScene {
  const StoryScene({
    required this.index,
    required this.text,
    this.colorImageUrl,
    this.colorImageBytes,
    this.bwImageUrl,
    this.narrationUrl,
  });

  final int index;
  final String text;
  final String? colorImageUrl;
  final Uint8List? colorImageBytes;
  final String? bwImageUrl;
  final String? narrationUrl;
}

class Story {
  const Story({
    this.id,
    required this.title,
    required this.protagonistName,
    required this.setting,
    required this.city,
    required this.friends,
    required this.animalFriends,
    required this.scenes,
    required this.durationSeconds,
    this.savedToCloud = false,
  });

  final String? id;
  final String title;
  final String protagonistName;
  final String setting;
  final String city;
  final List<String> friends;
  final List<String> animalFriends;
  final List<StoryScene> scenes;
  final int durationSeconds;
  final bool savedToCloud;

  String get text => scenes.map((scene) => scene.text).join('\n\n');
  int get wordCount => text.trim().split(RegExp(r'\s+')).length;
}

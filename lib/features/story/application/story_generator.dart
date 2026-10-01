import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../domain/story.dart';

class StoryRequest {
  const StoryRequest({
    required this.protagonistName,
    required this.setting,
    required this.city,
    required this.friends,
    required this.animalFriends,
    required this.animal,
    required this.locale,
  });

  final String protagonistName;
  final String setting;
  final String city;
  final List<String> friends;
  final List<String> animalFriends;
  final String animal;
  final String locale;
}

class StoryGenerator {
  StoryGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;
  List<Map<String, dynamic>>? _stories;

  Future<Story> generate(StoryRequest request) async {
    final stories = await _loadCatalog();
    if (stories.isEmpty) {
      throw StateError('Il catalogo delle 500 storie è vuoto.');
    }

    final master = Map<String, dynamic>.from(
      stories[_random.nextInt(stories.length)],
    );
    final masterId = master['id'] as String? ?? 'RM-000';
    final masterTitle = master['title'] as String? ?? 'Raccontamela';
    final masterSetting = master['setting'] as String? ?? request.setting;
    final requestedSetting = request.setting.trim().isEmpty
        ? masterSetting
        : request.setting.trim();
    final requestedAnimal = _animalSpecies(
      request.animal,
      master['animal'] as String? ?? 'animale',
    );
    final name = request.protagonistName.trim().isEmpty
        ? 'Il protagonista'
        : request.protagonistName.trim();

    final rawPages =
        List<String>.from(master['pages'] as List<dynamic>? ?? const []);
    if (rawPages.length != 8) {
      throw StateError('$masterId non contiene esattamente 8 pagine.');
    }

    final scenes = <StoryScene>[];
    for (var i = 0; i < rawPages.length; i++) {
      var text = rawPages[i];
      text = text.replaceAll('{{PROTAGONISTA}}', name);
      text = text.replaceAll('{{ANIMALE}}', requestedAnimal);
      text = text.replaceAll('{{LUOGO}}', requestedSetting);
      if (masterSetting.isNotEmpty &&
          masterSetting.toLowerCase() != requestedSetting.toLowerCase()) {
        text = text.replaceAll(masterSetting, requestedSetting);
        text = text.replaceAll(
          _capitalize(masterSetting),
          _capitalize(requestedSetting),
        );
      }

      scenes.add(
        StoryScene(
          index: i,
          text: text,
          colorImageUrl: await _catalogImageUrl(
            masterId,
            i + 1,
          ),
        ),
      );
    }

    final words = scenes
        .map((scene) => scene.text
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .length)
        .fold<int>(0, (a, b) => a + b);

    return Story(
      id: masterId,
      title: _personalizeTitle(masterTitle, masterSetting, requestedSetting),
      protagonistName: name,
      setting: requestedSetting,
      city: request.city,
      friends: request.friends,
      animalFriends: [requestedAnimal],
      scenes: scenes,
      durationSeconds: ((words / 135) * 60).round(),
    );
  }

  Future<String?> _catalogImageUrl(String masterId, int page) async {
    if (!AppConfig.hasSupabase) return null;

    final path =
        'catalog/$masterId/page-${page.toString().padLeft(2, '0')}.png';
    try {
      return await Supabase.instance.client.storage
          .from('story-assets')
          .createSignedUrl(path, 3600);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _loadCatalog() async {
    if (_stories != null) return _stories!;
    final jsonText =
        await rootBundle.loadString('assets/stories/master_stories.json');
    final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
    final raw = decoded['stories'] as List<dynamic>? ?? const [];
    if (raw.length != 500) {
      throw StateError(
        'Il catalogo deve contenere esattamente 500 storie: trovate ${raw.length}.',
      );
    }
    _stories =
        raw.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    return _stories!;
  }

  String _animalSpecies(String value, String fallback) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return fallback;
    return trimmed.contains(':') ? trimmed.split(':').first.trim() : trimmed;
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

  String _personalizeTitle(
    String title,
    String masterSetting,
    String requestedSetting,
  ) {
    if (masterSetting.isEmpty || masterSetting == requestedSetting) return title;
    return title.replaceAll(masterSetting, requestedSetting);
  }
}

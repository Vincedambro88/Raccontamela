import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_config.dart';
import '../domain/story.dart';

typedef CatalogImageLoader = Future<Uint8List?> Function(String path);

class StoryRequest {
  const StoryRequest({required this.protagonistName, required this.setting, required this.city, required this.friends, required this.animalFriends, required this.animal, required this.locale});
  final String protagonistName;
  final String setting;
  final String city;
  final List<String> friends;
  final List<String> animalFriends;
  final String animal;
  final String locale;
}

class StoryGenerator {
  StoryGenerator({Random? random, CatalogImageLoader? imageLoader})
      : _random = random ?? Random(),
        _imageLoader = imageLoader;
  final Random _random;
  final CatalogImageLoader? _imageLoader;
  List<Map<String, dynamic>>? _stories;

  Future<Story> generate(StoryRequest request) async {
    final stories = await _loadCatalog();
    final master = Map<String, dynamic>.from(stories[_random.nextInt(stories.length)]);
    final masterId = master['id'] as String? ?? 'RM-000';
    final masterTitle = master['title'] as String? ?? 'Raccontamela';
    final masterSetting = master['setting'] as String? ?? '';
    final requestedSetting = request.setting.trim().isEmpty ? masterSetting : request.setting.trim();
    final requestedAnimal = _animalSpecies(request.animal, master['animal'] as String? ?? 'animale');
    final name = request.protagonistName.trim().isEmpty ? 'Il protagonista' : request.protagonistName.trim();
    final friend = request.friends.map((value) => value.trim()).firstWhere((value) => value.isNotEmpty, orElse: () => 'un amico');
    final rawPages = List<String>.from(master['pages'] as List<dynamic>? ?? const []);
    if (rawPages.length != 8) throw StateError('$masterId non contiene esattamente 8 pagine.');

    final scenes = <StoryScene>[];
    for (var i = 0; i < rawPages.length; i++) {
      var text = rawPages[i]
          .replaceAll('{{PROTAGONISTA}}', name)
          .replaceAll('{{ANIMALE}}', requestedAnimal)
          .replaceAll('{{LUOGO}}', requestedSetting)
          .replaceAll('{{AMICO}}', friend);
      if (masterSetting.isNotEmpty && masterSetting.toLowerCase() != requestedSetting.toLowerCase()) {
        text = text.replaceAll(masterSetting, requestedSetting);
        text = text.replaceAll(_capitalize(masterSetting), _capitalize(requestedSetting));
      }
      if (text.trim().isEmpty) throw StateError('$masterId contiene una pagina vuota.');
      final imageBytes = await _loadCatalogImage(masterId, i + 1);
      if (imageBytes == null || imageBytes.isEmpty) {
        final page = (i + 1).toString().padLeft(2, '0');
        throw StateError('Immagine mancante: catalog/$masterId/page-$page.png');
      }
      scenes.add(StoryScene(
        index: i,
        text: text.trim(),
        colorImageUrl: _catalogImageUrl(masterId, i + 1),
        colorImageBytes: imageBytes,
      ));
    }

    final words = scenes.fold<int>(0, (total, scene) => total + scene.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length);
    if (words < 675) throw StateError('$masterId contiene solo $words parole: il catalogo deve garantire almeno 5 minuti di lettura.');

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

  Future<Uint8List?> _loadCatalogImage(String masterId, int page) async {
    final path = 'catalog/$masterId/page-' + page.toString().padLeft(2, '0') + '.png';
    final loader = _imageLoader;
    if (loader != null) return loader(path);
    if (!AppConfig.hasSupabase || !Supabase.instance.isInitialized) return null;
    try {
      return await Supabase.instance.client.storage.from('story-assets').download(path);
    } catch (_) {
      return null;
    }
  }

  String? _catalogImageUrl(String masterId, int page) {
    if (!AppConfig.hasSupabase || !Supabase.instance.isInitialized) return null;
    final path = 'catalog/$masterId/page-' + page.toString().padLeft(2, '0') + '.png';
    try {
      return Supabase.instance.client.storage.from('story-assets').getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _loadCatalog() async {
    if (_stories != null) return _stories!;
    final jsonText = await rootBundle.loadString('assets/stories/master_stories.json');
    final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
    final raw = decoded['stories'] as List<dynamic>? ?? const [];
    if (raw.length != 500) throw StateError('Il catalogo deve contenere esattamente 500 storie: trovate ' + raw.length.toString() + '.');
    _stories = raw.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    return _stories!;
  }

  String _animalSpecies(String value, String fallback) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return fallback;
    return trimmed.contains(':') ? trimmed.split(':').first.trim() : trimmed;
  }

  String _capitalize(String value) => value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

  String _personalizeTitle(String title, String masterSetting, String requestedSetting) {
    if (masterSetting.isEmpty || masterSetting == requestedSetting) return title;
    return title.replaceAll(masterSetting, requestedSetting);
  }
}
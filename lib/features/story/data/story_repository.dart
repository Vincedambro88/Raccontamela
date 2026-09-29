import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../application/story_generator.dart';
import '../domain/story.dart';

class StoryRepository {
  StoryRepository({SupabaseClient? client})
      : _client = client ?? (AppConfig.hasSupabase ? Supabase.instance.client : null);

  final SupabaseClient? _client;

  Future<Story> generate(StoryRequest request) async {
    final client = _client;
    if (client == null) return StoryGenerator().generate(request);
    final response = await client.functions.invoke('generate-story', body: {
      'protagonistName': request.protagonistName,
      'setting': request.setting,
      'city': request.city,
      'friends': request.friends,
      'animalFriends': request.animalFriends,
      'locale': request.locale,
    });
    final data = Map<String, dynamic>.from(response.data as Map);
    final scenes = (data['scenes'] as List<dynamic>)
        .map((item) => StoryScene(index: item['index'] as int, text: item['text'] as String))
        .toList();
    return Story(
      id: data['storyId'] as String?,
      title: data['title'] as String,
      protagonistName: request.protagonistName,
      setting: request.setting,
      city: request.city,
      friends: request.friends,
      animalFriends: request.animalFriends,
      scenes: scenes,
      durationSeconds: (data['durationSeconds'] as num).round(),
      savedToCloud: data['saved'] == true,
    );
  }

  Future<List<Story>> loadHistory() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return const [];
    final rows = await client.from('stories')
        .select('id,title,protagonist_name,setting,story_city,friends,animal_friends,duration_seconds,created_at,story_scenes(index,text)')
        .eq('user_id', user.id).eq('is_premium_story', true).eq('status', 'ready')
        .order('created_at', ascending: false);
    return (rows as List<dynamic>).map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final rawScenes = (map['story_scenes'] as List<dynamic>? ?? const []);
      final scenes = rawScenes.map((scene) {
        final s = Map<String, dynamic>.from(scene as Map);
        return StoryScene(index: s['index'] as int, text: s['text'] as String);
      }).toList()..sort((a, b) => a.index.compareTo(b.index));
      return Story(
        id: map['id'] as String,
        title: map['title'] as String? ?? 'Raccontamela',
        protagonistName: map['protagonist_name'] as String,
        setting: map['setting'] as String,
        city: map['story_city'] as String,
        friends: List<String>.from(map['friends'] as List<dynamic>? ?? const []),
        animalFriends: List<String>.from(map['animal_friends'] as List<dynamic>? ?? const []),
        scenes: scenes,
        durationSeconds: (map['duration_seconds'] as num?)?.round() ?? 0,
        savedToCloud: true,
      );
    }).toList();
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../application/story_generator.dart';
import '../domain/story.dart';

class StoryRepository {
  StoryRepository({SupabaseClient? client})
      : _client = client ?? (AppConfig.hasSupabase ? Supabase.instance.client : null);

  final SupabaseClient? _client;
  final StoryGenerator _generator = StoryGenerator();

  Future<Story> generate(StoryRequest request) => _generator.generate(request);

  Future<List<Story>> loadHistory() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return const [];

    final rows = await client
        .from('stories')
        .select('id,title,protagonist_name,setting,story_city,friends,animal_friends,duration_seconds,created_at,story_scenes(scene_index,text,color_image_path,bw_image_path,narration_path)')
        .eq('user_id', user.id)
        .eq('is_premium_story', true)
        .eq('status', 'ready')
        .order('created_at', ascending: false);

    final stories = <Story>[];
    for (final row in rows as List<dynamic>) {
      final map = Map<String, dynamic>.from(row as Map);
      final rawScenes = (map['story_scenes'] as List<dynamic>? ?? const []);
      final scenes = <StoryScene>[];
      for (final scene in rawScenes) {
        final s = Map<String, dynamic>.from(scene as Map);
        final colorPath = s['color_image_path'] as String?;
        final bwPath = s['bw_image_path'] as String?;
        final narrationPath = s['narration_path'] as String?;
        String? colorUrl;
        String? bwUrl;
        String? narrationUrl;
        if (colorPath != null) {
          colorUrl = await client.storage.from('story-assets').createSignedUrl(colorPath, 3600);
        }
        if (bwPath != null) {
          bwUrl = await client.storage.from('story-assets').createSignedUrl(bwPath, 3600);
        }
        if (narrationPath != null) {
          narrationUrl = await client.storage.from('story-assets').createSignedUrl(narrationPath, 3600);
        }
        scenes.add(StoryScene(
          index: s['scene_index'] as int,
          text: s['text'] as String,
          colorImageUrl: colorUrl,
          bwImageUrl: bwUrl,
          narrationUrl: narrationUrl,
        ));
      }
      scenes.sort((a, b) => a.index.compareTo(b.index));

      stories.add(Story(
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
      ));
    }
    return stories;
  }
}

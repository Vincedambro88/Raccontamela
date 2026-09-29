import 'package:supabase_flutter/supabase_flutter.dart';

import '../../story/domain/story.dart';

class PremiumMediaRepository {
  PremiumMediaRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const voices = <String>[
    'alloy',
    'ash',
    'coral',
    'echo',
    'nova',
    'shimmer',
  ];

  Future<Story> generate(
    Story story, {
    String voiceId = 'alloy',
  }) async {
    if (story.id == null) {
      throw StateError('A cloud story is required for Premium media.');
    }

    final response = await _client.functions.invoke(
      'generate-premium-media',
      body: {
        'storyId': story.id,
        'voiceId': voiceId,
        'kinds': ['bw_image', 'narration'],
      },
    );

    final data = Map<String, dynamic>.from(response.data as Map);
    final failed = (data['results'] as List<dynamic>? ?? const [])
        .where((item) => Map<String, dynamic>.from(item as Map)['status'] == 'failed')
        .toList();
    if (failed.isNotEmpty) {
      throw Exception('Premium media generation failed for one or more scenes.');
    }

    final rows = await _client
        .from('story_scenes')
        .select('scene_index,bw_image_path,narration_path')
        .eq('story_id', story.id!);

    final updated = <int, StoryScene>{};
    for (final row in rows as List<dynamic>) {
      final map = Map<String, dynamic>.from(row as Map);
      final index = (map['scene_index'] as num).toInt();
      final bwPath = map['bw_image_path'] as String?;
      final narrationPath = map['narration_path'] as String?;
      String? bwUrl;
      String? narrationUrl;
      if (bwPath != null) {
        bwUrl = (await _client.storage.from('story-assets').createSignedUrl(bwPath, 3600);
      }
      if (narrationPath != null) {
        narrationUrl = (await _client.storage.from('story-assets').createSignedUrl(narrationPath, 3600);
      }
      final original = story.scenes.firstWhere((scene) => scene.index == index);
      updated[index] = StoryScene(
        index: index,
        text: original.text,
        colorImageUrl: original.colorImageUrl,
        bwImageUrl: bwUrl,
        narrationUrl: narrationUrl,
      );
    }

    return Story(
      id: story.id,
      title: story.title,
      protagonistName: story.protagonistName,
      setting: story.setting,
      city: story.city,
      friends: story.friends,
      animalFriends: story.animalFriends,
      scenes: story.scenes.map((scene) => updated[scene.index] ?? scene).toList(),
      durationSeconds: story.durationSeconds,
      savedToCloud: story.savedToCloud,
    );
  }
}

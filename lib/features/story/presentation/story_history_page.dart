import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../data/story_repository.dart';
import '../domain/story.dart';
import 'story_reader_page.dart';

class StoryHistoryPage extends ConsumerStatefulWidget {
  const StoryHistoryPage({super.key});
  @override
  ConsumerState<StoryHistoryPage> createState() => _StoryHistoryPageState();
}

class _StoryHistoryPageState extends ConsumerState<StoryHistoryPage> {
  late Future<List<Story>> _history;
  @override
  void initState() { super.initState(); _history = StoryRepository().loadHistory(); }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.storyHistory)),
      body: FutureBuilder<List<Story>>(
        future: _history,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.historyLoadError)));
          final stories = snapshot.data ?? const <Story>[];
          if (stories.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.noStoriesYet, textAlign: TextAlign.center)));
          return RefreshIndicator(
            onRefresh: () async => setState(() => _history = StoryRepository().loadHistory()),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: stories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final story = stories[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.auto_stories)),
                    title: Text(story.title),
                    subtitle: Text(story.protagonistName + ' · ' + story.city + ' · ' + (story.durationSeconds / 60).toStringAsFixed(1) + ' min'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoryReaderPage(story: story))),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

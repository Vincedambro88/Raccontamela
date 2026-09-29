import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/story.dart';

class StoryReaderPage extends StatelessWidget {
  const StoryReaderPage({super.key, required this.story});
  final Story story;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(story.title)),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        itemCount: story.scenes.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) return _Header(story: story);
          if (index == story.scenes.length + 1) {
            return FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.auto_awesome),
              label: Text(l10n.premium),
            );
          }
          final scene = story.scenes[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 170,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primaryContainer,
                          Theme.of(context).colorScheme.secondaryContainer,
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.auto_stories_rounded,
                      size: 64,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      scene.text,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(height: 1.55),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.story});
  final Story story;

  @override
  Widget build(BuildContext context) {
    final minutes = story.durationSeconds ~/ 60;
    final seconds = story.durationSeconds % 60;
    final duration = minutes.toString() +
        ' min' +
        (seconds == 0 ? '' : ' ' + seconds.toString() + 's');

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            story.title,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            story.protagonistName +
                ' · ' +
                story.city +
                ' · ' +
                story.setting,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.schedule, size: 18),
                label: Text(duration),
              ),
              Chip(
                avatar: const Icon(Icons.menu_book, size: 18),
                label: Text(story.wordCount.toString() + ' parole'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

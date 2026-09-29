import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../l10n/app_localizations.dart';
import '../../premium/data/premium_media_repository.dart';
import '../../premium/data/premium_entitlement_repository.dart';
import '../../premium/presentation/premium_page.dart';
import '../domain/story.dart';

class StoryReaderPage extends StatefulWidget {
  const StoryReaderPage({super.key, required this.story});
  final Story story;

  @override
  State<StoryReaderPage> createState() => _StoryReaderPageState();
}

class _StoryReaderPageState extends State<StoryReaderPage> {
  final AudioPlayer _player = AudioPlayer();
  Story? _story;
  String _voice = PremiumMediaRepository.voices.first;
  bool _loadingPremiumMedia = false;
  bool _premiumActive = false;
  int? _playingScene;

  Story get story => _story ?? widget.story;

  @override
  void initState() {
    super.initState();
    _loadPremiumState();
  }

  Future<void> _loadPremiumState() async {
    try {
      final active = await PremiumEntitlementRepository().hasActivePremium();
      if (mounted) setState(() => _premiumActive = active);
    } catch (_) {
      if (mounted) setState(() => _premiumActive = false);
    }
  }

  Future<void> _openPremium() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PremiumPage()),
    );
    await _loadPremiumState();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _generatePremiumMedia() async {
    if (!_premiumActive) {
      await _openPremium();
      return;
    }
    if (Supabase.instance.client.auth.currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.premiumSignInRequired)),
        );
      }
      return;
    }
    setState(() => _loadingPremiumMedia = true);
    try {
      final updated = await PremiumMediaRepository().generate(story, voiceId: _voice);
      if (mounted) setState(() => _story = updated);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loadingPremiumMedia = false);
    }
  }

  Future<void> _playScene(StoryScene scene, AppLocalizations l10n) async {
    final url = scene.narrationUrl;
    if (url == null) return;
    try {
      if (_playingScene == scene.index && _player.playing) {
        await _player.pause();
        if (mounted) setState(() {});
        return;
      }
      await _player.setUrl(url);
      if (mounted) setState(() => _playingScene = scene.index);
      await _player.play();
      if (mounted) setState(() => _playingScene = null);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.playbackUnavailable}: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasPremiumMedia = story.scenes.any((scene) => scene.bwImageUrl != null || scene.narrationUrl != null);

    return Scaffold(
      appBar: AppBar(title: Text(story.title)),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        itemCount: story.scenes.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) return _Header(story: story, l10n: l10n);
          if (index == story.scenes.length + 1) {
            return Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.secondaryContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 9),
                        Expanded(child: Text(l10n.premium, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.narration + ' + ' + l10n.printColoring),
                    const SizedBox(height: 14),
                    if (_premiumActive)
                      DropdownButtonFormField<String>(
                        initialValue: _voice,
                        decoration: InputDecoration(labelText: l10n.voice),
                        items: PremiumMediaRepository.voices.map((voice) => DropdownMenuItem(value: voice, child: Text(voice))).toList(),
                        onChanged: _loadingPremiumMedia ? null : (value) {
                          if (value != null) setState(() => _voice = value);
                        },
                      )
                    else
                      InkWell(
                        onTap: _openPremium,
                        borderRadius: BorderRadius.circular(16),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n.voice,
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                          ),
                          child: Text('Disponibile con Premium', style: Theme.of(context).textTheme.bodyLarge),
                        ),
                      ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _loadingPremiumMedia ? null : _generatePremiumMedia,
                      icon: _loadingPremiumMedia
                          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(_premiumActive ? Icons.auto_awesome : Icons.lock_outline_rounded),
                      label: Text(_premiumActive
                          ? (hasPremiumMedia ? l10n.regeneratePremium : l10n.activatePremiumContent)
                          : l10n.buyPremium),
                    ),
                  ],
                ),
              ),
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
                  if (scene.colorImageUrl != null)
                    Image.network(scene.colorImageUrl!, height: 260, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _ImageFallback())
                  else
                    const _ImageFallback(),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(scene.text, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55)),
                  ),
                  if (scene.bwImageUrl != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(scene.bwImageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                      ),
                    ),
                  if (scene.narrationUrl != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      child: OutlinedButton.icon(
                        onPressed: () => _playScene(scene, l10n),
                        icon: Icon(_playingScene == scene.index && _player.playing ? Icons.pause : Icons.play_arrow),
                        label: Text(_playingScene == scene.index && _player.playing ? l10n.pause : l10n.narration),
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

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      alignment: Alignment.center,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.auto_stories_rounded, size: 64),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.story, required this.l10n});
  final Story story;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final minutes = story.durationSeconds ~/ 60;
    final seconds = story.durationSeconds % 60;
    final duration = minutes.toString() + ' min' + (seconds == 0 ? '' : ' ' + seconds.toString() + 's');

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(story.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(story.protagonistName + ' · ' + story.setting),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              Chip(avatar: const Icon(Icons.schedule, size: 18), label: Text(duration)),
              Chip(avatar: const Icon(Icons.menu_book, size: 18), label: Text(story.wordCount.toString() + ' ' + l10n.words)),
            ],
          ),
        ],
      ),
    );
  }
}

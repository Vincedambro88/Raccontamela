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
            padding: const EdgeInsets.only(bottom: 24),
            child: _StoryBookPage(
              scene: scene,
              l10n: l10n,
              onPlay: () => _playScene(scene, l10n),
              isPlaying: _playingScene == scene.index && _player.playing,
            ),
          );
        },
      ),
    );
  }
}

class _StoryBookPage extends StatelessWidget {
  const _StoryBookPage({
    required this.scene,
    required this.l10n,
    required this.onPlay,
    required this.isPlaying,
  });

  final StoryScene scene;
  final AppLocalizations l10n;
  final VoidCallback onPlay;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final hasColor = scene.colorImageUrl != null;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: AspectRatio(
        aspectRatio: 0.76,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasColor)
              Image.network(
                scene.colorImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _ImageFallback(),
              )
            else
              const _ImageFallback(),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.52, 0.74, 1.0],
                  colors: [
                    Colors.transparent,
                    Color(0xAAFFF9EE),
                    Color(0xF5FFF9EE),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              top: 18,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _PageBadge(index: scene.index + 1),
                  if (scene.narrationUrl != null)
                    Material(
                      color: Colors.white.withValues(alpha: 0.88),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: isPlaying ? l10n.pause : l10n.narration,
                        onPressed: onPlay,
                        icon: Icon(isPlaying ? Icons.pause_rounded : Icons.volume_up_rounded),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: Text(
                scene.text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 17,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF342A38),
                    ),
              ),
            ),
            if (scene.bwImageUrl != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Opacity(
                  opacity: 0.0,
                  child: Image.network(scene.bwImageUrl!, fit: BoxFit.cover),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PageBadge extends StatelessWidget {
  const _PageBadge({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          'Pagina $index',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
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

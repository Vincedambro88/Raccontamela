import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/story_generator.dart';
import '../data/story_repository.dart';
import 'story_history_page.dart';
import 'story_reader_page.dart';
import '../../premium/presentation/premium_page.dart';
import '../../auth/presentation/auth_page.dart';

class StoryHomePage extends ConsumerStatefulWidget {
  const StoryHomePage({super.key});

  @override
  ConsumerState<StoryHomePage> createState() => _StoryHomePageState();
}

class _StoryHomePageState extends ConsumerState<StoryHomePage> {
  final protagonistController = TextEditingController();
  final settingController = TextEditingController();
  final friendsController = TextEditingController();
  final animalsController = TextEditingController();
  bool generating = false;

  @override
  void dispose() {
    protagonistController.dispose();
    settingController.dispose();
    friendsController.dispose();
    animalsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raccontamela'),
        actions: [
          IconButton(
            tooltip: l10n.storyHistory,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StoryHistoryPage()),
            ),
            icon: const Icon(Icons.auto_stories_outlined),
          ),
          IconButton(
            tooltip: l10n.account,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AuthPage()),
            ),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
        children: [
          _HeroCard(l10n: l10n),
          const SizedBox(height: 22),
          Text(
            l10n.newStory,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            'Costruiamo insieme un’avventura su misura.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.person_rounded,
            title: '1 · Il protagonista',
            child: _field(
              l10n.protagonistName,
              protagonistController,
              hint: 'Es. Sofia',
              requiredField: true,
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.place_rounded,
            title: '2 · Il luogo dell’avventura',
            child: _field(
              l10n.storyCity,
              settingController,
              hint: 'Es. un castello incantato, una spiaggia, una foresta',
              requiredField: true,
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.groups_rounded,
            title: '3 · Chi parte con lui?',
            child: Column(
              children: [
                _field(
                  l10n.friends,
                  friendsController,
                  hint: l10n.friendsHint,
                ),
                const SizedBox(height: 10),
                _field(
                  l10n.animalFriends,
                  animalsController,
                  hint: 'Es. cane, gatto, cavallo',
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.pets_rounded,
                      size: 19,
                      color: colors.tertiary,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Gli animali restano animali: nella storia potranno correre, giocare, seguire, annusare e interagire con i personaggi.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              height: 1.35,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: generating ? null : _generate,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: generating
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: Text(
              generating ? l10n.creatingStory : l10n.generateStory,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 18),
          _PremiumCard(
            onTap: () => _showPremium(context),
            l10n: l10n,
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    bool requiredField = false,
  }) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: requiredField ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(
          requiredField ? Icons.edit_rounded : Icons.add_rounded,
        ),
      ),
    );
  }

  Future<void> _generate() async {
    final l10n = AppLocalizations.of(context)!;
    final protagonist = protagonistController.text.trim();
    final setting = settingController.text.trim();

    if (protagonist.isEmpty || setting.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.requiredFields)),
      );
      return;
    }

    final friends = _parseList(friendsController.text);
    final animals = _parseList(animalsController.text);
    if (friends.length > 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.maxFriends)),
      );
      return;
    }

    setState(() => generating = true);
    try {
      final locale = Localizations.localeOf(context).languageCode;
      final story = await StoryRepository().generate(
        StoryRequest(
          protagonistName: protagonist,
          setting: setting,
          // Kept internally for backward compatibility with the existing
          // database/API contract: the story location is no longer a city.
          city: setting,
          friends: friends,
          animalFriends: animals,
          locale: locale,
        ),
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => StoryReaderPage(story: story)),
      );
    } finally {
      if (mounted) setState(() => generating = false);
    }
  }

  List<String> _parseList(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  void _showPremium(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PremiumPage()),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryContainer,
            colors.tertiaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colors.surface.withOpacity(.72),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  color: colors.primary,
                  size: 28,
                ),
              ),
              const Spacer(),
              const _MiniBadge(icon: Icons.favorite_rounded, text: 'Personalizzata'),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'La tua storia.\nLe tue regole.',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.02,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.introText,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.45,
                  color: colors.onPrimaryContainer,
                ),
          ),
          const SizedBox(height: 18),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniBadge(icon: Icons.person_rounded, text: 'Protagonista'),
              _MiniBadge(icon: Icons.place_rounded, text: 'Luogo'),
              _MiniBadge(icon: Icons.pets_rounded, text: 'Animali'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(.75),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 21, color: colors.primary),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            child,
          ],
        ),
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.onTap, required this.l10n});
  final VoidCallback onTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.secondaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.secondary,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: colors.onSecondary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.premium,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.premiumDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: colors.onSecondaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

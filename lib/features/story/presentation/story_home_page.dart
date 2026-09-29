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
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            'Scegli gli ingredienti della tua avventura.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            accent: colors.primary,
            number: '1',
            icon: Icons.person_rounded,
            title: 'Il protagonista',
            subtitle: 'Chi sarà l’eroe della storia?',
            child: _field(
              l10n.protagonistName,
              protagonistController,
              hint: 'Es. Sofia',
              requiredField: true,
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            accent: colors.tertiary,
            number: '2',
            icon: Icons.explore_rounded,
            title: 'Il luogo dell’avventura',
            subtitle: 'Dove comincia il viaggio?',
            child: Column(
              children: [
                _field(
                  l10n.storyCity,
                  settingController,
                  hint: 'Es. castello, spiaggia, foresta incantata...',
                  requiredField: true,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Idee veloci',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _IdeaChip('🏰 Castello', () => _setSetting('un castello incantato')),
                    _IdeaChip('🌲 Foresta', () => _setSetting('una foresta magica')),
                    _IdeaChip('🏖️ Spiaggia', () => _setSetting('una spiaggia misteriosa')),
                    _IdeaChip('🚀 Spazio', () => _setSetting('una stazione spaziale')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            accent: colors.secondary,
            number: '3',
            icon: Icons.groups_rounded,
            title: 'Gli amici dell’avventura',
            subtitle: 'Chi viene con te?',
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
                  hint: 'Es. cane: Milo, gatto: Luna',
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _IdeaChip('🐶 Cane', () => _addAnimal('cane: Milo')),
                    _IdeaChip('🐱 Gatto', () => _addAnimal('gatto: Luna')),
                    _IdeaChip('🐉 Drago', () => _addAnimal('drago fantastico: Fiamma')),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: colors.tertiaryContainer.withOpacity(.55),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.pets_rounded, size: 19, color: colors.tertiary),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Gli animali restano animali: possono correre, saltare, volare, annusare e aiutare nella storia con comportamenti adatti alla loro specie.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                                height: 1.3,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withOpacity(.5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    generating ? 'Sto preparando la tua avventura...' : 'Tutto pronto? Si parte!',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: generating ? null : _generate,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: generating
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.rocket_launch_rounded),
            label: Text(
              generating ? l10n.creatingStory : l10n.generateStory,
              style: const TextStyle(fontWeight: FontWeight.w800),
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

  void _setSetting(String value) {
    settingController.text = value;
    settingController.selection = TextSelection.collapsed(offset: value.length);
    setState(() {});
  }

  void _addAnimal(String value) {
    final current = animalsController.text.trim();
    final next = current.isEmpty ? value : '$current, $value';
    animalsController.text = next;
    animalsController.selection = TextSelection.collapsed(offset: next.length);
    setState(() {});
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

class _IdeaChip extends StatelessWidget {
  const _IdeaChip(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.accent,
    required this.number,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final Color accent;
  final String number;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: accent.withOpacity(.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(.14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, size: 21, color: accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$number · $title',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
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

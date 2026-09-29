import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/story_generator.dart';
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
  final cityController = TextEditingController();
  final friendsController = TextEditingController();
  final animalsController = TextEditingController();
  bool generating = false;

  @override
  void dispose() {
    protagonistController.dispose();
    settingController.dispose();
    cityController.dispose();
    friendsController.dispose();
    animalsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.account,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthPage())),
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: l10n.premium,
            onPressed: () => _showPremium(context),
            icon: const Icon(Icons.auto_awesome),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _IntroCard(l10n: l10n),
          const SizedBox(height: 20),
          Text(
            l10n.newStory,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _field(l10n.protagonistName, protagonistController, requiredField: true),
          _field(l10n.setting, settingController, requiredField: true),
          _field(l10n.storyCity, cityController, requiredField: true),
          _field(l10n.friends, friendsController, hint: l10n.friendsHint),
          _field(l10n.animalFriends, animalsController),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: generating ? null : _generate,
            icon: generating
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_stories_rounded),
            label: Text(generating ? l10n.creatingStory : l10n.generateStory),
          ),
          const SizedBox(height: 20),
          _PremiumCard(onTap: () => _showPremium(context), l10n: l10n),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: requiredField ? '$label *' : label,
          hintText: hint,
          border: const OutlineInputBorder(),
          filled: true,
        ),
      ),
    );
  }

  Future<void> _generate() async {
    final l10n = AppLocalizations.of(context)!;
    final protagonist = protagonistController.text.trim();
    final setting = settingController.text.trim();
    final city = cityController.text.trim();

    if (protagonist.isEmpty || setting.isEmpty || city.isEmpty) {
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
      final story = await StoryGenerator().generate(
        StoryRequest(
          protagonistName: protagonist,
          setting: setting,
          city: city,
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

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              size: 38,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                l10n.introText,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.4,
                      color:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ),
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
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.premium,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.premiumDescription),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

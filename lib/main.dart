import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: RaccontamelaApp()));
}

class RaccontamelaApp extends StatelessWidget {
  const RaccontamelaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Raccontamela',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const StoryHomePage(),
    );
  }
}

class StoryHomePage extends StatefulWidget {
  const StoryHomePage({super.key});

  @override
  State<StoryHomePage> createState() => _StoryHomePageState();
}

class _StoryHomePageState extends State<StoryHomePage> {
  final protagonistController = TextEditingController();
  final settingController = TextEditingController();
  final cityController = TextEditingController();
  final friendsController = TextEditingController();
  final animalsController = TextEditingController();

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
            tooltip: l10n.premium,
            onPressed: () {},
            icon: const Icon(Icons.auto_awesome),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              l10n.newStory,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            _field(l10n.protagonistName, protagonistController),
            _field(l10n.setting, settingController),
            _field(l10n.storyCity, cityController),
            _field(
              l10n.friends,
              friendsController,
              hint: 'Fino a 4, separati da virgola',
            ),
            _field(l10n.animalFriends, animalsController),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.auto_stories),
              label: Text(l10n.generateStory),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.record_voice_over),
                title: Text(l10n.narration),
                subtitle: const Text('Premium'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.print),
                title: Text(l10n.printColoring),
                subtitle: const Text('Premium'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

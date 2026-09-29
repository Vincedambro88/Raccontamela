import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../data/premium_purchase_service.dart';
import '../../auth/data/device_registration_service.dart';
import '../../auth/presentation/auth_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final premiumPurchaseProvider = ChangeNotifierProvider<PremiumPurchaseService>((ref) {
  final service = PremiumPurchaseService();
  ref.onDispose(service.dispose);
  return service;
});

class PremiumPage extends ConsumerStatefulWidget {
  const PremiumPage({super.key});

  @override
  ConsumerState<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends ConsumerState<PremiumPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_preparePremium);
  }

  Future<void> _preparePremium() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      final signedIn = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const AuthPage()),
      );
      if (signedIn != true || !mounted) return;
    }

    try {
      await DeviceRegistrationService().registerCurrentDevice();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
      return;
    }

    if (mounted) {
      await ref.read(premiumPurchaseProvider).initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final purchase = ref.watch(premiumPurchaseProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.premium)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(
            Icons.auto_awesome,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.premium,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.premiumDescription,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _Feature(icon: Icons.record_voice_over, text: l10n.narration),
          _Feature(icon: Icons.print, text: l10n.printColoring),
          _Feature(icon: Icons.cloud_outlined, text: l10n.history),
          const SizedBox(height: 24),
          if (!purchase.storeAvailable)
            Text(
              l10n.storeUnavailable,
              textAlign: TextAlign.center,
            ),
          if (purchase.error != null) ...[
            const SizedBox(height: 12),
            Text(
              purchase.error!,
              textAlign: TextAlign.center,
            ),
          ],
          FilledButton.icon(
            onPressed: purchase.product == null || purchase.purchasing
                ? null
                : purchase.buyPremium,
            icon: purchase.purchasing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.shopping_bag_outlined),
            label: Text(
              purchase.product?.price ?? l10n.buyPremium,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: purchase.storeAvailable
                ? purchase.restorePurchases
                : null,
            child: Text(l10n.restorePurchase),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.purchaseValidationNotice,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      contentPadding: EdgeInsets.zero,
    );
  }
}

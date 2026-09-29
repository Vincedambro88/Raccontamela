import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PremiumPurchaseService extends ChangeNotifier {
  PremiumPurchaseService({InAppPurchase? store})
      : _store = store ?? InAppPurchase.instance;

  static const premiumProductId = 'raccontamela_premium';

  final InAppPurchase _store;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? product;
  bool storeAvailable = false;
  bool purchasing = false;
  String? error;

  Future<void> initialize() async {
    storeAvailable = await _store.isAvailable();
    notifyListeners();
    if (!storeAvailable) return;

    _subscription ??= _store.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) {
        error = e.toString();
        purchasing = false;
        notifyListeners();
      },
    );

    final response = await _store.queryProductDetails({premiumProductId});
    if (response.error != null) {
      error = response.error!.message;
    } else if (response.productDetails.isNotEmpty) {
      product = response.productDetails.first;
    }
    notifyListeners();
  }

  Future<bool> buyPremium() async {
    final item = product;
    if (item == null || purchasing) return false;

    purchasing = true;
    error = null;
    notifyListeners();

    final param = PurchaseParam(productDetails: item);
    return _store.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() => _store.restorePurchases();

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != premiumProductId) continue;

      if (purchase.status == PurchaseStatus.error) {
        error = purchase.error?.message ?? 'Purchase failed';
        purchasing = false;
        notifyListeners();
        continue;
      }

      if (purchase.status == PurchaseStatus.canceled) {
        purchasing = false;
        notifyListeners();
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Do not grant Premium from the client-side status alone.
        // The next step is server validation against Google Play and
        // persistence of the entitlement in Supabase.
        debugPrint('Purchase received; server validation required.');
        purchasing = false;
        notifyListeners();
      }

      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

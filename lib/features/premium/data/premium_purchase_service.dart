import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PremiumPurchaseService extends ChangeNotifier {
  PremiumPurchaseService({InAppPurchase? store})
      : _store = store ?? InAppPurchase.instance;

  static const premiumProductId = 'raccontamela_premium';

  final InAppPurchase _store;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  ProductDetails? product;
  bool storeAvailable = false;
  bool purchasing = false;
  bool validating = false;
  bool premiumActive = false;
  String? error;

  Future<void> initialize() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      error = 'AUTH_REQUIRED';
      notifyListeners();
      return;
    }

    storeAvailable = await _store.isAvailable();
    notifyListeners();
    if (!storeAvailable) return;

    _subscription ??= _store.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) {
        error = e.toString();
        purchasing = false;
        validating = false;
        notifyListeners();
      },
    );

    final response = await _store.queryProductDetails({premiumProductId});
    if (response.error != null) {
      error = response.error!.message;
    } else if (response.productDetails.isNotEmpty) {
      product = response.productDetails.first;
    }

    await _refreshEntitlement();
    notifyListeners();
  }

  Future<bool> buyPremium() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      error = 'AUTH_REQUIRED';
      notifyListeners();
      return false;
    }

    final item = product;
    if (item == null || purchasing || validating) return false;

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
        validating = false;
        notifyListeners();
        continue;
      }

      if (purchase.status == PurchaseStatus.canceled) {
        purchasing = false;
        validating = false;
        notifyListeners();
        continue;
      }

      if (purchase.status != PurchaseStatus.purchased &&
          purchase.status != PurchaseStatus.restored) {
        continue;
      }

      final serverToken = purchase.verificationData.serverVerificationData;
      if (serverToken.isEmpty) {
        error = 'PURCHASE_TOKEN_MISSING';
        purchasing = false;
        validating = false;
        notifyListeners();
        continue;
      }

      validating = true;
      error = null;
      notifyListeners();

      try {
        final response = await Supabase.instance.client.functions.invoke(
          'validate-google-play-purchase',
          body: {
            'productId': purchase.productID,
            'purchaseToken': serverToken,
          },
        );

        if (response.data is Map && response.data['status'] == 'active') {
          premiumActive = true;
          error = null;
        } else {
          error = 'PURCHASE_VALIDATION_FAILED';
        }
      } catch (e) {
        error = e.toString();
      } finally {
        validating = false;
        purchasing = false;
        notifyListeners();
      }

      if (premiumActive && purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
    }
  }

  Future<void> _refreshEntitlement() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final row = await Supabase.instance.client
        .from('premium_entitlements')
        .select('status')
        .eq('user_id', user.id)
        .maybeSingle();

    premiumActive = row?['status'] == 'active';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

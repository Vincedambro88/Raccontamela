import 'package:supabase_flutter/supabase_flutter.dart';

class PremiumEntitlementRepository {
  PremiumEntitlementRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<bool> hasActivePremium() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final row = await _client
        .from('premium_entitlements')
        .select('status')
        .eq('user_id', user.id)
        .maybeSingle();

    return row?['status'] == 'active';
  }

  Stream<bool> watchPremium() {
    final user = _client.auth.currentUser;
    if (user == null) return Stream.value(false);

    return _client
        .from('premium_entitlements')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', user.id)
        .map((rows) => rows.isNotEmpty && rows.first['status'] == 'active');
  }
}

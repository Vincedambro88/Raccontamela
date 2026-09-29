import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceRegistrationService {
  static const _deviceKey = 'raccontamela.device_id';

  Future<void> registerCurrentDevice() async {
    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) return;

    final preferences = SharedPreferencesAsync();
    var deviceId = await preferences.getString(_deviceKey);
    if (deviceId == null || deviceId.isEmpty) {
      final random = Random.secure();
      final bytes = List<int>.generate(32, (_) => random.nextInt(256));
      deviceId = base64UrlEncode(bytes);
      await preferences.setString(_deviceKey, deviceId);
    }

    final hash = sha256.convert(utf8.encode(deviceId)).toString();
    await client.rpc(
      'register_device',
      params: {
        'p_device_id_hash': hash,
        'p_platform': 'android',
        'p_device_name': 'Android',
      },
    );
  }
}

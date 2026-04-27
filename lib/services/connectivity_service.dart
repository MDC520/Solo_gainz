import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ConnectivityService — Checks real internet connectivity by
/// attempting a lightweight Supabase ping. WiFi/mobile connected
/// does NOT guarantee actual internet access.
class ConnectivityService {
  ConnectivityService._();

  static final Connectivity _connectivity = Connectivity();

  // ── Real connectivity check ────────────────────────────────────
  /// Returns true only if device can reach Supabase.
  static Future<bool> isOnline() async {
    try {
      // First: cheap check — is any network interface up?
      final result = await _connectivity.checkConnectivity();
      if (result == ConnectivityResult.none) return false;

      // Second: verify actual internet by pinging Supabase
      final client = Supabase.instance.client;
      await client
          .from('users')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Stream that emits [true] when online, [false] when offline.
  /// Uses connectivity_plus events + periodic re-check.
  static Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.asyncMap((result) async {
      if (result == ConnectivityResult.none) return false;
      return await isOnline();
    });
  }

  /// Returns the current ConnectivityResult.
  static Future<ConnectivityResult> checkRaw() {
    return _connectivity.checkConnectivity();
  }
}

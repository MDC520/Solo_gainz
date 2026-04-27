import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_stats.dart';
import 'storage.dart';
import 'security_service.dart';
import 'data_serializer.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  late SupabaseClient _supabaseClient;
  Timer? _syncDebounce;

  factory AuthService() => _instance;
  AuthService._internal();

  // ── Supabase credentials ───────────────────────────────────────
  static const _supabaseUrl = 'https://xelqafpkriikivviasfm.supabase.co';
  static const _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhlbHFhZnBrcmlpa2l2dmlhc2ZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcyMDMxNDAsImV4cCI6MjA5Mjc3OTE0MH0.roRtHxgAzM2h9lhQjQ2zCjYQnWbT4NRN7NpzQ3nhqBs';

  Future<void> initialize() async {
    await Supabase.initialize(url: _supabaseUrl, anonKey: _anonKey);
    _supabaseClient = Supabase.instance.client;
  }

  SupabaseClient get client => _supabaseClient;

  // ── Username check ─────────────────────────────────────────────
  Future<bool> checkUsernameExists(String username) async {
    try {
      final response = await _supabaseClient
          .from('users')
          .select('id')
          .eq('username', username.toLowerCase())
          .maybeSingle();
      return response != null;
    } catch (_) {
      return false;
    }
  }

  // ── Sign Up ────────────────────────────────────────────────────
  /// Creates a new user with hashed password + empty data row.
  /// Returns {success, isNewUser, username, country}.
  Future<Map<String, dynamic>> signUp(
      String username, String password, String country) async {
    try {
      if (username.isEmpty) return _fail('Username cannot be empty');
      if (password.length < 6) return _fail('Password must be at least 6 characters');
      if (country.isEmpty) return _fail('Please select a country');

      final lower = username.toLowerCase();

      final existing = await _supabaseClient
          .from('users')
          .select('id')
          .eq('username', lower)
          .maybeSingle();
      if (existing != null) return _fail('Username already taken');

      final hashedPw = SecurityService.hashPassword(password);

      final userRes = await _supabaseClient.from('users').insert({
        'username': lower,
        'password': hashedPw,
        'country': country,
      }).select();
      if (userRes.isEmpty) return _fail('Failed to create user');

      await _supabaseClient.from('user_data').insert({
        'username': lower,
        'data': '{}',
      });

      await SecurityService.storeSecure('current_password', password);

      return {
        'success': true,
        'isNewUser': true,
        'username': lower,
        'country': country,
      };
    } catch (e) {
      return _fail('Error: $e');
    }
  }

  // ── Sign In ────────────────────────────────────────────────────
  /// Authenticates and returns the encrypted data string.
  Future<Map<String, dynamic>> signIn(String username, String password) async {
    try {
      final lower = username.toLowerCase();
      final hashedPw = SecurityService.hashPassword(password);

      final userRow = await _supabaseClient
          .from('users')
          .select('username, country, password')
          .eq('username', lower)
          .maybeSingle();

      if (userRow == null) return _fail('User not found');
      if (userRow['password'] != hashedPw) return _fail('Incorrect password');

      final dataRow = await _supabaseClient
          .from('user_data')
          .select('data')
          .eq('username', lower)
          .maybeSingle();

      final rawData = dataRow?['data'] as String? ?? '{}';

      await SecurityService.storeSecure('current_password', password);

      return {
        'success': true,
        'username': lower,
        'country': userRow['country'] as String? ?? '',
        'data': rawData,
      };
    } catch (e) {
      return _fail('Error: $e');
    }
  }

  // ── Sync (debounced) ───────────────────────────────────────────
  /// Schedules a sync 2 seconds after the last call.
  void scheduleSyncData() {
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(seconds: 2), () async {
      await syncData();
    });
  }

  /// Immediately encodes, encrypts, and uploads all local data.
  Future<void> syncData() async {
    try {
      final username = Storage.getData('current_user');
      if (username == null) return;

      final password = await SecurityService.readSecure('current_password') ?? '';
      final jsonStr = DataSerializer.encodeAllData();
      final encrypted = password.isNotEmpty
          ? SecurityService.encrypt(jsonStr, password)
          : jsonStr;

      await _supabaseClient.from('user_data').upsert({
        'username': username,
        'data': encrypted,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'username');
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  // ── Upload Avatar ──────────────────────────────────────────────
  Future<String?> uploadAvatar(String filePath, String username) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) throw 'File not found';
      final size = await file.length();
      if (size > 2 * 1024 * 1024) throw 'Image too large (max 2MB)';

      final safeName =
          username.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      final fileName =
          '$safeName/v_${DateTime.now().millisecondsSinceEpoch}.png';

      await _supabaseClient.storage.from('avatars').upload(
        fileName,
        file,
        fileOptions:
            const FileOptions(upsert: true, contentType: 'image/png'),
      );
      return _supabaseClient.storage.from('avatars').getPublicUrl(fileName);
    } catch (e) {
      rethrow;
    }
  }

  // ── Logout ────────────────────────────────────────────────────
  Future<void> logout() async {
    _syncDebounce?.cancel();
    await Storage.saveData('is_logged_in', false);
    await Storage.saveData('is_onboarded', false);
    await Storage.saveData('current_user', null);
    await Storage.saveData('current_country', null);
    await Storage.saveUserStats(UserStats());
    await SecurityService.deleteSecure('current_password');
  }

  // ── Update user info ──────────────────────────────────────────
  Future<bool> updateUserInfo(
    String currentUsername, {
    String? newUsername,
    String? newCountry,
    String? newPassword,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (newUsername != null) updates['username'] = newUsername.toLowerCase();
      if (newCountry != null) updates['country'] = newCountry;
      if (newPassword != null) {
        updates['password'] = SecurityService.hashPassword(newPassword);
        await SecurityService.storeSecure('current_password', newPassword);
      }
      if (updates.isNotEmpty) {
        await _supabaseClient
            .from('users')
            .update(updates)
            .eq('username', currentUsername.toLowerCase());
        if (newUsername != null) {
          try {
            await _supabaseClient
                .from('user_data')
                .update({'username': newUsername.toLowerCase()})
                .eq('username', currentUsername.toLowerCase());
          } catch (_) {}
          await Storage.saveData('current_user', newUsername.toLowerCase());
        }
        if (newCountry != null) {
          await Storage.saveData('current_country', newCountry);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Account creation time ─────────────────────────────────────
  Future<String?> getAccountCreatedAt(String username) async {
    try {
      final r = await _supabaseClient
          .from('users')
          .select('created_at')
          .eq('username', username.toLowerCase())
          .maybeSingle();
      return r?['created_at']?.toString();
    } catch (_) {
      return null;
    }
  }

  // ── Helper ────────────────────────────────────────────────────
  Map<String, dynamic> _fail(String msg) =>
      {'success': false, 'message': msg};
}

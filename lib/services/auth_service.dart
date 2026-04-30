import 'dart:async';
import 'package:flutter/foundation.dart';
// import '../models/user_stats.dart';
// import 'data_serializer.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  // late SupabaseClient _supabaseClient;
  // Timer? _syncDebounce;

  factory AuthService() => _instance;
  AuthService._internal();

  // ── Supabase credentials ───────────────────────────────────────
  static const _supabaseUrl = 'https://xelqafpkriikivviasfm.supabase.co';
  static const _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhlbHFhZnBrcmlpa2l2dmlhc2ZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcyMDMxNDAsImV4cCI6MjA5Mjc3OTE0MH0.roRtHxgAzM2h9lhQjQ2zCjYQnWbT4NRN7NpzQ3nhqBs';

  Future<void> initialize() async {
    // await Supabase.initialize(url: _supabaseUrl, anonKey: _anonKey);
    // _supabaseClient = Supabase.instance.client;
    debugPrint('Supabase disabled');
  }

  // SupabaseClient get client => _supabaseClient;

  // ── Username check ─────────────────────────────────────────────
  Future<bool> checkUsernameExists(String username) async {
    return false;
  }

  // ── Sign Up ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> signUp(
      String username, String password, String country) async {
    return {
      'success': true,
      'isNewUser': true,
      'username': 'Player',
      'country': country,
    };
  }

  // ── Sign In ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> signIn(String username, String password) async {
    return {
      'success': true,
      'username': 'Player',
      'country': 'World',
      'data': '{}',
    };
  }

  // ── Sync (debounced) ───────────────────────────────────────────
  void scheduleSyncData() {
    // Disabled
  }

  Future<void> syncData() async {
    // Disabled
  }

  // ── Upload Avatar ──────────────────────────────────────────────
  Future<String?> uploadAvatar(String filePath, String username) async {
    return null;
  }

  // ── Logout ────────────────────────────────────────────────────
  Future<void> logout() async {
    // Disabled
  }

  // ── Update user info ──────────────────────────────────────────
  Future<bool> updateUserInfo(
    String currentUsername, {
    String? newUsername,
    String? newCountry,
    String? newPassword,
  }) async {
    return true;
  }

  // ── Account creation time ─────────────────────────────────────
  Future<String?> getAccountCreatedAt(String username) async {
    return DateTime.now().toIso8601String();
  }

  // ── Helper ────────────────────────────────────────────────────
  Map<String, dynamic> _fail(String msg) =>
      {'success': false, 'message': msg};
}

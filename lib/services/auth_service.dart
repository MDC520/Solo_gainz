import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'storage.dart';
import '../models/user_stats.dart';


class AuthService {
  static final AuthService _instance = AuthService._internal();
  late SupabaseClient _supabaseClient;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://tulbevwmqhrxjjtuehmy.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR1bGJldndtcWhyeGpqdHVlaG15Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU0NDk3NDIsImV4cCI6MjA5MTAyNTc0Mn0.5Q0rgPjIuvlE27yPPRmXp3nDPofimvS3BXP9PqSpsgQ',
    );
    _supabaseClient = Supabase.instance.client;
  }

  SupabaseClient get client => _supabaseClient;

  // Upload avatar to Supabase Storage
  Future<String?> uploadAvatar(String filePath, String username) async {
    if (username == 'Player') return null; // Skip for default local user
    try {
      final file = File(filePath);
      if (!await file.exists()) throw 'File not found at $filePath';

      // 1MB = 1,048,576 bytes
      final size = await file.length();
      if (size > 2 * 1024 * 1024) {
        throw 'Image is too large (${(size / 1024 / 1024).toStringAsFixed(2)}MB). Max 2MB allowed.';
      }

      final safeName = username.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      final fileName = '$safeName/v_${DateTime.now().millisecondsSinceEpoch}.png';
      
      print('Uploading to avatars/$fileName...');

      // 1. Upload file
      await _supabaseClient.storage.from('avatars').upload(
        fileName, 
        file,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/png'),
      );

      // 2. Get Public URL
      final publicUrl = _supabaseClient.storage.from('avatars').getPublicUrl(fileName);
      
      // 3. Update database
      await _supabaseClient
          .from('user_data')
          .update({'avatar_url': publicUrl})
          .eq('username', username.toLowerCase());

      return publicUrl;
    } catch (e) {
      print('Upload Error: $e');
      rethrow;
    }
  }

  // Check if username exists in database
  Future<bool> checkUsernameExists(String username) async {
    try {
      final response = await _supabaseClient
          .from('users')
          .select()
          .eq('username', username.toLowerCase())
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking username: $e');
      return false;
    }
  }

  // Sign in
  Future<Map<String, dynamic>> signIn(
      String username, String password) async {
    try {
      final response = await _supabaseClient
          .from('users')
          .select()
          .eq('username', username.toLowerCase())
          .maybeSingle();

      if (response == null) {
        return {'success': false, 'message': 'User not found'};
      }

      if (response['password'] != password) {
        return {'success': false, 'message': 'Incorrect password'};
      }

      // Storage will be updated in login screen finalize

      // Fetch user data
      final userData = await _supabaseClient
          .from('user_data')
          .select()
          .eq('username', username.toLowerCase())
          .maybeSingle();

      if (userData != null) {
        return {
          'success': true,
          'message': 'Login successful',
          'user': {
            'username': username.toLowerCase(),
            'country': response['country'],
            'avatar_url': userData['avatar_url'],
            'coins': userData['coins'],
            'progress': userData['progress'],
            'stats': userData, 
          }
        };
      }

      return {'success': true, 'message': 'Login successful'};
    } catch (e) {
      print('SignIn Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Sign up
  Future<Map<String, dynamic>> signUp(
      String username, String password, String country) async {
    try {
      // Validate inputs
      if (username.isEmpty) {
        return {'success': false, 'message': 'Username cannot be empty'};
      }
      if (password.length < 6) {
        return {
          'success': false,
          'message': 'Password must be at least 6 characters'
        };
      }
      if (country.isEmpty) {
        return {'success': false, 'message': 'Please select a country'};
      }

      // Check if username exists
      final existingUser = await _supabaseClient
          .from('users')
          .select()
          .eq('username', username.toLowerCase())
          .maybeSingle();

      if (existingUser != null) {
        return {'success': false, 'message': 'Username already exists'};
      }

      // Create user in users table
      final userResponse = await _supabaseClient.from('users').insert({
        'username': username.toLowerCase(),
        'password': password,
        'country': country,
      }).select();

      if (userResponse.isEmpty) {
        return {'success': false, 'message': 'Failed to create user'};
      }

      // Create user data in user_data table
      await _supabaseClient.from('user_data').insert({
        'username': username.toLowerCase(),
        'coins': 0,
        'progress': 0,
      });

      // Storage will be updated in login screen finalize

      return {
        'success': true,
        'message': 'Account created successfully',
        'user': {
          'username': username.toLowerCase(),
          'country': country,
          'avatar_url': null,
          'coins': 0,
          'progress': 0,
        }
      };
    } catch (e) {
      print('SignUp Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Sync data with database
  Future<void> syncData() async {
    try {
      final username = Storage.getData('current_user');
      if (username == null) return;

      final stats = Storage.getUserStats();
      final avatarUrl = Storage.getData('profile_image_path'); 

      await _supabaseClient.from('user_data').update({
        'coins': stats.coins,
        'progress': stats.progress,
        'rank': stats.rank,
        'level': stats.level,
        'xp': stats.xp,
        if (avatarUrl != null && avatarUrl.startsWith('http')) 'avatar_url': avatarUrl,
        'last_synced': DateTime.now().toIso8601String(),
      }).eq('username', username);
    } catch (e) {
      print('Error syncing data: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    await Storage.saveData('is_logged_in', false);
    await Storage.saveData('current_user', null);
    await Storage.saveData('current_country', null);
    // Reset UserStats to defaults
    await Storage.saveUserStats(UserStats());
    // Also clear individual keys if they were used redundantly
    await Storage.deleteData('coins');
    await Storage.deleteData('progress');
  }

  // Update user information
  Future<bool> updateUserInfo(String currentUsername, {String? newUsername, String? newCountry, String? newPassword}) async {
    if (currentUsername == 'Player') {
      // Handle local updates
      if (newUsername != null) await Storage.saveData('current_user', newUsername);
      if (newCountry != null) await Storage.saveData('current_country', newCountry);
      return true;
    }
    try {
      final updates = <String, dynamic>{};
      if (newUsername != null) updates['username'] = newUsername.toLowerCase();
      if (newCountry != null) updates['country'] = newCountry;
      if (newPassword != null) updates['password'] = newPassword;

      if (updates.isNotEmpty) {
        // Update users table
        await _supabaseClient.from('users').update(updates).eq('username', currentUsername.toLowerCase());
        
        // Also update user_data table if username changed and didn't cascade
        if (newUsername != null) {
          try {
            await _supabaseClient.from('user_data').update({'username': newUsername.toLowerCase()}).eq('username', currentUsername.toLowerCase());
          } catch (_) {}
          await Storage.saveData('current_user', newUsername.toLowerCase());
        }
        if (newCountry != null) {
          await Storage.saveData('current_country', newCountry);
        }
      }
      return true;
    } catch (e) {
      print('Update error: $e');
      return false;
    }
  }

  // Get account creation time
  Future<String?> getAccountCreatedAt(String username) async {
    try {
      final response = await _supabaseClient.from('users').select('created_at').eq('username', username.toLowerCase()).maybeSingle();
      if (response != null && response['created_at'] != null) {
        return response['created_at'].toString();
      }
    } catch (e) {
      print('Get created_at error: $e');
    }
    return null;
  }
}

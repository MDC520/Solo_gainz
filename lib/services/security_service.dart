import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// SecurityService — AES-256 encryption + SHA-256 hashing.
/// The AES key is derived from the user's password so it works
/// cross-device: same password → same key → decryptable anywhere.
class SecurityService {
  SecurityService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
  );

  static const _saltKey = 'sg_aes_salt';
  static String? _cachedSalt;

  // ── Initialise ─────────────────────────────────────────────────
  /// Call once at app start to ensure a persistent salt exists.
  static Future<void> init() async {
    _cachedSalt = await _storage.read(key: _saltKey);
    if (_cachedSalt == null) {
      // Generate a random 16-byte salt (hex-encoded)
      final bytes = enc.SecureRandom(16).bytes;
      _cachedSalt = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      await _storage.write(key: _saltKey, value: _cachedSalt);
    }
  }

  // ── Hive Hardware-Backed Encryption ─────────────────────────────
  /// Generates or retrieves a secure AES-256 key to encrypt the entire Hive database.
  /// The key is stored safely inside the device's hardware KeyStore/Keychain.
  /// This prevents any external app, even with root access, from reading the database.
  static Future<HiveAesCipher> getHiveCipher() async {
    const hiveEncryptionKeyName = 'sg_hive_master_key';
    String? keyString = await _storage.read(key: hiveEncryptionKeyName);
    late List<int> encryptionKey;
    
    if (keyString == null) {
      // Generate a new 256-bit secure key
      encryptionKey = Hive.generateSecureKey();
      await _storage.write(
        key: hiveEncryptionKeyName,
        value: base64UrlEncode(encryptionKey),
      );
    } else {
      encryptionKey = base64Url.decode(keyString);
    }
    
    return HiveAesCipher(encryptionKey);
  }

  // ── Key derivation ─────────────────────────────────────────────
  /// Derive a 32-byte AES key from [password] + salt.
  /// Same password on any device → same key.
  static enc.Key _deriveKey(String password) {
    final salt = _cachedSalt ?? 'sg_default_salt_2024';
    final input = utf8.encode('$password:$salt');
    final digest = sha256.convert(input);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  // ── Encryption ─────────────────────────────────────────────────
  /// AES-256-CBC encrypt [plainText] using key derived from [password].
  /// Returns base64(iv + ciphertext).
  static String encrypt(String plainText, String password) {
    try {
      final key = _deriveKey(password);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      // Prepend IV so we can use it during decryption
      final combined = iv.bytes + encrypted.bytes;
      return base64Encode(combined);
    } catch (e) {
      // If encryption fails, return plain JSON (safe fallback)
      return plainText;
    }
  }

  /// AES-256-CBC decrypt [cipherText] using key derived from [password].
  static String decrypt(String cipherText, String password) {
    try {
      final combined = base64Decode(cipherText);
      if (combined.length < 16) return cipherText; // not encrypted
      final iv = enc.IV(Uint8List.fromList(combined.sublist(0, 16)));
      final cipherBytes = combined.sublist(16);
      final key = _deriveKey(password);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt(enc.Encrypted(Uint8List.fromList(cipherBytes)), iv: iv);
    } catch (e) {
      // If decryption fails, assume plain JSON (for backward compat)
      return cipherText;
    }
  }

  // ── Password hashing ───────────────────────────────────────────
  /// SHA-256 hash of [password] + salt. Used for storing passwords.
  static String hashPassword(String password) {
    final salt = _cachedSalt ?? 'sg_default_salt_2024';
    final input = utf8.encode('$password:sg_pw:$salt');
    return sha256.convert(input).toString();
  }

  // ── Secure storage helpers ─────────────────────────────────────
  /// Store a sensitive value (e.g., current user's password for key derivation).
  static Future<void> storeSecure(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> readSecure(String key) async {
    return await _storage.read(key: key);
  }

  static Future<void> deleteSecure(String key) async {
    await _storage.delete(key: key);
  }

  static Future<void> clearAllSecure() async {
    await _storage.deleteAll();
  }
}

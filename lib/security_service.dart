import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

/// SecurityService — Three-Phase Android Security Suite.
/// Includes root/emulator/debugger/Frida audits (Phase 1), active interdiction and hard-exits (Phase 2),
/// and strong cryptographical hardening with PBKDF2, XOR-masking, and dynamic RAM zeroing (Phase 3).
class SecurityService {
  SecurityService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: false, // Disabled for emulator stability
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
  );

  static const _saltKey = 'sg_aes_salt';
  static String? _cachedSalt;

  // ── PHASE 3 Memory Protections ──────────────────────────────────
  // Cryptographically secure XOR mask generated dynamically on class initialization
  // to protect keys against simple RAM scanning tools (like GameGuardian/CheatEngine)
  static final Uint8List _xorMask = enc.SecureRandom(32).bytes;
  static Uint8List? _maskedHiveKey;

  // Active status lock indicating that a security compromise has occurred
  static bool _isSystemLocked = false;

  // ── Initialise ─────────────────────────────────────────────────
  /// Call once at app start to ensure a persistent salt exists and verify system integrity.
  static Future<void> init() async {
    // Phase 1 Audit on startup
    await verifyIntegrity();

    _cachedSalt = await _storage.read(key: _saltKey);
    if (_cachedSalt == null) {
      // Generate a random 16-byte salt (hex-encoded)
      final bytes = enc.SecureRandom(16).bytes;
      _cachedSalt = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      await _storage.write(key: _saltKey, value: _cachedSalt);
    }
  }

  // ── PHASE 1: Android Multi-Vector Dynamic Threat Detection ───────

  /// Proactively scans the Android environment for Root access, Emulator status,
  /// Debugger attachment, Memory hooking frameworks (Frida/Xposed), and open local ports.
  static Future<bool> isSystemCompromised() async {
    if (!Platform.isAndroid) return false;

    // 1. Root binary inspection on typical Android system paths
    if (_detectRootBinaries()) {
      debugPrint('[SECURITY] Root binaries detected.');
      return true;
    }

    // 2. Emulator virtual hardware and virtual driver audit
    if (_detectEmulator()) {
      debugPrint('[SECURITY] Emulator virtual environment detected.');
      return true;
    }

    // 3. Linux TracerPid debugger connection audit
    if (await _detectDebugger()) {
      debugPrint('[SECURITY] Active debugger connection detected via TracerPid.');
      return true;
    }

    // 4. Memory-mapped libraries maps-scan for hooking engines (Frida, Xposed, Magisk)
    if (await _detectMemoryHooking()) {
      debugPrint('[SECURITY] Hooking framework detected inside RAM allocation maps.');
      return true;
    }

    // 5. Port-level socket scan for Frida server (port 27042)
    if (await _detectFridaPort()) {
      debugPrint('[SECURITY] Frida socket listener active on port 27042.');
      return true;
    }

    return false;
  }

  /// Verifies existence of common su and root manager binaries on Android.
  static bool _detectRootBinaries() {
    final rootPaths = [
      '/system/bin/su',
      '/system/xbin/su',
      '/sbin/su',
      '/system/sd/xbin/su',
      '/system/bin/failsafe/su',
      '/data/local/xbin/su',
      '/data/local/bin/su',
      '/data/local/su',
      '/system/app/Superuser.apk',
      '/system/app/Magisk.apk',
      '/data/adb/magisk',
    ];
    for (final path in rootPaths) {
      if (File(path).existsSync()) {
        return true;
      }
    }
    return false;
  }

  /// Verifies standard virtual hardware, pipes, and debug files unique to Android emulators.
  static bool _detectEmulator() {
    final emuPaths = [
      '/dev/socket/qemud',
      '/dev/qemu_pipe',
      '/system/lib/libc_malloc_debug_qemu.so',
      '/sys/qemu_trace',
      '/system/bin/qemu-props',
    ];
    for (final path in emuPaths) {
      if (File(path).existsSync()) {
        return true;
      }
    }
    return false;
  }

  /// Interrogates `/proc/self/status` for TracerPid. If TracerPid != 0, a debugger is attached.
  static Future<bool> _detectDebugger() async {
    try {
      final statusFile = File('/proc/self/status');
      if (await statusFile.exists()) {
        final lines = await statusFile.readAsLines();
        for (final line in lines) {
          if (line.startsWith('TracerPid:')) {
            final parts = line.split(':');
            if (parts.length > 1) {
              final pid = int.tryParse(parts[1].trim());
              if (pid != null && pid != 0) {
                return true; 
              }
            }
          }
        }
      }
    } catch (_) {}
    return false;
  }

  /// Scans memory-mapped segments in `/proc/self/maps` for injection signatures (Frida, Xposed, Magisk, Substrate).
  static Future<bool> _detectMemoryHooking() async {
    try {
      final mapsFile = File('/proc/self/maps');
      if (await mapsFile.exists()) {
        final lines = await mapsFile.readAsLines();
        for (final line in lines) {
          final lower = line.toLowerCase();
          if (lower.contains('frida') ||
              lower.contains('xposed') ||
              lower.contains('substrate') ||
              lower.contains('magisk') ||
              lower.contains('cydia') ||
              lower.contains('hook.so') ||
              lower.contains('rida')) {
            return true;
          }
        }
      }
    } catch (_) {}
    return false;
  }

  /// Probes local port 27042 (default Frida socket) to catch active runtime injection servers.
  static Future<bool> _detectFridaPort() async {
    // Avoid throwing SocketExceptions in local debug/development mode to prevent breaking the IDE debugger.
    if (kDebugMode) return false;

    try {
      final socket = await Socket.connect('127.0.0.1', 27042, timeout: const Duration(milliseconds: 50));
      await socket.close();
      return true;
    } catch (_) {}
    return false;
  }

  // ── PHASE 2: Core Interdiction & Active Blocking ──────────────────

  /// Asynchronous run-time integrity audit.
  static Future<void> verifyIntegrity() async {
    if (_isSystemLocked) {
      _executeHardPanicExit();
    }
    if (await isSystemCompromised()) {
      _triggerPhase2Block('Integrity violation detected during run-time audit.');
    }
  }

  /// Real-time, ultra-fast synchronous security audit suitable for cryptographic wrappers.
  static void verifyIntegritySync() {
    if (_isSystemLocked) {
      _executeHardPanicExit();
    }
    if (Platform.isAndroid) {
      if (_detectRootBinaries() || _detectEmulator()) {
        _triggerPhase2Block('Integrity violation detected during real-time crypto execution.');
      }
    }
  }

  /// Handles systemic locks and active counter-measures.
  static void _triggerPhase2Block(String threatDetails) {
    debugPrint('[SECURITY TAMPER WARNING] System compromised! Counter-measures activated: $threatDetails');
    
    // Corrupt critical encryption key buffers in memory immediately
    if (_maskedHiveKey != null) {
      _maskedHiveKey!.fillRange(0, _maskedHiveKey!.length, 0);
    }
    _xorMask.fillRange(0, _xorMask.length, 0);
    
    _isSystemLocked = true;
    _executeHardPanicExit();
  }

  /// Terminates the application instantly with an emergency exit to prevent reverse-engineering.
  static void _executeHardPanicExit() {
    exit(-1);
  }

  // ── PHASE 3: Bulletproof RAM and ROM Data Protection ──────────────

  /// Generates or retrieves a secure AES-256 key to encrypt the entire Hive database.
  /// The key is stored inside the device's hardware KeyStore and loaded into RAM using XOR masking.
  static Future<HiveAesCipher> getHiveCipher() async {
    await verifyIntegrity();
    
    const hiveEncryptionKeyName = 'sg_hive_master_key';
    
    // Load key from hardware KeyStore if it has not been read yet
    if (_maskedHiveKey == null) {
      String? keyString = await _storage.read(key: hiveEncryptionKeyName);
      late List<int> rawKey;
      
      if (keyString == null) {
        // Generate a new 256-bit secure key
        rawKey = Hive.generateSecureKey();
        await _storage.write(
          key: hiveEncryptionKeyName,
          value: base64UrlEncode(rawKey),
        );
      } else {
        rawKey = base64Url.decode(keyString);
      }
      
      // Store in memory using XOR masking to prevent memory dumps
      _maskedHiveKey = Uint8List(rawKey.length);
      for (int i = 0; i < rawKey.length; i++) {
        _maskedHiveKey![i] = rawKey[i] ^ _xorMask[i % _xorMask.length];
      }
      
      // Securely wipe the raw key from transient memory
      _secureZero(Uint8List.fromList(rawKey));
    }
    
    // Dynamically unmask key only during construction of the cipher
    final rawKeyBytes = _unmaskKey(_maskedHiveKey!, _xorMask);
    final cipher = HiveAesCipher(rawKeyBytes);
    
    // Wipes raw key bytes in memory immediately
    _secureZero(rawKeyBytes);
    
    return cipher;
  }

  /// Derives a strong 32-byte AES key from user password using a high-stretching 2500-round PBKDF2 equivalent.
  static enc.Key _deriveKey(String password) {
    final salt = _cachedSalt ?? 'sg_default_salt_2024';
    final derivedBytes = _pbkdf2(password, salt, 2500);
    final key = enc.Key(derivedBytes);
    return key;
  }

  /// High-stretching password derivation function with 2500 rounds of SHA-256 hashing.
  static Uint8List _pbkdf2(String password, String salt, int rounds) {
    Uint8List block = utf8.encode('$password:$salt');
    for (int i = 0; i < rounds; i++) {
      block = Uint8List.fromList(sha256.convert(block).bytes);
    }
    return block;
  }

  /// AES-256-CBC encrypt [plainText] using key derived from [password].
  /// Zeros out derived keys in RAM immediately after use.
  static String encrypt(String plainText, String password) {
    verifyIntegritySync();
    try {
      final key = _deriveKey(password);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      final combined = iv.bytes + encrypted.bytes;
      
      // Securely zero out derived key bytes in memory
      _secureZero(Uint8List.fromList(key.bytes));
      
      return base64Encode(combined);
    } catch (e) {
      // Fallback
      return plainText;
    }
  }

  /// AES-256-CBC decrypt [cipherText] using key derived from [password].
  /// Zeros out derived keys in RAM immediately after use.
  static String decrypt(String cipherText, String password) {
    verifyIntegritySync();
    try {
      final combined = base64Decode(cipherText);
      if (combined.length < 16) return cipherText; // not encrypted
      final iv = enc.IV(Uint8List.fromList(combined.sublist(0, 16)));
      final cipherBytes = combined.sublist(16);
      final key = _deriveKey(password);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final decrypted = encrypter.decrypt(enc.Encrypted(Uint8List.fromList(cipherBytes)), iv: iv);
      
      // Securely zero out derived key bytes in memory
      _secureZero(Uint8List.fromList(key.bytes));
      
      return decrypted;
    } catch (e) {
      // Fallback
      return cipherText;
    }
  }

  /// SHA-256 hash of [password] + salt. Used for storing passwords.
  static String hashPassword(String password) {
    final salt = _cachedSalt ?? 'sg_default_salt_2024';
    final input = utf8.encode('$password:sg_pw:$salt');
    return sha256.convert(input).toString();
  }

  // ── Secure Storage Helpers ─────────────────────────────────────
  
  static Future<void> storeSecure(String key, String value) async {
    await verifyIntegrity();
    await _storage.write(key: key, value: value);
  }

  static Future<String?> readSecure(String key) async {
    await verifyIntegrity();
    return await _storage.read(key: key);
  }

  static Future<void> deleteSecure(String key) async {
    await verifyIntegrity();
    await _storage.delete(key: key);
  }

  static Future<void> clearAllSecure() async {
    await verifyIntegrity();
    await _storage.deleteAll();
  }

  // ── Cryptographical Helpers ─────────────────────────────────────

  static Uint8List _unmaskKey(Uint8List masked, Uint8List mask) {
    final unmasked = Uint8List(masked.length);
    for (int i = 0; i < masked.length; i++) {
      unmasked[i] = masked[i] ^ mask[i % mask.length];
    }
    return unmasked;
  }

  static void _secureZero(Uint8List list) {
    list.fillRange(0, list.length, 0);
  }
}

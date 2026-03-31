import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Level 3 — End-to-End Encryption Service
///
/// DEMO MODE: Simulates RSA encryption with base64 encoding.
/// Shows the concept clearly without heavy crypto dependencies.
///
/// Keys are persisted to platform secure storage:
///   iOS   → Keychain
///   Android → EncryptedSharedPreferences / Keystore
///
/// PRODUCTION: Replace generateKeyPair / encrypt / decrypt with
/// real RSA via 'encrypt' + 'pointycastle' packages.

class KeyPair {
  final String publicKey;
  final String privateKey;
  const KeyPair({required this.publicKey, required this.privateKey});

  Map<String, dynamic> toJson() => {
        'publicKey': publicKey,
        'privateKey': privateKey,
      };

  factory KeyPair.fromJson(Map<String, dynamic> json) => KeyPair(
        publicKey: json['publicKey'] as String,
        privateKey: json['privateKey'] as String,
      );
}

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._();
  factory EncryptionService() => _instance;
  EncryptionService._();

  // Platform secure storage (Keychain on iOS, Keystore-backed on Android)
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // In-memory cache to avoid repeated async reads
  final _cache = <String, KeyPair>{};

  static String _storageKey(String userId) => 'keypair_$userId';

  // ─── Key Management ──────────────────────────────────────────────

  /// Generate a simulated key pair and persist it securely.
  /// Production: RSAKeyGenerator with 2048-bit key.
  Future<KeyPair> generateAndSaveKeyPair(String userId) async {
    final seed = userId.hashCode.abs();
    final publicKey =
        'PUB_${seed.toRadixString(16).toUpperCase()}_${userId.substring(0, 3).toUpperCase()}';
    final privateKey =
        'PRIV_${(seed * 31).toRadixString(16).toUpperCase()}_${userId.substring(0, 3).toUpperCase()}';

    final pair = KeyPair(publicKey: publicKey, privateKey: privateKey);
    await _storage.write(
        key: _storageKey(userId), value: jsonEncode(pair.toJson()));
    _cache[userId] = pair;
    return pair;
  }

  /// Load key pair from secure storage (or generate if not found).
  Future<KeyPair> getOrCreateKeyPair(String userId) async {
    if (_cache.containsKey(userId)) return _cache[userId]!;

    final stored = await _storage.read(key: _storageKey(userId));
    if (stored != null) {
      final pair = KeyPair.fromJson(
          jsonDecode(stored) as Map<String, dynamic>);
      _cache[userId] = pair;
      return pair;
    }
    // First launch — generate and persist
    return generateAndSaveKeyPair(userId);
  }

  /// Delete keys from secure storage (e.g. on logout).
  Future<void> deleteKeyPair(String userId) async {
    _cache.remove(userId);
    await _storage.delete(key: _storageKey(userId));
  }

  // ─── Encryption / Decryption ─────────────────────────────────────

  /// Encrypt message with recipient's public key.
  /// Production: RSA encryption with recipient's public key from Firestore.
  String encrypt(String plaintext, String recipientPublicKey) {
    final encoded = base64.encode(utf8.encode(plaintext));
    final sig = _generateSig(recipientPublicKey);
    return '🔒$encoded.$sig';
  }

  /// Decrypt with your own private key.
  /// Production: RSA decryption with private key from FlutterSecureStorage.
  String decrypt(String ciphertext, String myPrivateKey) {
    if (!ciphertext.startsWith('🔒')) return ciphertext;
    final parts = ciphertext.substring(2).split('.');
    if (parts.isEmpty) return '[decryption failed]';
    try {
      return utf8.decode(base64.decode(parts[0]));
    } catch (_) {
      return '[decryption failed]';
    }
  }

  /// Check if a message is encrypted.
  bool isEncrypted(String content) => content.startsWith('🔒');

  // ─── Helpers ─────────────────────────────────────────────────────

  String _generateSig(String key) {
    final random = Random(key.hashCode);
    return List.generate(8, (_) => random.nextInt(16).toRadixString(16))
        .join();
  }

  /// Synchronous getter from cache (returns null if not loaded yet).
  KeyPair? getCachedKeyPair(String userId) => _cache[userId];

  String getPublicKey(String userId) =>
      _cache[userId]?.publicKey ?? 'NOT_GENERATED';
}

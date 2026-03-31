import 'dart:convert';
import 'dart:math';

/// Level 3 — End-to-End Encryption Service
///
/// DEMO MODE: Simulates RSA encryption with base64 encoding.
/// Shows the concept clearly without heavy crypto dependencies.
///
/// PRODUCTION: Use 'encrypt' + 'pointycastle' packages:
/// ```dart
/// import 'package:encrypt/encrypt.dart';
/// import 'package:pointycastle/export.dart';
/// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
///
/// class EncryptionService {
///   static const _storage = FlutterSecureStorage();
///
///   // Generate RSA key pair on first launch
///   static KeyPair generateKeyPair() {
///     final keyGen = RSAKeyGenerator()
///       ..init(ParametersWithRandom(
///         RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
///         SecureRandom('Fortuna')..seed(KeyParameter(
///             Uint8List.fromList(List.generate(32, (_) => Random.secure().nextInt(256))))),
///       ));
///     return keyGen.generateKeyPair();
///   }
///
///   // Encrypt with recipient's PUBLIC key (stored in Firestore)
///   static String encrypt(String plaintext, RSAPublicKey publicKey) {
///     final encrypter = Encrypter(RSA(publicKey: publicKey));
///     return encrypter.encrypt(plaintext).base64;
///   }
///
///   // Decrypt with YOUR PRIVATE key (stored in FlutterSecureStorage)
///   static String decrypt(String ciphertext, RSAPrivateKey privateKey) {
///     final encrypter = Encrypter(RSA(privateKey: privateKey));
///     return encrypter.decrypt64(ciphertext);
///   }
///
///   // Save private key to Keychain (iOS) / Keystore (Android)
///   static Future<void> savePrivateKey(String key) =>
///       _storage.write(key: 'private_key', value: key);
///
///   // Never send private key to server!
///   static Future<String?> getPrivateKey() =>
///       _storage.read(key: 'private_key');
/// }
/// ```

class KeyPair {
  final String publicKey;
  final String privateKey;
  const KeyPair({required this.publicKey, required this.privateKey});
}

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._();
  factory EncryptionService() => _instance;
  EncryptionService._();

  // Simulated key storage (production: FlutterSecureStorage)
  final _keyStore = <String, KeyPair>{};

  /// Generate a simulated key pair for a user.
  /// Production: RSAKeyGenerator with 2048-bit key
  KeyPair generateKeyPair(String userId) {
    // Simulate asymmetric key generation
    final seed = userId.hashCode.abs();
    final publicKey = 'PUB_${seed.toRadixString(16).toUpperCase()}_${userId.substring(0, 3).toUpperCase()}';
    final privateKey = 'PRIV_${(seed * 31).toRadixString(16).toUpperCase()}_${userId.substring(0, 3).toUpperCase()}';

    final pair = KeyPair(publicKey: publicKey, privateKey: privateKey);
    _keyStore[userId] = pair;
    return pair;
  }

  /// Encrypt message with recipient's public key.
  /// Production: RSA encryption with recipient's public key from Firestore
  String encrypt(String plaintext, String recipientPublicKey) {
    // Simulate encryption: base64(plaintext) + signature
    final encoded = base64.encode(utf8.encode(plaintext));
    final sig = _generateSig(recipientPublicKey);
    return '🔒$encoded.$sig';
  }

  /// Decrypt with your own private key.
  /// Production: RSA decryption with private key from FlutterSecureStorage
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

  String _generateSig(String key) {
    final random = Random(key.hashCode);
    return List.generate(8, (_) => random.nextInt(16).toRadixString(16))
        .join();
  }

  KeyPair? getKeyPair(String userId) => _keyStore[userId];

  String getPublicKey(String userId) =>
      _keyStore[userId]?.publicKey ?? 'NOT_GENERATED';
}

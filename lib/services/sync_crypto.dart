import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class SyncCrypto {
  static final _gcm = AesGcm.with256bits();

  /// Generates a cryptographically secure 256-bit (32-byte) key.
  static Uint8List generateSecret() {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(32, (_) => random.nextInt(256)));
  }

  /// Generates a random session token (32 bytes) for one-time pairing use.
  static String generateSessionToken() {
    final bytes = generateSecret();
    return _toHex(bytes);
  }

  /// AES-256-GCM encrypt. Output format: nonce(12) ++ ciphertext ++ mac(16).
  static Future<Uint8List> encrypt(Uint8List key, Uint8List plaintext) async {
    final secretKey = SecretKey(key);
    final secretBox = await _gcm.encrypt(plaintext, secretKey: secretKey);
    final nonce = secretBox.nonce;
    final cipher = secretBox.cipherText;
    final mac = secretBox.mac.bytes;
    final out = Uint8List(12 + cipher.length + 16);
    out.setAll(0, nonce);
    out.setAll(12, cipher);
    out.setAll(12 + cipher.length, mac);
    return out;
  }

  /// AES-256-GCM decrypt. Throws if authentication tag is invalid.
  static Future<Uint8List> decrypt(Uint8List key, Uint8List packed) async {
    if (packed.length < 28) throw ArgumentError('Ciphertext too short');
    final secretKey = SecretKey(key);
    final nonce = packed.sublist(0, 12);
    final cipherText = packed.sublist(12, packed.length - 16);
    final mac = Mac(packed.sublist(packed.length - 16));
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
    final plaintext = await _gcm.decrypt(secretBox, secretKey: secretKey);
    return Uint8List.fromList(plaintext);
  }

  static String _toHex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

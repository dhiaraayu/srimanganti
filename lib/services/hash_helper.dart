import 'package:crypto/crypto.dart';
import 'dart:convert';

class HashHelper {
  // Fungsi untuk mengubah password jadi hash SHA-256
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
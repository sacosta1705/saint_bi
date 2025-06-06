import 'dart:convert';
import 'package:crypto/crypto.dart';

class SecurityService {
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool verifyPassword(String password, String hashedPassword) {
    final newHash = hashPassword(password);
    return newHash == hashedPassword;
  }
}

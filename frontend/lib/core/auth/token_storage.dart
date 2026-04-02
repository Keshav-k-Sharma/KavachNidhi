import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _keyAccessToken = 'access_token';
  static const String _keyUserId = 'user_id';

  final FlutterSecureStorage _storage;

  Future<void> saveSession({
    required String accessToken,
    required String userId,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyUserId, value: userId);
  }

  Future<String?> readAccessToken() => _storage.read(key: _keyAccessToken);

  Future<String?> readUserId() => _storage.read(key: _keyUserId);

  Future<void> clear() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyUserId);
  }
}

import 'package:http/http.dart' as http;

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/network/api_response.dart';

class AuthRepository {
  AuthRepository({required this.client});

  final ApiClient client;

  /// [phone] is 10-digit Indian mobile without country code, e.g. 9876543210.
  Future<void> sendOtp(String phone) async {
    final http.Response res = await client.postJson(
      '/auth/send-otp',
      <String, dynamic>{'phone': phone},
      bearer: false,
    );
    final ApiEnvelope<Map<String, dynamic>> env = ApiClient.parseEnvelope(res);
    if (!env.success) {
      throw AuthException(env.error ?? 'Failed to send OTP');
    }
  }

  /// Returns access token and user id from verify-otp.
  /// [phone] matches [sendOtp]: 10-digit local number without country code.
  Future<({String accessToken, String userId})> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final http.Response res = await client.postJson(
      '/auth/verify-otp',
      <String, dynamic>{
        'phone': phone,
        'otp': otp,
      },
      bearer: false,
    );
    final ApiEnvelope<Map<String, dynamic>> env = ApiClient.parseEnvelope(res);
    if (!env.success || env.data == null) {
      throw AuthException(env.error ?? 'Invalid OTP');
    }
    final String? token = env.data!['access_token'] as String?;
    final String? userId = env.data!['user_id'] as String?;
    if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
      throw AuthException('Malformed auth response');
    }
    return (accessToken: token, userId: userId);
  }
}

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
